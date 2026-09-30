import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import 'auth_repository.dart';

/// Clave de SharedPreferences donde se guarda el uid de la última sesión
/// que tocó los datos locales de este dispositivo.
const _kLastUidPrefKey = 'sync_last_uid';

/// Decide si una fila remota debe pisar a la versión local, comparando
/// `updated_at` (ISO8601 UTC — comparable como texto). Función pura, sin
/// tocar Firestore ni SQLite, para poder testearla directo.
///
/// - Si no hay `remoteUpdatedAt`, nunca gana lo remoto.
/// - Si no hay `localUpdatedAt` (fila nueva localmente), gana lo remoto.
/// - Si no, gana el más reciente (estrictamente mayor).
bool remoteWinsConflict({
  required String? localUpdatedAt,
  required String? remoteUpdatedAt,
}) {
  if (remoteUpdatedAt == null) return false;
  if (localUpdatedAt == null) return true;
  return remoteUpdatedAt.compareTo(localUpdatedAt) > 0;
}

/// Orquesta la sincronización offline-first con Firestore, patrón outbox:
/// SQLite (`DatabaseHelper`) sigue siendo la única fuente de verdad para la
/// UI; este servicio sólo empuja filas `sync_status = 'pending'` cuando hay
/// sesión + conexión, y trae cambios remotos más nuevos. Ver
/// `lib/database/database_helper.dart` → sección SYNC SUPPORT para la
/// plomería de bajo nivel que usa.
class SyncService extends ChangeNotifier {
  SyncService({
    required DatabaseHelper db,
    required AuthRepository auth,
  })  : _db = db,
        _auth = auth {
    _auth.addListener(_onAuthChanged);
    if (_auth.isAvailable) {
      _connectivitySub =
          Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
    }
    // Nota: a propósito NO se dispara acá un refresh de `pendingCount` — el
    // constructor corre en paralelo con el resto del arranque de la app
    // (que ya está disparando sus propias lecturas iniciales a SQLite), y
    // sumarle otra tanda de queries justo en ese momento sólo agrega
    // contención sin necesidad. `main()` llama a `refreshPendingCount()`
    // una vez que la app ya está corriendo; `syncNow()` también lo hace al
    // empezar cada sincronización.
  }

  final DatabaseHelper _db;
  final AuthRepository _auth;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isOnline = true;
  bool _isSyncing = false;
  int _pendingCount = 0;
  DateTime? _lastSyncedAt;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  int get pendingCount => _pendingCount;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  bool get canSync => _auth.isAvailable && _auth.isSignedIn;

  void _onAuthChanged() {
    unawaited(_handleAuthChanged());
  }

  /// Si la sesión activa pertenece a un uid distinto del que generó los
  /// datos que hay ahora mismo en SQLite, los borra antes de sincronizar —
  /// si no, al cerrar sesión y entrar con otra cuenta en el mismo
  /// dispositivo se seguían viendo rutina/perfil/logs de la cuenta
  /// anterior (SQLite es una sola base compartida, sin aislamiento por
  /// cuenta).
  Future<void> _handleAuthChanged() async {
    if (_auth.isSignedIn) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final prefs = await SharedPreferences.getInstance();
        final lastUid = prefs.getString(_kLastUidPrefKey);
        if (lastUid != null && lastUid != uid) {
          await _db.clearLocalData();
          _lastSyncedAt = null;
        }
        await prefs.setString(_kLastUidPrefKey, uid);
      }
      requestSync();
    }
    notifyListeners();
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online != _isOnline) {
      _isOnline = online;
      notifyListeners();
    }
    if (online) requestSync();
  }

  /// Recalcula `pendingCount` contra SQLite. Pensado para llamarse una vez
  /// que la app ya terminó de arrancar (ver `main.dart`), no desde el
  /// constructor — evita sumar otra tanda de queries justo cuando el resto
  /// de la app también está haciendo sus lecturas iniciales.
  Future<void> refreshPendingCount() async {
    _pendingCount = await _db.countPendingRows();
    notifyListeners();
  }

  /// Dispara una sincronización "mejor esfuerzo" sin esperar el resultado.
  /// Es lo que llaman los repositorios después de cada escritura local
  /// (ver `lib/repositories/*.dart`) — si no hay sesión o conexión, no pasa
  /// nada; el dato queda `pending` y se sincroniza en el próximo trigger.
  void requestSync() {
    unawaited(syncNow());
  }

  /// Sincroniza ahora mismo. Pensado también para el botón manual del
  /// ícono ☁️ del AppBar (`SyncStatusButton`), que muestra el resultado.
  /// Devuelve `true` si terminó sin excepciones. Si no se puede sincronizar
  /// ahora (sin sesión/conexión) o ya hay una sincronización en curso,
  /// devuelve `false` sin reintentar — quien llama decide qué mensaje
  /// mostrar según `isOnline`/`isSyncing`.
  Future<bool> syncNow() async {
    await refreshPendingCount();
    if (!canSync || _isSyncing) return false;
    _isSyncing = true;
    notifyListeners();
    var ok = true;
    try {
      await _push();
      await _pull();
      _lastSyncedAt = DateTime.now().toUtc();
    } catch (_) {
      // Se reintenta en el próximo trigger automático; acá solo reportamos
      // el fallo para que quien llamó explícitamente pueda avisar.
      ok = false;
    } finally {
      _isSyncing = false;
      await refreshPendingCount();
      notifyListeners();
    }
    return ok;
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _connectivitySub?.cancel();
    super.dispose();
  }

  // ─────────────────────────────── PUSH ───────────────────────────────

  Future<void> _push() async {
    await _pushSimpleTable('exercises', _exerciseToDoc);
    await _pushSimpleTable('body_weight_logs', _bodyWeightToDoc);
    await _pushSimpleTable('body_measurements', _bodyMeasurementToDoc);
    await _pushExerciseLogs();
    await _pushProfile();
    await _pushTombstones();
  }

  Future<void> _pushSimpleTable(
    String table,
    Map<String, Object?> Function(Map<String, Object?> row) toDoc,
  ) async {
    final rows = await _db.getPendingRows(table);
    for (final row in rows) {
      final syncId = row['sync_id'] as String?;
      if (syncId == null) continue;
      await _collection(table).doc(syncId).set(
            toDoc(row),
            SetOptions(merge: true),
          );
      await _db.markSynced(table, row['id'] as int);
    }
  }

  Future<void> _pushExerciseLogs() async {
    final rows = await _db.getPendingRows('exercise_logs');
    for (final row in rows) {
      final syncId = row['sync_id'] as String?;
      if (syncId == null) continue;
      final exerciseSyncId =
          await _resolveExerciseSyncId(row['exercise_id'] as int);
      if (exerciseSyncId == null) continue;
      final doc = _exerciseLogToDoc(row)..['exerciseSyncId'] = exerciseSyncId;
      await _collection('exercise_logs')
          .doc(syncId)
          .set(doc, SetOptions(merge: true));
      await _db.markSynced('exercise_logs', row['id'] as int);
    }
  }

  Future<void> _pushProfile() async {
    final db = await _db.database;
    final rows = await db.query(
      'user_profile',
      where: 'id = ? AND sync_status = ?',
      whereArgs: [1, 'pending'],
      limit: 1,
    );
    if (rows.isEmpty) return;
    await _profileDoc().set(_profileToDoc(rows.first), SetOptions(merge: true));
    await _db.markSynced('user_profile', 1);
  }

  Future<void> _pushTombstones() async {
    final tombstones = await _db.getTombstones();
    for (final t in tombstones) {
      final table = t['table_name'] as String;
      final syncId = t['sync_id'] as String;
      final ref = table == 'user_profile' ? _profileDoc() : _collection(table).doc(syncId);
      await ref.set(
        {'deleted': true, 'updatedAt': Timestamp.now()},
        SetOptions(merge: true),
      );
      await _db.clearTombstone(t['id'] as int);
    }
  }

  Future<String?> _resolveExerciseSyncId(int localExerciseId) async {
    final db = await _db.database;
    final rows = await db.query(
      'exercises',
      columns: ['sync_id'],
      where: 'id = ?',
      whereArgs: [localExerciseId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['sync_id'] as String?;
  }

  // ─────────────────────────────── PULL ───────────────────────────────

  Future<void> _pull() async {
    // exercises antes que exercise_logs: los logs resuelven su FK contra
    // ejercicios que ya tienen que existir localmente.
    await _pullSimpleTable('exercises', _exerciseFromDoc);
    await _pullSimpleTable('body_weight_logs', _bodyWeightFromDoc);
    await _pullSimpleTable('body_measurements', _bodyMeasurementFromDoc);
    await _pullProfile();
    await _pullExerciseLogs();
  }

  Future<void> _pullSimpleTable(
    String table,
    Map<String, Object?> Function(String syncId, Map<String, Object?> data)
        fromDoc,
  ) async {
    final snapshot = await _sinceQuery(_collection(table)).get();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['deleted'] == true) {
        await _db.hardDeleteBySyncId(table, doc.id);
        continue;
      }
      await _db.upsertFromRemote(table, fromDoc(doc.id, data));
    }
  }

  Future<void> _pullExerciseLogs() async {
    final snapshot = await _sinceQuery(_collection('exercise_logs')).get();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['deleted'] == true) {
        await _db.hardDeleteBySyncId('exercise_logs', doc.id);
        continue;
      }
      final exerciseSyncId = data['exerciseSyncId'] as String?;
      if (exerciseSyncId == null) continue;
      final localExerciseId = await _resolveLocalExerciseId(exerciseSyncId);
      if (localExerciseId == null) continue; // el ejercicio padre no llegó (todavía)
      final row = _exerciseLogFromDoc(doc.id, data)
        ..['exercise_id'] = localExerciseId;
      await _db.upsertFromRemote('exercise_logs', row);
    }
  }

  Future<void> _pullProfile() async {
    final doc = await _profileDoc().get();
    final data = doc.data();
    if (data == null || data['deleted'] == true) return;

    final db = await _db.database;
    final existing = await db.query(
      'user_profile',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    final localUpdatedAt =
        existing.isNotEmpty ? existing.first['updated_at'] as String? : null;
    final remoteUpdatedAt = _fromTimestamp(data['updatedAt']);
    if (!remoteWinsConflict(
      localUpdatedAt: localUpdatedAt,
      remoteUpdatedAt: remoteUpdatedAt,
    )) {
      return;
    }

    // INSERT OR REPLACE en vez de UPDATE: en un dispositivo nuevo (o desde
    // que `_onCreate` dejó de sembrar un perfil vacío) puede no existir
    // todavía la fila id=1, y un UPDATE sobre una fila inexistente no hace
    // nada — el perfil remoto se perdía silenciosamente en el primer pull.
    await db.insert(
      'user_profile',
      {
        'id': 1,
        'first_name': data['firstName'],
        'last_name': data['lastName'],
        'height_cm': data['heightCm'],
        'birth_date': data['birthDate'],
        'gender': data['gender'],
        'updated_at': remoteUpdatedAt,
        'sync_status': 'synced',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int?> _resolveLocalExerciseId(String exerciseSyncId) async {
    final db = await _db.database;
    final rows = await db.query(
      'exercises',
      columns: ['id'],
      where: 'sync_id = ?',
      whereArgs: [exerciseSyncId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['id'] as int;
  }

  Query<Map<String, Object?>> _sinceQuery(
    CollectionReference<Map<String, Object?>> ref,
  ) {
    final since = _lastSyncedAt;
    if (since == null) return ref;
    return ref.where('updatedAt', isGreaterThan: Timestamp.fromDate(since));
  }

  // ─────────────────────── REFERENCIAS FIRESTORE ───────────────────────

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('SyncService: no hay sesión activa');
    return user.uid;
  }

  CollectionReference<Map<String, Object?>> _collection(String table) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection(table) as CollectionReference<Map<String, Object?>>;
  }

  /// El perfil es un único documento por usuario (no una colección con IDs
  /// generados por cliente como las demás tablas), para evitar que dos
  /// dispositivos creen cada uno "su" documento de perfil.
  DocumentReference<Map<String, Object?>> _profileDoc() {
    return FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .collection('profile')
            .doc('main')
        as DocumentReference<Map<String, Object?>>;
  }

  // ────────────────────── MAPEO FILA ↔ DOCUMENTO ──────────────────────

  Timestamp? _toTimestamp(String? iso) =>
      iso == null ? null : Timestamp.fromDate(DateTime.parse(iso));

  String? _fromTimestamp(Object? value) =>
      value is Timestamp ? value.toDate().toUtc().toIso8601String() : null;

  Map<String, Object?> _exerciseToDoc(Map<String, Object?> row) => {
        'updatedAt': _toTimestamp(row['updated_at'] as String?),
        'deleted': false,
        'dayOfWeek': row['day_of_week'],
        'name': row['name'],
        'sets': row['sets'],
        'repsMin': row['reps_min'],
        'repsMax': row['reps_max'],
        'durationSecondsMin': row['duration_seconds_min'],
        'durationSecondsMax': row['duration_seconds_max'],
        'trackingType': row['tracking_type'],
        'orderIndex': row['order_index'],
        'notes': row['notes'],
        'muscleGroup': row['muscle_group'],
      };

  Map<String, Object?> _exerciseFromDoc(
    String syncId,
    Map<String, Object?> data,
  ) =>
      {
        'sync_id': syncId,
        'updated_at': _fromTimestamp(data['updatedAt']),
        'day_of_week': data['dayOfWeek'],
        'name': data['name'],
        'sets': data['sets'],
        'reps_min': data['repsMin'],
        'reps_max': data['repsMax'],
        'duration_seconds_min': data['durationSecondsMin'],
        'duration_seconds_max': data['durationSecondsMax'],
        'tracking_type': data['trackingType'],
        'order_index': data['orderIndex'],
        'notes': data['notes'],
        'muscle_group': data['muscleGroup'],
      };

  Map<String, Object?> _bodyWeightToDoc(Map<String, Object?> row) => {
        'updatedAt': _toTimestamp(row['updated_at'] as String?),
        'deleted': false,
        'date': row['date'],
        'weightKg': row['weight_kg'],
        'notes': row['notes'],
      };

  Map<String, Object?> _bodyWeightFromDoc(
    String syncId,
    Map<String, Object?> data,
  ) =>
      {
        'sync_id': syncId,
        'updated_at': _fromTimestamp(data['updatedAt']),
        'date': data['date'],
        'weight_kg': data['weightKg'],
        'notes': data['notes'],
      };

  Map<String, Object?> _bodyMeasurementToDoc(Map<String, Object?> row) => {
        'updatedAt': _toTimestamp(row['updated_at'] as String?),
        'deleted': false,
        'date': row['date'],
        'waistCm': row['waist_cm'],
        'chestCm': row['chest_cm'],
        'hipCm': row['hip_cm'],
        'bicepCm': row['bicep_cm'],
        'thighCm': row['thigh_cm'],
        'calfCm': row['calf_cm'],
        'neckCm': row['neck_cm'],
        'notes': row['notes'],
      };

  Map<String, Object?> _bodyMeasurementFromDoc(
    String syncId,
    Map<String, Object?> data,
  ) =>
      {
        'sync_id': syncId,
        'updated_at': _fromTimestamp(data['updatedAt']),
        'date': data['date'],
        'waist_cm': data['waistCm'],
        'chest_cm': data['chestCm'],
        'hip_cm': data['hipCm'],
        'bicep_cm': data['bicepCm'],
        'thigh_cm': data['thighCm'],
        'calf_cm': data['calfCm'],
        'neck_cm': data['neckCm'],
        'notes': data['notes'],
      };

  Map<String, Object?> _exerciseLogToDoc(Map<String, Object?> row) => {
        'updatedAt': _toTimestamp(row['updated_at'] as String?),
        'deleted': false,
        'date': row['date'],
        'weightKg': row['weight_kg'],
        'setsCompleted': row['sets_completed'],
        'repsCompleted': row['reps_completed'],
        'durationSeconds': row['duration_seconds'],
        'notes': row['notes'],
      };

  Map<String, Object?> _exerciseLogFromDoc(
    String syncId,
    Map<String, Object?> data,
  ) =>
      {
        'sync_id': syncId,
        'updated_at': _fromTimestamp(data['updatedAt']),
        'date': data['date'],
        'weight_kg': data['weightKg'],
        'sets_completed': data['setsCompleted'],
        'reps_completed': data['repsCompleted'],
        'duration_seconds': data['durationSeconds'],
        'notes': data['notes'],
      };

  Map<String, Object?> _profileToDoc(Map<String, Object?> row) => {
        'updatedAt': _toTimestamp(row['updated_at'] as String?),
        'deleted': false,
        'firstName': row['first_name'],
        'lastName': row['last_name'],
        'heightCm': row['height_cm'],
        'birthDate': row['birth_date'],
        'gender': row['gender'],
      };
}
