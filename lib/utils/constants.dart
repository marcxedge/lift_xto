// Días de la semana (1 = Lunes ... 7 = Domingo, ISO 8601)
class Weekday {
  static const monday = 1;
  static const tuesday = 2;
  static const wednesday = 3;
  static const thursday = 4;
  static const friday = 5;
  static const saturday = 6;
  static const sunday = 7;

  static const Map<int, String> names = {
    1: 'Lunes',
    2: 'Martes',
    3: 'Miércoles',
    4: 'Jueves',
    5: 'Viernes',
    6: 'Sábado',
    7: 'Domingo',
  };

  static const Map<int, String> shortNames = {
    1: 'Lun',
    2: 'Mar',
    3: 'Mié',
    4: 'Jue',
    5: 'Vie',
    6: 'Sáb',
    7: 'Dom',
  };

  static String name(int day) => names[day] ?? '';
  static String shortName(int day) => shortNames[day] ?? '';
}

/// Tipo de seguimiento de un ejercicio.
/// - weight: se registra peso x reps (ejercicios con carga)
/// - duration: se registra tiempo (planchas, cardio, trote)
class TrackingType {
  static const weight = 'weight';
  static const duration = 'duration';
}