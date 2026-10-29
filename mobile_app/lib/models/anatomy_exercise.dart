import 'package:flutter/material.dart';

/// Datos de un ejercicio para la demostracion anatomica 3D.
///
/// Cada ejercicio define que musculo es el agonista (principal), cuales
/// actuan como sinergistas o estabilizadores, el nivel de intensidad,
/// los rangos articulares que debe respetar, el tempo recomendado y las notas
/// de postura y prevencion.
class AnatomyExercise {
  const AnatomyExercise({
    required this.id,
    required this.name,
    required this.shortName,
    required this.agonist,
    required this.synergists,
    required this.biomechanics,
    required this.tempo,
    required this.posture,
    required this.warning,
    required this.gifUrl,
    this.intensityLevel = 'Intermedio (Intensidad Media)',
  });

  final String id;
  final String name;
  final String shortName;

  /// Musculo principal, el que mas estimula el ejercicio.
  final String agonist;

  /// Musculos que asisten y estabilizan durante el movimiento.
  final List<String> synergists;

  /// Descripcion de los angulos articulares clave.
  final String biomechanics;

  /// Tempo de ejecucion recomendado.
  final String tempo;

  /// Nota postural clave.
  final String posture;

  /// Advertencia de prevencion de lesiones.
  final String warning;

  /// Animacion anatomica que se muestra para este ejercicio.
  final String gifUrl;

  /// Clasificacion de intensidad (Basico / Intermedio / Avanzado).
  final String intensityLevel;
}

const String _kGifBase =
    'https://raw.githubusercontent.com/JahelCuadrado/ExerciseGymGifsDB/main/';

/// Garantiza que SIEMPRE exista un GIF anatómico exacto acorde al movimiento e intensidad.
String resolveGuaranteedGifUrl({
  required String name,
  required String agonist,
  required String intensityLevel,
  String? existingUrl,
}) {
  final nameLower = name.toLowerCase();
  final intLower = intensityLevel.toLowerCase();
  final isLow = intLower.contains('baja') || intLower.contains('basico') || intLower.contains('básico');
  final isHigh = intLower.contains('alta') || intLower.contains('avanzado');

  if (existingUrl != null && existingUrl.trim().isNotEmpty) {
    final cleanExisting = existingUrl.trim();
    // Validar si existe incongruencia biomecánica conocida
    final bool hasMismatch =
        // 1. Puentes, Buenos Días o Peso Muerto mostrando Curl de Pierna
        ((nameLower.contains('puente') || nameLower.contains('bridge') || nameLower.contains('hip thrust') || nameLower.contains('buenos d') || nameLower.contains('deadlift') || nameLower.contains('peso muerto')) && cleanExisting.contains('curl')) ||
        // 2. Fondos o Tríceps mostrando Flexiones de Pecho (Push-up)
        ((nameLower.contains('fondo') || nameLower.contains('dip') || nameLower.contains('tricep') || nameLower.contains('trícep')) && cleanExisting.contains('push-up')) ||
        // 3. Dead Bug, Plancha, Remos o Flexiones mostrando Gemelos
        ((nameLower.contains('dead bug') || nameLower.contains('plank') || nameLower.contains('plancha') || nameLower.contains('remo') || nameLower.contains('flexion') || nameLower.contains('flexión')) && cleanExisting.contains('calf')) ||
        // 4. Talones sentado / en silla mostrando elevación de pie
        ((nameLower.contains('sentado') || nameLower.contains('silla') || nameLower.contains('seated')) && cleanExisting.contains('standing-calf-raise')) ||
        // 5. Talones unipodal mostrando elevación bilateral de pie
        ((nameLower.contains('unipodal') || nameLower.contains('una pierna') || nameLower.contains('single leg')) && cleanExisting.contains('standing-calf-raise')) ||
        // 6. Ejercicios caseros con toalla o deslizador mostrando máquinas de gimnasio o slide plano
        ((nameLower.contains('toalla') || nameLower.contains('deslizador') || nameLower.contains('piso liso')) && (cleanExisting.contains('single-leg-platform-slide') || cleanExisting.contains('lever') || cleanExisting.contains('cable') || cleanExisting.contains('smith') || cleanExisting.contains('seated-leg-curl'))) ||
        // 7. Plancha frontal en antebrazos mostrando rodillas apoyadas
        ((nameLower.contains('antebrazo') || nameLower.contains('frontal')) && cleanExisting.contains('kneeling-plank'));

    if (!hasMismatch) {
      return cleanExisting;
    }
  }

  // 1. Puentes de Glúteo / Hip Thrust / Elevación Pélvica
  if (nameLower.contains('puente') || nameLower.contains('bridge') || nameLower.contains('hip thrust') || nameLower.contains('elevacion pelvica') || nameLower.contains('elevación pélvica')) {
    return _kGifBase + (isLow
        ? 'glutes/low-glute-bridge-on-floor.gif'
        : (isHigh ? 'glutes/barbell-glute-bridge.gif' : 'glutes/glute-bridge-two-legs-on-bench-male.gif'));
  }

  // 2. Buenos Días (Good Morning)
  if (nameLower.contains('buenos dias') || nameLower.contains('buenos días') || nameLower.contains('good morning') || nameLower.contains('buenos d')) {
    return _kGifBase + (isLow
        ? 'glutes/band-straight-back-stiff-leg-deadlift.gif'
        : 'hamstrings/barbell-good-morning.gif');
  }

  // 3. Fondos de Tríceps (Chair Dips / Bench Dips)
  if (nameLower.contains('fondo') || nameLower.contains('fondos') || nameLower.contains('dip') || nameLower.contains('chair dip') || nameLower.contains('bench dip')) {
    return _kGifBase + (isLow
        ? 'triceps/bench-dip-knees-bent.gif'
        : (isHigh ? 'triceps/triceps-dip.gif' : 'triceps/bench-dip-on-floor.gif'));
  }

  // 4. Dead Bug (Bicho Muerto)
  if (nameLower.contains('dead bug') || nameLower.contains('dead-bug') || nameLower.contains('bicho muerto')) {
    return _kGifBase + 'abs/dead-bug.gif';
  }

  // 5. Plancha Lateral (Side Plank)
  if (nameLower.contains('plancha lateral') || nameLower.contains('side plank')) {
    return _kGifBase + 'abs/side-bridge-v-2.gif';
  }

  // 6. Plancha Frontal (Plank)
  if (nameLower.contains('rodillas apoyadas') || nameLower.contains('plancha suave') || nameLower.contains('con rodillas')) {
    return _kGifBase + 'abs/kneeling-plank-tap-shoulder-male.gif';
  }
  if (nameLower.contains('plancha') || nameLower.contains('plank')) {
    return _kGifBase + 'abs/front-plank-with-twist.gif';
  }

  // 7. Crunches / Abdomen
  if (nameLower.contains('crunch') || nameLower.contains('abdominal') || nameLower.contains('abdomen') || nameLower.contains('twist')) {
    return _kGifBase + (isLow
        ? 'abs/oblique-crunches-floor.gif'
        : (isHigh ? 'abs/hanging-leg-raise.gif' : 'abs/crunch-floor.gif'));
  }

  // 8. Superman / Lumbares
  if (nameLower.contains('superman') || nameLower.contains('lumbar') || nameLower.contains('lumbares')) {
    return _kGifBase + 'glutes/band-straight-back-stiff-leg-deadlift.gif';
  }

  // 9a. Curl Femoral en Suelo / con Deslizador / Toalla (Sliding Leg Curl on Floor with Towel)
  if (nameLower.contains('deslizador') || nameLower.contains('toalla en piso') || nameLower.contains('toalla en suelo') || nameLower.contains('piso liso') || nameLower.contains('femoral en suelo') || nameLower.contains('deslizante')) {
    return 'https://ai-fitness-coach-818a.onrender.com/static/sliding-leg-curl-on-floor-with-towel.gif';
  }

  // 9. Curl Femoral / Isquiotibiales (Hamstring Curls)
  if (nameLower.contains('curl femoral') || nameLower.contains('curl de isquio') || nameLower.contains('curl de pierna') || nameLower.contains('leg curl') || nameLower.contains('nordico') || nameLower.contains('nórdico')) {
    return _kGifBase + (isLow
        ? 'hamstrings/standing-single-leg-curl.gif'
        : (isHigh ? 'hamstrings/lever-lying-leg-curl.gif' : 'hamstrings/lever-seated-leg-curl.gif'));
  }

  // 10. Peso Muerto (Deadlift / RDL)
  if (nameLower.contains('peso muerto') || nameLower.contains('deadlift') || nameLower.contains('rdl')) {
    return _kGifBase + (isLow
        ? 'glutes/band-stiff-leg-deadlift.gif'
        : (isHigh ? 'glutes/barbell-deadlift.gif' : 'glutes/dumbbell-romanian-deadlift.gif'));
  }

  // 11. Sentadilla Búlgara / Split Squat
  if (nameLower.contains('bulgara') || nameLower.contains('búlgara') || nameLower.contains('split squat')) {
    return _kGifBase + (isLow
        ? 'quads/split-squats.gif'
        : (isHigh ? 'quads/barbell-single-leg-split-squat.gif' : 'quads/dumbbell-single-leg-split-squat.gif'));
  }

  // 12. Sentadillas con Salto / Jump Squats
  if (nameLower.contains('salto') || nameLower.contains('jump')) {
    return _kGifBase + (isLow
        ? 'quads/split-squats.gif'
        : (isHigh ? 'glutes/bodyweight-drop-jump-squat.gif' : 'glutes/jump-squat.gif'));
  }

  // 13. Sentadillas (Squats)
  if (nameLower.contains('sentadilla') || nameLower.contains('squat')) {
    return _kGifBase + (isLow
        ? 'glutes/potty-squat-with-support.gif'
        : (isHigh ? 'glutes/barbell-full-squat.gif' : 'quads/dumbbell-goblet-squat.gif'));
  }

  // 14. Zancadas / Lunges
  if (nameLower.contains('zancada') || nameLower.contains('desplante') || nameLower.contains('lunge')) {
    return _kGifBase + (isLow
        ? 'glutes/forward-lunge-male.gif'
        : (isHigh ? 'glutes/barbell-lunge.gif' : 'glutes/dumbbell-lunge.gif'));
  }

  // 15. Prensa de Piernas
  if (nameLower.contains('prensa') || nameLower.contains('leg press')) {
    if (nameLower.contains('gemelo') || nameLower.contains('talon') || nameLower.contains('pantorrilla')) {
      return _kGifBase + 'calves/sled-calf-press-on-leg-press.gif';
    }
    return _kGifBase + (isLow ? 'quads/lever-alternate-leg-press.gif' : 'glutes/sled-45-leg-press.gif');
  }

  // 16. Extensión de Cuádriceps
  if (nameLower.contains('extension de cuadriceps') || nameLower.contains('extensión de cuádriceps') || nameLower.contains('extension de pierna') || nameLower.contains('leg extension')) {
    return _kGifBase + (isLow ? 'quads/resistance-band-leg-extension.gif' : 'quads/lever-leg-extension.gif');
  }

  // 17. Elevación de Talones / Sóleo / Pantorrilla / Gemelos
  if (nameLower.contains('talon') || nameLower.contains('talón') || nameLower.contains('gemelo') || nameLower.contains('pantorrilla') || nameLower.contains('calf') || nameLower.contains('soleo') || nameLower.contains('sóleo')) {
    if (nameLower.contains('sentado') || nameLower.contains('silla') || nameLower.contains('seated')) {
      return _kGifBase + (isLow
          ? 'calves/seated-calf-stretch-male.gif'
          : (isHigh ? 'calves/barbell-seated-calf-raise.gif' : 'calves/lever-seated-calf-raise.gif'));
    }
    if (nameLower.contains('unipodal') || nameLower.contains('una pierna') || nameLower.contains('single leg')) {
      return _kGifBase + (isLow
          ? 'calves/band-single-leg-calf-raise.gif'
          : (isHigh ? 'calves/single-leg-calf-raise-on-a-dumbbell.gif' : 'calves/dumbbell-single-leg-calf-raise.gif'));
    }
    return _kGifBase + (isLow
        ? 'calves/bodyweight-standing-calf-raise.gif'
        : (isHigh ? 'calves/lever-standing-calf-raise.gif' : 'calves/dumbbell-standing-calf-raise.gif'));
  }

  // 18. Flexiones en Pica / Pike Push-ups
  if (nameLower.contains('pica') || nameLower.contains('pike')) {
    return _kGifBase + (isLow ? 'delts/band-shoulder-press.gif' : 'delts/dumbbell-seated-shoulder-press.gif');
  }

  // 19. Flexiones Diamante
  if (nameLower.contains('diamante') || nameLower.contains('diamond')) {
    return _kGifBase + (isLow ? 'triceps/bench-dip-knees-bent.gif' : 'pectorals/push-up.gif');
  }

  // 20. Flexiones de Pecho (Push-ups)
  if (nameLower.contains('flexion de pecho') || nameLower.contains('flexión de pecho') || nameLower.contains('flexiones') || nameLower.contains('push up') || nameLower.contains('pushup') || nameLower.contains('lagartija')) {
    return _kGifBase + (isLow
        ? 'pectorals/incline-push-up.gif'
        : (isHigh ? 'pectorals/barbell-bench-press.gif' : 'pectorals/push-up.gif'));
  }

  // 21. Press de Banca / Pecho
  if (nameLower.contains('press de banca') || nameLower.contains('bench press') || nameLower.contains('press de pecho') || nameLower.contains('pecho') || nameLower.contains('pectoral')) {
    return _kGifBase + (isLow
        ? 'pectorals/incline-push-up.gif'
        : (isHigh ? 'pectorals/barbell-bench-press.gif' : 'pectorals/dumbbell-bench-press.gif'));
  }

  // 22. Extensiones de Tríceps / Francés / Copa
  if (nameLower.contains('tricep') || nameLower.contains('trícep') || nameLower.contains('press frances') || nameLower.contains('copa')) {
    return _kGifBase + (isLow
        ? 'triceps/bench-dip-knees-bent.gif'
        : (isHigh ? 'triceps/barbell-lying-triceps-extension.gif' : 'triceps/cable-alternate-triceps-extension.gif'));
  }

  // 23. Curl de Bíceps
  if (nameLower.contains('bicep') || nameLower.contains('bícep') || nameLower.contains('martillo') || nameLower.contains('curl')) {
    if (nameLower.contains('martillo') || nameLower.contains('hammer')) {
      return _kGifBase + 'biceps/dumbbell-seated-hammer-curl.gif';
    }
    return _kGifBase + (isLow
        ? 'biceps/band-alternating-biceps-curl.gif'
        : (isHigh ? 'biceps/barbell-curl.gif' : 'biceps/dumbbell-biceps-curl.gif'));
  }

  // 24. Elevaciones Laterales
  if (nameLower.contains('lateral raise') || nameLower.contains('elevacion lateral') || nameLower.contains('elevaciones laterales') || nameLower.contains('elevación lateral')) {
    return _kGifBase + (isLow ? 'delts/band-front-lateral-raise.gif' : 'delts/dumbbell-lateral-raise.gif');
  }

  // 25. Press Militar / Hombros
  if (nameLower.contains('militar') || nameLower.contains('shoulder press') || nameLower.contains('hombro') || nameLower.contains('deltoid')) {
    return _kGifBase + (isLow
        ? 'delts/band-shoulder-press.gif'
        : (isHigh ? 'delts/barbell-seated-overhead-press.gif' : 'delts/dumbbell-seated-shoulder-press.gif'));
  }

  // 26a. Remo / Tracción con Toalla en Marco de Puerta o Calistenia
  if (nameLower.contains('toalla') || nameLower.contains('towel')) {
    return _kGifBase + 'upper-back/bodyweight-standing-row-with-towel.gif';
  }

  // 26. Remos / Jalones / Dominadas
  if (nameLower.contains('remo') || nameLower.contains('row') || nameLower.contains('jalon') || nameLower.contains('jalón') || nameLower.contains('dominada') || nameLower.contains('pulldown') || nameLower.contains('espalda') || nameLower.contains('dorsal')) {
    return _kGifBase + (isLow
        ? 'upper-back/band-one-arm-twisting-seated-row.gif'
        : (isHigh ? 'upper-back/barbell-bent-over-row.gif' : 'upper-back/cable-low-seated-row.gif'));
  }

  // 27. Abducción de Cadera
  if (nameLower.contains('abduc')) {
    return _kGifBase + (isLow ? 'abductors/side-hip-abduction.gif' : 'abductors/lever-seated-hip-abduction.gif');
  }

  // 28. Aducción de Cadera
  if (nameLower.contains('aduc')) {
    return _kGifBase + (isLow ? 'adductors/side-lying-hip-adduction-male.gif' : 'adductors/lever-seated-hip-adduction.gif');
  }

  // 29. Fallback general por agonista
  final text = '${nameLower} ${agonist.toLowerCase()}';
  if (text.contains('isquio') || text.contains('femoral')) {
    return _kGifBase + (isLow ? 'hamstrings/standing-single-leg-curl.gif' : 'hamstrings/lever-seated-leg-curl.gif');
  }
  if (text.contains('glute') || text.contains('glúte')) {
    return _kGifBase + (isLow ? 'glutes/low-glute-bridge-on-floor.gif' : 'glutes/glute-bridge-two-legs-on-bench-male.gif');
  }
  if (text.contains('cuadricep') || text.contains('cuádricep') || text.contains('pierna')) {
    return _kGifBase + (isLow ? 'glutes/potty-squat-with-support.gif' : 'quads/dumbbell-goblet-squat.gif');
  }

  return _kGifBase + 'delts/dumbbell-seated-shoulder-press.gif';
}

/// Color del agonista: rojo brillante, como pide el diseno didactico.
const Color kAgonistColor = Color(0xFFFF3B30);

/// Color de los sinergistas: ambar/naranja.
const Color kSynergistColor = Color(0xFFFF9500);

/// Fondo superior de la pantalla.
const Color kAnatomyBackground = Color(0xFF121212);

/// Fondo de las tarjetas y del panel inferior.
const Color kAnatomySurface = Color(0xFF1E1E1E);

/// Modelo anatómico 3D de alta fidelidad con musculatura y esqueleto real (Z-Anatomy GLB).
const String kMuscularAnatomyModelUrl =
    'https://cdn.jsdelivr.net/gh/hpfrei/body-anatomy-3d-viewer@main/public/body.glb';

/// Modelo humanoide alternativo de Khronos.
const String kDefaultAnatomyModelUrl =
    'https://cdn.jsdelivr.net/gh/hpfrei/body-anatomy-3d-viewer@main/public/body.glb';

/// Catálogo de los cuatro ejercicios de la demostracion.
const List<AnatomyExercise> kAnatomyExercises = [
  AnatomyExercise(
    id: 'squat',
    gifUrl: 'https://raw.githubusercontent.com/JahelCuadrado/ExerciseGymGifsDB/main/glutes/potty-squat-with-support.gif',
    name: 'Sentadilla Asistida con Peso Corporal',
    shortName: 'Sentadilla',
    agonist: 'Cuadriceps',
    synergists: ['Gluteos', 'Isquiotibiales', 'Core', 'Aductores'],
    intensityLevel: 'Básico (Intensidad Baja)',
    biomechanics:
        'Rodillas flexionadas a 90 grados o menos de forma controlada. '
        'Espalda neutra, sin arquearla.',
    tempo: '3s bajada · 1s pausa · 2s subida suave',
    posture:
        'Apoya toda la planta del pie. Piernas paralelas, rodillas alineadas '
        'con la punta de los pies. Pecho abierto y mirada al frente.',
    warning:
        'Si sientes dolor en la rodilla o la cadera, baja la profundidad y '
        'consulta a un profesional. No bloquees la articulacion.',
  ),
  AnatomyExercise(
    id: 'glute-bridge',
    gifUrl: 'https://raw.githubusercontent.com/JahelCuadrado/ExerciseGymGifsDB/main/glutes/low-glute-bridge-on-floor.gif',
    name: 'Puente de Glúteos en Suelo',
    shortName: 'Puente Glúteo',
    agonist: 'Gluteos',
    synergists: ['Isquiotibiales', 'Core', 'Estabilizadores'],
    intensityLevel: 'Básico (Intensidad Baja)',
    biomechanics:
        'Extensión de cadera en suelo alineando rodillas, caderas y hombros en el punto superior.',
    tempo: '3s bajada · 1s contracción arriba · 1s subida',
    posture:
        'Empuja el suelo con los talones y mantén el abdomen firme sin arquear la espalda baja.',
    warning:
        'No hiperextiendas la zona lumbar; el empuje nace exclusivamente de los glúteos.',
  ),
  AnatomyExercise(
    id: 'lunge',
    gifUrl: 'https://raw.githubusercontent.com/JahelCuadrado/ExerciseGymGifsDB/main/glutes/forward-lunge-male.gif',
    name: 'Zancada con Peso Corporal',
    shortName: 'Zancada',
    agonist: 'Cuadriceps, Gluteos',
    synergists: ['Isquiotibiales', 'Core', 'Gemelos'],
    intensityLevel: 'Básico (Intensidad Baja)',
    biomechanics:
        'Paso controlado formando ángulos de 90 grados en ambas rodillas.',
    tempo: '3s excéntrico · 1s pausa · 1s concéntrico',
    posture:
        'Torso erguido, pelvis neutra y rodilla delantera alineada con el segundo dedo del pie.',
    warning:
        'Evita golpear la rodilla trasera contra el suelo; frena suavemente antes de tocar.',
  ),
  AnatomyExercise(
    id: 'hamstring-curl',
    gifUrl: 'https://raw.githubusercontent.com/JahelCuadrado/ExerciseGymGifsDB/main/hamstrings/lever-seated-leg-curl.gif',
    name: 'Curl de Isquiotibiales',
    shortName: 'Curl Femoral',
    agonist: 'Isquiotibiales',
    synergists: ['Gemelos', 'Gluteos'],
    intensityLevel: 'Intermedio (Intensidad Media)',
    biomechanics:
        'Flexión controlada de rodilla aislando la musculatura posterior del muslo.',
    tempo: '3s excéntrico · 1s pausa · 1s concéntrico',
    posture:
        'Espalda bien apoyada y pelvis estable durante toda la flexión.',
    warning:
        'Controla el regreso del peso sin soltarlo de golpe para proteger los tendones.',
  ),
];
