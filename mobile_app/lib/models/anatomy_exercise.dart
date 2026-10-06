import 'package:flutter/material.dart';

/// Datos de un ejercicio para la demostracion anatomica 3D.
///
/// Cada ejercicio define que musculo es el agonista (principal), cuales
/// ligaments como sinergistas o estabilizadores, los rangos articulares que debe
/// respetar, el tempo recomendado y las notas de postura y prevencion.
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
  });

  final String id;
  final String name;
  final String shortName;

  /// Musculo principal, el que mas-stimula el ejercicio.
  final String agonist;

  /// Musculos queاوية y estabiliza durante el movimiento.
  final List<String> synergists;

  /// Descripcion de los angulos articulares clave.
  final String biomechanics;

  /// Tempo de ejecucion recomendado.
  final String tempo;

  /// Nota postural clave.
  final String posture;

  /// Advertencia de prevencion de lesiones.
  final String warning;

  /// Modelo 3D que se muestra para este ejercicio.
  final String gifUrl;
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
    gifUrl: 'https://raw.githubusercontent.com/JahelCuadrado/ExerciseGymGifsDB/main/legs/squat.gif',
    name: 'Sentadilla Profunda con Barra',
    shortName: 'Sentadilla',
    agonist: 'Cuadriceps',
    synergists: ['Gluteos', 'Isquiotibiales', 'Core', 'Aductores'],
    biomechanics:
        'Rodillas flexionadas a 90 grados o menos. La cadera debe descender '
        'por debajo de la rodilla. Espalda neutra, sin arquearla.',
    tempo: '3s excéntrico · 1s pausa · 1s concéntrico',
    posture:
        'Apoya toda la planta del pie. Piernas paralelas, rodillas alineadas '
        'con la punta de los pies. pecho abierto y mirada al frente.',
    warning:
        'Si sientes dolor en la rodilla o la cadera, baja la profundidad y '
        'consulta a un profesional. No bloquees la articulacion.',
  ),
  AnatomyExercise(
    id: 'military-press',
    gifUrl: 'https://raw.githubusercontent.com/JahelCuadrado/ExerciseGymGifsDB/main/shoulders/barbell-military-press.gif',
    name: 'Press Militar con Barra',
    shortName: 'Press Militar',
    agonist: 'Deltoides',
    synergists: ['Triceps', 'Trapecio', 'Core', 'Biceps'],
    biomechanics:
        'Codos por debajo de la linea de los hombros al final del empuje. '
        'Trayectoria vertical, la barra pasa frente a la cara.',
    tempo: '2s excéntrico · 1s pausa · 1s concéntrico',
    posture:
        'Aprieta el abdomen para no arquear la espalda. Muñecas neutras, '
        'por encima del codo. No empujes con las piernas.',
    warning:
        'Demasiada extension lumbar puede lesionar la zona lumbar. '
        'Reduce el peso si no puedes mantener la pelvis neutra.',
  ),
  AnatomyExercise(
    id: 'deadlift',
    gifUrl: 'https://raw.githubusercontent.com/JahelCuadrado/ExerciseGymGifsDB/main/back/barbell-deadlift.gif',
    name: 'Peso Muerto con Barra',
    shortName: 'Peso Muerto',
    agonist: 'Isquiotibiales',
    synergists: ['Gluteos', 'Dorsal ancho', 'Core', 'Trapecio'],
    biomechanics:
        'Flexion de cadera marcada. La cadera sube y baja a la vez que los '
        'hombros. Barra rozando las piernas durante todo el recorrido.',
    tempo: '2s excéntrico · 1s pausa · 1s concéntrico',
    posture:
        'Coluna neutra en todo momento, como una tabla. Empuja el suelo con '
        'los pies, no tires solo con la espalda.',
    warning:
        'Redondear la espalda es el riesgo principal: tecnica antes que peso. '
        'Si aparece dolor lumbar, detente y busca un profesional de salud.',
  ),
  AnatomyExercise(
    id: 'pull-up',
    gifUrl: 'https://raw.githubusercontent.com/JahelCuadrado/ExerciseGymGifsDB/main/lats/pull-up.gif',
    name: 'Dominadas',
    shortName: 'Dominadas',
    agonist: 'Dorsal ancho',
    synergists: ['Biceps', 'Trapecio', 'Core', 'Romboides'],
    biomechanics:
        'Codos por debajo de la barra al final. Hombros bajan primero, luego '
        'los codos suben hacia las costillas.',
    tempo: '2s concéntrico · 1s pausa · 3s excéntrico',
    posture:
        'Empieza con los brazos estirados. No balancees el cuerpo ni uses '
        'impulso: el trabajo es de la espalda, no del vaiven.',
    warning:
        'Colgar con los hombros muy elevados puede molestiar en el manguito '
        'rotador. Si hay molestia en el hombro, reduce amplitud.',
  ),
];
