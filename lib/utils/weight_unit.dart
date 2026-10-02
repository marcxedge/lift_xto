import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unidad de peso preferida para mostrar/ingresar valores. Internamente
/// TODO se sigue guardando en kg (SQLite, Firestore, cálculos de volumen/
/// 1RM) — esto sólo afecta cómo se muestra y se escribe en los
/// formularios, nunca cómo se persiste.
enum WeightUnit { kg, lb }

const _kgPerLb = 0.45359237;

extension WeightUnitX on WeightUnit {
  String get suffix => this == WeightUnit.kg ? 'kg' : 'lb';
  String get label => this == WeightUnit.kg ? 'Kilogramos (kg)' : 'Libras (lb)';

  double fromKg(double kg) => this == WeightUnit.kg ? kg : kg / _kgPerLb;

  double toKg(double value) => this == WeightUnit.kg ? value : value * _kgPerLb;
}

/// Controlador global de la unidad de peso preferida. Mismo patrón que
/// `ThemeController`: un `ValueNotifier` persistido en SharedPreferences,
/// consultado por cada pantalla que muestra o pide un peso.
class WeightUnitController {
  WeightUnitController._();
  static final WeightUnitController instance = WeightUnitController._();

  static const _kPrefKey = 'weight_unit';

  final ValueNotifier<WeightUnit> unit = ValueNotifier(WeightUnit.kg);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    unit.value = prefs.getString(_kPrefKey) == 'lb' ? WeightUnit.lb : WeightUnit.kg;
  }

  Future<void> set(WeightUnit value) async {
    unit.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefKey, value == WeightUnit.lb ? 'lb' : 'kg');
  }

  Future<void> toggle() => set(unit.value == WeightUnit.kg ? WeightUnit.lb : WeightUnit.kg);

  /// Convierte un valor almacenado en kg a la unidad activa y lo formatea
  /// con sufijo, listo para mostrar (ej. "82 kg" o "180.6 lb").
  String format(double? kg) {
    if (kg == null) return '—';
    return '${formatNumber(kg)} ${unit.value.suffix}';
  }

  /// Igual que [format] pero sin el sufijo — para cuando el sufijo ya se
  /// muestra aparte (ej. en el label de un campo).
  String formatNumber(double kg) {
    final v = unit.value.fromKg(kg);
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  }
}
