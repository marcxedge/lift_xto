import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/catalog_exercise.dart';
import '../utils/muscle_groups.dart';

/// Da acceso al catálogo de referencia de ~1300 ejercicios empaquetado en
/// `assets/data/exercise_catalog.json` (texto/metadata bajo licencia MIT —
/// ver `scripts/build_exercise_catalog.py`). Es dato estático de sólo
/// lectura: se carga una vez desde el asset bundle y se cachea en memoria,
/// sin tocar SQLite ni Firestore.
class ExerciseCatalogRepository {
  List<CatalogExercise>? _cache;

  Future<List<CatalogExercise>> _all() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('assets/data/exercise_catalog.json');
    final list = (jsonDecode(raw) as List)
        .map((e) => CatalogExercise.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = list;
    return list;
  }

  /// Busca por nombre (case-insensitive, substring) y opcionalmente filtra
  /// por grupo muscular. `query` vacío devuelve todo (filtrado sólo por
  /// [muscleGroup] si se pasó).
  Future<List<CatalogExercise>> search({
    String query = '',
    MuscleGroup? muscleGroup,
  }) async {
    final all = await _all();
    final q = query.trim().toLowerCase();
    return all.where((e) {
      if (muscleGroup != null && e.muscleGroup != muscleGroup) return false;
      if (q.isEmpty) return true;
      return e.name.toLowerCase().contains(q);
    }).toList();
  }

  Future<CatalogExercise?> byId(String id) async {
    final all = await _all();
    for (final e in all) {
      if (e.id == id) return e;
    }
    return null;
  }
}
