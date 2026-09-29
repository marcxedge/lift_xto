import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../sync/auth_repository.dart';
import '../utils/feedback.dart';

/// Puerta de acceso obligatoria: sin sesión de Google no se entra a la app.
/// `AuthGate` (en main.dart) decide entre esta pantalla y `HomeScreen` según
/// `AuthRepository.isSignedIn` — acá sólo hace falta disparar el login;
/// una vez que `signInWithGoogle()` cambia el estado de auth, `AuthGate`
/// reacciona solo y navega a `HomeScreen`.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _signingIn = false;

  Future<void> _signIn() async {
    final auth = context.read<AuthRepository>();
    setState(() => _signingIn = true);
    try {
      await auth.signInWithGoogle();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.fitness_center,
                    color: scheme.onPrimary,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Lift.xto',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Iniciá sesión para guardar tu rutina, tu progreso y tu '
                  'peso corporal, y tenerlos sincronizados en cualquier '
                  'dispositivo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 40),
                if (!auth.isAvailable)
                  Card(
                    color: scheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.cloud_off, color: scheme.onErrorContainer),
                          const SizedBox(height: 8),
                          Text(
                            'La sincronización no está configurada en esta '
                            'build (falta un google-services.json real). '
                            'Contactá al desarrollador.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: scheme.onErrorContainer),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _signingIn ? null : _signIn,
                      icon: _signingIn
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: const Text('Iniciar sesión con Google'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
