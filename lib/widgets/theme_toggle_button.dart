import 'package:flutter/material.dart';

import '../utils/theme_controller.dart';

/// Botón que cicla entre los modos sistema → claro → oscuro y muestra un
/// icono distinto según el estado actual. Pensado para usarse dentro de
/// `AppBar.actions`.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.mode,
      builder: (context, mode, _) {
        final IconData icon;
        final String tooltip;
        switch (mode) {
          case ThemeMode.system:
            icon = Icons.brightness_auto;
            tooltip = 'Tema: sistema (tap para claro)';
            break;
          case ThemeMode.light:
            icon = Icons.light_mode;
            tooltip = 'Tema: claro (tap para oscuro)';
            break;
          case ThemeMode.dark:
            icon = Icons.dark_mode;
            tooltip = 'Tema: oscuro (tap para sistema)';
            break;
        }
        return IconButton(
          tooltip: tooltip,
          icon: Icon(icon),
          onPressed: () => ThemeController.instance.cycle(),
        );
      },
    );
  }
}