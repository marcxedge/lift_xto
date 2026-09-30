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

  /// Busca por nombre (en inglés o en la traducción automática a español,
  /// ver [CatalogExercise.nameEs]) y opcionalmente filtra por grupo
  /// muscular. La búsqueda es por palabras: cada palabra de `query` tiene
  /// que aparecer en algún lado del nombre (en cualquier orden), no exige
  /// la frase completa — así "press banca" encuentra "barra press de
  /// banca" aunque el orden no coincida exacto. `query` vacío devuelve
  /// todo (filtrado sólo por [muscleGroup] si se pasó).
  Future<List<CatalogExercise>> search({
    String query = '',
    MuscleGroup? muscleGroup,
  }) async {
    final all = await _all();
    final words = query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    return all.where((e) {
      if (muscleGroup != null && e.muscleGroup != muscleGroup) return false;
      if (words.isEmpty) return true;
      final haystack = '${e.name} ${e.nameEs}'.toLowerCase();
      return words.every(haystack.contains);
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
