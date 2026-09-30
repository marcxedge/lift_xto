/// Una "sesión" de medidas corporales (cinta métrica) en una fecha dada.
/// Cada campo es opcional porque el usuario puede medirse sólo una o dos
/// zonas en vez de todas — complementa el peso/IMC con composición
/// corporal aproximada (¿lo que cambia es músculo o grasa?).
class BodyMeasurement {
  final int? id;
  final DateTime date;
  final double? waistCm;
  final double? chestCm;
  final double? hipCm;
  final double? bicepCm;
  final double? thighCm;
  final double? calfCm;
  final double? neckCm;
  final String? notes;

  const BodyMeasurement({
    this.id,
    required this.date,
    this.waistCm,
    this.chestCm,
    this.hipCm,
    this.bicepCm,
    this.thighCm,
    this.calfCm,
    this.neckCm,
    this.notes,
  });

  /// `true` si al menos una medida tiene valor — usado para validar que el
  /// formulario no se guarde completamente vacío.
  bool get hasAnyValue =>
      waistCm != null ||
      chestCm != null ||
      hipCm != null ||
      bicepCm != null ||
      thighCm != null ||
      calfCm != null ||
      neckCm != null;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date.toIso8601String(),
      'waist_cm': waistCm,
      'chest_cm': chestCm,
      'hip_cm': hipCm,
      'bicep_cm': bicepCm,
      'thigh_cm': thighCm,
      'calf_cm': calfCm,
      'neck_cm': neckCm,
      'notes': notes,
    };
  }

  factory BodyMeasurement.fromMap(Map<String, dynamic> map) {
    return BodyMeasurement(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      waistCm: (map['waist_cm'] as num?)?.toDouble(),
      chestCm: (map['chest_cm'] as num?)?.toDouble(),
      hipCm: (map['hip_cm'] as num?)?.toDouble(),
      bicepCm: (map['bicep_cm'] as num?)?.toDouble(),
      thighCm: (map['thigh_cm'] as num?)?.toDouble(),
      calfCm: (map['calf_cm'] as num?)?.toDouble(),
      neckCm: (map['neck_cm'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
    );
  }
}

/// Las 7 zonas medibles, con su etiqueta en español — usado tanto por el
/// formulario de carga como por el selector de métrica del gráfico.
enum MeasurementField {
  waist,
  chest,
  hip,
  bicep,
  thigh,
  calf,
  neck,
}

extension MeasurementFieldX on MeasurementField {
  String get label {
    switch (this) {
      case MeasurementField.waist:
        return 'Cintura';
      case MeasurementField.chest:
        return 'Pecho';
      case MeasurementField.hip:
        return 'Cadera';
      case MeasurementField.bicep:
        return 'Bíceps';
      case MeasurementField.thigh:
        return 'Muslo';
      case MeasurementField.calf:
        return 'Pantorrilla';
      case MeasurementField.neck:
        return 'Cuello';
    }
  }

  double? valueIn(BodyMeasurement m) {
    switch (this) {
      case MeasurementField.waist:
        return m.waistCm;
      case MeasurementField.chest:
        return m.chestCm;
      case MeasurementField.hip:
        return m.hipCm;
      case MeasurementField.bicep:
        return m.bicepCm;
      case MeasurementField.thigh:
        return m.thighCm;
      case MeasurementField.calf:
        return m.calfCm;
      case MeasurementField.neck:
        return m.neckCm;
    }
  }
}
