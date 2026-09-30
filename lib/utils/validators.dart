/// Validadores centralizados con rangos físicamente razonables. Antes cada
/// formulario tenía su propia validación ad-hoc (algunas sólo chequeaban
/// `n >= 0`, sin techo), lo que permitía guardar valores absurdos (un peso
/// de 999999 kg, por ejemplo) que después rompían la escala de los gráficos.
/// Centralizarlos acá también evita divergencias entre formularios que
/// deberían validar lo mismo (p. ej. peso de log de ejercicio vs. peso
/// corporal).
class Validators {
  Validators._();

  // Rangos con sentido físico/real.
  static const weightLogMin = 0.0;
  static const weightLogMax = 500.0;
  static const bodyWeightMin = 20.0;
  static const bodyWeightMax = 300.0;
  static const heightMin = 50.0;
  static const heightMax = 250.0;
  /// Límites razonables para la fecha de nacimiento (ver `_datePicker` en
  /// `ProfileSetupScreen`/`ProfileSheet`): entre 1 y 120 años de edad.
  static const ageMin = 1;
  static const ageMax = 120;
  static const setsMin = 1;
  static const setsMax = 50;
  static const repsMin = 1;
  static const repsMax = 999;
  static const durationSecondsMin = 1;
  static const durationSecondsMax = 14400; // 4 horas
  static const shortTextMaxLength = 60;
  static const notesMaxLength = 200;

  static double? parseDecimal(String input) {
    return double.tryParse(input.trim().replaceAll(',', '.'));
  }

  /// Validador genérico para campos de peso (kg) obligatorios.
  static String? weight(
    String? value, {
    double min = weightLogMin,
    double max = weightLogMax,
    bool required = true,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return required ? 'Requerido' : null;
    final n = parseDecimal(trimmed);
    if (n == null) return 'Número inválido';
    if (n < min || n > max) {
      return 'Debe estar entre ${_fmt(min)} y ${_fmt(max)}';
    }
    return null;
  }

  static String? height(String? value, {bool required = false}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return required ? 'Requerido' : null;
    final n = parseDecimal(trimmed);
    if (n == null) return 'Número inválido';
    if (n < heightMin || n > heightMax) {
      return 'Debe estar entre ${_fmt(heightMin)} y ${_fmt(heightMax)} cm';
    }
    return null;
  }

  /// Validador genérico para enteros positivos (sets, reps, duración) con
  /// rango configurable.
  static String? integerInRange(
    String? value, {
    required int min,
    required int max,
    bool required = true,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return required ? 'Requerido' : null;
    final n = int.tryParse(trimmed);
    if (n == null) return 'Número inválido';
    if (n < min || n > max) return 'Debe estar entre $min y $max';
    return null;
  }

  static String? sets(String? value, {bool required = true}) =>
      integerInRange(value, min: setsMin, max: setsMax, required: required);

  static String? reps(String? value, {bool required = true}) =>
      integerInRange(value, min: repsMin, max: repsMax, required: required);

  static String? durationSeconds(String? value, {bool required = true}) =>
      integerInRange(
        value,
        min: durationSecondsMin,
        max: durationSecondsMax,
        required: required,
      );

  static String? requiredText(String? value, {int maxLength = shortTextMaxLength}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Requerido';
    if (trimmed.length > maxLength) return 'Máximo $maxLength caracteres';
    return null;
  }

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Requerido';
    if (!_emailRegex.hasMatch(trimmed)) return 'Correo inválido';
    return null;
  }

  /// Firebase Auth exige mínimo 6 caracteres para contraseñas por email.
  static const passwordMinLength = 6;

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Requerido';
    if (v.length < passwordMinLength) {
      return 'Mínimo $passwordMinLength caracteres';
    }
    return null;
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}
