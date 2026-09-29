import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../database/database_helper.dart';
import '../models/exercise.dart';
import '../sync/sync_service.dart';

/// Repositorio de ejercicios. Envuelve [DatabaseHelper] (que ya usa SQL
/// parametrizado) y notifica a los listeners después de cada escritura para
/// que cualquier pantalla que dependa de la lista de ejercicios se entere
/// sin necesidad de recargar la app (patrón Observer).
class ExerciseRepository extends ChangeNotifier {
  ExerciseRepository(this._db, [this._sync]) {
    // Un `pull` de SyncService escribe directo en DatabaseHelper (no pasa
    // por este repositorio), así que sin esto una sincronización que trae
    // datos nuevos de otro dispositivo no se reflejaría en la UI hasta la
    // próxima acción manual. Reenviamos su notificación como propia.
    _sync?.addListener(notifyListeners);
  }

  final DatabaseHelper _db;
  // Opcional: si está presente, cada escritura local le avisa "hay algo
  // pendiente" (fire-and-forget). El repositorio sigue sin saber nada de
  // Firestore — sólo empuja el aviso.
  final SyncService? _sync;

  @override
  void dispose() {
    _sync?.removeListener(notifyListeners);
    super.dispose();
  }

  Future<List<Exercise>> getByDay(int dayOfWeek) async {
    try {
      return await _db.getExercisesByDay(dayOfWeek);
    } catch (e) {
      throw AppException('No se pudo cargar la rutina del día.', cause: e);
    }
  }

  Future<Exercise?> getById(int id) async {
    try {
      return await _db.getExercise(id);
    } catch (e) {
      throw AppException('No se pudo cargar el ejercicio.', cause: e);
    }
  }

  Future<void> add(Exercise exercise) async {
    try {
      await _db.insertExercise(exercise);
      notifyListeners();
      _sync?.requestSync();
    } catch (e) {
      throw AppException('No se pudo crear el ejercicio.', cause: e);
    }
  }

  Future<void> update(Exercise exercise) async {
    try {
      await _db.updateExercise(exercise);
      notifyListeners();
      _sync?.requestSync();
    } catch (e) {
      throw AppException('No se pudo guardar el ejercicio.', cause: e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _db.deleteExercise(id);
      notifyListeners();
      _sync?.requestSync();
    } catch (e) {
      throw AppException('No se pudo eliminar el ejercicio.', cause: e);
    }
  }
}
