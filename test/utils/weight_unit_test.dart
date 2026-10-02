import 'package:flutter_test/flutter_test.dart';
import 'package:lift_xto/utils/weight_unit.dart';

void main() {
  group('WeightUnitX conversions', () {
    test('kg se muestra sin conversión', () {
      expect(WeightUnit.kg.fromKg(100), 100);
      expect(WeightUnit.kg.toKg(100), 100);
    });

    test('kg -> lb', () {
      expect(WeightUnit.lb.fromKg(100).toStringAsFixed(2), '220.46');
      expect(WeightUnit.lb.fromKg(1).toStringAsFixed(4), '2.2046');
    });

    test('lb -> kg (viaje de ida y vuelta no pierde precisión relevante)', () {
      const originalKg = 82.5;
      final lb = WeightUnit.lb.fromKg(originalKg);
      final backToKg = WeightUnit.lb.toKg(lb);
      expect(backToKg, closeTo(originalKg, 0.0001));
    });

    test('toKg invierte exactamente a fromKg', () {
      const kg = 50.0;
      final lb = WeightUnit.lb.fromKg(kg);
      expect(WeightUnit.lb.toKg(lb), closeTo(kg, 1e-9));
    });
  });
}
