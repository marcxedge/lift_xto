class ExerciseLog {
  final int? id;
  final int exerciseId;
  final DateTime date;
  final double? weightKg;        // null para ejercicios de duración
  final int? setsCompleted;
  final int? repsCompleted;
  final int? durationSeconds;    // para planchas / cardio
  final String? notes;

  const ExerciseLog({
    this.id,
    required this.exerciseId,
    required this.date,
    this.weightKg,
    this.setsCompleted,
    this.repsCompleted,
    this.durationSeconds,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'exercise_id': exerciseId,
      'date': date.toIso8601String(),
      'weight_kg': weightKg,
      'sets_completed': setsCompleted,
      'reps_completed': repsCompleted,
      'duration_seconds': durationSeconds,
      'notes': notes,
    };
  }

  factory ExerciseLog.fromMap(Map<String, dynamic> map) {
    return ExerciseLog(
      id: map['id'] as int?,
      exerciseId: map['exercise_id'] as int,
      date: DateTime.parse(map['date'] as String),
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      setsCompleted: map['sets_completed'] as int?,
      repsCompleted: map['reps_completed'] as int?,
      durationSeconds: map['duration_seconds'] as int?,
      notes: map['notes'] as String?,
    );
  }
}