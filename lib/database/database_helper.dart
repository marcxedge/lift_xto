import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/exercise.dart';
import '../models/exercise_log.dart';
import '../models/body_weight_log.dart';
import '../models/user_profile.dart';
import '../utils/muscle_groups.dart';

/// Helper de SQLite. Singleton para mantener una sola conexión.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'lift_xto.db';
  static const _dbVersion = 4;
  static const _uuid = Uuid();

  /// Tablas que participan de la sincronización con Firestore (ver
  /// `lib/sync/sync_service.dart`). Todas comparten las 4 columnas de
  /// sincronización: sync_id, sync_status, updated_at, deleted.
  static const syncTables = [
    'exercises',
    'exercise_logs',
    'body_weight_logs',
    'user_profile',
  ];

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Columnas de sincronización comunes a toda tabla en [syncTables]. Se
  /// agregan al final del `CREATE TABLE` de cada una.
  static const _syncColumnsSql = '''
        sync_id TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        updated_at TEXT,
        deleted INTEGER NOT NULL DEFAULT 0
  ''';

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day_of_week INTEGER NOT NULL,
        name TEXT NOT NULL,
        sets INTEGER NOT NULL,
        reps_min INTEGER,
        reps_max INTEGER,
        duration_seconds_min INTEGER,
        duration_seconds_max INTEGER,
        tracking_type TEXT NOT NULL DEFAULT 'weight',
        order_index INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        muscle_group TEXT,
        $_syncColumnsSql
      )
    ''');

    await db.execute('''
      CREATE TABLE exercise_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        weight_kg REAL,
        sets_completed INTEGER,
        reps_completed INTEGER,
        duration_seconds INTEGER,
        notes TEXT,
        $_syncColumnsSql,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE body_weight_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        weight_kg REAL NOT NULL,
        notes TEXT,
        $_syncColumnsSql
      )
    ''');

    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY,
        first_name TEXT,
        last_name TEXT,
        height_cm REAL,
        age INTEGER,
        gender TEXT,
        $_syncColumnsSql
      )
    ''');

    await _createTombstonesTable(db);

    // Índices útiles
    await db.execute(
      'CREATE INDEX idx_exercises_day ON exercises(day_of_week, order_index)',
    );
    await db.execute(
      'CREATE INDEX idx_logs_exercise_date ON exercise_logs(exercise_id, date)',
    );
    await db.execute(
      'CREATE INDEX idx_bw_date ON body_weight_logs(date)',
    );

    // Sin seed: una instalación nueva arranca sin ejercicios, para que cada
    // usuario arme su propia rutina desde cero. `getProfile()` ya devuelve
    // un `UserProfile` vacío si no hay fila, así que tampoco hace falta
    // insertar un perfil placeholder acá.
  }

  Future<void> _createTombstonesTable(Database db) async {
    await db.execute('''
      CREATE TABLE sync_tombstones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        sync_id TEXT NOT NULL,
        deleted_at TEXT NOT NULL
      )
    ''');
  }

  /// Migraciones incrementales. Cada bloque `if (oldVersion < N)` aplica los
  /// cambios necesarios para llevar la BD a la versión N.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v2: campos de nombre/apellido en user_profile.
      await db.execute('ALTER TABLE user_profile ADD COLUMN first_name TEXT');
      await db.execute('ALTER TABLE user_profile ADD COLUMN last_name TEXT');
    }
    if (oldVersion < 3) {
      // v3: columnas de sincronización con Firestore + tabla de tombstones
      // para propagar borrados. El backfill genera un UUID v4 por fila
      // existente directamente en SQL (randomblob), sin loop en Dart.
      for (final table in syncTables) {
        await db.execute('ALTER TABLE $table ADD COLUMN sync_id TEXT');
        await db.execute(
          "ALTER TABLE $table ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'pending'",
        );
        await db.execute('ALTER TABLE $table ADD COLUMN updated_at TEXT');
        await db.execute(
          'ALTER TABLE $table ADD COLUMN deleted INTEGER NOT NULL DEFAULT 0',
        );
        await db.execute('''
          UPDATE $table SET
            sync_id = lower(
              hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' ||
              substr(hex(randomblob(2)), 2) || '-' ||
              substr('89ab', abs(random()) % 4 + 1, 1) ||
              substr(hex(randomblob(2)), 2) || '-' || hex(randomblob(6))
            ),
            updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now'),
            sync_status = 'pending'
          WHERE sync_id IS NULL
        ''');
      }
      await _createTombstonesTable(db);
    }
    if (oldVersion < 4) {
      // v4: categorización muscular manual por ejercicio (antes se
      // detectaba al vuelo por el nombre). Backfill best-effort con el
      // detector existente para no perder el mapa muscular ya armado con
      // los ejercicios que el usuario ya tenía cargados.
      await db.execute('ALTER TABLE exercises ADD COLUMN muscle_group TEXT');
      final rows = await db.query('exercises', columns: ['id', 'name']);
      final now = DateTime.now().toUtc().toIso8601String();
      final batch = db.batch();
      for (final row in rows) {
        final assignment = MuscleDetector.detect(row['name'] as String);
        if (assignment.primary.isEmpty) continue;
        batch.update(
          'exercises',
          {
            'muscle_group': assignment.primary.first.name,
            'sync_status': 'pending',
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }
      await batch.commit(noResult: true);
    }
  }

  // ───────────────────────── SYNC STAMPING HELPERS ─────────────────────────

  /// Marca un mapa recién armado desde un modelo (que no conoce nada de
  /// sync) como una escritura local nueva: le asigna `sync_id` si no tenía,
  /// `sync_status = 'pending'` y `updated_at = ahora`.
  static Map<String, Object?> _stampForInsert(Map<String, Object?> map) {
    return {
      ...map,
      'sync_id': map['sync_id'] ?? _uuid.v4(),
      'sync_status': 'pending',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'deleted': 0,
    };
  }

  /// Igual que arriba, pero para un `UPDATE` (no toca `sync_id`: `db.update`
  /// sólo escribe las columnas presentes en el mapa, así que el `sync_id`
  /// ya guardado en la fila queda intacto).
  static Map<String, Object?> _stampForUpdate(Map<String, Object?> map) {
    return {
      ...map,
      'sync_status': 'pending',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Para upserts tipo `INSERT OR REPLACE` (perfil): a diferencia de
  /// `UPDATE`, `REPLACE` reescribe la fila entera, así que hay que traer el
  /// `sync_id` existente a mano para no perderlo.
  Future<Map<String, Object?>> _stampForReplace(
    Database db,
    String table,
    Object id,
    Map<String, Object?> map,
  ) async {
    final existing = await db.query(
      table,
      columns: ['sync_id'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    final existingSyncId =
        existing.isNotEmpty ? existing.first['sync_id'] as String? : null;
    return _stampForInsert({...map, 'sync_id': existingSyncId});
  }

  Future<void> _tombstone(Database db, String table, String? syncId) async {
    if (syncId == null) return;
    await db.insert('sync_tombstones', {
      'table_name': table,
      'sync_id': syncId,
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // ─────────────────────────── EXERCISES ───────────────────────────

  Future<List<Exercise>> getExercisesByDay(int dayOfWeek) async {
    final db = await database;
    final rows = await db.query(
      'exercises',
      where: 'day_of_week = ?',
      whereArgs: [dayOfWeek],
      orderBy: 'order_index ASC, id ASC',
    );
    return rows.map(Exercise.fromMap).toList();
  }

  Future<Exercise?> getExercise(int id) async {
    final db = await database;
    final rows = await db.query(
      'exercises',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Exercise.fromMap(rows.first);
  }

  Future<int> insertExercise(Exercise exercise) async {
    final db = await database;
    // Auto-asigna order_index al final del día si no se especificó
    final map = _stampForInsert(exercise.toMap());
    if (exercise.orderIndex == 0) {
      final result = await db.rawQuery(
        'SELECT COALESCE(MAX(order_index), -1) + 1 AS next_order '
            'FROM exercises WHERE day_of_week = ?',
        [exercise.dayOfWeek],
      );
      map['order_index'] = result.first['next_order'] as int;
    }
    return db.insert('exercises', map);
  }

  Future<int> updateExercise(Exercise exercise) async {
    final db = await database;
    return db.update(
      'exercises',
      _stampForUpdate(exercise.toMap()),
      where: 'id = ?',
      whereArgs: [exercise.id],
    );
  }

  Future<int> deleteExercise(int id) async {
    final db = await database;
    // Los logs de este ejercicio se borran en cascada a nivel SQLite; acá
    // los "tombstoneamos" primero para poder propagar el borrado a
    // Firestore también (la cascada no nos da la chance de hacerlo después).
    final logRows = await db.query(
      'exercise_logs',
      columns: ['sync_id'],
      where: 'exercise_id = ?',
      whereArgs: [id],
    );
    for (final row in logRows) {
      await _tombstone(db, 'exercise_logs', row['sync_id'] as String?);
    }
    final exRows = await db.query(
      'exercises',
      columns: ['sync_id'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (exRows.isNotEmpty) {
      await _tombstone(db, 'exercises', exRows.first['sync_id'] as String?);
    }
    return db.delete('exercises', where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────── EXERCISE LOGS ───────────────────────────

  Future<int> insertExerciseLog(ExerciseLog log) async {
    final db = await database;
    return db.insert('exercise_logs', _stampForInsert(log.toMap()));
  }

  Future<int> updateExerciseLog(ExerciseLog log) async {
    final db = await database;
    return db.update(
      'exercise_logs',
      _stampForUpdate(log.toMap()),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<int> deleteExerciseLog(int id) async {
    final db = await database;
    final rows = await db.query(
      'exercise_logs',
      columns: ['sync_id'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      await _tombstone(db, 'exercise_logs', rows.first['sync_id'] as String?);
    }
    return db.delete('exercise_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ExerciseLog>> getLogsForExercise(int exerciseId) async {
    final db = await database;
    final rows = await db.query(
      'exercise_logs',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'date ASC',
    );
    return rows.map(ExerciseLog.fromMap).toList();
  }

  /// Récord personal (mayor peso registrado) por ejercicio.
  Future<ExerciseLog?> getPersonalRecord(int exerciseId) async {
    final db = await database;
    final rows = await db.query(
      'exercise_logs',
      where: 'exercise_id = ? AND weight_kg IS NOT NULL',
      whereArgs: [exerciseId],
      orderBy: 'weight_kg DESC, date DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ExerciseLog.fromMap(rows.first);
  }

  /// Último registro de un ejercicio (cualquier tipo).
  Future<ExerciseLog?> getLastLog(int exerciseId) async {
    final db = await database;
    final rows = await db.query(
      'exercise_logs',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ExerciseLog.fromMap(rows.first);
  }

  // ─────────────────────────── BODY WEIGHT ───────────────────────────

  Future<int> insertBodyWeight(BodyWeightLog log) async {
    final db = await database;
    return db.insert('body_weight_logs', _stampForInsert(log.toMap()));
  }

  Future<int> updateBodyWeight(BodyWeightLog log) async {
    final db = await database;
    return db.update(
      'body_weight_logs',
      _stampForUpdate(log.toMap()),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<int> deleteBodyWeight(int id) async {
    final db = await database;
    final rows = await db.query(
      'body_weight_logs',
      columns: ['sync_id'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      await _tombstone(
        db,
        'body_weight_logs',
        rows.first['sync_id'] as String?,
      );
    }
    return db.delete('body_weight_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<BodyWeightLog>> getAllBodyWeights() async {
    final db = await database;
    final rows = await db.query('body_weight_logs', orderBy: 'date ASC');
    return rows.map(BodyWeightLog.fromMap).toList();
  }

  Future<BodyWeightLog?> getLatestBodyWeight() async {
    final db = await database;
    final rows = await db.query(
      'body_weight_logs',
      orderBy: 'date DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BodyWeightLog.fromMap(rows.first);
  }

  // ─────────────────────────── USER PROFILE ───────────────────────────

  Future<UserProfile> getProfile() async {
    final db = await database;
    final rows = await db.query(
      'user_profile',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (rows.isEmpty) return const UserProfile();
    return UserProfile.fromMap(rows.first);
  }

  Future<int> upsertProfile(UserProfile profile) async {
    final db = await database;
    final map = await _stampForReplace(
      db,
      'user_profile',
      profile.id,
      profile.toMap(),
    );
    return db.insert(
      'user_profile',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─────────────────────────── AGGREGATE QUERIES ───────────────────────────

  /// Fila cruda por ejercicio con su PR, último registro y conteo de
  /// sesiones, en un solo viaje a la base. Usado por
  /// `ExerciseLogRepository.progressSummary()`.
  Future<List<Map<String, Object?>>> getAllExerciseProgress() async {
    final db = await database;
    return db.rawQuery('''
      SELECT
        e.*,
        (SELECT MAX(weight_kg) FROM exercise_logs l WHERE l.exercise_id = e.id) AS pr_weight,
        (SELECT MAX(duration_seconds) FROM exercise_logs l WHERE l.exercise_id = e.id) AS pr_duration,
        (SELECT COUNT(*) FROM exercise_logs l WHERE l.exercise_id = e.id) AS log_count,
        (SELECT MAX(date) FROM exercise_logs l WHERE l.exercise_id = e.id) AS last_date,
        (SELECT weight_kg FROM exercise_logs l WHERE l.exercise_id = e.id ORDER BY date DESC LIMIT 1) AS last_weight,
        (SELECT duration_seconds FROM exercise_logs l WHERE l.exercise_id = e.id ORDER BY date DESC LIMIT 1) AS last_duration
      FROM exercises e
      ORDER BY e.day_of_week ASC, e.order_index ASC
    ''');
  }

  /// Logs de un período junto con nombre/tipo del ejercicio asociado. Usado
  /// por `ExerciseLogRepository.logsWithExerciseSince()` para el mapa
  /// muscular.
  Future<List<Map<String, Object?>>> getLogsWithExerciseSince(
    DateTime since,
  ) async {
    final db = await database;
    return db.rawQuery(
      '''
      SELECT
        l.weight_kg, l.sets_completed, l.reps_completed, l.duration_seconds,
        e.name, e.tracking_type, e.muscle_group
      FROM exercise_logs l
      JOIN exercises e ON e.id = l.exercise_id
      WHERE l.date >= ?
      ''',
      [since.toIso8601String().substring(0, 10)],
    );
  }

  // ─────────────────────────── SYNC SUPPORT ───────────────────────────
  //
  // Usado exclusivamente por `SyncService` (lib/sync/sync_service.dart).
  // DatabaseHelper sólo expone plomería genérica por tabla; toda la lógica
  // de qué hacer con esos datos (resolver FKs, decidir ganador de
  // conflicto, hablar con Firestore) vive en la capa de sync, no acá.

  Future<List<Map<String, Object?>>> getPendingRows(String table) async {
    final db = await database;
    return db.query(table, where: 'sync_status = ?', whereArgs: ['pending']);
  }

  Future<void> markSynced(String table, int id) async {
    final db = await database;
    await db.update(
      table,
      {'sync_status': 'synced'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> countPendingRows() async {
    final db = await database;
    var total = 0;
    for (final table in syncTables) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM $table WHERE sync_status = ?',
        ['pending'],
      );
      total += (result.first['c'] as int?) ?? 0;
    }
    final tombstones = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM sync_tombstones',
    );
    total += (tombstones.first['c'] as int?) ?? 0;
    return total;
  }

  /// Inserta o actualiza una fila local a partir de un documento remoto ya
  /// normalizado a columnas de [table] (incluyendo `sync_id` y
  /// `updated_at` en el mismo formato ISO8601 UTC que se usa localmente),
  /// resolviendo por `sync_id`. Si la fila local es igual o más nueva, no
  /// la pisa (last-write-wins). Devuelve el `id` local o `null` si no
  /// tenía `sync_id`.
  Future<int?> upsertFromRemote(
    String table,
    Map<String, Object?> remoteRow,
  ) async {
    final db = await database;
    final syncId = remoteRow['sync_id'] as String?;
    if (syncId == null) return null;

    final existing = await db.query(
      table,
      where: 'sync_id = ?',
      whereArgs: [syncId],
      limit: 1,
    );
    final row = Map<String, Object?>.from(remoteRow)
      ..['sync_status'] = 'synced';

    if (existing.isEmpty) {
      row.remove('id');
      return db.insert(table, row);
    }

    final localId = existing.first['id'] as int;
    final localUpdatedAt = existing.first['updated_at'] as String?;
    final remoteUpdatedAt = remoteRow['updated_at'] as String?;
    if (localUpdatedAt != null &&
        remoteUpdatedAt != null &&
        localUpdatedAt.compareTo(remoteUpdatedAt) >= 0) {
      return localId; // local es igual o más nuevo: no se pisa
    }

    row['id'] = localId;
    await db.update(table, row, where: 'id = ?', whereArgs: [localId]);
    return localId;
  }

  /// Borra localmente (si existe) la fila con este `sync_id` — usado al
  /// detectar en `pull()` que otro dispositivo la eliminó.
  Future<void> hardDeleteBySyncId(String table, String syncId) async {
    final db = await database;
    await db.delete(table, where: 'sync_id = ?', whereArgs: [syncId]);
  }

  Future<List<Map<String, Object?>>> getTombstones() async {
    final db = await database;
    return db.query('sync_tombstones');
  }

  Future<void> clearTombstone(int id) async {
    final db = await database;
    await db.delete('sync_tombstones', where: 'id = ?', whereArgs: [id]);
  }
}
