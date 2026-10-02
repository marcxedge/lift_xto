import '../repositories/exercise_log_repository.dart';
import 'muscle_groups.dart';

/// Un récord personal destacado en el resumen.
class WrappedPr {
  const WrappedPr({required this.exerciseName, required this.weightKg});
  final String exerciseName;
  final double weightKg;
}

/// Resumen histórico tipo "Wrapped": agrega todo lo que ya se registró
/// (sin pedir nada nuevo al usuario) en unos pocos números destacables,
/// pensado para compartir como imagen. Función pura — ver `WrappedScreen`
/// para quien junta los datos desde los repositorios.
class WrappedSummary {
  const WrappedSummary({
    required this.totalVolumeKg,
    required this.totalSessions,
    required this.longestStreak,
    required this.topMuscleGroup,
    required this.topPrs,
  });

  /// Suma de peso × series × repeticiones de todos los registros con
  /// carga, de siempre.
  final double totalVolumeKg;

  /// Días distintos con al menos un registro.
  final int totalSessions;

  /// Racha más larga que tuvo alguna vez (ver `computeLongestStreak`).
  final int longestStreak;

  /// Grupo muscular con más volumen acumulado (null si no hay datos).
  final MuscleGroup? topMuscleGroup;

  /// Hasta 3 récords personales, de mayor a menor peso.
  final List<WrappedPr> topPrs;

  bool get hasData => totalSessions > 0;
}

WrappedSummary computeWrappedSummary({
  required List<MuscleVolumeLog> allLogs,
  required List<ExerciseProgress> progress,
  required int longestStreak,
  required int totalSessions,
}) {
  var totalVolume = 0.0;
  final muscleVolume = <MuscleGroup, double>{};

  for (final row in allLogs) {
    if (row.trackingType != 'weight') continue;
    final w = row.weightKg ?? 0;
    final s = row.setsCompleted ?? 0;
    final r = row.repsCompleted ?? 0;
    final effort = w * s * r;
    if (effort <= 0) continue;
    totalVolume += effort;

    final assignment = MuscleDetector.resolve(row.muscleGroup, row.exerciseName);
    for (final g in assignment.primary) {
      muscleVolume[g] = (muscleVolume[g] ?? 0) + effort;
    }
    for (final g in assignment.secondary) {
      muscleVolume[g] = (muscleVolume[g] ?? 0) + effort * 0.5;
    }
  }

  MuscleGroup? topMuscle;
  if (muscleVolume.isNotEmpty) {
    topMuscle = muscleVolume.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  final prs = progress
      .where((p) => p.prWeight != null && p.prWeight! > 0)
      .map((p) => WrappedPr(exerciseName: p.exercise.name, weightKg: p.prWeight!))
      .toList()
    ..sort((a, b) => b.weightKg.compareTo(a.weightKg));

  return WrappedSummary(
    totalVolumeKg: totalVolume,
    totalSessions: totalSessions,
    longestStreak: longestStreak,
    topMuscleGroup: topMuscle,
    topPrs: prs.take(3).toList(),
  );
}
