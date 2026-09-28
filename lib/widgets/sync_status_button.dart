import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../sync/auth_repository.dart';
import '../sync/sync_service.dart';
import 'account_sheet.dart';

/// Ícono de estado de sincronización para el AppBar (mismo lugar que
/// [ThemeToggleButton]). Tocarlo abre [AccountSheet].
class SyncStatusButton extends StatelessWidget {
  const SyncStatusButton({super.key});

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
      tooltip = '${sync.pendingCount} cambios pendientes';
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
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const AccountSheet(),
      ),
    );
  }
}
