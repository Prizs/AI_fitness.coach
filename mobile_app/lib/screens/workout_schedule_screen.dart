import 'package:flutter/material.dart';
import 'package:mobile_app/models/schedule_models.dart';
import 'package:mobile_app/widgets/exercise_3d_viewer.dart';

class WorkoutScheduleScreen extends StatefulWidget {
  const WorkoutScheduleScreen({super.key});

  @override
  State<WorkoutScheduleScreen> createState() => _WorkoutScheduleScreenState();
}

class _WorkoutScheduleScreenState extends State<WorkoutScheduleScreen> {
  int _selectedDayIndex = 0;
  final List<String> _days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

  late List<DaySchedule> _weeklySchedule;

  @override
  void initState() {
    super.initState();
    _weeklySchedule = [
      DaySchedule(
        dayName: 'Lunes',
        title: 'Fase Cardio-Pulmonar & Resistencia',
        focus: 'Zona 2 & Umbral Anaeróbico',
        exercises: [
          ExerciseItem(name: 'Intervalos aeróbicos en remo/carrera', sets: 4, reps: '3 min ritmo vivo', animationKey: 'row-intervals', primaryMuscle: 'Cardio', secondaryMuscle: 'Piernas'),
          ExerciseItem(name: 'Sentadillas con tempo 3-1-1', sets: 4, reps: '15 reps', animationKey: 'squat', primaryMuscle: 'Cuádriceps', secondaryMuscle: 'Glúteos'),
          ExerciseItem(name: 'Plancha con respiración diafragmática', sets: 3, reps: '45 seg', animationKey: 'front-plank', primaryMuscle: 'Core', secondaryMuscle: 'Hombros'),
        ],
        meals: {
          'Desayuno': 'Avena con leche vegetal, frutos rojos y zumo de remolacha (rico en nitratos).',
          'Almuerzo': 'Pechuga a la plancha con quinoa, espinacas y zanahoria al vapor.',
          'Cena': 'Tortilla de claras con espárragos y aguacate.',
          'Snack': 'Plátano maduro con un puñado de nueces.',
        },
      ),
      DaySchedule(
        dayName: 'Martes',
        title: 'Recuperación Activa & Movilidad',
        focus: 'Movilidad articular y descanso',
        isRestDay: true,
        exercises: [
          ExerciseItem(name: 'Caminata suave / Movilidad torácica', sets: 1, reps: '30 min', animationKey: 'walk', primaryMuscle: 'Oxigenación', secondaryMuscle: 'Articular'),
        ],
        meals: {
          'Desayuno': 'Yogur natural con semillas de chía y papaya.',
          'Almuerzo': 'Lentejas guisadas con verduras variadas y arroz integral.',
          'Cena': 'Crema de calabacín y filete de merluza al vapor.',
        },
      ),
      DaySchedule(
        dayName: 'Miércoles',
        title: 'Potencia & Capacidad Muscular',
        focus: 'Fuerza funcional y respiración',
        exercises: [
          ExerciseItem(name: 'Kettlebell swings / Zancadas', sets: 4, reps: '12 reps', animationKey: 'swing', primaryMuscle: 'Isquiotibiales', secondaryMuscle: 'Glúteos'),
          ExerciseItem(name: 'Press de pecho inclinado', sets: 3, reps: '12 reps', animationKey: 'incline-push-up', primaryMuscle: 'Pectoral', secondaryMuscle: 'Tríceps'),
        ],
        meals: {
          'Desayuno': 'Batido de proteína vegetal, espinacas tiernas, plátano y agua de coco.',
          'Almuerzo': 'Salmón a la plancha con batata asada y ensalada con aceite de oliva.',
          'Cena': 'Wok de verduras con tofu o pollo troceado.',
        },
      ),
      DaySchedule(
        dayName: 'Jueves',
        title: 'Descanso Total',
        focus: 'Regeneración celular y mitocondrial',
        isRestDay: true,
        exercises: [],
        meals: {
          'Desayuno': 'Tostadas integrales con tomate rallado y aceite de oliva.',
          'Almuerzo': 'Arroz salvaje con pavo y ensalada mixta.',
          'Cena': 'Sopa ligera de verduras y huevo cocido.',
        },
      ),
      DaySchedule(
        dayName: 'Viernes',
        title: 'Circuito HIIT de Alta Eficiencia',
        focus: 'VO2 Max y resistencia al lactato',
        exercises: [
          ExerciseItem(name: 'Burpees adaptados o Jumping jacks', sets: 4, reps: '40 seg trabajo', animationKey: 'burpee', primaryMuscle: 'Cardio', secondaryMuscle: 'Cuerpo entero'),
          ExerciseItem(name: 'Remo con mancuernas', sets: 4, reps: '12 reps', animationKey: 'dumbbell-row', primaryMuscle: 'Dorsal ancho', secondaryMuscle: 'Bíceps'),
        ],
        meals: {
          'Desayuno': 'Pancakes de avena y plátano con miel pura.',
          'Almuerzo': 'Pasta integral con atún al natural y salsa de tomate casera.',
          'Cena': 'Pechuga a la plancha con brócoli y champiñones.',
        },
      ),
      DaySchedule(
        dayName: 'Sábado',
        title: 'Fuerza de Tronco y Postura',
        focus: 'Cadena posterior y respiración diafragmática',
        exercises: [
          ExerciseItem(name: 'Puente de glúteos unilateral', sets: 3, reps: '12 por pierna', animationKey: 'glute-bridge', primaryMuscle: 'Glúteo mayor', secondaryMuscle: 'Core'),
          ExerciseItem(name: 'Press militar con mancuernas', sets: 3, reps: '10 reps', animationKey: 'seated-shoulder-press', primaryMuscle: 'Deltoides', secondaryMuscle: 'Tríceps'),
        ],
        meals: {
          'Desayuno': 'Huevos revueltos con espinacas y pan de centeno.',
          'Almuerzo': 'Guiso de garbanzos con verduras y ternera magra.',
          'Cena': 'Ensalada completa con queso fresco desnatado y semillas de sésamo.',
        },
      ),
      DaySchedule(
        dayName: 'Domingo',
        title: 'Descanso y Recalibración IA',
        focus: 'Evaluación del progreso semanal',
        isRestDay: true,
        exercises: [],
        meals: {
          'Desayuno': 'Macedonia de frutas de temporada con yogur griego.',
          'Almuerzo': 'Paella de verduras o arroz con pollo campero.',
          'Cena': 'Crema de verduras y pescado blanco.',
        },
      ),
    ];
  }

  void _markExerciseFeedback(ExerciseItem exercise) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF101B2D),
        title: Text('Feedback: ${exercise.name}', style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Pudiste completar todas las series y repeticiones?', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 14),
            const Text('Nivel de esfuerzo percibido (RPE):', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [6, 7, 8, 9, 10].map((rpe) => ActionChip(
                backgroundColor: exercise.rpe == rpe ? const Color(0xFF8BE0C0) : const Color(0xFF173B45),
                label: Text('RPE $rpe', style: TextStyle(color: exercise.rpe == rpe ? Colors.black : Colors.white)),
                onPressed: () {
                  setState(() {
                    exercise.isCompleted = true;
                    exercise.rpe = rpe;
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(rpe <= 7 ? '¡Excelente! La IA programará +2.5kg o +2 reps la próxima sesión.' : 'Registrado. El Coach mantendrá el volumen para evitar fatiga excesiva.'),
                    ),
                  );
                },
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentDay = _weeklySchedule[_selectedDayIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        title: const Text('Cronograma Interactivo', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: const Color(0xFF0F192B),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Selector de Días
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_days.length, (index) {
                  final isSelected = index == _selectedDayIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selectedColor: const Color(0xFF8BE0C0),
                      backgroundColor: const Color(0xFF101B2D),
                      label: Text(
                        _days[index],
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF0B1220) : Colors.white70,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _selectedDayIndex = index);
                      },
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),

            // Encabezado del Día
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF173B45),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8BE0C0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      currentDay.isRestDay ? Icons.nightlight_round : Icons.fitness_center_rounded,
                      color: const Color(0xFF0B1220),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(currentDay.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(currentDay.focus, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Sección de Entrenamiento
            if (!currentDay.isRestDay) ...[
              const Row(
                children: [
                  Icon(Icons.directions_run_rounded, color: Color(0xFF8BE0C0)),
                  SizedBox(width: 8),
                  Text('Rutina del Día', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              ...currentDay.exercises.map((ex) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F192B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ex.isCompleted ? const Color(0xFF8BE0C0) : Colors.white10),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        ex.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: ex.isCompleted ? const Color(0xFF8BE0C0) : Colors.white54,
                      ),
                      onPressed: () => _markExerciseFeedback(ex),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ex.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('${ex.sets} series · ${ex.reps} · Primario: ${ex.primaryMuscle}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          if (ex.rpe != null)
                            Text('RPE Registrado: ${ex.rpe}/10', style: const TextStyle(color: Color(0xFF8BE0C0), fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF101B2D),
                        foregroundColor: const Color(0xFF8BE0C0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.threed_rotation_rounded, size: 16),
                      label: const Text('3D', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        // Modal 3D didáctico
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: const Color(0xFF0F192B),
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                          builder: (ctx) => _Interactive3DViewer(exercise: ex),
                        );
                      },
                    ),
                  ],
                ),
              )),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF0F192B), borderRadius: BorderRadius.circular(16)),
                child: const Text('Día de descanso activo o regeneración celular. Respeta las pausas para asimilar el entrenamiento.', style: TextStyle(color: Colors.white70)),
              ),
            ],
            const SizedBox(height: 20),

            // Sección de Nutrición
            const Row(
              children: [
                Icon(Icons.restaurant_rounded, color: Color(0xFF8BE0C0)),
                SizedBox(width: 8),
                Text('Plan Nutricional Sinergético', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F192B),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: currentDay.meals.entries.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF173B45), borderRadius: BorderRadius.circular(8)),
                        child: Text(m.key, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF8BE0C0))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(m.value, style: const TextStyle(color: Colors.white70, fontSize: 13))),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Interactive3DViewer extends StatelessWidget {
  const _Interactive3DViewer({required this.exercise});
  final ExerciseItem exercise;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(exercise.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            children: [
              Chip(
                backgroundColor: const Color(0xFFFF3B30),
                label: Text('Agonista: ${exercise.primaryMuscle}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Chip(
                backgroundColor: const Color(0xFFFF9500),
                label: Text('Sinergista: ${exercise.secondaryMuscle}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Exercise3DViewer(
            animationKey: exercise.animationKey,
            primaryMuscle: exercise.primaryMuscle,
            secondaryMuscle: exercise.secondaryMuscle,
            height: 300,
            showMuscleLegend: false,
          ),
          const SizedBox(height: 8),
          const Text(
            'Tempo sugerido: 3s excéntrico - 1s isometría - 1s concéntrico',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8BE0C0), foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar Visor Biomecánico', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}