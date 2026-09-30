import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../database/database_helper.dart';
import '../models/body_measurement.dart';
import '../sync/sync_service.dart';

/// Repositorio de medidas corporales. Ver [BodyWeightRepository] para el
/// razonamiento del patrón.
class BodyMeasurementRepository extends ChangeNotifier {
  BodyMeasurementRepository(this._db, [this._sync]) {
    _sync?.addListener(notifyListeners);
  }

  final DatabaseHelper _db;
  final SyncService? _sync;

  @override
  void dispose() {
    _sync?.removeListener(notifyListeners);
    super.dispose();
  }

  Future<List<BodyMeasurement>> getAll() async {
    try {
      return await _db.getAllBodyMeasurements();
    } catch (e) {
      throw AppException('No se pudo cargar el historial de medidas.', cause: e);
    }
  }

  Future<void> add(BodyMeasurement measurement) async {
    try {
      await _db.insertBodyMeasurement(measurement);
      notifyListeners();
      _sync?.requestSync();
    } catch (e) {
      throw AppException('No se pudo guardar las medidas.', cause: e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _db.deleteBodyMeasurement(id);
      notifyListeners();
      _sync?.requestSync();
    } catch (e) {
      throw AppException('No se pudo eliminar el registro.', cause: e);
    }
  }
}
