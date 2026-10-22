import 'package:flutter/material.dart';
import 'package:mobile_app/models/anatomy_exercise.dart';
import 'package:mobile_app/screens/anatomy_workout_screen.dart';
import 'package:mobile_app/screens/coach_screen.dart';
import 'package:mobile_app/services/weekly_plan_service.dart';

/// Datos estructurados de ejercicios adaptados para tren inferior / discapacidad motora / silla de ruedas.
class AdaptiveExerciseItem {
  final String id;
  final String name;
  final String category; // 'Pecho', 'Espalda', 'Hombros', 'Brazos', 'Core'
  final String muscle;
  final String secondary;
  final String setsReps;
  final String intensity;
  final String adaptationRationale;
  final String posture;
  final String warning;
  final String explicitGifUrl;

  const AdaptiveExerciseItem({
    required this.id,
    required this.name,
    required this.category,
    required this.muscle,
    required this.secondary,
    required this.setsReps,
    required this.intensity,
    required this.adaptationRationale,
    required this.posture,
    required this.warning,
    required this.explicitGifUrl,
  });

  AnatomyExercise toAnatomyExercise() {
    return AnatomyExercise(
      id: id,
      name: name,
      shortName: name,
      agonist: muscle,
      synergists: [secondary],
      intensityLevel: intensity,
      biomechanics: adaptationRationale,
      tempo: '3s fase excéntrica · 1s pausa isométrica · 2s contracción concéntrica',
      posture: posture,
      warning: warning,
      gifUrl: explicitGifUrl,
    );
  }
}

/// Catálogo certificado de ejercicios 100% en sedestación (silla de ruedas o banco adaptado),
/// con cero impacto o reclutamiento de miembros inferiores.
const List<AdaptiveExerciseItem> kAdaptiveExercises = [
  // ---------------- PECHO (PECTORALES) ----------------
  AdaptiveExerciseItem(
    id: 'aperturas_maquina_sentado',
    name: 'Aperturas Pectorales en Máquina Sentado (Pec Deck)',
    category: 'Pecho',
    muscle: 'Pecho',
    secondary: 'Deltoides Anterior',
    setsReps: '3 series × 12 reps (RPE 6-7)',
    intensity: 'Intermedio (Intensidad Media)',
    adaptationRationale: 'Aislamiento pectoral puro ejecutado 100% sentado en la máquina o silla adaptada. Elimina cualquier necesidad de apoyo o empuje podal (sin leg drive), garantizando estabilidad lumbar completa.',
    posture: 'Espalda totalmente pegada al respaldo. Codos a la altura media del pecho, cerrando con tensión controlada.',
    warning: 'No hiperextender los hombros hacia atrás más allá de los 90 grados para proteger la cápsula articular.',
    explicitGifUrl: 'https://cdn.jsdelivr.net/gh/JahelCuadrado/ExerciseGymGifsDB@v1.1.0/pectorals/lever-seated-fly.gif',
  ),
  AdaptiveExerciseItem(
    id: 'press_pecho_maquina_sentado',
    name: 'Press de Pecho en Máquina Sentado',
    category: 'Pecho',
    muscle: 'Pecho',
    secondary: 'Tríceps / Hombros',
    setsReps: '3 series × 10-12 reps (RPE 7)',
    intensity: 'Intermedio (Intensidad Media)',
    adaptationRationale: 'La trayectoria fija de la máquina elimina el desequilibrio lateral y permite un empuje seguro sin requerir soporte de los pies ni tensión en la pelvis.',
    posture: 'Agarre prono firme, torso perpendicular al suelo, exhalar al extender los codos hacia el frente.',
    warning: 'No bloquear los codos bruscamente al final del recorrido.',
    explicitGifUrl: 'https://cdn.jsdelivr.net/gh/JahelCuadrado/ExerciseGymGifsDB@v1.1.0/pectorals/lever-chest-press.gif',
  ),
  AdaptiveExerciseItem(
    id: 'press_pecho_banda_silla',
    name: 'Press de Pecho con Banda Elástica en Silla de Ruedas',
    category: 'Pecho',
    muscle: 'Pecho',
    secondary: 'Tríceps',
    setsReps: '3 series × 12-15 reps (RPE 6)',
    intensity: 'Básico (Intensidad Baja)',
    adaptationRationale: 'La banda se ancla al respaldo posterior de la silla de ruedas o soporte vertical. Permite una tensión progresiva sin impacto articular, ideal para casa o gimnasio.',
    posture: 'Espalda bien apoyada en el respaldo de la silla. Empuje frontal suave manteniendo los codos a 45°.',
    warning: 'Verificar que el anclaje de la banda esté firme antes de iniciar las repeticiones.',
    explicitGifUrl: 'https://cdn.jsdelivr.net/gh/JahelCuadrado/ExerciseGymGifsDB@v1.1.0/pectorals/resistance-band-seated-chest-press.gif',
  ),
  AdaptiveExerciseItem(
    id: 'press_svend_disco_sentado',
    name: 'Press Svend Isométrico con Disco Sentado',
    category: 'Pecho',
    muscle: 'Pecho',
    secondary: 'Deltoides Anterior',
    setsReps: '3 series × 12 reps con 2s de pausa',
    intensity: 'Básico (Intensidad Baja)',
    adaptationRationale: 'Presión palmar bilateral de un disco a la altura del esternón. Gran activación de las fibras medias del pectoral sin requerir peso libre sobre la cabeza ni apoyo podal.',
    posture: 'Tronco erguido, palmas apretando el disco contra el centro del pecho y extendiendo hacia el frente.',
    warning: 'Mantener la tensión de compresión constante sin encoger los hombros.',
    explicitGifUrl: 'https://cdn.jsdelivr.net/gh/JahelCuadrado/ExerciseGymGifsDB@v1.1.0/pectorals/weighted-svend-press.gif',
  ),

  // ---------------- ESPALDA (DORSALES / TRACCIÓN) ----------------
  AdaptiveExerciseItem(
    id: 'jalon_pecho_polea_alta',
    name: 'Jalón al Pecho Sentado en Polea Alta',
    category: 'Espalda',
    muscle: 'Espalda',
    secondary: 'Bíceps',
    setsReps: '3 series × 10-12 reps (RPE 7)',
    intensity: 'Intermedio (Intensidad Media)',
    adaptationRationale: 'Tracción vertical óptima ejecutada desde el asiento o silla de ruedas. Desarrolla la fuerza escapular y dorsal imprescindible para la propulsión y transferencias en silla.',
    posture: 'Torso con leve inclinación de 10°. Tirar llevando los codos hacia los bolsillos traseros hasta tocar la parte alta del esternón.',
    warning: 'No balancear el tronco ni bajar la barra por detrás de la nuca.',
    explicitGifUrl: 'https://cdn.jsdelivr.net/gh/JahelCuadrado/ExerciseGymGifsDB@v1.1.0/lats/cable-pulldown.gif',
  ),
  AdaptiveExerciseItem(
    id: 'remo_sentado_polea_vbar',
    name: 'Remo Sentado en Polea con Agarre Estrecho V-Bar',
    category: 'Espalda',
    muscle: 'Espalda',
    secondary: 'Bíceps / Romboides',
    setsReps: '3 series × 12 reps (RPE 6-7)',
    intensity: 'Intermedio (Intensidad Media)',
    adaptationRationale: 'Tracción horizontal que tonifica romboides y trapecio medio. El apoyo de almohadilla o respaldo estabiliza la pelvis sin carga compresiva en la columna lumbar.',
    posture: 'Pecho abierto, hombros descendidos. Retracción escapular acentuada al final del tirón.',
    warning: 'Evitar tirones bruscos con los lumbares; el movimiento debe ser 100% de brazos y escápulas.',
    explicitGifUrl: 'https://cdn.jsdelivr.net/gh/JahelCuadrado/ExerciseGymGifsDB@v1.1.0/lats/cable-seated-high-row-v-bar.gif',
  ),
  AdaptiveExerciseItem(
    id: 'remo_unilateral_banda_sentado',
    name: 'Remo Sentado Unilateral con Banda / Polea',
    category: 'Espalda',
    muscle: 'Espalda',
    secondary: 'Deltoides Posterior',
    setsReps: '3 series × 12 reps por lado',
    intensity: 'Básico (Intensidad Baja)',
    adaptationRationale: 'Permite equilibrar asimetrías de fuerza entre ambos brazos y entrena la estabilidad anti-rotacional del tronco en sedestación.',
    posture: 'Una mano estabiliza el reposabrazos o muslo mientras el brazo opuesto tracciona con el codo pegado al torso.',
    warning: 'Mantener el tronco fijo sin rotar bruscamente.',
    explicitGifUrl: 'https://cdn.jsdelivr.net/gh/JahelCuadrado/ExerciseGymGifsDB@v1.1.0/upper-back/band-one-arm-twisting-seated-row.gif',
  ),

  // ---------------- HOMBROS (DELTOIDES) ----------------
  AdaptiveExerciseItem(
    id: 'press_militar_sentado_mancuernas',
    name: 'Press Militar Sentado con Mancuernas',
    category: 'Hombros',
    muscle: 'Hombros',
    secondary: 'Tríceps',
    setsReps: '3 series × 10-12 reps (RPE 6-7)',
    intensity: 'Intermedio (Intensidad Media)',
    adaptationRationale: 'Desarrolla la fuerza vertical del deltoides anterior y lateral con la espalda apoyada a 90°, protegiendo la columna sin requerir soporte podal.',
    posture: 'Respaldo vertical firme, core compacto. Empuje hacia arriba en arco suave sin golpear las mancuernas.',
    warning: 'No hiperextender el cuello ni dejar caer el peso bruscamente.',
    explicitGifUrl: 'https://cdn.jsdelivr.net/gh/JahelCuadrado/ExerciseGymGifsDB@v1.1.0/delts/dumbbell-seated-shoulder-press.gif',
  ),
  AdaptiveExerciseItem(
    id: 'elevaciones_laterales_sentado',
    name: 'Elevaciones Laterales Sentado con Mancuernas',
    category: 'Hombros',
    muscle: 'Hombros',
    secondary: 'Trapecio Superior',
    setsReps: '3 series × 12-15 reps (RPE 6)',
    intensity: 'Básico (Intensidad Baja)',
    adaptationRationale: 'Al estar sentado se anula el impulso o balanceo de piernas, logrando un estímulo puro en el deltoides lateral.',
    posture: 'Ligera flexión de codo (15°). Elevar hasta la horizontal con control excéntrico en la bajada.',
    warning: 'No levantar los brazos por encima de la altura de los hombros para no pinzar el manguito rotador.',
    explicitGifUrl: 'https://cdn.jsdelivr.net/gh/JahelCuadrado/ExerciseGymGifsDB@v1.1.0/delts/dumbbell-seated-lateral-raise.gif',
  ),
  AdaptiveExerciseItem(
    id: 'pajaros_deltoides_posterior_maquina',
    name: 'Pájaros / Deltoides Posterior en Máquina Sentado',
    category: 'Hombros',
    muscle: 'Hombros',
    secondary: 'Espalda Alta',
    setsReps: '3 series × 12 reps (RPE 6)',
    intensity: 'Intermedio (Intensidad Media)',
    adaptationRationale: 'Con el pecho apoyado contra la máquina, se trabaja la parte posterior del hombro y manguito rotador externo, clave para prevenir el síndrome de pinzamiento en usuarios de silla de ruedas.',
    posture: 'Pecho en la almohadilla, brazos casi rectos abriendo en plano horizontal hacia atrás.',
    warning: 'Usar carga moderada que permita sentir la contracción detrás del hombro.',
    explicitGifUrl: 'https://cdn.jsdelivr.net/gh/JahelCuadrado/ExerciseGymGifsDB@v1.1.0/delts/lever-seated-reverse-fly.gif',
  ),
  AdaptiveExerciseItem(
    id: 'press_hombro_banda_sentado',
    name: 'Press de Hombro Sentado con Banda Elástica',
    category: 'Hombros',
    muscle: 'Hombros',
    secondary: 'Tríceps',
    setsReps: '3 series × 12 reps (RPE 5-6)',
    intensity: 'Básico (Intensidad Baja)',
    adaptationRationale: 'Banda pasada bajo el asiento de la silla de ruedas. Proporciona resistencia lineal suave y control postural sin riesgo de caída de pesos.',
    posture: 'Empujar bilateralmente hacia arriba manteniendo la vista al frente.',
    warning: 'Verificar la elasticidad y tensión uniforme de ambos lados.',
    explicitGifUrl: 'https://cdn.jsdelivr.net/gh/JahelCuadrado/ExerciseGymGifsDB@v1.1.0/delts/resistance-band-seated-shoulder-press.gif',
  ),

  // ---------------- BRAZOS (BÍCEPS Y TRÍCEPS) ----------------
  AdaptiveExerciseItem(
    id: 'curl_biceps_sentado_mancuernas',
    name: 'Curl de Bíceps Sentado con Mancuernas',
    category: 'Brazos',
    muscle: 'Brazos',
    secondary: 'Antebrazos',
    setsReps: '3 series × 12 reps (RPE 6)',
    intensity: 'Básico (Intensidad Baja)',
    adaptationRationale: 'Flexión de codo estricta en sedestación. Desarrolla la musculatura flexora del brazo necesaria para tareas de agarre y arrastre.',
    posture: 'Codos pegados a los costados del torso, rotando las palmas hacia arriba al subir (supinación).',
    warning: 'Evitar adelantar los codos para no involucrar el deltoides anterior.',
    explicitGifUrl: 'https://cdn.jsdelivr.net/gh/JahelCuadrado/ExerciseGymGifsDB@v1.1.0/biceps/dumbbell-seated-bicep-curl.gif',
  ),
  AdaptiveExerciseItem(
    id: 'curl_martillo_sentado',
    name: 'Curl Martillo Sentado con Mancuernas',
    category: 'Brazos',
    muscle: 'Brazos',
    secondary: 'Braquial Anterior',
    setsReps: '3 series × 12 reps (RPE 6)',
    intensity: 'Básico (Intensidad Baja)',
    adaptationRationale: 'Agarre neutro (palmas enfrentadas) que fortalece el braquiorradial y los tendones del antebrazo con comodidad de muñeca.',
    posture: 'Mancuernas verticales durante todo el trayecto sin balanceo del tronco.',
    warning: 'Bajar lentamente en 3 segundos para maximizar el control articular.',
    explicitGifUrl: 'https://cdn.jsdelivr.net/gh/JahelCuadrado/ExerciseGymGifsDB@v1.1.0/biceps/dumbbell-seated-hammer-curl.gif',
  ),
  AdaptiveExerciseItem(
    id: 'extension_triceps_copa_sentado',
    name: 'Extensión de Tríceps Copa Sentado con Mancuerna',
    category: 'Brazos',
    muscle: 'Brazos',
    secondary: 'Hombros',
    setsReps: '3 series × 12 reps (RPE 6-7)',
    intensity: 'Intermedio (Intensidad Media)',
    adaptationRationale: 'Estira y tonifica la cabeza larga del tríceps con la espalda bien posicionada contra el respaldo de la silla.',
    posture: 'Sujetar la mancuerna con ambas manos por detrás de la cabeza, codos hacia el techo y flexionando solo los antebrazos.',
    warning: 'Mantener los codos cerrados sin abrirlos excesivamente hacia los laterales.',
    explicitGifUrl: 'https://cdn.jsdelivr.net/gh/JahelCuadrado/ExerciseGymGifsDB@v1.1.0/triceps/dumbbell-seated-triceps-extension.gif',
  ),
  AdaptiveExerciseItem(
    id: 'fondos_triceps_maquina_sentado',
    name: 'Fondos de Tríceps en Máquina Sentado (Dip Sentado)',
    category: 'Brazos',
    muscle: 'Brazos',
    secondary: 'Pectoral Inferior',
    setsReps: '3 series × 10-12 reps (RPE 7)',
    intensity: 'Intermedio (Intensidad Media)',
    adaptationRationale: 'Simula el patrón motor de empuje hacia abajo requerido para elevar el propio cuerpo durante transferencias entre la silla de ruedas, cama o vehículo.',
    posture: 'Manos en los agarres laterales, empujar hacia el suelo extendiendo los codos con el torso erguido.',
    warning: 'No dejar que los hombros se eleven hacia las orejas durante la subida.',
    explicitGifUrl: 'https://cdn.jsdelivr.net/gh/JahelCuadrado/ExerciseGymGifsDB@v1.1.0/triceps/lever-seated-dip.gif',
  ),

  // ---------------- CORE Y TRONCO SENTADO ----------------
  AdaptiveExerciseItem(
    id: 'giros_torso_banda_sentado',
    name: 'Giros de Torso Sentado con Banda Elástica',
    category: 'Core',
    muscle: 'Core',
    secondary: 'Oblicuos',
    setsReps: '3 series × 12-15 giros por lado',
    intensity: 'Básico (Intensidad Baja)',
    adaptationRationale: 'Fortalece la musculatura rotadora del tronco y los oblicuos en sedestación. Vital para el equilibrio sentado y la estabilidad del tronco sin requerir cadera.',
    posture: 'Sujetar la banda con ambas manos frente al esternón y rotar el tórax en bloque 30-40° hacia un lado.',
    warning: 'Rotar de manera controlada y sin movimientos bruscos o sacudidas.',
    explicitGifUrl: 'https://cdn.jsdelivr.net/gh/JahelCuadrado/ExerciseGymGifsDB@v1.1.0/abs/band-seated-twist.gif',
  ),
  AdaptiveExerciseItem(
    id: 'crunch_abdominal_polea_sentado',
    name: 'Crunch Abdominal Sentado en Polea Alta',
    category: 'Core',
    muscle: 'Core',
    secondary: 'Transverso Abdominal',
    setsReps: '3 series × 12 reps (RPE 6)',
    intensity: 'Intermedio (Intensidad Media)',
    adaptationRationale: 'Flexión anterior controlada de la columna torácica contra resistencia en polea. Estimula el recto abdominal sin compresión de cadera ni piernas.',
    posture: 'Sujetar la cuerda a la altura de las orejas, exhalar y curvar suavemente el torso hacia los muslos.',
    warning: 'El movimiento proviene del abdomen, no de tirar con los brazos.',
    explicitGifUrl: 'https://cdn.jsdelivr.net/gh/JahelCuadrado/ExerciseGymGifsDB@v1.1.0/abs/cable-seated-crunch.gif',
  ),
  AdaptiveExerciseItem(
    id: 'rotaciones_tronco_pica_sentado',
    name: 'Rotaciones de Tronco con Pica Sentado',
    category: 'Core',
    muscle: 'Core',
    secondary: 'Estabilidad Espinal',
    setsReps: '3 series × 20 giros suaves',
    intensity: 'Básico (Intensidad Baja)',
    adaptationRationale: 'Movilidad torácica suave con barra ligera o pica para descomprimir la columna y mejorar la capacidad respiratoria en sedestación prolongada.',
    posture: 'Pica sobre los hombros, mirada al frente, rotación armónica respirando profundamente.',
    warning: 'Mantener un rango cómodo sin forzar el final del giro.',
    explicitGifUrl: 'https://cdn.jsdelivr.net/gh/JahelCuadrado/ExerciseGymGifsDB@v1.1.0/abs/barbell-seated-twist.gif',
  ),
];

class AdaptiveWorkoutScreen extends StatefulWidget {
  const AdaptiveWorkoutScreen({super.key});

  @override
  State<AdaptiveWorkoutScreen> createState() => _AdaptiveWorkoutScreenState();
}

class _AdaptiveWorkoutScreenState extends State<AdaptiveWorkoutScreen> {
  String _selectedCategory = 'Todos';

  final List<String> _categories = const [
    'Todos',
    'Pecho',
    'Espalda',
    'Hombros',
    'Brazos',
    'Core',
  ];

  List<AdaptiveExerciseItem> get _filteredExercises {
    if (_selectedCategory == 'Todos') {
      return kAdaptiveExercises;
    }
    return kAdaptiveExercises
        .where((e) => e.category.toLowerCase() == _selectedCategory.toLowerCase())
        .toList();
  }

  void _openExerciseViewer(AdaptiveExerciseItem item) {
    final allAnatomyExercises =
        kAdaptiveExercises.map((e) => e.toAnatomyExercise()).toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnatomyWorkoutScreen(
          initialExerciseId: item.id,
          dynamicExercises: allAnatomyExercises,
        ),
      ),
    );
  }

  Future<void> _injectAdaptiveRoutineToSchedule() async {
    final plan = {
      'routine_name': 'Torso Adaptado (Discapacidad Motora / Sentado)',
      'notes': 'Sesión adaptada con 0% carga podal y máxima estabilidad en banco/silla.',
      'exercises': _filteredExercises.map((e) {
        return {
          'name': e.name,
          'primary_muscle': e.muscle,
          'secondary_muscle': e.secondary,
          'sets': '3',
          'reps': '10-12',
          'intensity_level': e.intensity,
          'biomechanics': e.adaptationRationale,
          'posture': e.posture,
          'warning': e.warning,
          'gif_url': e.explicitGifUrl,
        };
      }).toList(),
      'nutrition': {
        'desayuno': 'Tortilla de claras de huevo con avena y manzana en rodajas.',
        'almuerzo': 'Pechuga a la plancha con arroz integral y vegetales al vapor.',
        'cena': 'Filete de pescado o tofu al horno con ensalada fresca.',
      }
    };

    final result = await WeeklyPlanService.instance.injectCustomPlanForToday(plan);
    if (!mounted) return;

    final daysStr = (result['assigned_days'] as List?)?.join(', ') ?? 'hoy';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Rutina adaptada agregada a tu cronograma ($daysStr).'),
        backgroundColor: const Color(0xFF1B4D3E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _consultWithCoach() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CoachScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredExercises;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.accessible_forward_rounded, color: Color(0xFF8BE0C0), size: 24),
            SizedBox(width: 10),
            Text(
              'Ejercicios Adaptados',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F192B),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Consultar Coach IA',
            icon: const Icon(Icons.smart_toy_rounded, color: Color(0xFF8BE0C0)),
            onPressed: _consultWithCoach,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner de Seguridad Médica y Biomecánica Inclusiva
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF132D29), Color(0xFF0F1B2B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF8BE0C0).withOpacity(0.4), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8BE0C0).withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_user_rounded, color: Color(0xFF8BE0C0), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Protocolo de Entrenamiento Adaptado',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14.5),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8BE0C0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '100% SEGURO',
                        style: TextStyle(color: Color(0xFF0B1220), fontSize: 10, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Rutinas diseñadas para personas con discapacidad motora en miembros inferiores, uso de silla de ruedas o limitaciones de apoyo podal. 0% carga axial en piernas, soporte espinal total y visualización 3D 360°.',
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildPillBadge(Icons.chair_alt_rounded, 'Sedestación Estable'),
                    _buildPillBadge(Icons.shield_outlined, 'Sin Carga en Rodillas/Pelvis'),
                    _buildPillBadge(Icons.view_in_ar_rounded, 'Visor 3D Dual 360°'),
                  ],
                ),
              ],
            ),
          ),

          // Selector de Categorías (Chips)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    showCheckmark: false,
                    avatar: Icon(
                      _getCategoryIcon(cat),
                      size: 15,
                      color: isSelected ? const Color(0xFF0B1220) : const Color(0xFF8BE0C0),
                    ),
                    label: Text(cat),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF0B1220) : Colors.white,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    selectedColor: const Color(0xFF8BE0C0),
                    backgroundColor: const Color(0xFF16233A),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF8BE0C0) : Colors.white12,
                    ),
                    onSelected: (val) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // Lista de Ejercicios
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = list[index];
                return _buildExerciseCard(item);
              },
            ),
          ),

          // Barra Inferior de Acciones
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF0F192B),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8BE0C0),
                      side: const BorderSide(color: Color(0xFF8BE0C0)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add_to_photos_rounded, size: 18),
                    label: const Text('Añadir al Cronograma', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: _injectAdaptiveRoutineToSchedule,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8BE0C0),
                      foregroundColor: const Color(0xFF0B1220),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.view_in_ar_rounded, size: 18),
                    label: const Text('Ver Todos en 3D', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                    onPressed: () {
                      final all = kAdaptiveExercises.map((e) => e.toAnatomyExercise()).toList();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AnatomyWorkoutScreen(
                            initialExerciseId: all.first.id,
                            dynamicExercises: all,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF16253B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF8BE0C0)),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'pecho':
        return Icons.fitness_center_rounded;
      case 'espalda':
        return Icons.accessibility_new_rounded;
      case 'hombros':
        return Icons.sports_gymnastics_rounded;
      case 'brazos':
        return Icons.sports_martial_arts_rounded;
      case 'core':
        return Icons.self_improvement_rounded;
      default:
        return Icons.grid_view_rounded;
    }
  }

  Widget _buildExerciseCard(AdaptiveExerciseItem item) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF10192A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2740),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF8BE0C0).withOpacity(0.3)),
                ),
                child: const Icon(Icons.accessible_rounded, color: Color(0xFF8BE0C0), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '🎯 ${item.muscle}',
                          style: const TextStyle(color: Color(0xFF8BE0C0), fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '·  ${item.setsReps}',
                          style: const TextStyle(color: Colors.white60, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0C1322),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology_alt_rounded, color: Color(0xFFFFB340), size: 14),
                    const SizedBox(width: 6),
                    const Text('Adaptación Biomecánica:', style: TextStyle(color: Color(0xFFFFB340), fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.adaptationRationale,
                  style: const TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.3),
                ),
                const SizedBox(height: 6),
                Text(
                  '💡 Postura: ${item.posture}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A3832),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('♿ 0% Piernas', style: TextStyle(color: Color(0xFF8BE0C0), fontSize: 10.5, fontWeight: FontWeight.bold)),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF173B45),
                  foregroundColor: const Color(0xFF8BE0C0),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.view_in_ar_rounded, size: 15),
                label: const Text('Ver GIF & 3D 360°', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                onPressed: () => _openExerciseViewer(item),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
