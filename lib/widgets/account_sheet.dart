import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../sync/auth_repository.dart';
import '../sync/sync_service.dart';
import '../utils/feedback.dart';

/// Bottom sheet de cuenta y sincronización: estado de sesión, botón de
/// login/logout con Google, y estado del patrón outbox (pendientes /
/// sincronizado / sin conexión) con un botón manual de "Sincronizar ahora".
class AccountSheet extends StatefulWidget {
  const AccountSheet({super.key});

  @override
  State<AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends State<AccountSheet> {
  bool _busy = false;

  Future<void> _signIn(AuthRepository auth) async {
    setState(() => _busy = true);
    try {
      await auth.signInWithGoogle();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut(AuthRepository auth) async {
    setState(() => _busy = true);
    try {
      await auth.signOut();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _syncNow(SyncService sync) async {
    setState(() => _busy = true);
    await sync.syncNow();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final sync = context.watch<SyncService>();
    final scheme = Theme.of(context).colorScheme;
    final user = auth.currentUser;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cuenta y sincronización',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (!auth.isAvailable)
              const _InfoRow(
                icon: Icons.cloud_off_outlined,
                title: 'Sincronización no configurada',
                subtitle:
                    'Esta build no tiene un proyecto de Firebase real conectado '
                    'todavía. Tus datos se siguen guardando localmente sin '
                    'ningún problema.',
              )
            else if (user == null) ...[
              const _InfoRow(
                icon: Icons.cloud_queue,
                title: 'Sin sesión iniciada',
                subtitle:
                    'Iniciá sesión con Google para respaldar tus datos y '
                    'poder usarlos en otro dispositivo.',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : () => _signIn(auth),
                  icon: const Icon(Icons.login),
                  label: const Text('Iniciar sesión con Google'),
                ),
              ),
            ] else ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundImage:
                      user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                  child: user.photoURL == null ? const Icon(Icons.person) : null,
                ),
                title: Text(user.displayName ?? user.email ?? 'Cuenta de Google'),
                subtitle: user.email == null ? null : Text(user.email!),
              ),
              const SizedBox(height: 8),
              _SyncStatusCard(sync: sync),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy || sync.isSyncing
                          ? null
                          : () => _syncNow(sync),
                      icon: sync.isSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync),
                      label: const Text('Sincronizar ahora'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _busy ? null : () => _signOut(auth),
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar sesión'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: scheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SyncStatusCard extends StatelessWidget {
  const _SyncStatusCard({required this.sync});

  final SyncService sync;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final String status;
    final IconData icon;
    if (!sync.isOnline) {
      status = 'Sin conexión — se sincroniza al reconectar';
      icon = Icons.cloud_off;
    } else if (sync.isSyncing) {
      status = 'Sincronizando…';
      icon = Icons.sync;
    } else if (sync.pendingCount > 0) {
      final n = sync.pendingCount;
      status = '$n cambio${n == 1 ? '' : 's'} pendiente${n == 1 ? '' : 's'} de subir';
      icon = Icons.cloud_upload_outlined;
    } else {
      status = 'Todo sincronizado';
      icon = Icons.cloud_done_outlined;
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(status, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
