/// Calcula la racha de constancia: días consecutivos con ejercicios
/// programados en la rutina que sí se entrenaron. Los días que la rutina
/// marca como libres (sin ejercicios asignados para ese día de la semana)
/// no cortan la racha — sólo importan los días en que había algo
/// planeado.
///
/// Función pura (sin tocar SQLite) para poder testearla directo — ver
/// `ExerciseLogRepository.currentStreak()` para quien arma los datos.
int computeStreak({
  required Set<int> trainingWeekdays,
  required Set<DateTime> loggedDates,
  DateTime? now,
}) {
  if (trainingWeekdays.isEmpty) return 0;

  DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  var day = dateOnly(now ?? DateTime.now());

  // Si hoy es día de entrenar pero todavía no se registró nada, el día no
  // "terminó" — no penalizamos la racha por eso, arrancamos a contar desde
  // ayer en vez de cortarla en seco.
  if (trainingWeekdays.contains(day.weekday) && !loggedDates.contains(day)) {
    day = day.subtract(const Duration(days: 1));
  }

  var streak = 0;
  var daysChecked = 0;
  const maxDaysBack = 365 * 2;
  while (daysChecked < maxDaysBack) {
    if (trainingWeekdays.contains(day.weekday)) {
      if (loggedDates.contains(day)) {
        streak++;
      } else {
        break;
      }
    }
    day = day.subtract(const Duration(days: 1));
    daysChecked++;
  }
  return streak;
}

/// Igual que [computeStreak], pero recorre todo el historial (desde el
/// primer registro hasta hoy) para encontrar la racha más larga que el
/// usuario tuvo alguna vez — no sólo la que está activa ahora. Usado en el
/// resumen "Wrapped".
int computeLongestStreak({
  required Set<int> trainingWeekdays,
  required Set<DateTime> loggedDates,
  DateTime? now,
}) {
  if (trainingWeekdays.isEmpty || loggedDates.isEmpty) return 0;

  DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  final today = dateOnly(now ?? DateTime.now());
  final earliest = loggedDates.reduce((a, b) => a.isBefore(b) ? a : b);

  var longest = 0;
  var current = 0;
  var day = earliest;
  while (!day.isAfter(today)) {
    if (trainingWeekdays.contains(day.weekday)) {
      if (loggedDates.contains(day)) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 0;
      }
    }
    day = day.add(const Duration(days: 1));
  }
  return longest;
}
