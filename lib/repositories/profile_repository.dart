import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../database/database_helper.dart';
import '../models/user_profile.dart';
import '../sync/sync_service.dart';

/// Repositorio del perfil de usuario (único, id fijo = 1). Ver
/// [ExerciseRepository] para el razonamiento del patrón.
class ProfileRepository extends ChangeNotifier {
  ProfileRepository(this._db, [this._sync]);

  final DatabaseHelper _db;
  final SyncService? _sync;

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
      _sync?.requestSync();
    } catch (e) {
      throw AppException('No se pudo guardar tu perfil.', cause: e);
    }
  }
}
