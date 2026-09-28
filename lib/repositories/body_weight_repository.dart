import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../database/database_helper.dart';
import '../models/body_weight_log.dart';
import '../sync/sync_service.dart';

/// Repositorio de peso corporal. Ver [ExerciseRepository] para el
/// razonamiento del patrón (envuelve [DatabaseHelper], notifica en cada
/// escritura).
class BodyWeightRepository extends ChangeNotifier {
  BodyWeightRepository(this._db, [this._sync]);

  final DatabaseHelper _db;
  final SyncService? _sync;

  Future<List<BodyWeightLog>> getAll() async {
    try {
      return await _db.getAllBodyWeights();
    } catch (e) {
      throw AppException('No se pudo cargar el historial de peso.', cause: e);
    }
  }

  Future<BodyWeightLog?> getLatest() async {
    try {
      return await _db.getLatestBodyWeight();
    } catch (e) {
      throw AppException('No se pudo cargar tu peso.', cause: e);
    }
  }

  Future<void> add(BodyWeightLog log) async {
    try {
      await _db.insertBodyWeight(log);
      notifyListeners();
      _sync?.requestSync();
    } catch (e) {
      throw AppException('No se pudo guardar el registro.', cause: e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _db.deleteBodyWeight(id);
      notifyListeners();
      _sync?.requestSync();
    } catch (e) {
      throw AppException('No se pudo eliminar el registro.', cause: e);
    }
  }
}
