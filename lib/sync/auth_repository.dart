import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/app_exception.dart';

/// Envuelve `firebase_auth` + `google_sign_in`. Si Firebase no pudo
/// inicializarse (por ejemplo, porque `google-services.json` todavía es el
/// placeholder de ejemplo), [isAvailable] queda en `false` y todos los
/// métodos fallan de forma controlada — la app sigue funcionando 100%
/// local, sólo se deshabilita el inicio de sesión.
class AuthRepository extends ChangeNotifier {
  AuthRepository({required bool firebaseAvailable})
      : _firebaseAvailable = firebaseAvailable {
    if (_firebaseAvailable) {
      _authSub = FirebaseAuth.instance.authStateChanges().listen((_) {
        notifyListeners();
      });
    }
  }

  final bool _firebaseAvailable;
  StreamSubscription<User?>? _authSub;

  bool get isAvailable => _firebaseAvailable;

  User? get currentUser =>
      _firebaseAvailable ? FirebaseAuth.instance.currentUser : null;

  bool get isSignedIn => currentUser != null;

  Future<void> signInWithGoogle() async {
    _ensureAvailable();
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // el usuario canceló el picker
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      throw AppException('No se pudo iniciar sesión con Google.', cause: e);
    }
  }

  Future<void> registerWithEmail(String email, String password) async {
    _ensureAvailable();
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AppException(_messageForAuthError(e), cause: e);
    } catch (e) {
      throw AppException('No se pudo crear la cuenta.', cause: e);
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    _ensureAvailable();
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AppException(_messageForAuthError(e), cause: e);
    } catch (e) {
      throw AppException('No se pudo iniciar sesión.', cause: e);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    _ensureAvailable();
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AppException(_messageForAuthError(e), cause: e);
    } catch (e) {
      throw AppException(
        'No se pudo enviar el correo de recuperación.',
        cause: e,
      );
    }
  }

  Future<void> signOut() async {
    if (!_firebaseAvailable) return;
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      throw AppException('No se pudo cerrar sesión.', cause: e);
    }
  }

  void _ensureAvailable() {
    if (!_firebaseAvailable) {
      throw const AppException(
        'La sincronización no está configurada en esta build. '
        'Ver README → Sincronización.',
      );
    }
  }

  /// Traduce los códigos de `FirebaseAuthException` a mensajes en español
  /// aptos para mostrar directo al usuario (ver `AppException`).
  String _messageForAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Ese correo ya tiene una cuenta. Inicia sesión en vez de crear una nueva.';
      case 'weak-password':
        return 'La contraseña es muy débil (mínimo 6 caracteres).';
      case 'invalid-email':
        return 'El correo no es válido.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'user-disabled':
        return 'Esta cuenta fue deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta de nuevo en unos minutos.';
      case 'network-request-failed':
        return 'Sin conexión. Revisa tu internet e intenta de nuevo.';
      default:
        return 'No se pudo completar la operación (${e.code}).';
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
