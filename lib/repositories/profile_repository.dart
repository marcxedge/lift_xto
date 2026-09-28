import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../database/database_helper.dart';
import '../models/user_profile.dart';

/// Repositorio del perfil de usuario (único, id fijo = 1). Ver
/// [ExerciseRepository] para el razonamiento del patrón.
class ProfileRepository extends ChangeNotifier {
  ProfileRepository(this._db);

  final DatabaseHelper _db;

  Future<UserProfile> get() async {
    try {
      return await _db.getProfile();
    } catch (e) {
      throw AppException('No se pudo cargar tu perfil.', cause: e);
    }
  }

  Future<void> save(UserProfile profile) async {
    try {
      await _db.upsertProfile(profile);
      notifyListeners();
    } catch (e) {
      throw AppException('No se pudo guardar tu perfil.', cause: e);
    }
  }
}
