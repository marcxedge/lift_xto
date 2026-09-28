import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../database/database_helper.dart';
import '../models/exercise.dart';
import '../models/exercise_log.dart';

/// Resumen agregado (PR, último registro, sesiones) de un ejercicio. Usado
/// por la tab de Progreso.
class ExerciseProgress {
  const ExerciseProgress({
    required this.exercise,
    required this.prWeight,
    required this.prDuration,
    required this.logCount,
    required this.lastDate,
    required this.lastWeight,
    required this.lastDuration,
  });

  final Exercise exercise;
  final double? prWeight;
  final int? prDuration;
  final int logCount;
  final DateTime? lastDate;
  final double? lastWeight;
  final int? lastDuration;
}

/// Log de ejercicio enriquecido con el nombre/tipo del ejercicio asociado,
/// usado para calcular volumen por grupo muscular.
class MuscleVolumeLog {
  const MuscleVolumeLog({
    required this.exerciseName,
    required this.trackingType,
    this.weightKg,
    this.setsCompleted,
    this.repsCompleted,
    this.durationSeconds,
  });

  final String exerciseName;
  final String trackingType;
  final double? weightKg;
  final double? setsCompleted;
  final double? repsCompleted;
  final double? durationSeconds;
}

/// Repositorio de registros de ejercicio (sobrecarga progresiva). Además del
/// CRUD básico, expone las dos consultas agregadas que antes vivían
/// embebidas como `rawQuery` dentro de las pantallas de Progreso y Mapa
/// Muscular — moverlas acá separa la lógica de datos de la de presentación.
class ExerciseLogRepository extends ChangeNotifier {
  ExerciseLogRepository(this._db);

  final DatabaseHelper _db;

  Future<List<ExerciseLog>> logsForExercise(int exerciseId) async {
    try {
      return await _db.getLogsForExercise(exerciseId);
    } catch (e) {
      throw AppException('No se pudo cargar el historial.', cause: e);
    }
  }

  Future<ExerciseLog?> lastLog(int exerciseId) async {
    try {
      return await _db.getLastLog(exerciseId);
    } catch (e) {
      throw AppException('No se pudo cargar el último registro.', cause: e);
    }
  }

  Future<void> add(ExerciseLog log) async {
    try {
      await _db.insertExerciseLog(log);
      notifyListeners();
    } catch (e) {
      throw AppException('No se pudo guardar el registro.', cause: e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _db.deleteExerciseLog(id);
      notifyListeners();
    } catch (e) {
      throw AppException('No se pudo eliminar el registro.', cause: e);
    }
  }

  Future<List<ExerciseProgress>> progressSummary() async {
    try {
      final rows = await _db.getAllExerciseProgress();
      return rows.map((row) {
        return ExerciseProgress(
          exercise: Exercise.fromMap(row),
          prWeight: (row['pr_weight'] as num?)?.toDouble(),
          prDuration: row['pr_duration'] as int?,
          logCount: (row['log_count'] as int?) ?? 0,
          lastDate: row['last_date'] == null
              ? null
              : DateTime.parse(row['last_date'] as String),
          lastWeight: (row['last_weight'] as num?)?.toDouble(),
          lastDuration: row['last_duration'] as int?,
        );
      }).toList();
    } catch (e) {
      throw AppException('No se pudo cargar el progreso.', cause: e);
    }
  }

  Future<List<MuscleVolumeLog>> logsWithExerciseSince(DateTime since) async {
    try {
      final rows = await _db.getLogsWithExerciseSince(since);
      return rows
          .map(
            (row) => MuscleVolumeLog(
              exerciseName: row['name'] as String,
              trackingType: row['tracking_type'] as String,
              weightKg: (row['weight_kg'] as num?)?.toDouble(),
              setsCompleted: (row['sets_completed'] as num?)?.toDouble(),
              repsCompleted: (row['reps_completed'] as num?)?.toDouble(),
              durationSeconds: (row['duration_seconds'] as num?)?.toDouble(),
            ),
          )
          .toList();
    } catch (e) {
      throw AppException('No se pudo cargar el mapa muscular.', cause: e);
    }
  }
}
