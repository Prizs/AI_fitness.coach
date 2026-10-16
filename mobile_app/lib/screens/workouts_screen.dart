import 'package:flutter/material.dart';
import 'package:mobile_app/screens/coach_screen.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/weekly_plan_service.dart';
import 'package:mobile_app/widgets/exercise_detail.dart';
import 'package:mobile_app/models/anatomy_exercise.dart';
import 'package:mobile_app/widgets/plan_options_sheet.dart';
import 'package:mobile_app/widgets/pre_workout_checkin.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Rutinas de la semana, con el dia de hoy destacado.
///
/// Arriba se ven primero las rutinas pendientes. El usuario puede marcar cada
/// dia como completado, y el boton inferior lleva al Coach para pedir una rutina
/// nueva o agregar un ejercicio.
class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  final WeeklyPlanService _service = WeeklyPlanService.instance;

  /// Dias ya completados por el usuario, como indices de dia de la semana.
  final Set<int> _completed = {};
  final Set<int> _startedDays = {};

  @override
  void initState() {
    super.initState();
    _service.ensureLoaded(AuthService.instance.loggedInUser);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _service,
          builder: (context, _) => _buildBody(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF8BE0C0),
        foregroundColor: const Color(0xFF0B1220),
        onPressed: _openCoach,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva rutina',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  /// Lleva al Coach, que es donde se piden rutinas y se agregan ejercicios.
  void _openCoach() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CoachScreen()),
    );
  }

  Widget _buildBody() {
    if (_service.week == null) {
      if (_service.isLoading) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 14),
              Text('Cargando tu semana...',
                  style: TextStyle(color: Colors.white70)),
            ],
          ),
        );
      }
      if (_service.lastError != null) {
        return _EmptyState(
          message: _service.lastError!,
          onRetry: () => _service.refresh(AuthService.instance.loggedInUser),
          isError: true,
        );
      }
      
      return _EmptyState(
        message: 'Aún no tienes una rutina activa.\n\nPresiona el botón de abajo para que la IA diseñe un plan personalizado a tu nivel, disponibilidad y equipo.',
        onRetry: () => showPlanOptionsSheet(context),
        isError: false,
      );
    }

    final days = _service.days;
    final today = _service.todayIndex;
    final pending = days.where((d) => !_completed.contains(d['weekday']));
    final done = days.where((d) => _completed.contains(d['weekday']));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Rutinas',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              tooltip: 'Actualizar semana',
              onPressed: () =>
                  _service.refresh(AuthService.instance.loggedInUser),
              icon: const Icon(Icons.refresh_rounded,
                  color: Color(0xFF8BE0C0)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Hoy es ${_service.todayName} · '
          '${_completed.length} de ${days.length} completadas',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 18),
        if (pending.isNotEmpty) ...[
          const _SectionLabel('Pendientes'),
          ...pending.map((day) => _DayCard(
                day: day,
                isToday: day['weekday'] == today,
                isDone: false,
                onToggle: () =>
                    setState(() => _completed.add(day['weekday'] as int)),
              )),
        ],
        if (done.isNotEmpty) ...[
          const SizedBox(height: 10),
          const _SectionLabel('Completadas'),
          ...done.map((day) => _DayCard(
                day: day,
                isToday: day['weekday'] == today,
                isDone: true,
                onToggle: () => setState(
                    () => _completed.remove(day['weekday'] as int)),
              )),
        ],
        // Espacio para que el boton flotante no tape la ultima tarjeta.
        const SizedBox(height: 80),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.onRetry, this.isError = true});

  final String message;
  final VoidCallback onRetry;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isError ? Icons.cloud_off_rounded : Icons.fitness_center_rounded,
              size: 56, 
              color: isError ? const Color(0xFFFF7A7A) : const Color(0xFF8BE0C0)
            ),
            const SizedBox(height: 16),
            Text(
              isError ? 'Error de Carga' : 'Bienvenido',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, height: 1.5)),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8BE0C0),
                foregroundColor: const Color(0xFF0B1220),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
              ),
              onPressed: onRetry,
              icon: Icon(isError ? Icons.refresh_rounded : Icons.add_rounded),
              label: Text(isError ? 'Reintentar' : 'Crear mi rutina', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: Color(0xFF8BE0C0),
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.isToday,
    required this.isDone,
    required this.onToggle,
  });

  final Map<String, dynamic> day;
  final bool isToday;
  final bool isDone;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final exercises = (day['exercises'] as List<dynamic>?) ?? [];
    final synergy = '${day['synergy'] ?? ''}';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: isDone ? const Color(0xFF121C2B) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${day['weekday_name']} · ${day['title']}',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDone ? Colors.white54 : Colors.white,
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (isToday)
                        const Text('HOY',
                            style: TextStyle(
                                color: Color(0xFF8BE0C0),
                                fontSize: 11,
                                fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: isDone
                      ? 'Marcar como pendiente'
                      : 'Marcar completada',
                  onPressed: onToggle,
                  icon: Icon(
                    isDone
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: isDone
                        ? const Color(0xFF8BE0C0)
                        : Colors.white38,
                    size: 28,
                  ),
                ),
              ],
            ),
            if (synergy.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF16233A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.bolt_rounded,
                        size: 16, color: Color(0xFF8BE0C0)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        synergy,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 6),
            ...exercises.map((exercise) {
              final item = Map<String, dynamic>.from(exercise as Map);
              final intensityLvl =
                  item['intensity_level'] as String? ?? 'Básico (Intensidad Baja)';
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF173B45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.view_in_ar_rounded,
                      color: Color(0xFF8BE0C0)),
                ),
                title: Text(
                  item['name'] as String? ?? 'Ejercicio',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${item['sets']} series · ${item['reps']} · $intensityLvl',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                trailing: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF101B2D),
                    foregroundColor: const Color(0xFF8BE0C0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Ver 3D'),
                  onPressed: () => _openExercisePreview(context, item, exercises, day['weekday']),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _openExercisePreview(BuildContext context, Map<String, dynamic> item, List<dynamic> exercises, int dayIndex) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    List<AnatomyExercise> dyn = [];
    for (var e in exercises) {
      final ex = Map<String, dynamic>.from(e as Map);
      final exName = ex['name'] as String? ?? 'Ejercicio';
      final primary = ex['primary_muscle'] as String? ?? 'General';
      final secondary = ex['secondary_muscle'] as String? ?? 'Secundario';
      final intensityLvl = ex['intensity_level'] as String? ?? 'Básico (Intensidad Baja)';
      
      String url = (ex['gif_url'] as String? ?? '').trim();
      if (url.isEmpty) {
        try {
          final res = await http.get(Uri.parse(
              'https://ai-fitness-coach-818a.onrender.com/api/exercises/gif?query=${Uri.encodeComponent(exName)}&intensity=${Uri.encodeComponent(intensityLvl)}'));
          if (res.statusCode == 200) {
            url = jsonDecode(res.body)['url'] ?? '';
          }
        } catch (_) {}
      }
      
      dyn.add(AnatomyExercise(
        id: exName,
        name: exName,
        shortName: exName,
        gifUrl: url,
        intensityLevel: intensityLvl,
        agonist: primary,
        synergists: [secondary],
        biomechanics: ex['biomechanics'] as String? ?? 'Biomecánica sugerida por IA.',
        tempo: '3-1-1',
        posture: ex['posture'] as String? ?? 'Mantén la postura natural.',
        warning: 'Consulta a tu entrenador si sientes dolor.'
      ));
    }
    
    if (!context.mounted) return;
    Navigator.pop(context); // close dialog
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F192B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _Exercise3DPreviewSheet(exercise: item, dynamicExercises: dyn, dayIndex: dayIndex),
    );
  }
}

class _Exercise3DPreviewSheet extends StatefulWidget {
  const _Exercise3DPreviewSheet({required this.exercise, this.dynamicExercises, required this.dayIndex});
  final Map<String, dynamic> exercise;
  final List<AnatomyExercise>? dynamicExercises;
  final int dayIndex;

  @override
  State<_Exercise3DPreviewSheet> createState() =>
      _Exercise3DPreviewSheetState();
}

class _Exercise3DPreviewSheetState extends State<_Exercise3DPreviewSheet> {
  @override
  Widget build(BuildContext context) {
    final name = widget.exercise['name'] as String? ?? 'Ejercicio';
    final sets = widget.exercise['sets']?.toString() ?? '3';
    final reps = widget.exercise['reps']?.toString() ?? '12';
    final animKey =
        widget.exercise['animation_key'] as String? ?? 'generic_exercise';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8BE0C0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.fitness_center_rounded,
                    color: Color(0xFF0B1220)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '$sets series · $reps repeticiones',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ExerciseDetailView(
            animationKey: name, // We use 'name' as ID now!
            primaryMuscle: widget.exercise['primary_muscle'] as String?,
            secondaryMuscle: widget.exercise['secondary_muscle'] as String?,
            height: 300,
            dynamicExercises: widget.dynamicExercises,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orangeAccent,
              side: const BorderSide(color: Colors.orangeAccent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () async {
              // Swap exercise logic
              final currentName = widget.exercise['name'] as String? ?? '';
              final primaryMuscle = widget.exercise['primary_muscle'] as String? ?? 'General';
              
              showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
              final newEx = await WeeklyPlanService.instance.swapExercise(currentName, primaryMuscle, widget.dayIndex);
              if (context.mounted) Navigator.pop(context); // close dialog
              
              if (newEx != null && context.mounted) {
                 Navigator.pop(context); // close sheet
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cambiado por: ')));
              } else if (context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al cambiar ejercicio')));
              }
            },
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text('Máquina Ocupada (Cambiar)', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8BE0C0),
              foregroundColor: const Color(0xFF0B1220),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Entendido, continuar rutina',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}