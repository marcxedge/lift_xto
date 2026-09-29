import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lift_xto/database/database_helper.dart';

/// Verifica las migraciones incrementales (v2→v3→v4) abriendo con
/// `DatabaseHelper` (que siempre corre en la versión actual) una BD armada
/// a mano en schema v2. Es un solo `test()` porque `DatabaseHelper` es un
/// singleton con una sola conexión cacheada — abrir dos BDs distintas en el
/// mismo proceso de test pisaría esa caché.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test(
    'el backfill v2→v3→v4 completa sync + muscle_group en filas '
    'preexistentes sin perder datos',
    () async {
      final path = join(await getDatabasesPath(), 'lift_xto.db');
      await databaseFactory.deleteDatabase(path);

      // 1) Simulamos una instalación existente en schema v2 (sin columnas de
      //    sync ni muscle_group), con dos ejercicios: uno que el detector
      //    por nombre reconoce, y otro con un nombre ambiguo que no matchea
      //    ningún patrón.
      final legacyDb = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, version) async {
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
      final ambiguousId = await legacyDb.insert('exercises', {
        'day_of_week': 1,
        'name': 'Ejercicio misterioso XYZ',
        'sets': 3,
        'tracking_type': 'weight',
        'order_index': 1,
      });
      await legacyDb.close();

      // 2) Abrimos con DatabaseHelper (versión actual = 4): dispara
      //    onUpgrade encadenando los bloques v3 y v4.
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'exercises',
        where: 'id = ?',
        whereArgs: [legacyId],
      );

      expect(rows, hasLength(1));
      final row = rows.first;

      expect(
        row['name'],
        'Press banca',
        reason: 'no debe perder los datos existentes',
      );

      final syncId = row['sync_id'] as String?;
      expect(syncId, isNotNull);
      expect(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ).hasMatch(syncId!),
        isTrue,
        reason: 'sync_id debe ser un UUID v4 válido, fue: $syncId',
      );

      expect(row['sync_status'], 'pending');
      expect(row['updated_at'], isNotNull);
      expect(row['deleted'], 0);
      expect(
        row['muscle_group'],
        'pecho',
        reason: 'el backfill v4 debe reconocer "Press banca" como pecho',
      );

      // 3) El ejercicio con nombre ambiguo no debe perder datos ni
      //    inventarse un grupo muscular que el detector no encontró.
      final ambiguousRow = (await db.query(
        'exercises',
        where: 'id = ?',
        whereArgs: [ambiguousId],
      )).first;
      expect(ambiguousRow['name'], 'Ejercicio misterioso XYZ');
      expect(ambiguousRow['muscle_group'], isNull);

      // 4) La tabla de tombstones también debe existir y estar vacía.
      final tombstones = await db.query('sync_tombstones');
      expect(tombstones, isEmpty);
    },
  );
}
