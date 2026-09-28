import 'package:flutter_test/flutter_test.dart';
import 'package:lift_xto/utils/constants.dart';

void main() {
  group('Weekday — names', () {
    test('name() retorna el nombre correcto para cada día', () {
      expect(Weekday.name(1), 'Lunes');
      expect(Weekday.name(2), 'Martes');
      expect(Weekday.name(3), 'Miércoles');
      expect(Weekday.name(4), 'Jueves');
      expect(Weekday.name(5), 'Viernes');
      expect(Weekday.name(6), 'Sábado');
      expect(Weekday.name(7), 'Domingo');
    });

    test('name() retorna cadena vacía para días inválidos', () {
      expect(Weekday.name(0), '');
      expect(Weekday.name(8), '');
      expect(Weekday.name(-1), '');
    });

    test('shortName() retorna la abreviación correcta', () {
      expect(Weekday.shortName(1), 'Lun');
      expect(Weekday.shortName(5), 'Vie');
      expect(Weekday.shortName(7), 'Dom');
    });

    test('shortName() retorna cadena vacía para días inválidos', () {
      expect(Weekday.shortName(0), '');
      expect(Weekday.shortName(9), '');
    });

    test('constantes tienen los valores ISO 8601 correctos', () {
      expect(Weekday.monday, 1);
      expect(Weekday.tuesday, 2);
      expect(Weekday.wednesday, 3);
      expect(Weekday.thursday, 4);
      expect(Weekday.friday, 5);
      expect(Weekday.saturday, 6);
      expect(Weekday.sunday, 7);
    });
  });

  group('TrackingType — constantes', () {
    test('weight es "weight"', () {
      expect(TrackingType.weight, 'weight');
    });

    test('duration es "duration"', () {
      expect(TrackingType.duration, 'duration');
    });

    test('los dos valores son distintos', () {
      expect(TrackingType.weight, isNot(equals(TrackingType.duration)));
    });
  });
}
