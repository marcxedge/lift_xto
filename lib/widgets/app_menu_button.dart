import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/wrapped_screen.dart';
import '../sync/auth_repository.dart';
import '../utils/feedback.dart';
import '../utils/theme_controller.dart';
import '../utils/weight_unit.dart';

enum _MenuAction { wrapped, toggleTheme, toggleWeightUnit, signOut }

/// Menú de opciones (⋮) del AppBar: agrupa el cambio de tema y "Cerrar
/// sesión" — antes eran un ícono suelto en el AppBar y un botón dentro del
/// sheet de cuenta/sincronización respectivamente.
class AppMenuButton extends StatelessWidget {
  const AppMenuButton({super.key});

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await context.read<AuthRepository>().signOut();
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.mode,
      builder: (context, mode, _) {
        final String themeLabel;
        final IconData themeIcon;
        switch (mode) {
          case ThemeMode.system:
            themeLabel = 'Sistema';
            themeIcon = Icons.brightness_auto;
            break;
          case ThemeMode.light:
            themeLabel = 'Claro';
            themeIcon = Icons.light_mode;
            break;
          case ThemeMode.dark:
            themeLabel = 'Oscuro';
            themeIcon = Icons.dark_mode;
            break;
        }
        return ValueListenableBuilder<WeightUnit>(
          valueListenable: WeightUnitController.instance.unit,
          builder: (context, unit, _) {
        return PopupMenuButton<_MenuAction>(
          tooltip: 'Más opciones',
          icon: const Icon(Icons.more_vert),
          onSelected: (action) {
            switch (action) {
              case _MenuAction.wrapped:
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WrappedScreen()),
                );
                break;
              case _MenuAction.toggleTheme:
                ThemeController.instance.cycle();
                break;
              case _MenuAction.toggleWeightUnit:
                WeightUnitController.instance.toggle();
                break;
              case _MenuAction.signOut:
                _signOut(context);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: _MenuAction.wrapped,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.insights),
                title: Text('Tu resumen'),
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: _MenuAction.toggleTheme,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(themeIcon),
                title: const Text('Cambiar tema'),
                subtitle: Text(themeLabel),
              ),
            ),
            PopupMenuItem(
              value: _MenuAction.toggleWeightUnit,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.scale),
                title: const Text('Unidad de peso'),
                subtitle: Text(unit.label),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: _MenuAction.signOut,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.logout),
                title: Text('Cerrar sesión'),
              ),
            ),
          ],
        );
          },
        );
      },
    );
  }
}
