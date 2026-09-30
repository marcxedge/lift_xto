#!/usr/bin/env python3
"""Procesa el dataset de ejercicios (github.com/hasaneyldrm/exercises-dataset)
y genera un catálogo liviano en español para empaquetar como asset de Flutter.

Uso:
    python scripts/build_exercise_catalog.py <ruta-al-dataset>

Donde <ruta-al-dataset> es la carpeta que contiene data/exercises.json
(la carpeta "exercises-dataset-main" descomprimida del ZIP de GitHub).

Sólo toca datos de texto (nombre, categoría, equipo, instrucciones en
español, músculo mapeado) — licenciados MIT. Las imágenes/GIFs (© Gym
visual) NO se tocan acá; ver scripts/upload_exercise_media.js para subirlas
a Firebase Storage por separado.
"""
import json
import re
import sys
from pathlib import Path

# ─── target (inglés, dataset) → MuscleGroup.name (español, app) ───
# Mismos 18 grupos que lib/utils/muscle_groups.dart. "delts" se reparte
# entre hombroFrontal/hombroPosterior según el nombre del ejercicio (ver
# _map_delts), igual que hace MuscleDetector con "posterior"/"rear".
TARGET_TO_GROUP = {
    "abductors": "abductores",
    "abs": "abdomen",
    "adductors": "aductores",
    "biceps": "biceps",
    "calves": "pantorrilla",
    "cardiovascular system": "cardio",
    "forearms": "antebrazo",
    "glutes": "gluteos",
    "hamstrings": "isquios",
    "lats": "dorsal",
    "levator scapulae": "trapecio",
    "pectorals": "pecho",
    "quads": "cuadriceps",
    "serratus anterior": "abdomen",
    "spine": "lumbar",
    "traps": "trapecio",
    "triceps": "triceps",
    "upper back": "dorsal",
}

EQUIPMENT_ES = {
    "body weight": "Peso corporal",
    "cable": "Polea",
    "leverage machine": "Máquina de palanca",
    "assisted": "Asistido",
    "medicine ball": "Balón medicinal",
    "stability ball": "Pelota de estabilidad",
    "band": "Banda elástica",
    "barbell": "Barra",
    "rope": "Cuerda",
    "dumbbell": "Mancuerna",
    "ez barbell": "Barra Z",
    "sled machine": "Máquina de trineo",
    "upper body ergometer": "Ergómetro de brazos",
    "kettlebell": "Kettlebell",
    "olympic barbell": "Barra olímpica",
    "weighted": "Con peso",
    "bosu ball": "Bosu",
    "resistance band": "Banda de resistencia",
    "roller": "Rodillo",
    "skierg machine": "Máquina SkiErg",
    "hammer": "Martillo",
    "smith machine": "Máquina Smith",
    "wheel roller": "Rueda abdominal",
    "stationary bike": "Bicicleta estática",
    "tire": "Neumático",
    "trap bar": "Barra hexagonal",
    "elliptical machine": "Elíptica",
    "stepmill machine": "Escaladora",
}

BODY_PART_ES = {
    "waist": "Cintura",
    "upper legs": "Piernas (sup.)",
    "back": "Espalda",
    "lower legs": "Piernas (inf.)",
    "chest": "Pecho",
    "upper arms": "Brazos (sup.)",
    "cardio": "Cardio",
    "shoulders": "Hombros",
    "lower arms": "Brazos (inf.)",
    "neck": "Cuello",
}

_REAR_PATTERN = re.compile(r"\b(rear|reverse|posterior)\b", re.IGNORECASE)


def map_muscle_group(target: str, name: str) -> str | None:
    if target == "delts":
        return "hombroPosterior" if _REAR_PATTERN.search(name) else "hombroFrontal"
    return TARGET_TO_GROUP.get(target)


def main() -> None:
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)

    dataset_dir = Path(sys.argv[1])
    src = dataset_dir / "data" / "exercises.json"
    if not src.exists():
        print(f"No encontré {src}")
        sys.exit(1)

    with src.open(encoding="utf-8") as f:
        raw = json.load(f)

    out = []
    unmapped = 0
    for d in raw:
        group = map_muscle_group(d["target"], d["name"])
        if group is None:
            unmapped += 1

        image = Path(d["image"]).name if d.get("image") else None
        gif = Path(d["gif_url"]).name if d.get("gif_url") else None

        out.append(
            {
                "id": d["id"],
                "name": d["name"],
                "bodyPart": d["body_part"],
                "bodyPartEs": BODY_PART_ES.get(d["body_part"], d["body_part"]),
                "equipment": d["equipment"],
                "equipmentEs": EQUIPMENT_ES.get(d["equipment"], d["equipment"]),
                "target": d["target"],
                "muscleGroup": group,
                "secondaryMuscles": d.get("secondary_muscles", []),
                "instructionsEs": d["instructions"].get("es", ""),
                "stepsEs": d.get("instruction_steps", {}).get("es", []),
                "mediaId": d["media_id"],
                "image": image,
                "gif": gif,
            }
        )

    dest = Path(__file__).resolve().parent.parent / "assets" / "data" / "exercise_catalog.json"
    dest.parent.mkdir(parents=True, exist_ok=True)
    with dest.open("w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, separators=(",", ":"))

    size_kb = dest.stat().st_size / 1024
    print(f"{len(out)} ejercicios procesados, {unmapped} sin grupo muscular mapeado.")
    print(f"Escrito en {dest} ({size_kb:.0f} KB)")


if __name__ == "__main__":
    main()
