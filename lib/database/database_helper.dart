import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/exercise.dart';
import '../models/exercise_log.dart';
import '../models/body_weight_log.dart';
import '../models/user_profile.dart';
import 'default_routine.dart';

/// Helper de SQLite. Singleton para mantener una sola conexión.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'lift_xto.db';
  static const _dbVersion = 2;

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
        notes TEXT
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
        FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE body_weight_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        weight_kg REAL NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY,
        first_name TEXT,
        last_name TEXT,
        height_cm REAL,
        age INTEGER,
        gender TEXT
      )
    ''');

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

    // Seed: rutina por defecto + perfil vacío
    final batch = db.batch();
    for (final ex in DefaultRoutine.all()) {
      batch.insert('exercises', ex.toMap());
    }
    batch.insert('user_profile', const UserProfile().toMap());
    await batch.commit(noResult: true);
  }

  /// Migraciones incrementales. Cada bloque `if (oldVersion < N)` aplica los
  /// cambios necesarios para llevar la BD a la versión N.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v2: campos de nombre/apellido en user_profile.
      await db.execute('ALTER TABLE user_profile ADD COLUMN first_name TEXT');
      await db.execute('ALTER TABLE user_profile ADD COLUMN last_name TEXT');
    }
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
    final map = exercise.toMap();
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
      exercise.toMap(),
      where: 'id = ?',
      whereArgs: [exercise.id],
    );
  }

  Future<int> deleteExercise(int id) async {
    final db = await database;
    return db.delete('exercises', where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────── EXERCISE LOGS ───────────────────────────

  Future<int> insertExerciseLog(ExerciseLog log) async {
    final db = await database;
    return db.insert('exercise_logs', log.toMap());
  }

  Future<int> updateExerciseLog(ExerciseLog log) async {
    final db = await database;
    return db.update(
      'exercise_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<int> deleteExerciseLog(int id) async {
    final db = await database;
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
    return db.insert('body_weight_logs', log.toMap());
  }

  Future<int> updateBodyWeight(BodyWeightLog log) async {
    final db = await database;
    return db.update(
      'body_weight_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<int> deleteBodyWeight(int id) async {
    final db = await database;
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
    return db.insert(
      'user_profile',
      profile.toMap(),
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
        e.name, e.tracking_type
      FROM exercise_logs l
      JOIN exercises e ON e.id = l.exercise_id
      WHERE l.date >= ?
      ''',
      [since.toIso8601String().substring(0, 10)],
    );
  }
}