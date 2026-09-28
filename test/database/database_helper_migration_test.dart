import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lift_xto/database/database_helper.dart';

/// Verifica la migración v2 → v3 (columnas de sincronización con
/// Firestore): arma a mano una BD "vieja" (schema v2, sin columnas de
/// sync) con una fila real, y confirma que al abrirla con
/// `DatabaseHelper` (que corre en la versión actual) el backfill deja esa
/// fila lista para sincronizar.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('el backfill v2→v3 completa sync_id/sync_status/updated_at/deleted '
      'en filas preexistentes', () async {
    final path = join(await getDatabasesPath(), 'lift_xto.db');
    await databaseFactory.deleteDatabase(path);

    // 1) Simulamos una instalación existente en schema v2 (sin columnas de
    //    sync), con un ejercicio ya cargado por el usuario.
    final legacyDb = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, version) async {
          // Réplica del schema v2 real (antes de las columnas de sync),
          // con las 4 tablas que toca la migración v3.
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
        },
      ),
    );
    final legacyId = await legacyDb.insert('exercises', {
      'day_of_week': 1,
      'name': 'Press banca',
      'sets': 4,
      'reps_min': 6,
      'reps_max': 10,
      'tracking_type': 'weight',
      'order_index': 0,
    });
    await legacyDb.close();

    // 2) Abrimos con DatabaseHelper (versión actual = 3): dispara onUpgrade.
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'exercises',
      where: 'id = ?',
      whereArgs: [legacyId],
    );

    expect(rows, hasLength(1));
    final row = rows.first;

    expect(row['name'], 'Press banca', reason: 'no debe perder los datos existentes');

    final syncId = row['sync_id'] as String?;
    expect(syncId, isNotNull);
    expect(
      RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')
          .hasMatch(syncId!),
      isTrue,
      reason: 'sync_id debe ser un UUID v4 válido, fue: $syncId',
    );

    expect(row['sync_status'], 'pending');
    expect(row['updated_at'], isNotNull);
    expect(row['deleted'], 0);

    // 3) La tabla de tombstones también debe existir y estar vacía.
    final tombstones = await db.query('sync_tombstones');
    expect(tombstones, isEmpty);
  });
}
