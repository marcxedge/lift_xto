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


# ─── Traducción de nombres ───
# El dataset no trae traducción de `name` (sólo las instrucciones vienen en
# español) — esto arma una traducción automática a partir de un diccionario
# de vocabulario de gimnasio. No es una traducción literaria (no reordena
# la oración más allá de las frases hechas de abajo), pero cubre >95% del
# vocabulario real de los 1324 nombres (ver análisis de frecuencia usado
# para armar este diccionario) y da un resultado claro y reconocible para
# alguien que entrena en español.

# Frases (2-3 palabras) que se traducen como unidad, antes que palabra por
# palabra — capturan los nombres de ejercicios "hechos" que sonarían raro
# traducidos suelto. Se revisan de más larga a más corta.
PHRASES_ES: dict[str, str] = {
    "bench press": "press de banca",
    "sit up": "abdominal",
    "sit ups": "abdominales",
    "chin up": "dominada supina",
    "chin ups": "dominadas supinas",
    "push up": "flexión de pecho",
    "push ups": "flexiones de pecho",
    "pull up": "dominada",
    "pull ups": "dominadas",
    "mountain climber": "escalador",
    "mountain climbers": "escaladores",
    "good morning": "buenos días",
    "lat pulldown": "jalón al pecho",
    "tricep pushdown": "jalón de tríceps",
    "triceps pushdown": "jalón de tríceps",
    "hip thrust": "empuje de cadera",
    "leg press": "prensa de piernas",
    "leg curl": "curl femoral",
    "leg extension": "extensión de cuádriceps",
    "calf raise": "elevación de talones",
    "calf raises": "elevaciones de talones",
    "face pull": "jalón a la cara",
    "skull crusher": "press francés",
    "skullcrusher": "press francés",
    "preacher curl": "curl predicador",
    "hack squat": "sentadilla hack",
    "bear crawl": "gateo de oso",
    "battling ropes": "cuerdas de batalla",
    "box jump": "salto al cajón",
    "jumping jack": "salto de tijera",
    "jumping jacks": "saltos de tijera",
    "russian twist": "giro ruso",
    "romanian deadlift": "peso muerto rumano",
    "sumo deadlift": "peso muerto sumo",
    "goblet squat": "sentadilla copa",
    "front squat": "sentadilla frontal",
    "back squat": "sentadilla trasera",
    "overhead press": "press militar",
    "military press": "press militar",
    "upright row": "remo al mentón",
    "one arm": "a un brazo",
    "single arm": "a un brazo",
    "one leg": "a una pierna",
    "single leg": "a una pierna",
    "both arms": "a dos brazos",
    "both legs": "a dos piernas",
}

# Vocabulario palabra por palabra — se aplica a lo que no matcheó una frase
# de arriba. Cubre equipo, movimientos, posiciones, músculos y conectores
# comunes. Lo que no está en el diccionario se deja tal cual (en inglés) en
# vez de perderse, así el nombre nunca queda incompleto.
WORDS_ES: dict[str, str] = {
    # equipo / aparatos
    "dumbbell": "mancuerna", "dumbbells": "mancuernas",
    "barbell": "barra", "barbells": "barras",
    "cable": "polea", "cables": "poleas",
    "ball": "balón", "band": "banda", "bands": "bandas",
    "bench": "banca", "lever": "palanca", "machine": "máquina",
    "smith": "smith", "kettlebell": "kettlebell", "ez": "Z",
    "bar": "barra", "bars": "barras", "rope": "cuerda", "ropes": "cuerdas",
    "sled": "trineo", "stability": "estabilidad", "wheel": "rueda",
    "wall": "pared", "chair": "silla", "pulley": "polea", "cage": "jaula",
    "trainer": "entrenador", "medicine": "medicinal",
    "resistance": "resistencia", "bosu": "bosu", "towel": "toalla",
    "roller": "rodillo", "blaster": "blaster", "bike": "bicicleta",
    "olympic": "olímpica", "iron": "hierro", "landmine": "landmine",
    "rollerout": "rueda abdominal", "rack": "rack", "pin": "pin",
    "box": "cajón", "step": "escalón",
    # movimientos
    "curl": "curl", "curls": "curls", "press": "press", "presses": "presses",
    "row": "remo", "raise": "elevación", "raises": "elevaciones",
    "extension": "extensión", "push": "empuje", "pushdown": "jalón",
    "pull": "tirón", "pulldown": "jalón", "pullover": "pull-over",
    "squat": "sentadilla", "squats": "sentadillas", "squatting": "sentadilla",
    "fly": "apertura", "flye": "apertura", "flys": "aperturas",
    "crunch": "abdominal", "crunches": "abdominales",
    "stretch": "estiramiento", "deadlift": "peso muerto",
    "lunge": "zancada", "lunges": "zancadas",
    "dip": "fondo", "dips": "fondos", "twist": "giro", "twisting": "giro",
    "jump": "salto", "jumps": "saltos", "shrug": "encogimiento",
    "bridge": "puente", "cross": "cruzado", "crossovers": "cruces",
    "step": "paso", "split": "split", "clean": "cargada",
    "kickback": "patada", "hyperextension": "hiperextensión",
    "snatch": "arranque", "swing": "balanceo", "throw": "lanzamiento",
    "lift": "levantamiento", "lifting": "levantamiento",
    "touch": "toque", "touchers": "toques", "bend": "flexión",
    "run": "correr", "walk": "caminata", "walking": "caminando",
    "hang": "colgado", "hanging": "colgado", "plank": "plancha",
    "thruster": "empuje", "jerk": "envión", "burpee": "burpee",
    "windmill": "molino", "handstand": "pino", "pistol": "pistola",
    "goblet": "copa", "zottman": "zottman", "archer": "arquero",
    "spider": "araña", "concentration": "concentración",
    "preacher": "predicador", "hammer": "martillo", "military": "militar",
    "overhead": "por encima de la cabeza", "kick": "patada", "kicks": "patadas",
    "circles": "círculos", "circular": "circular", "rotation": "rotación",
    "rotational": "rotacional", "squeeze": "apriete", "pass": "pase",
    "tap": "toque", "donkey": "burro", "sumo": "sumo", "russian": "ruso",
    "romanian": "rumano", "arnold": "arnold", "french": "francés",
    "jefferson": "jefferson", "pendlay": "pendlay", "zercher": "zercher",
    "cuban": "cubano", "bradford": "bradford", "guillotine": "guillotina",
    "crusher": "trituradora", "skull": "cráneo", "skier": "esquiador",
    "ski": "esquí", "piriformis": "piriforme", "balance": "equilibrio",
    "pallof": "pallof", "hug": "abrazo", "flexion": "flexión",
    "maltese": "maltés", "march": "marcha", "clasped": "entrelazado",
    "isometric": "isométrico", "point": "punto", "power": "potencia",
    "sissy": "sissy", "straddle": "straddle", "crawl": "gateo",
    "climber": "escalador", "climbers": "escaladores", "flip": "voltereta",
    "drag": "arrastre", "drop": "caída", "slam": "golpe", "pose": "pose",
    "speed": "velocidad", "basic": "básico", "bear": "oso",
    "stabilization": "estabilización", "variation": "variación",
    "backward": "hacia atrás", "forward": "hacia adelante",
    "reach": "alcance", "tilt": "inclinación", "pelvic": "pélvico",
    "scapula": "escápula", "bicycle": "bicicleta", "frog": "rana",
    "pike": "pica", "butterfly": "mariposa", "yoga": "yoga", "judo": "judo",
    "abduction": "abducción", "adduction": "aducción",
    "pronation": "pronación", "supination": "supinación",
    "inverted": "invertido", "suspended": "suspendido",
    "modified": "modificado", "fixed": "fijo",
    # posiciones / modificadores
    "seated": "sentado", "standing": "de pie", "lying": "acostado",
    "prone": "boca abajo", "supine": "boca arriba", "kneeling": "arrodillado",
    "incline": "inclinado", "decline": "declinado", "flat": "plano",
    "vertical": "vertical", "horizontal": "horizontal", "front": "frontal",
    "rear": "posterior", "side": "lateral", "lateral": "lateral",
    "back": "trasero", "low": "bajo", "high": "alto", "full": "completo",
    "half": "medio", "inner": "interno", "outer": "externo",
    "stiff": "rígido", "straight": "recto", "bent": "inclinado",
    "close": "cerrado", "wide": "abierto", "narrow": "estrecho",
    "reverse": "inverso", "alternate": "alternado", "alternating": "alternado",
    "single": "único", "double": "doble", "assisted": "asistido",
    "weighted": "con peso", "bodyweight": "peso corporal",
    "male": "hombre", "female": "mujer", "internal": "interno",
    "external": "externo", "extended": "extendido", "raised": "elevado",
    "upper": "superior", "lower": "inferior", "behind": "detrás de",
    "underhand": "agarre supino", "neutral": "neutro", "support": "apoyo",
    "against": "contra", "parallel": "paralelo", "cross": "cruzado",
    "stance": "postura", "self": "auto",
    # números
    "one": "uno", "two": "dos", "three": "tres", "v": "V", "t": "T",
    "l": "L", "y": "Y",
    # músculos / cuerpo
    "arm": "brazo", "arms": "brazos", "leg": "pierna", "legs": "piernas",
    "grip": "agarre", "hip": "cadera", "chest": "pecho",
    "triceps": "tríceps", "tricep": "tríceps", "biceps": "bíceps",
    "bicep": "bíceps", "shoulder": "hombro", "shoulders": "hombros",
    "wrist": "muñeca", "knee": "rodilla", "knees": "rodillas",
    "delt": "deltoides", "deltoid": "deltoides", "calf": "pantorrilla",
    "calves": "pantorrillas", "hamstring": "isquiotibial",
    "hamstrings": "isquiotibiales", "glute": "glúteo", "glutes": "glúteos",
    "gluteus": "glúteo", "quad": "cuádriceps", "quads": "cuádriceps",
    "oblique": "oblicuo", "obliques": "oblicuos", "lat": "dorsal",
    "lats": "dorsales", "trap": "trapecio", "traps": "trapecios",
    "neck": "cuello", "toe": "dedo del pie", "elbow": "codo",
    "spine": "columna", "palm": "palma", "palms": "palmas",
    "finger": "dedo", "hand": "mano", "hands": "manos",
    "head": "cabeza", "body": "cuerpo", "muscle": "músculo",
    "adductor": "aductor", "rectus": "recto", "femoris": "femoral",
    "pectoralis": "pectoral", "major": "mayor", "ankle": "tobillo",
    # conectores / genéricos
    "with": "con", "on": "en", "to": "a", "and": "y", "of": "de",
    "from": "desde", "in": "en", "through": "a través de",
    "around": "alrededor", "between": "entre", "under": "debajo",
    "off": "fuera", "a": "un", "the": "", "exercise": "ejercicio",
    "attachment": "accesorio", "range": "rango", "motion": "movimiento",
    "pov": "pov", "over": "", "floor": "suelo", "ring": "anillas",
    "rings": "anillas", "short": "corto", "stride": "paso",
    "clap": "con palmada", "curtsey": "reverencia",
    # variantes con guión (el dataset mezcla "push up" y "push-up")
    "push-up": "flexión de pecho", "push-ups": "flexiones de pecho",
    "pull-up": "dominada", "pull-ups": "dominadas",
    "chin-up": "dominada supina", "chin-ups": "dominadas supinas",
    "sit-up": "abdominal", "sit-ups": "abdominales",
    "close-grip": "agarre cerrado", "v-bar": "barra V",
    "y-raise": "elevación en Y", "skull-crusher": "press francés",
    "wide-grip": "agarre abierto", "reverse-grip": "agarre inverso",
    "clean-grip": "agarre de cargada", "step-up": "subida", "step-ups": "subidas",
    "bent-over": "inclinado", "cross-over": "cruzado", "side-to-side": "de lado a lado",
    "t-bar": "barra T", "ez-bar": "barra Z", "v-up": "V abdominal",
    "up": "", "down": "", "revers": "inverso", "inverse": "inverso",
    "flexor": "flexor", "chin": "barbilla", "hack": "hack", "face": "cara",
    "stationary": "estática", "posterior": "posterior", "hyper": "hiper",
    "plyo": "pliométrico", "tuck": "encogido", "planche": "planche",
}


def translate_name(name: str) -> str:
    n = name.lower()

    # Las frases se sustituyen primero por un placeholder (no por su texto
    # en español directo) — si insertáramos el español ya traducido acá, el
    # paso de tokenización de abajo lo volvería a escanear palabra por
    # palabra y podría "retraducir" alguna palabra española que coincida
    # con una clave del diccionario inglés->español (ej. "a" de "a una
    # pierna" volviendo a mapearse como el artículo inglés "a"). Guardamos
    # el texto final en `placeholders` y lo insertamos después de tokenizar.
    placeholders: list[str] = []

    def _stash(phrase: str) -> str:
        placeholders.append(PHRASES_ES[phrase])
        return f" \x00{len(placeholders) - 1}\x00 "

    for phrase in sorted(PHRASES_ES, key=len, reverse=True):
        n = re.sub(rf"\b{re.escape(phrase)}\b", lambda _m, p=phrase: _stash(p), n)

    tokens = re.findall(r"\x00\d+\x00|[a-záéíóúñ'/-]+|\d+", n)
    translated = []
    for tok in tokens:
        placeholder_match = re.fullmatch(r"\x00(\d+)\x00", tok)
        if placeholder_match:
            translated.append(placeholders[int(placeholder_match.group(1))])
        elif tok in WORDS_ES:
            es = WORDS_ES[tok]
            if es:
                translated.append(es)
        else:
            translated.append(tok)
    result = " ".join(translated).strip()
    result = re.sub(r"\s+", " ", result)
    return result[:1].upper() + result[1:] if result else name


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
                "nameEs": translate_name(d["name"]),
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
