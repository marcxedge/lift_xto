import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_exception.dart';
import '../sync/auth_repository.dart';
import '../utils/feedback.dart';
import '../utils/validators.dart';
import '../widgets/google_logo.dart';

/// Puerta de acceso obligatoria: sin sesión no se entra a la app. Ofrece
/// Google Sign-In o email/contraseña (con alta de cuenta y recuperación de
/// contraseña). `AuthGate` (en main.dart) decide entre esta pantalla y
/// `HomeScreen` según `AuthRepository.isSignedIn` — acá sólo hace falta
/// disparar el login; una vez que cambia el estado de auth, `AuthGate`
/// reacciona solo y navega a `HomeScreen`.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _busy = false;
  bool _isRegisterMode = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    final auth = context.read<AuthRepository>();
    setState(() => _busy = true);
    try {
      await auth.signInWithGoogle();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitEmailForm() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthRepository>();
    setState(() => _busy = true);
    try {
      if (_isRegisterMode) {
        await auth.registerWithEmail(_email.text, _password.text);
      } else {
        await auth.signInWithEmail(_email.text, _password.text);
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (Validators.email(email) != null) {
      showErrorSnackBar(
        context,
        const AppException('Ingresa tu correo arriba primero.'),
      );
      return;
    }
    final auth = context.read<AuthRepository>();
    setState(() => _busy = true);
    try {
      await auth.sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Te enviamos un correo a $email para restablecer tu contraseña.')),
        );
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
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
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/icon/icon.png',
                    width: 96,
                    height: 96,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Lift.xto',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
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
                            'Contacta al desarrollador.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: scheme.onErrorContainer),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Correo',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: Validators.password,
                        ),
                        if (!_isRegisterMode) ...[
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _busy ? null : _forgotPassword,
                              child: const Text('¿Olvidaste tu contraseña?'),
                            ),
                          ),
                        ] else
                          const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _busy ? null : _submitEmailForm,
                            icon: _busy
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.email_outlined),
                            label: Text(
                              _isRegisterMode
                                  ? 'Crear cuenta'
                                  : 'Iniciar sesión',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(
                                  () => _isRegisterMode = !_isRegisterMode,
                                ),
                          child: Text(
                            _isRegisterMode
                                ? '¿Ya tienes cuenta? Inicia sesión'
                                : '¿No tienes cuenta? Crea una',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: Divider(color: scheme.outlineVariant)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'o',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ),
                      Expanded(child: Divider(color: scheme.outlineVariant)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _signInWithGoogle,
                      icon: const GoogleLogo(),
                      label: const Text('Iniciar sesión con Google'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
