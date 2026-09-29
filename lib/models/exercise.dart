import '../utils/constants.dart';
import '../utils/muscle_groups.dart';

class Exercise {
  final int? id;
  final int dayOfWeek; // 1..7
  final String name;
  final int sets;
  final int? repsMin;
  final int? repsMax;
  final int? durationSecondsMin;
  final int? durationSecondsMax;
  final String trackingType; // TrackingType.weight | TrackingType.duration
  final int orderIndex;
  final String? notes;
  final MuscleGroup? muscleGroup;

  const Exercise({
    this.id,
    required this.dayOfWeek,
    required this.name,
    required this.sets,
    this.repsMin,
    this.repsMax,
    this.durationSecondsMin,
    this.durationSecondsMax,
    this.trackingType = TrackingType.weight,
    this.orderIndex = 0,
    this.notes,
    this.muscleGroup,
  });

  /// Asignación muscular efectiva para mostrar en chips y alimentar el mapa
  /// muscular: prioriza el grupo elegido a mano y cae a la detección por
  /// nombre sólo para ejercicios viejos que nunca lo tuvieron seteado. Ver
  /// [MuscleDetector.resolve].
  MuscleAssignment get muscleAssignment =>
      MuscleDetector.resolve(muscleGroup, name);

  Exercise copyWith({
    int? id,
    int? dayOfWeek,
    String? name,
    int? sets,
    int? repsMin,
    int? repsMax,
    int? durationSecondsMin,
    int? durationSecondsMax,
    String? trackingType,
    int? orderIndex,
    String? notes,
    MuscleGroup? muscleGroup,
  }) {
    return Exercise(
      id: id ?? this.id,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      repsMin: repsMin ?? this.repsMin,
      repsMax: repsMax ?? this.repsMax,
      durationSecondsMin: durationSecondsMin ?? this.durationSecondsMin,
      durationSecondsMax: durationSecondsMax ?? this.durationSecondsMax,
      trackingType: trackingType ?? this.trackingType,
      orderIndex: orderIndex ?? this.orderIndex,
      notes: notes ?? this.notes,
      muscleGroup: muscleGroup ?? this.muscleGroup,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'day_of_week': dayOfWeek,
      'name': name,
      'sets': sets,
      'reps_min': repsMin,
      'reps_max': repsMax,
      'duration_seconds_min': durationSecondsMin,
      'duration_seconds_max': durationSecondsMax,
      'tracking_type': trackingType,
      'order_index': orderIndex,
      'notes': notes,
      'muscle_group': muscleGroup?.name,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as int?,
      dayOfWeek: map['day_of_week'] as int,
      name: map['name'] as String,
      sets: map['sets'] as int,
      repsMin: map['reps_min'] as int?,
      repsMax: map['reps_max'] as int?,
      durationSecondsMin: map['duration_seconds_min'] as int?,
      durationSecondsMax: map['duration_seconds_max'] as int?,
      trackingType: (map['tracking_type'] as String?) ?? TrackingType.weight,
      orderIndex: (map['order_index'] as int?) ?? 0,
      notes: map['notes'] as String?,
      muscleGroup: muscleGroupFromName(map['muscle_group'] as String?),
    );
  }

  /// Resumen tipo "3 x 8-12" o "3 x 30-60s"
  String get repsLabel {
    if (trackingType == TrackingType.duration) {
      if (durationSecondsMin != null && durationSecondsMax != null) {
        return '$sets x ${durationSecondsMin}-${durationSecondsMax}s';
      }
      if (durationSecondsMin != null) {
        return '$sets x ${durationSecondsMin}s';
      }
      return '$sets sets';
    }
    if (repsMin != null && repsMax != null) {
      return '$sets x $repsMin-$repsMax';
    }
    if (repsMin != null) {
      return '$sets x $repsMin';
    }
    return '$sets sets';
  }
}
