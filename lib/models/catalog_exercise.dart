import '../utils/muscle_groups.dart';

/// Un ejercicio del catálogo de referencia (dataset externo, ver
/// `scripts/build_exercise_catalog.py`). Es dato estático de sólo lectura,
/// distinto de [Exercise] (que es la rutina propia del usuario) — sirve
/// para mostrar nombre/músculo/instrucciones/GIF de referencia al agregar
/// un ejercicio nuevo, no se guarda en SQLite.
class CatalogExercise {
  const CatalogExercise({
    required this.id,
    required this.name,
    required this.bodyPart,
    required this.bodyPartEs,
    required this.equipment,
    required this.equipmentEs,
    required this.target,
    required this.muscleGroup,
    required this.secondaryMuscles,
    required this.instructionsEs,
    required this.stepsEs,
    required this.mediaId,
    required this.image,
    required this.gif,
  });

  final String id;
  final String name;
  final String bodyPart;
  final String bodyPartEs;
  final String equipment;
  final String equipmentEs;
  final String target;
  final MuscleGroup? muscleGroup;
  final List<String> secondaryMuscles;
  final String instructionsEs;
  final List<String> stepsEs;
  final String mediaId;
  final String? image;
  final String? gif;

  factory CatalogExercise.fromJson(Map<String, dynamic> json) {
    return CatalogExercise(
      id: json['id'] as String,
      name: json['name'] as String,
      bodyPart: json['bodyPart'] as String,
      bodyPartEs: json['bodyPartEs'] as String,
      equipment: json['equipment'] as String,
      equipmentEs: json['equipmentEs'] as String,
      target: json['target'] as String,
      muscleGroup: muscleGroupFromName(json['muscleGroup'] as String?),
      secondaryMuscles: (json['secondaryMuscles'] as List)
          .map((e) => e as String)
          .toList(),
      instructionsEs: json['instructionsEs'] as String? ?? '',
      stepsEs: (json['stepsEs'] as List).map((e) => e as String).toList(),
      mediaId: json['mediaId'] as String,
      image: json['image'] as String?,
      gif: json['gif'] as String?,
    );
  }
}
