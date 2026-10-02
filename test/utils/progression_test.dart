import 'package:flutter_test/flutter_test.dart';
import 'package:lift_xto/models/exercise.dart';
import 'package:lift_xto/models/exercise_log.dart';
import 'package:lift_xto/utils/muscle_groups.dart';
import 'package:lift_xto/utils/progression.dart';

void main() {
  group('suggestNextSession', () {
    final exercise = Exercise(
      dayOfWeek: 1,
      name: 'Press de banca',
      sets: 3,
      repsMin: 8,
      repsMax: 12,
      muscleGroup: MuscleGroup.pecho,
    );

    test('sin registro previo, no hay sugerencia', () {
      expect(suggestNextSession(exercise: exercise, lastLog: null), isNull);
    });

    test('ejercicio de duración nunca sugiere peso', () {
      final durationExercise = exercise.copyWith(
        trackingType: 'duration',
        repsMin: null,
        repsMax: null,
      );
      final last = ExerciseLog(
        exerciseId: 1,
        date: DateTime(2026, 1, 1),
        durationSeconds: 60,
      );
      expect(
        suggestNextSession(exercise: durationExercise, lastLog: last),
        isNull,
      );
    });

    test('llegó al máximo de reps -> sube el peso', () {
      final last = ExerciseLog(
        exerciseId: 1,
        date: DateTime(2026, 1, 1),
        weightKg: 60,
        repsCompleted: 12,
      );
      final s = suggestNextSession(exercise: exercise, lastLog: last)!;
      expect(s.weightKg, 62.5); // pecho -> incremento chico
      expect(s.reps, 8);
    });

    test('tren inferior recibe un incremento mayor al subir peso', () {
      final legExercise = exercise.copyWith(muscleGroup: MuscleGroup.cuadriceps);
      final last = ExerciseLog(
        exerciseId: 1,
        date: DateTime(2026, 1, 1),
        weightKg: 80,
        repsCompleted: 12,
      );
      final s = suggestNextSession(exercise: legExercise, lastLog: last)!;
      expect(s.weightKg, 85);
    });

    test('no llegó al mínimo de reps -> mismo peso, +1 rep', () {
      final last = ExerciseLog(
        exerciseId: 1,
        date: DateTime(2026, 1, 1),
        weightKg: 60,
        repsCompleted: 6,
      );
      final s = suggestNextSession(exercise: exercise, lastLog: last)!;
      expect(s.weightKg, 60);
      expect(s.reps, 7);
    });

    test('progreso normal -> mismo peso, intenta una rep más', () {
      final last = ExerciseLog(
        exerciseId: 1,
        date: DateTime(2026, 1, 1),
        weightKg: 60,
        repsCompleted: 9,
      );
      final s = suggestNextSession(exercise: exercise, lastLog: last)!;
      expect(s.weightKg, 60);
      expect(s.reps, 10);
    });
  });
}
