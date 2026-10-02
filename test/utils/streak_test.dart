import 'package:flutter_test/flutter_test.dart';
import 'package:lift_xto/utils/streak.dart';

void main() {
  group('computeStreak', () {
    test('sin días de entrenamiento configurados, la racha es 0', () {
      final now = DateTime(2026, 10, 2);
      expect(
        computeStreak(trainingWeekdays: const {}, loggedDates: {now}, now: now),
        0,
      );
    });

    test('cuenta los días consecutivos entrenados hasta hoy', () {
      final now = DateTime(2026, 10, 2);
      final weekdays = {
        for (var i = 0; i < 5; i++) now.subtract(Duration(days: i)).weekday,
      };
      final logged = {
        for (var i = 0; i < 5; i++) now.subtract(Duration(days: i)),
      };
      expect(
        computeStreak(trainingWeekdays: weekdays, loggedDates: logged, now: now),
        5,
      );
    });

    test('si hoy es día de entrenar pero no se registró aún, no rompe la racha', () {
      final now = DateTime(2026, 10, 2);
      final weekdays = {
        for (var i = 0; i < 4; i++) now.subtract(Duration(days: i)).weekday,
      };
      // Se registró ayer, hace 2 y hace 3 días, pero no hoy todavía.
      final logged = {
        for (var i = 1; i < 4; i++) now.subtract(Duration(days: i)),
      };
      expect(
        computeStreak(trainingWeekdays: weekdays, loggedDates: logged, now: now),
        3,
      );
    });

    test('un día programado sin registrar corta la racha ahí', () {
      final now = DateTime(2026, 10, 2);
      final weekdays = {
        for (var i = 0; i < 5; i++) now.subtract(Duration(days: i)).weekday,
      };
      final logged = {
        now,
        now.subtract(const Duration(days: 1)),
        // falta el registro de hace 2 días -> la racha corta ahí
        now.subtract(const Duration(days: 3)),
        now.subtract(const Duration(days: 4)),
      };
      expect(
        computeStreak(trainingWeekdays: weekdays, loggedDates: logged, now: now),
        2,
      );
    });

    test('un día libre en la rutina (sin ejercicios asignados) no corta la racha', () {
      final now = DateTime(2026, 10, 2);
      // Todos los días de la ventana son "de entrenar" salvo el de hace 2
      // días, que queda fuera de la rutina (día libre).
      final weekdays = {
        for (var i = 0; i < 5; i++)
          if (i != 2) now.subtract(Duration(days: i)).weekday,
      };
      final logged = {
        now,
        now.subtract(const Duration(days: 1)),
        now.subtract(const Duration(days: 3)),
        now.subtract(const Duration(days: 4)),
      };
      expect(
        computeStreak(trainingWeekdays: weekdays, loggedDates: logged, now: now),
        4,
      );
    });
  });

  group('computeLongestStreak', () {
    test('sin registros, es 0', () {
      final now = DateTime(2026, 10, 2);
      expect(
        computeLongestStreak(trainingWeekdays: {1, 2, 3, 4, 5}, loggedDates: {}, now: now),
        0,
      );
    });

    test('encuentra la racha más larga, aunque ya no esté activa', () {
      final now = DateTime(2026, 10, 10);
      final weekdays = {1, 2, 3, 4, 5, 6, 7}; // todos los días son de entrenar
      // Racha de 5 días (1 al 5 de octubre), luego un hueco, luego sólo 2
      // días activos ahora (9 y 10) -> la racha ACTUAL sería 2, pero la
      // MÁXIMA histórica fue 5.
      final logged = {
        DateTime(2026, 10, 1),
        DateTime(2026, 10, 2),
        DateTime(2026, 10, 3),
        DateTime(2026, 10, 4),
        DateTime(2026, 10, 5),
        DateTime(2026, 10, 9),
        DateTime(2026, 10, 10),
      };
      expect(
        computeLongestStreak(trainingWeekdays: weekdays, loggedDates: logged, now: now),
        5,
      );
      expect(
        computeStreak(trainingWeekdays: weekdays, loggedDates: logged, now: now),
        2,
      );
    });
  });
}
