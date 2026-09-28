import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../database/database_helper.dart';
import '../models/exercise.dart';

/// Repositorio de ejercicios. Envuelve [DatabaseHelper] (que ya usa SQL
/// parametrizado) y notifica a los listeners después de cada escritura para
/// que cualquier pantalla que dependa de la lista de ejercicios se entere
/// sin necesidad de recargar la app (patrón Observer).
class ExerciseRepository extends ChangeNotifier {
  ExerciseRepository(this._db);

  final DatabaseHelper _db;

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
    } catch (e) {
      throw AppException('No se pudo crear el ejercicio.', cause: e);
    }
  }

  Future<void> update(Exercise exercise) async {
    try {
      await _db.updateExercise(exercise);
      notifyListeners();
    } catch (e) {
      throw AppException('No se pudo guardar el ejercicio.', cause: e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _db.deleteExercise(id);
      notifyListeners();
    } catch (e) {
      throw AppException('No se pudo eliminar el ejercicio.', cause: e);
    }
  }
}
