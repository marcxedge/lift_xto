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
    if (!_firebaseAvailable) {
      throw const AppException(
        'La sincronización no está configurada en esta build. '
        'Ver README → Sincronización.',
      );
    }
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

  Future<void> signOut() async {
    if (!_firebaseAvailable) return;
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      throw AppException('No se pudo cerrar sesión.', cause: e);
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
