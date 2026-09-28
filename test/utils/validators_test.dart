import 'package:flutter_test/flutter_test.dart';
import 'package:lift_xto/utils/validators.dart';

void main() {
  group('Validators.weight', () {
    test('rechaza vacío cuando es requerido', () {
      expect(Validators.weight(''), 'Requerido');
      expect(Validators.weight(null), 'Requerido');
    });

    test('acepta vacío cuando no es requerido', () {
      expect(Validators.weight('', required: false), isNull);
    });

    test('rechaza texto no numérico', () {
      expect(Validators.weight('abc'), 'Número inválido');
    });

    test('acepta coma como separador decimal', () {
      expect(Validators.weight('22,5'), isNull);
    });

    test('rechaza valores fuera de rango', () {
      expect(Validators.weight('-1'), isNotNull);
      expect(Validators.weight('501'), isNotNull);
    });

    test('acepta el límite superior por defecto', () {
      expect(Validators.weight('500'), isNull);
    });

    test('respeta rangos custom (peso corporal)', () {
      expect(
        Validators.weight(
          '15',
          min: Validators.bodyWeightMin,
          max: Validators.bodyWeightMax,
        ),
        isNotNull,
      );
      expect(
        Validators.weight(
          '80',
          min: Validators.bodyWeightMin,
          max: Validators.bodyWeightMax,
        ),
        isNull,
      );
    });
  });

  group('Validators.height', () {
    test('opcional por defecto', () {
      expect(Validators.height(''), isNull);
    });

    test('rechaza estaturas fuera de rango humano', () {
      expect(Validators.height('10'), isNotNull);
      expect(Validators.height('300'), isNotNull);
    });

    test('acepta estaturas razonables', () {
      expect(Validators.height('178'), isNull);
    });
  });

  group('Validators.age', () {
    test('rechaza 0 y negativos', () {
      expect(Validators.age('0'), isNotNull);
      expect(Validators.age('-5'), isNotNull);
    });

    test('rechaza edades absurdas', () {
      expect(Validators.age('200'), isNotNull);
    });

    test('acepta edades válidas', () {
      expect(Validators.age('28'), isNull);
    });
  });

  group('Validators.sets / reps / durationSeconds', () {
    test('sets requiere al menos 1', () {
      expect(Validators.sets('0'), isNotNull);
      expect(Validators.sets('1'), isNull);
    });

    test('reps respeta el techo', () {
      expect(Validators.reps('1000'), isNotNull);
      expect(Validators.reps('999'), isNull);
    });

    test('durationSeconds respeta el techo de 4 horas', () {
      expect(Validators.durationSeconds('14401'), isNotNull);
      expect(Validators.durationSeconds('14400'), isNull);
    });
  });

  group('Validators.requiredText', () {
    test('rechaza vacío', () {
      expect(Validators.requiredText(''), isNotNull);
      expect(Validators.requiredText('   '), isNotNull);
    });

    test('rechaza texto más largo que el máximo', () {
      final tooLong = 'a' * 61;
      expect(Validators.requiredText(tooLong), isNotNull);
    });

    test('acepta texto válido', () {
      expect(Validators.requiredText('Press banca'), isNull);
    });
  });

  group('Validators.parseDecimal', () {
    test('interpreta coma y punto como separador decimal', () {
      expect(Validators.parseDecimal('22,5'), 22.5);
      expect(Validators.parseDecimal('22.5'), 22.5);
    });

    test('devuelve null para texto inválido', () {
      expect(Validators.parseDecimal('abc'), isNull);
    });
  });
}
