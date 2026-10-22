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
      gifUrl: resolveGuaranteedGifUrl(
        name: name,
        agonist: muscle,
        intensityLevel: intensity,
      ),
    );
  }
}

const List<AdaptiveExerciseItem> kAdaptiveExercises = [
  // PECHO
  AdaptiveExerciseItem(
    id: 'press_banca_mancuernas',
    name: 'Press de Banca Plano con Mancuernas (Sentado/Tumbado)',
    category: 'Pecho',
    muscle: 'Pecho',
    secondary: 'Tríceps / Deltoides',
    setsReps: '3 series × 10-12 reps (RPE 6-7)',
    intensity: 'Intermedio (Intensidad Media)',
    adaptationRationale: 'El usuario se recuesta o sienta con la columna totalmente apoyada contra el respaldo del banco o silla. No requiere activación ni empuje podal (sin leg drive), garantizando seguridad articular total en pelvis y cadera.',
    posture: 'Espalda y glúteos firmemente en contacto con el acolchado. Retracción escapular activa.',
    warning: 'No arquear la zona lumbar ni balancear el tronco para impulsar el peso.',
  ),
  AdaptiveExerciseItem(
    id: 'press_inclinado_sentado',
    name: 'Press Inclinado en Banco Sentado con Mancuernas',
    category: 'Pecho',
    muscle: 'Pecho',
    secondary: 'Hombros',
    setsReps: '3 series × 12 reps (RPE 6-7)',
    intensity: 'Intermedio (Intensidad Media)',
    adaptationRationale: 'Banco colocado a 30-45° de inclinación con soporte lumbar integral. Transfiere el 100% de la carga al haz clavicular del pectoral sin requerir apoyo o fuerza en miembros inferiores.',
    posture: 'Cabeza y espalda fijas en el respaldo. Muñecas neutras durante todo el recorrido.',
    warning: 'Mantén una bajada controlada sin abrir excesivamente los codos para proteger el manguito rotador.',
  ),
  AdaptiveExerciseItem(
    id: 'aperturas_banco_plano',
    name: 'Aperturas en Banco Plano con Mancuernas',
    category: 'Pecho',
    muscle: 'Pecho',
    secondary: 'Deltoides Anterior',
    setsReps: '3 series × 12-15 reps (RPE 6)',
    intensity: 'Básico (Intensidad Baja)',
    adaptationRationale: 'Aislamiento seguro de apertura pectoral. Elimina la fatiga en brazos al mantener un ángulo de codo fijo y permite estirar la fascia torácica con estabilidad corporal.',
    posture: 'Codos ligeramente flexionados fijos a 15°. Movimiento amplio como si abrazaras un barril.',
    warning: 'No bajes los codos más abajo del nivel del banco para evitar hiperextensión del hombro.',
  ),

  // ESPALDA
  AdaptiveExerciseItem(
    id: 'jalon_pecho_polea',
    name: 'Jalón al Pecho Sentado en Polea Alta',
    category: 'Espalda',
    muscle: 'Espalda',
    secondary: 'Bíceps',
    setsReps: '3 series × 10-12 reps (RPE 7)',
    intensity: 'Intermedio (Intensidad Media)',
    adaptationRationale: 'Permite realizar tracción vertical desde la propia silla de ruedas o banco adaptado con almohadillas estabilizadoras en los muslos o torso.',
    posture: 'Torso erguido con leve inclinación posterior (10-15°). Tirar llevando los codos hacia las costillas.',
    warning: 'No dar tirones con el tronco ni bajar la barra tras la nuca.',
  ),
  AdaptiveExerciseItem(
    id: 'remo_sentado_polea_baja',
    name: 'Remo Sentado en Polea Baja con Agarre Estrecho',
    category: 'Espalda',
    muscle: 'Espalda',
    secondary: 'Bíceps / Romboides',
    setsReps: '3 series × 12 reps (RPE 6-7)',
    intensity: 'Intermedio (Intensidad Media)',
    adaptationRationale: 'Tracción horizontal pura que trabaja dorsales medios y romboides. El respaldo o sujeción frontal estabiliza el torso sin sobrecargar la zona baja de la espalda.',
    posture: 'Hombros descendidos, pecho hacia fuera. Máxima contracción escapular en el punto final.',
    warning: 'Evita oscilaciones hacia adelante y atrás para no generar inercia compensatoria.',
  ),
  AdaptiveExerciseItem(
    id: 'remo_unilateral_apoyo',
    name: 'Remo Unilateral con Apoyo de Pecho / Respaldo',
    category: 'Espalda',
    muscle: 'Espalda',
    secondary: 'Deltoides Posterior',
    setsReps: '3 series × 10-12 reps por brazo',
    intensity: 'Intermedio (Intensidad Media)',
    adaptationRationale: 'El apoyo de pecho en banco inclinado elimina cualquier carga compresiva axial en la columna y la necesidad de sostenerse sobre las piernas.',
    posture: 'Un brazo sostiene la mancuerna mientras el pecho reposa completamente sobre el acolchado.',
    warning: 'No rotar bruscamente el torso al elevar el peso.',
  ),

  // HOMBROS
  AdaptiveExerciseItem(
    id: 'press_militar_sentado',
    name: 'Press Militar Sentado con Mancuernas',
    category: 'Hombros',
    muscle: 'Hombros',
    secondary: 'Tríceps',
    setsReps: '3 series × 10-12 reps (RPE 6-7)',
    intensity: 'Intermedio (Intensidad Media)',
    adaptationRationale: 'Realizado en silla o banco a 90° con respaldo lumbar vertical. Elimina el desequilibrio y fortalece los hombros sin fatiga de sustentación.',
    posture: 'Espalda vertical contra el respaldo, core activo, empuje controlado por encima de la cabeza.',
    warning: 'Bajar hasta la altura de las orejas sin golpear las mancuernas arriba.',
  ),
  AdaptiveExerciseItem(
    id: 'elevaciones_laterales_sentado',
    name: 'Elevaciones Laterales Sentado con Mancuernas',
    category: 'Hombros',
    muscle: 'Hombros',
    secondary: 'Trapecio',
    setsReps: '3 series × 12-15 reps (RPE 6)',
    intensity: 'Básico (Intensidad Baja)',
    adaptationRationale: 'Al estar sentado se evita el balanceo o impulso pendular de piernas, logrando un estímulo limpio y directo en el deltoides medio.',
    posture: 'Brazos casi rectos con ligera semiflexión. Elevar hasta la línea de los hombros.',
    warning: 'Evita elevar los hombros hacia las orejas durante la subida.',
  ),
  AdaptiveExerciseItem(
    id: 'pajaros_sentado',
    name: 'Pájaros Sentado (Deltoides Posterior con Mancuernas)',
    category: 'Hombros',
    muscle: 'Hombros',
    secondary: 'Espalda Alta',
    setsReps: '3 series × 12-15 reps (RPE 6)',
    intensity: 'Intermedio (Intensidad Media)',
    adaptationRationale: 'Torso inclinado hacia adelante descansando sobre los muslos o con cojín de apoyo, trabajando la postura escapular y hombro posterior.',
    posture: 'Movimiento en plano horizontal abriendo los brazos hacia los lados como alas.',
    warning: 'Selecciona una carga ligera a moderada para garantizar control.',
  ),

  // BRAZOS
  AdaptiveExerciseItem(
    id: 'curl_biceps_sentado',
    name: 'Curl de Bíceps Sentado con Mancuernas',
    category: 'Brazos',
    muscle: 'Brazos',
    secondary: 'Antebrazos',
    setsReps: '3 series × 12 reps (RPE 6)',
    intensity: 'Básico (Intensidad Baja)',
    adaptationRationale: 'Flexión de codo pura con supinación. Estabilidad total en silla de ruedas o banco.',
    posture: 'Codos pegados a los costados del torso, sin adelantarlos al subir.',
    warning: 'Completar todo el rango de movimiento sin balancear el torso.',
  ),
  AdaptiveExerciseItem(
    id: 'extension_triceps_copa',
    name: 'Extensión de Tríceps Sentado en Banco con Mancuerna Copa',
    category: 'Brazos',
    muscle: 'Brazos',
    secondary: 'Hombros',
    setsReps: '3 series × 12 reps (RPE 6-7)',
    intensity: 'Intermedio (Intensidad Media)',
    adaptationRationale: 'Enfoca la cabeza larga del tríceps con la espalda bien posicionada contra el respaldo.',
    posture: 'Mancuerna sujeta con ambas manos por detrás de la cabeza, codos orientados hacia el frente.',
    warning: 'Mantén los codos cerrados sin abrirlos excesivamente hacia los lados.',
  ),

  // CORE ADAPTADO
  AdaptiveExerciseItem(
    id: 'contracciones_isometricas_sentado',
    name: 'Contracciones Abdominales Isométricas Sentado',
    category: 'Core',
    muscle: 'Core',
    secondary: 'Suelo Pélvico',
    setsReps: '4 series × 20-30 seg de retención',
    intensity: 'Básico (Intensidad Baja)',
    adaptationRationale: 'Activación del transverso profundo y diafragma mediante maniobras de vaciado y tensión controlada en sedestación. Fortalece la estabilidad del tronco sin requerir flexiones espinales comprometedoras.',
    posture: 'Espalda neutra, exhalar todo el aire y meter el ombligo hacia la columna manteniendo la tensión.',
    warning: 'No contener la respiración de forma forzada; respira superficialmente durante la tensión.',
  ),
  AdaptiveExerciseItem(
    id: 'giros_rusos_banco_soporte',
    name: 'Giros Rusos en Banco con Apoyo Seguro',
    category: 'Core',
    muscle: 'Core',
    secondary: 'Oblicuos',
    setsReps: '3 series × 12-16 giros alternados',
    intensity: 'Intermedio (Intensidad Media)',
    adaptationRationale: 'Rotación torácica controlada con cadera estabilizada. Estimula los oblicuos y rotadores espinales con total seguridad.',
    posture: 'Sujetar un disco o mancuerna pequeña pegada al pecho y rotar suavemente de lado a lado.',
    warning: 'Rotar el tórax en bloque sin torsiones violentas.',
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
          'gif_url': resolveGuaranteedGifUrl(
            name: e.name,
            agonist: e.muscle,
            intensityLevel: e.intensity,
          ),
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
