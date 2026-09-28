class BodyWeightLog {
  final int? id;
  final DateTime date;
  final double weightKg;
  final String? notes;

  const BodyWeightLog({
    this.id,
    required this.date,
    required this.weightKg,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date.toIso8601String(),
      'weight_kg': weightKg,
      'notes': notes,
    };
  }

  factory BodyWeightLog.fromMap(Map<String, dynamic> map) {
    return BodyWeightLog(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      weightKg: (map['weight_kg'] as num).toDouble(),
      notes: map['notes'] as String?,
    );
  }
}