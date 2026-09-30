import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../sync/auth_repository.dart';
import '../utils/feedback.dart';
import '../utils/theme_controller.dart';

enum _MenuAction { toggleTheme, signOut }

/// Menú de opciones (⋮) del AppBar: agrupa el cambio de tema y "Cerrar
/// sesión" — antes eran un ícono suelto en el AppBar y un botón dentro del
/// sheet de cuenta/sincronización respectivamente.
class AppMenuButton extends StatelessWidget {
  const AppMenuButton({super.key});

  Future<void> _signOut(BuildContext context) async {
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
        return PopupMenuButton<_MenuAction>(
          tooltip: 'Más opciones',
          icon: const Icon(Icons.more_vert),
          onSelected: (action) {
            switch (action) {
              case _MenuAction.toggleTheme:
                ThemeController.instance.cycle();
                break;
              case _MenuAction.signOut:
                _signOut(context);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _MenuAction.toggleTheme,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(themeIcon),
                title: const Text('Cambiar tema'),
                subtitle: Text(themeLabel),
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
  }
}
