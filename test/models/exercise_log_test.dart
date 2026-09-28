import 'package:flutter_test/flutter_test.dart';
import 'package:lift_xto/models/exercise_log.dart';

void main() {
  group('ExerciseLog — serialización', () {
    final date = DateTime(2025, 6, 15, 10, 30);

    final log = ExerciseLog(
      id: 1,
      exerciseId: 42,
      date: date,
      weightKg: 80.0,
      setsCompleted: 4,
      repsCompleted: 10,
      notes: 'Buen día',
    );

    test('toMap incluye todos los campos', () {
      final map = log.toMap();
      expect(map['id'], 1);
      expect(map['exercise_id'], 42);
      expect(map['date'], date.toIso8601String());
      expect(map['weight_kg'], 80.0);
      expect(map['sets_completed'], 4);
      expect(map['reps_completed'], 10);
      expect(map['notes'], 'Buen día');
    });

    test('toMap omite el id cuando es null', () {
      final noId = ExerciseLog(exerciseId: 1, date: date);
      final map = noId.toMap();
      expect(map.containsKey('id'), isFalse);
    });

    test('fromMap reconstruye idéntico', () {
      final rebuilt = ExerciseLog.fromMap(log.toMap());
      expect(rebuilt.id, log.id);
      expect(rebuilt.exerciseId, log.exerciseId);
      expect(rebuilt.date, log.date);
      expect(rebuilt.weightKg, log.weightKg);
      expect(rebuilt.setsCompleted, log.setsCompleted);
      expect(rebuilt.repsCompleted, log.repsCompleted);
      expect(rebuilt.notes, log.notes);
    });

    test('fromMap con campos opcionales nulos', () {
      final map = {
        'exercise_id': 5,
        'date': date.toIso8601String(),
      };
      final rebuilt = ExerciseLog.fromMap(map);
      expect(rebuilt.id, isNull);
      expect(rebuilt.weightKg, isNull);
      expect(rebuilt.durationSeconds, isNull);
      expect(rebuilt.notes, isNull);
    });

    test('fromMap convierte height_cm numérico a double', () {
      // Sqflite puede devolver enteros cuando el valor es exacto
      final map = {
        'exercise_id': 5,
        'date': date.toIso8601String(),
        'weight_kg': 75, // entero desde la BD
      };
      final rebuilt = ExerciseLog.fromMap(map);
      expect(rebuilt.weightKg, 75.0);
      expect(rebuilt.weightKg, isA<double>());
    });
  });
}
