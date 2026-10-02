import 'package:flutter_test/flutter_test.dart';
import 'package:lift_xto/models/exercise_log.dart';
import 'package:lift_xto/utils/overtraining.dart';

ExerciseLog _log(DateTime date, double weight, int reps) => ExerciseLog(
      exerciseId: 1,
      date: date,
      weightKg: weight,
      repsCompleted: reps,
      setsCompleted: 3,
    );

void main() {
  group('computeOvertrainingSignal', () {
    test('sin suficiente historial, no se activa', () {
      final logs = [
        [_log(DateTime(2026, 1, 1), 50, 10), _log(DateTime(2026, 1, 8), 55, 10)],
      ];
      final signal = computeOvertrainingSignal(logs);
      expect(signal.totalChecked, 0);
      expect(signal.triggered, isFalse);
    });

    test('progreso normal en todos los ejercicios, no se activa', () {
      final logs = [
        [
          _log(DateTime(2026, 1, 1), 50, 10),
          _log(DateTime(2026, 1, 8), 55, 10),
          _log(DateTime(2026, 1, 15), 60, 10),
        ],
        [
          _log(DateTime(2026, 1, 1), 40, 10),
          _log(DateTime(2026, 1, 8), 42, 10),
          _log(DateTime(2026, 1, 15), 45, 10),
        ],
      ];
      final signal = computeOvertrainingSignal(logs);
      expect(signal.totalChecked, 2);
      expect(signal.stagnantCount, 0);
      expect(signal.triggered, isFalse);
    });

    test('la mitad o más estancados activa la alerta', () {
      final logs = [
        // Estancado: la última sesión no supera el 1RM estimado previo.
        [
          _log(DateTime(2026, 1, 1), 60, 10),
          _log(DateTime(2026, 1, 8), 60, 10),
          _log(DateTime(2026, 1, 15), 60, 10),
        ],
        // En progreso.
        [
          _log(DateTime(2026, 1, 1), 40, 10),
          _log(DateTime(2026, 1, 8), 42, 10),
          _log(DateTime(2026, 1, 15), 46, 10),
        ],
      ];
      final signal = computeOvertrainingSignal(logs);
      expect(signal.totalChecked, 2);
      expect(signal.stagnantCount, 1);
      expect(signal.triggered, isTrue);
    });
  });
}
