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

/// Garantiza que SIEMPRE exista un GIF anatomico acorde al musculo y a la intensidad,
/// evitando cualquier recuadro textual.
String resolveGuaranteedGifUrl({
  required String name,
  required String agonist,
  required String intensityLevel,
  String? existingUrl,
}) {
  if (existingUrl != null && existingUrl.trim().isNotEmpty) {
    return existingUrl.trim();
  }
  final text = '${name.toLowerCase()} ${agonist.toLowerCase()}';
  final intLower = intensityLevel.toLowerCase();
  final isLow = intLower.contains('baja') || intLower.contains('basico') || intLower.contains('básico');
  final isHigh = intLower.contains('alta') || intLower.contains('avanzado');

  if (text.contains('isquio') || text.contains('femoral') || text.contains('hamstring')) {
    return _kGifBase +
        (isLow
            ? 'hamstrings/standing-single-leg-curl.gif'
            : (isHigh
                ? 'hamstrings/lever-lying-leg-curl.gif'
                : 'hamstrings/lever-seated-leg-curl.gif'));
  }
  if (text.contains('prensa') || text.contains('leg press')) {
    return _kGifBase +
        (isLow
            ? 'quads/lever-alternate-leg-press.gif'
            : 'glutes/sled-45-leg-press.gif');
  }
  if (text.contains('zancada') || text.contains('desplante') || text.contains('lunge')) {
    return _kGifBase +
        (isLow
            ? 'glutes/forward-lunge-male.gif'
            : (isHigh ? 'glutes/barbell-lunge.gif' : 'glutes/dumbbell-lunge.gif'));
  }
  if (text.contains('puente') || text.contains('bridge') || text.contains('hip thrust')) {
    return _kGifBase +
        (isLow
            ? 'glutes/low-glute-bridge-on-floor.gif'
            : (isHigh
                ? 'glutes/barbell-glute-bridge.gif'
                : 'glutes/glute-bridge-two-legs-on-bench-male.gif'));
  }
  if (text.contains('gemelo') || text.contains('pantorrilla') || text.contains('talon') || text.contains('talón') || text.contains('calf')) {
    return _kGifBase +
        (isLow
            ? 'calves/bodyweight-standing-calf-raise.gif'
            : 'calves/dumbbell-standing-calf-raise.gif');
  }
  if (text.contains('abduc')) {
    return _kGifBase +
        (isLow
            ? 'abductors/side-hip-abduction.gif'
            : 'abductors/lever-seated-hip-abduction.gif');
  }
  if (text.contains('aduc')) {
    return _kGifBase +
        (isLow
            ? 'adductors/side-lying-hip-adduction-male.gif'
            : 'adductors/lever-seated-hip-adduction.gif');
  }
  if (text.contains('sentadilla') || text.contains('squat') || text.contains('cuadriceps') || text.contains('cuádriceps') || text.contains('glute') || text.contains('glúte') || text.contains('pierna')) {
    return _kGifBase +
        (isLow
            ? 'glutes/potty-squat-with-support.gif'
            : (isHigh
                ? 'glutes/barbell-full-squat.gif'
                : 'quads/dumbbell-goblet-squat.gif'));
  }
  if (text.contains('pecho') || text.contains('pectoral') || text.contains('flexion') || text.contains('push')) {
    return _kGifBase +
        (isLow ? 'pectorals/incline-push-up.gif' : 'pectorals/push-up.gif');
  }
  if (text.contains('espalda') || text.contains('dorsal') || text.contains('remo') || text.contains('dominada')) {
    return _kGifBase +
        (isLow
            ? 'upper-back/band-one-arm-twisting-seated-row.gif'
            : 'lats/cable-pulldown.gif');
  }
  if (text.contains('hombro') || text.contains('deltoid') || text.contains('militar')) {
    return _kGifBase +
        (isLow
            ? 'delts/band-shoulder-press.gif'
            : 'delts/dumbbell-seated-shoulder-press.gif');
  }
  if (text.contains('core') || text.contains('abdom') || text.contains('plancha') || text.contains('dead bug')) {
    return _kGifBase + 'abs/dead-bug.gif';
  }
  return _kGifBase + 'glutes/potty-squat-with-support.gif';
}

/// Color del agonista: rojo brillante, como pide el diseno didactico.
const Color kAgonistColor = Color(0xFFFF3B30);

/// Color de los sinergistas: ambar/naranja.
const Color kSynergistColor = Color(0xFFFF9500);

/// Fondo superior de la pantalla.
const Color kAnatomyBackground = Color(0xFF121212);

/// Fondo de las tarjetas y del panel inferior.
const Color kAnatomySurface = Color(0xFF1E1E1E);

/// Modelo humanoide real y con licencia, servido por modelviewer.dev.
const String kDefaultAnatomyModelUrl =
    'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/CesiumMan/glTF-Binary/CesiumMan.glb';

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
