import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controlador global del modo de tema. Expone un [ValueNotifier] para que
/// [MaterialApp] pueda reconstruirse al cambiar entre claro/oscuro/sistema y
/// persiste la elección en SharedPreferences.
class ThemeController {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const _kPrefKey = 'theme_mode';

  final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.dark);

  /// Lee el valor guardado y lo aplica. Llamar una vez al iniciar la app.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrefKey);
    mode.value = _decode(raw);
  }

  Future<void> set(ThemeMode value) async {
    mode.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefKey, _encode(value));
  }

  /// Cicla entre los tres modos: sistema → claro → oscuro → sistema.
  Future<void> cycle() async {
    switch (mode.value) {
      case ThemeMode.system:
        await set(ThemeMode.light);
        break;
      case ThemeMode.light:
        await set(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        await set(ThemeMode.system);
        break;
    }
  }

  static String _encode(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Sin preferencia guardada, la app arranca en modo oscuro por defecto
  /// (no sigue el tema del sistema salvo que el usuario lo elija a mano).
  static ThemeMode _decode(String? s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      case 'dark':
      default:
        return ThemeMode.dark;
    }
  }
}