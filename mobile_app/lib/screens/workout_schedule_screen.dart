import 'package:mobile_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/models/schedule_models.dart';
import 'package:mobile_app/widgets/exercise_detail.dart';
import 'package:mobile_app/services/weekly_plan_service.dart';
import 'package:mobile_app/models/anatomy_exercise.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WorkoutScheduleScreen extends StatefulWidget {
  const WorkoutScheduleScreen({super.key});

  @override
  State<WorkoutScheduleScreen> createState() => _WorkoutScheduleScreenState();
}

class _WorkoutScheduleScreenState extends State<WorkoutScheduleScreen> {
  int _selectedDayIndex = 0;
  final List<String> _days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

  final WeeklyPlanService _service = WeeklyPlanService.instance;

  @override
  void initState() {
    super.initState();
    _selectedDayIndex = _service.todayIndex;
    _service.addListener(_onServiceUpdate);
    _service.ensureLoaded(AuthService.instance.loggedInUser);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _markExerciseFeedback(ExerciseItem ex) {
    setState(() {
      ex.isCompleted = !ex.isCompleted;
    });
  }

  List<DaySchedule> get _weeklySchedule {
    if (_service.week == null) return [];
    
    List<DaySchedule> schedule = [];
    try {
      final dynamic daysData = _service.week!['days'];
      List<dynamic> days = [];
      if (daysData is List) {
        days = daysData;
      } else if (daysData is Map) {
        days = daysData.values.toList();
      }
      
      for (int i = 0; i < 7; i++) {
        dynamic dayData;
        try {
          dayData = days.firstWhere((d) => (d is Map) && (d['weekday'] == i || d['weekday'] == i.toString()), orElse: () => null);
        } catch (_) {}
        
        if (dayData != null && dayData is Map) {
          List<ExerciseItem> exercises = [];
          if (dayData['exercises'] is List) {
            for (var ex in dayData['exercises']) {
              try {
                if (ex is Map<String, dynamic>) {
                  exercises.add(ExerciseItem.fromJson(ex));
                } else if (ex is Map) {
                  exercises.add(ExerciseItem.fromJson(Map<String, dynamic>.from(ex)));
                }
              } catch (e) {
                // Ignore invalid exercise
              }
            }
          }
          
          Map<String, String> meals = {};
          if (dayData['nutrition'] is Map) {
            final nut = dayData['nutrition'];
            if (nut['desayuno'] != null) meals['Desayuno'] = nut['desayuno'].toString();
            if (nut['almuerzo'] != null) meals['Almuerzo'] = nut['almuerzo'].toString();
            if (nut['cena'] != null) meals['Cena'] = nut['cena'].toString();
            if (nut['snack'] != null) meals['Snack'] = nut['snack'].toString();
          }
          
          schedule.add(DaySchedule(
            dayName: _days[i],
            title: dayData['title']?.toString() ?? 'Rutina del Día',
            focus: 'Enfoque General',
            exercises: exercises,
            meals: meals,
          ));
        } else {
          schedule.add(DaySchedule(
            dayName: _days[i],
            title: 'Día de Descanso',
            focus: 'Recuperación Activa',
            exercises: [],
            meals: {},
            isRestDay: true,
          ));
        }
      }
    } catch (e) {
      // If parsing fails completely, just return 7 rest days
      for (int i = 0; i < 7; i++) {
        schedule.add(DaySchedule(
          dayName: _days[i],
          title: 'Error de Formato',
          focus: 'Recuperación Activa',
          exercises: [],
          meals: {},
          isRestDay: true,
        ));
      }
    }
    return schedule;
  }

@override
  Widget build(BuildContext context) {
    if (_service.isLoading && _service.week == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0F1D),
        appBar: AppBar(
          title: const Text('Cronograma Interactivo', style: TextStyle(fontWeight: FontWeight.w800)),
          backgroundColor: const Color(0xFF0F192B),
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF8BE0C0))),
      );
    }
    
    if (_weeklySchedule.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0F1D),
        appBar: AppBar(
          title: const Text('Cronograma Interactivo', style: TextStyle(fontWeight: FontWeight.w800)),
          backgroundColor: const Color(0xFF0F192B),
          elevation: 0,
        ),
        body: const Center(
          child: Text('No hay rutina generada.\nPide a tu coach que genere un plan.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
        ),
      );
    }
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
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: ex.intensityLevel.toLowerCase().contains('baja') || ex.intensityLevel.toLowerCase().contains('básico')
                                  ? const Color(0xFF8BE0C0).withOpacity(0.18)
                                  : ex.intensityLevel.toLowerCase().contains('alta') || ex.intensityLevel.toLowerCase().contains('avanzado')
                                      ? const Color(0xFFFF3B30).withOpacity(0.22)
                                      : const Color(0xFFFF9500).withOpacity(0.22),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ex.intensityLevel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: ex.intensityLevel.toLowerCase().contains('baja') || ex.intensityLevel.toLowerCase().contains('básico')
                                    ? const Color(0xFF8BE0C0)
                                    : ex.intensityLevel.toLowerCase().contains('alta') || ex.intensityLevel.toLowerCase().contains('avanzado')
                                        ? const Color(0xFFFF6B6B)
                                        : const Color(0xFFFFB340),
                              ),
                            ),
                          ),
                          Text('${ex.sets} series · ${ex.reps} · Primario: ${ex.primaryMuscle}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          Builder(builder: (ctx) {
                            final setsNum = ex.sets > 0 ? ex.sets : 3;
                            final nameLower = ex.name.toLowerCase();
                            final isCompound = nameLower.contains('sentadilla') ||
                                nameLower.contains('squat') ||
                                nameLower.contains('peso muerto') ||
                                nameLower.contains('deadlift') ||
                                nameLower.contains('prensa') ||
                                nameLower.contains('dominada') ||
                                nameLower.contains('pull-up') ||
                                nameLower.contains('remo') ||
                                nameLower.contains('zancada') ||
                                nameLower.contains('lunge') ||
                                nameLower.contains('burpee');
                            final userWeight = AuthService.instance.loggedInUser?.weight ?? 75.0;
                            final weightFactor = (userWeight / 75.0).clamp(0.7, 1.4);
                            final estKcal = (setsNum * (isCompound ? 15.0 : 11.5) * weightFactor).round();
                            final estFat = ((estKcal * 0.70) / 9.0).toStringAsFixed(1);
                            return Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 2),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFB340).withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFFFB340).withOpacity(0.3), width: 0.8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.local_fire_department_rounded, size: 12, color: Color(0xFFFFB340)),
                                        const SizedBox(width: 3),
                                        Text('~$estKcal kcal', style: const TextStyle(color: Color(0xFFFFB340), fontSize: 11, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8BE0C0).withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF8BE0C0).withOpacity(0.3), width: 0.8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.water_drop_rounded, size: 12, color: Color(0xFF8BE0C0)),
                                        const SizedBox(width: 3),
                                        Text('~$estFat g grasa est.', style: const TextStyle(color: Color(0xFF8BE0C0), fontSize: 11, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
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
                      onPressed: () async {
                        showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                        List<AnatomyExercise> dyn = [];
                        for (var e in currentDay.exercises) {
                          String url = e.gifUrl;
                          String intensityLbl = e.intensityLevel;
                          if (url.isEmpty) {
                            try {
                              final uri = Uri.parse(
                                '${AuthService.apiBaseUrl}/api/exercises/gif?query=${Uri.encodeComponent(e.name)}&muscle=${Uri.encodeComponent(e.primaryMuscle)}&intensity=${Uri.encodeComponent(e.intensityLevel)}',
                              );
                              final res = await http.get(uri).timeout(const Duration(seconds: 6));
                              if (res.statusCode == 200) {
                                final data = jsonDecode(res.body);
                                url = data['url']?.toString() ?? '';
                                intensityLbl = data['intensity_level']?.toString() ?? intensityLbl;
                              }
                            } catch (_) {}
                          }
                          if (url.isEmpty) {
                            url = resolveGuaranteedGifUrl(
                              name: e.name,
                              agonist: e.primaryMuscle,
                              intensityLevel: intensityLbl,
                            );
                          }
                          dyn.add(AnatomyExercise(
                            id: e.name,
                            name: e.name,
                            shortName: e.name,
                            gifUrl: url,
                            intensityLevel: intensityLbl,
                            agonist: e.primaryMuscle,
                            synergists: [e.secondaryMuscle],
                            biomechanics: e.biomechanics,
                            tempo: e.tempo,
                            posture: e.posture,
                            warning: e.warning,
                          ));
                        }
                        if (!mounted) return;
                        Navigator.pop(context); // close dialog
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: const Color(0xFF0F192B),
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                          builder: (ctx) => _Interactive3DViewer(exercise: ex, dynamicExercises: dyn),
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
  const _Interactive3DViewer({required this.exercise, this.dynamicExercises});
  final List<AnatomyExercise>? dynamicExercises;
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
          ExerciseDetailView(
            animationKey: exercise.name, // Use name as ID to match dynamicExercises
            primaryMuscle: exercise.primaryMuscle,
            secondaryMuscle: exercise.secondaryMuscle,
            height: 300,
            dynamicExercises: dynamicExercises,
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