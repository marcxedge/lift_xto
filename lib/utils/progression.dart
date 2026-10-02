import '../models/exercise.dart';
import '../models/exercise_log.dart';
import 'constants.dart';
import 'muscle_groups.dart';

/// Sugerencia de progresión para la próxima sesión de un ejercicio con
/// carga — nunca se guarda sola, sólo precarga el formulario de registro
/// para que el usuario la confirme o la cambie.
class ProgressionSuggestion {
  const ProgressionSuggestion({
    required this.weightKg,
    required this.reps,
    required this.reason,
  });

  final double weightKg;
  final int? reps;
  final String reason;
}

/// Grupos de tren inferior — reciben un incremento de peso más grande que
/// el resto (convención habitual de gimnasio: las piernas toleran saltos
/// más grandes que los ejercicios de brazos/hombro).
const _lowerBodyGroups = {
  MuscleGroup.cuadriceps,
  MuscleGroup.isquios,
  MuscleGroup.gluteos,
  MuscleGroup.pantorrilla,
  MuscleGroup.aductores,
  MuscleGroup.abductores,
};

/// Autorregulación simple de sobrecarga progresiva: mira el último
/// registro de este ejercicio y el rango de reps objetivo (`repsMin`/
/// `repsMax` del ejercicio) para sugerir peso/reps de la próxima sesión.
/// No usa IA ni heurísticas complejas — son las mismas reglas que
/// cualquier programa de fuerza básico: si llegaste al techo de reps, sube
/// peso; si no llegaste al piso, repite peso y suma una rep la próxima;
/// si no, intenta una rep más con el mismo peso.
///
/// Devuelve `null` si no hay suficiente información (ejercicio de
/// duración, sin registro previo, o sin peso en el último registro).
ProgressionSuggestion? suggestNextSession({
  required Exercise exercise,
  required ExerciseLog? lastLog,
}) {
  if (exercise.trackingType != TrackingType.weight) return null;
  if (lastLog == null || lastLog.weightKg == null) return null;

  final lastWeight = lastLog.weightKg!;
  final lastReps = lastLog.repsCompleted;
  final repsMin = exercise.repsMin;
  final repsMax = exercise.repsMax;
  final increment = _lowerBodyGroups.contains(exercise.muscleGroup) ? 5.0 : 2.5;

  if (repsMax != null && lastReps != null && lastReps >= repsMax) {
    return ProgressionSuggestion(
      weightKg: lastWeight + increment,
      reps: repsMin ?? lastReps,
      reason:
          'Completaste el máximo de reps la última vez — hora de subir el peso.',
    );
  }

  if (repsMin != null && lastReps != null && lastReps < repsMin) {
    return ProgressionSuggestion(
      weightKg: lastWeight,
      reps: lastReps + 1,
      reason: 'La última vez no llegaste al mínimo de reps — repite el peso.',
    );
  }

  final nextReps = (lastReps != null && (repsMax == null || lastReps < repsMax))
      ? lastReps + 1
      : lastReps;
  return ProgressionSuggestion(
    weightKg: lastWeight,
    reps: nextReps,
    reason: 'Mismo peso que la última vez — intenta una repetición más.',
  );
}
