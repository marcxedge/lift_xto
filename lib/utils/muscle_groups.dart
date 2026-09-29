/// Grupos musculares que la app reconoce. Se usan para etiquetar ejercicios
/// y para colorear el mapa muscular según el volumen trabajado.
///
/// La detección se hace por palabras clave en el nombre del ejercicio (en
/// español). Si un usuario crea un ejercicio con un nombre que no machea
/// ningún patrón, simplemente queda sin grupos asignados.
enum MuscleGroup {
  // ─── Tren superior — frente ───
  pecho,
  hombroFrontal,
  biceps,
  antebrazo,

  // ─── Tren superior — espalda ───
  trapecio,
  dorsal,
  hombroPosterior,
  triceps,
  lumbar,

  // ─── Core ───
  abdomen,
  oblicuos,

  // ─── Tren inferior ───
  cuadriceps,
  isquios,
  gluteos,
  pantorrilla,
  aductores,
  abductores,

  // ─── Otros ───
  cardio,
}

/// Parsea el `.name` de un [MuscleGroup] guardado en SQLite/Firestore,
/// devolviendo `null` en vez de tirar si es `null` o un valor desconocido
/// (por ejemplo, un dato de una versión vieja de la app). Centralizado acá
/// para no duplicar el mismo try/catch en cada `fromMap`.
MuscleGroup? muscleGroupFromName(String? name) {
  if (name == null) return null;
  try {
    return MuscleGroup.values.byName(name);
  } on ArgumentError {
    return null;
  }
}

extension MuscleGroupX on MuscleGroup {
  /// Nombre legible para mostrar en chips/leyendas.
  String get label {
    switch (this) {
      case MuscleGroup.pecho:
        return 'Pecho';
      case MuscleGroup.hombroFrontal:
        return 'Hombro front.';
      case MuscleGroup.biceps:
        return 'Bíceps';
      case MuscleGroup.antebrazo:
        return 'Antebrazo';
      case MuscleGroup.trapecio:
        return 'Trapecio';
      case MuscleGroup.dorsal:
        return 'Dorsal';
      case MuscleGroup.hombroPosterior:
        return 'Hombro post.';
      case MuscleGroup.triceps:
        return 'Tríceps';
      case MuscleGroup.lumbar:
        return 'Lumbar';
      case MuscleGroup.abdomen:
        return 'Abdomen';
      case MuscleGroup.oblicuos:
        return 'Oblicuos';
      case MuscleGroup.cuadriceps:
        return 'Cuádriceps';
      case MuscleGroup.isquios:
        return 'Isquios';
      case MuscleGroup.gluteos:
        return 'Glúteos';
      case MuscleGroup.pantorrilla:
        return 'Pantorrillas';
      case MuscleGroup.aductores:
        return 'Aductores';
      case MuscleGroup.abductores:
        return 'Abductores';
      case MuscleGroup.cardio:
        return 'Cardio';
    }
  }
}

/// Helpers de detección automática de músculos por nombre del ejercicio.
class MuscleDetector {
  MuscleDetector._();

  /// Devuelve los grupos musculares trabajados por un ejercicio dado su
  /// nombre. Distingue entre primarios (al frente del set retornado) y
  /// secundarios para poder ponderar volumen distinto.
  ///
  /// Retorna un mapa con:
  ///   - `primary`: músculos que trabaja directamente
  ///   - `secondary`: músculos asistentes
  static MuscleAssignment detect(String exerciseName) {
    final n = exerciseName.toLowerCase();
    final primary = <MuscleGroup>{};
    final secondary = <MuscleGroup>{};

    bool has(String s) => n.contains(s);

    // ─── Cardio (chequear primero, suele ser exclusivo) ───
    if (has('cardio') ||
        has('caminata') ||
        has('trote') ||
        has('correr') ||
        has('cinta') ||
        has('elipt') ||
        has('biciclet')) {
      primary.add(MuscleGroup.cardio);
    }

    // ─── Pecho ───
    if (has('press') &&
        (has('inclin') ||
            has('plano') ||
            has('declin') ||
            has('mancuern') ||
            has('banca') ||
            has('pecho'))) {
      primary.add(MuscleGroup.pecho);
      secondary.add(MuscleGroup.hombroFrontal);
      secondary.add(MuscleGroup.triceps);
    }
    if (has('pec deck') || has('apertur') || has('cruce') || has('contractor')) {
      primary.add(MuscleGroup.pecho);
    }
    if (has('fondo') || has('dip')) {
      primary.add(MuscleGroup.pecho);
      primary.add(MuscleGroup.triceps);
      secondary.add(MuscleGroup.hombroFrontal);
    }
    if (has('flexion') || has('push up') || has('lagartij')) {
      primary.add(MuscleGroup.pecho);
      secondary.add(MuscleGroup.triceps);
      secondary.add(MuscleGroup.hombroFrontal);
    }

    // ─── Hombros ───
    if ((has('hombro') &&
        (has('elevac') || has('lateral') || has('press') || has('frontal'))) ||
        has('elevación') ||
        has('overhead press') ||
        has('arnold') ||
        has('press militar')) {
      primary.add(MuscleGroup.hombroFrontal);
    }
    if (has('cara') || has('face pull') || has('rear delt') || has('posterior') ||
        has('pájaro') || has('pajaro') || (has('elevac') && has('inclin'))) {
      primary.add(MuscleGroup.hombroPosterior);
      secondary.add(MuscleGroup.trapecio);
    }
    if (has('tirones cara') || has('tirón cara')) {
      primary.add(MuscleGroup.hombroPosterior);
      secondary.add(MuscleGroup.trapecio);
    }

    // ─── Bíceps ───
    if (has('curl') &&
        !has('pierna') &&
        !has('femoral') &&
        !has('isquio')) {
      primary.add(MuscleGroup.biceps);
      secondary.add(MuscleGroup.antebrazo);
    }
    if (has('bicep') || has('predicador') || has('martillo') || has('hammer')) {
      primary.add(MuscleGroup.biceps);
    }

    // ─── Tríceps ───
    if (has('triceps') ||
        has('tríceps') ||
        (has('extens') && has('barra')) ||
        has('overhead ext') ||
        has('jalón triceps') ||
        has('jalon triceps') ||
        has('patada') ||
        has('skullcrush')) {
      primary.add(MuscleGroup.triceps);
    }

    // ─── Dorsal / Espalda ───
    if (has('lat pull') ||
        has('jalón') ||
        has('jalon') ||
        has('pulldown') ||
        has('dominada') ||
        has('chin up') ||
        has('chin-up')) {
      primary.add(MuscleGroup.dorsal);
      secondary.add(MuscleGroup.biceps);
      secondary.add(MuscleGroup.trapecio);
    }
    if (has('pull over') || has('pullover') || has('pull-over')) {
      primary.add(MuscleGroup.dorsal);
      secondary.add(MuscleGroup.pecho);
    }
    if (has('remo') || has('row')) {
      primary.add(MuscleGroup.dorsal);
      primary.add(MuscleGroup.trapecio);
      secondary.add(MuscleGroup.biceps);
      secondary.add(MuscleGroup.hombroPosterior);
    }

    // ─── Trapecio ───
    if (has('trapec') || has('encogim') || has('shrug')) {
      primary.add(MuscleGroup.trapecio);
    }

    // ─── Pierna — cuádriceps ───
    if ((has('extens') &&
        (has('pierna') || has('cuadr') || has('rodilla'))) ||
        n.trim() == 'extensiones') {
      primary.add(MuscleGroup.cuadriceps);
    }
    if (has('sentadilla') ||
        has('squat') ||
        has('prensa') ||
        has('hack') ||
        has('zancada') ||
        has('lunge') ||
        has('búlgar') ||
        has('bulgar')) {
      primary.add(MuscleGroup.cuadriceps);
      primary.add(MuscleGroup.gluteos);
      secondary.add(MuscleGroup.aductores);
    }

    // ─── Pierna — posterior (isquios + glúteos + lumbar) ───
    if (has('peso muerto') || has('deadlift')) {
      primary.add(MuscleGroup.isquios);
      primary.add(MuscleGroup.gluteos);
      primary.add(MuscleGroup.lumbar);
      secondary.add(MuscleGroup.trapecio);
    }
    if (has('rumano') || has('rdl')) {
      primary.add(MuscleGroup.isquios);
      primary.add(MuscleGroup.gluteos);
      secondary.add(MuscleGroup.lumbar);
    }
    if (has('hip thrust') ||
        has('puente glúteo') ||
        has('puente gluteo') ||
        has('gluteo') ||
        has('glúteo')) {
      primary.add(MuscleGroup.gluteos);
      secondary.add(MuscleGroup.isquios);
    }
    if (has('curl') &&
        (has('pierna') ||
            has('femoral') ||
            has('isquio') ||
            has('acostado') ||
            has('sentado'))) {
      primary.add(MuscleGroup.isquios);
    }

    // ─── Pierna — laterales y pantorrillas ───
    if (has('aductor')) primary.add(MuscleGroup.aductores);
    if (has('abductor')) primary.add(MuscleGroup.abductores);
    if (has('pantorr') ||
        has('gemelo') ||
        has('soleo') ||
        has('sóleo') ||
        has('calf')) {
      primary.add(MuscleGroup.pantorrilla);
    }

    // ─── Core ───
    if (has('abdominal') || has('crunch') || has('ab wheel') || has('rueda abd')) {
      primary.add(MuscleGroup.abdomen);
    }
    if (has('rotac') && has('torso')) {
      primary.add(MuscleGroup.oblicuos);
      secondary.add(MuscleGroup.abdomen);
    }
    if (has('oblicu')) {
      primary.add(MuscleGroup.oblicuos);
    }
    if (has('plancha') || has('plank')) {
      primary.add(MuscleGroup.abdomen);
      secondary.add(MuscleGroup.oblicuos);
      secondary.add(MuscleGroup.lumbar);
    }
    if (has('lumbar') || has('hiperextens')) {
      primary.add(MuscleGroup.lumbar);
      secondary.add(MuscleGroup.gluteos);
    }

    // Sacar de secundarios cualquier grupo que ya esté como primario
    secondary.removeAll(primary);

    return MuscleAssignment(
      primary: primary.toList(),
      secondary: secondary.toList(),
    );
  }

  /// Resuelve la asignación muscular "efectiva" de un ejercicio: si tiene un
  /// grupo elegido a mano ([explicit], vía el combo de
  /// `AddEditExerciseScreen`), ese es el único primario y gana siempre. Si
  /// no, cae a la detección por nombre (compatibilidad con ejercicios
  /// creados antes de que existiera el combo).
  static MuscleAssignment resolve(MuscleGroup? explicit, String name) {
    if (explicit != null) {
      return MuscleAssignment(primary: [explicit], secondary: const []);
    }
    return detect(name);
  }
}

class MuscleAssignment {
  const MuscleAssignment({required this.primary, required this.secondary});

  final List<MuscleGroup> primary;
  final List<MuscleGroup> secondary;

  bool get isEmpty => primary.isEmpty && secondary.isEmpty;
  List<MuscleGroup> get all => [...primary, ...secondary];
}