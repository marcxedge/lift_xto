import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../sync/auth_repository.dart';
import '../sync/sync_service.dart';

/// Ícono de estado de sincronización para el AppBar. Tocarlo no abre nada:
/// si ya está todo sincronizado, solo lo confirma; si hay cambios
/// pendientes, sincroniza ahí mismo y avisa si terminó bien o falló.
class SyncStatusButton extends StatelessWidget {
  const SyncStatusButton({super.key});

  Future<void> _handleTap(
    BuildContext context,
    AuthRepository auth,
    SyncService sync,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    void show(String text) =>
        messenger.showSnackBar(SnackBar(content: Text(text)));

    if (!auth.isAvailable) {
      show('La sincronización no está configurada en esta build.');
      return;
    }
    if (!auth.isSignedIn) {
      // No debería pasar con el login obligatorio, pero por las dudas.
      show('Inicia sesión para sincronizar.');
      return;
    }
    if (sync.isSyncing) {
      show('Ya se está sincronizando, espera un momento.');
      return;
    }
    if (!sync.isOnline) {
      show('Sin conexión. Se va a sincronizar solo cuando vuelvas a tener internet.');
      return;
    }
    if (sync.pendingCount == 0) {
      show('Todo sincronizado.');
      return;
    }

    final ok = await sync.syncNow();
    if (!context.mounted) return;
    show(ok ? 'Sincronización completa.' : 'No se pudo sincronizar. Se va a reintentar más tarde.');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final sync = context.watch<SyncService>();

    final IconData icon;
    final String tooltip;
    if (!auth.isAvailable) {
      icon = Icons.cloud_off_outlined;
      tooltip = 'Sincronización no configurada';
    } else if (!auth.isSignedIn) {
      icon = Icons.cloud_queue;
      tooltip = 'Iniciar sesión para sincronizar';
    } else if (sync.isSyncing) {
      icon = Icons.sync;
      tooltip = 'Sincronizando…';
    } else if (!sync.isOnline) {
      icon = Icons.cloud_off;
      tooltip = 'Sin conexión';
    } else if (sync.pendingCount > 0) {
      icon = Icons.cloud_upload_outlined;
      tooltip = '${sync.pendingCount} cambios pendientes — toca para sincronizar';
    } else {
      icon = Icons.cloud_done_outlined;
      tooltip = 'Todo sincronizado';
    }

    final showBadge = auth.isSignedIn && sync.pendingCount > 0;

    return IconButton(
      tooltip: tooltip,
      icon: showBadge
          ? Badge(label: Text('${sync.pendingCount}'), child: Icon(icon))
          : Icon(icon),
      onPressed: () => _handleTap(context, auth, sync),
    );
  }
}
