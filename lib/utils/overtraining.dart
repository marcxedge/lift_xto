import '../models/exercise_log.dart';

/// Resultado de analizar si el progreso reciente se estancó en varios
/// ejercicios a la vez — señal de posible sobreentrenamiento o de que
/// conviene una semana de descarga.
class OvertrainingSignal {
  const OvertrainingSignal({
    required this.stagnantCount,
    required this.totalChecked,
  });

  /// Ejercicios con suficiente historial (≥3 sesiones con peso) cuya
  /// última sesión no superó el mejor 1RM estimado de las 2 sesiones
  /// anteriores.
  final int stagnantCount;

  /// Cuántos ejercicios tenían suficiente historial como para evaluarse.
  final int totalChecked;

  /// Se activa sólo si hay al menos 2 ejercicios evaluables y la mitad o
  /// más están estancados — una sola rutina floja no dispara la alerta,
  /// evita falsos positivos por una mala noche de sueño puntual.
  bool get triggered => totalChecked >= 2 && stagnantCount / totalChecked >= 0.5;
}

double _estimated1Rm(ExerciseLog log) {
  final weight = log.weightKg ?? 0;
  final reps = log.repsCompleted ?? 0;
  return weight * (1 + reps / 30);
}

/// Analiza el historial de cada ejercicio (una lista de logs por
/// ejercicio, ordenados por fecha ascendente — mismo orden que devuelve
/// `ExerciseLogRepository.logsForExercise`) y determina cuántos muestran
/// estancamiento: la última sesión no mejoró el 1RM estimado de las 2
/// sesiones previas. Pura función de estadística sobre datos ya
/// registrados — sin IA, sin heurísticas ocultas.
OvertrainingSignal computeOvertrainingSignal(List<List<ExerciseLog>> logsByExercise) {
  var stagnant = 0;
  var checked = 0;

  for (final logs in logsByExercise) {
    final weighted = logs.where((l) => l.weightKg != null).toList();
    if (weighted.length < 3) continue;
    checked++;

    final last = weighted.last;
    final previous = weighted.sublist(0, weighted.length - 1);
    final recentPrevious =
        previous.length > 2 ? previous.sublist(previous.length - 2) : previous;
    final recentBest =
        recentPrevious.map(_estimated1Rm).reduce((a, b) => a > b ? a : b);

    if (_estimated1Rm(last) <= recentBest) stagnant++;
  }

  return OvertrainingSignal(stagnantCount: stagnant, totalChecked: checked);
}
