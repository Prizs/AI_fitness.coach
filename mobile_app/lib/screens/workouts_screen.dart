import 'package:flutter/material.dart';
import 'package:mobile_app/screens/coach_screen.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/weekly_plan_service.dart';
import 'package:mobile_app/services/coach_chat_service.dart';
import 'package:mobile_app/models/anatomy_exercise.dart';
import 'package:mobile_app/database/db_helper.dart';
import 'package:mobile_app/screens/anatomy_workout_screen.dart';
import 'package:mobile_app/screens/adaptive_workout_screen.dart';

/// Rutinas de la semana, con el ciclo activo, días programados y fechas de periodización.
class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  final WeeklyPlanService _service = WeeklyPlanService.instance;

  /// Dias ya completados por el usuario, como indices de dia de la semana (0=Lunes, 6=Domingo).
  final Set<int> _completed = {};

  @override
  void initState() {
    super.initState();
    _initSchedule();
  }

  Future<void> _initSchedule() async {
    final user = AuthService.instance.loggedInUser;
    final cedula = user?.cedula;
    await CoachChatService.instance.init(cedula: cedula);
    await _service.ensureLoaded(user);

    // Sincronización de concordancia: Si el Coach IA recomendó un plan,
    // sincronizarlo inmediatamente para que Rutinas lo refleje como activo:
    final latestCoachPlan = CoachChatService.instance.latestRecommendedPlan;
    if (latestCoachPlan != null) {
      final currentTrainingDays = _service.activeTrainingDayNames.length;
      final coachDaysSched = latestCoachPlan['days_schedule'] as Map?;
      final int coachTrainingCount = coachDaysSched != null
          ? coachDaysSched.values.where((d) => d is Map && d['is_rest'] == false && (d['exercises'] as List?)?.isNotEmpty == true).length
          : 0;
      if (_service.week == null || _service.isPlanExpired || !_service.hasActivePlan || (coachTrainingCount > currentTrainingDays && coachTrainingCount >= 3)) {
        await _service.injectCustomPlanForToday(latestCoachPlan);
      }
    }
    await _loadCompletedDays();
  }

  Future<void> _loadCompletedDays() async {
    final cedula = AuthService.instance.loggedInUser?.cedula;
    final saved = await DBHelper.instance.getCompletedDays(cedula: cedula);
    if (mounted) {
      setState(() {
        _completed.addAll(saved);
      });
    }
  }


  void _handleToggleCompletion(Map<String, dynamic> day) {
    final weekday = day['weekday'] as int;
    final isDone = _completed.contains(weekday);
    if (isDone) {
      _showUnmarkConfirmationDialog(day);
    } else {
      _showWorkoutCompletionSheet(day);
    }
  }

  void _showUnmarkConfirmationDialog(Map<String, dynamic> day) {
    final weekday = day['weekday'] as int;
    final title = '${day['weekday_name']} · ${day['title']}';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F192B),
        title: const Text('¿Desmarcar sesión?'),
        content: Text(
          '¿Deseas desmarcar "$title"? Se recalculará tu racha de entrenamientos.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF173B45)),
            onPressed: () async {
              Navigator.pop(ctx);
              await DBHelper.instance.removeSessionRecord(weekday);
              await _service.refreshWorkoutStats();
              if (mounted) {
                setState(() {
                  _completed.remove(weekday);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sesión desmarcada.'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Color(0xFF173B45),
                  ),
                );
              }
            },
            child: const Text('Desmarcar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showWorkoutCompletionSheet(Map<String, dynamic> day) {
    int selectedRpe = 7;
    String selectedFeeling = '⚡ Con energía';
    final TextEditingController noteCtrl = TextEditingController();
    final weekday = day['weekday'] as int;
    final title = '${day['weekday_name']} · ${day['title']}';
    final exercises = (day['exercises'] as List<dynamic>?) ?? [];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F192B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF173B45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Color(0xFF8BE0C0),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Confirmar Sesión Completada',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Evita toques por error y registra datos para el Coach IA',
                            style: TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16233A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF8BE0C0),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${exercises.length} ejercicios planificados para hoy',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '1. Esfuerzo Percibido (RPE 1-10):',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _rpeChip(4, 'Fácil (4)', selectedRpe, (v) => setModalState(() => selectedRpe = v)),
                    _rpeChip(6, 'Medio (6)', selectedRpe, (v) => setModalState(() => selectedRpe = v)),
                    _rpeChip(8, 'Exigente (8)', selectedRpe, (v) => setModalState(() => selectedRpe = v)),
                    _rpeChip(10, 'Máximo (10)', selectedRpe, (v) => setModalState(() => selectedRpe = v)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '2. Sensación post-entrenamiento:',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _feelingChip('⚡ Con energía', selectedFeeling, (v) => setModalState(() => selectedFeeling = v)),
                    _feelingChip('🙂 Adecuado', selectedFeeling, (v) => setModalState(() => selectedFeeling = v)),
                    _feelingChip('😴 Fatigado', selectedFeeling, (v) => setModalState(() => selectedFeeling = v)),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    hintText: 'Comentario opcional para el Coach IA...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF141F32),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8BE0C0),
                    foregroundColor: const Color(0xFF0B1220),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await DBHelper.instance.recordWorkoutSession(
                      weekday: weekday,
                      title: title,
                      rpe: selectedRpe,
                      feeling: selectedFeeling,
                      notes: noteCtrl.text.trim(),
                    );
                    await _service.refreshWorkoutStats();
                    if (mounted) {
                      setState(() {
                        _completed.add(weekday);
                      });
                      final streak = _service.currentStreak;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '🔥 ¡Sesión completada y registrada! Llevas una racha de $streak sesiones seguidas. Datos guardados en tu perfil para el Coach IA.',
                          ),
                          backgroundColor: const Color(0xFF1B4D3E),
                          duration: const Duration(seconds: 4),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.local_fire_department_rounded),
                  label: const Text(
                    '¡Sí, registrar y sumar a mi racha! 🔥',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancelar (evitar registro por error)',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rpeChip(int value, String label, int current, ValueChanged<int> onSelect) {
    final isSelected = value == current;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8BE0C0) : const Color(0xFF141F32),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF8BE0C0) : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF0B1220) : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _feelingChip(String label, String current, ValueChanged<String> onSelect) {
    final isSelected = label == current;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onSelect(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF173B45) : const Color(0xFF141F32),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF8BE0C0) : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF8BE0C0) : Colors.white70,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
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
        onPressed: _handleNewRoutinePress,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Nueva rutina',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  /// Maneja el clic en "Nueva rutina", informando al usuario si ya tiene un plan activo
  /// o si puede iniciar uno nuevo a partir del próximo ciclo.
  void _handleNewRoutinePress() {
    if (_service.hasActivePlan) {
      _showActiveCycleInfoSheet();
    } else {
      _openCoach();
    }
  }

  void _showActiveCycleInfoSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F192B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final trainingDaysStr = _service.activeTrainingDayNames.join(', ');
        final restDaysStr = _service.activeRestDayNames.isNotEmpty
            ? _service.activeRestDayNames.join(', ')
            : 'Fines de semana';

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF173B45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.event_available_rounded,
                      color: Color(0xFF8BE0C0),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Planificación Semanal Activa',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF16233A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.date_range_rounded,
                            size: 16, color: Color(0xFF8BE0C0)),
                        const SizedBox(width: 6),
                        Text(
                          'Ciclo en curso: ${_service.cycleDateRangeStr}',
                          style: const TextStyle(
                            color: Color(0xFF8BE0C0),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '🏋️ Días con entrenamiento ya programado:\n$trainingDaysStr',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '🧘 Días de recuperación / disponibles:\n$restDaysStr',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const Divider(color: Colors.white12, height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 16, color: Color(0xFFFFB340)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '¿Cuándo podrás planificar un nuevo ciclo general?\nA partir del ${_service.nextCycleDateStr}. Esto asegura el cumplimiento de la periodización deportiva y la recuperación muscular fisiológica (48 a 72 horas).',
                            style: const TextStyle(
                              color: Color(0xFFFFB340),
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8BE0C0),
                  foregroundColor: const Color(0xFF0B1220),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _openCoach();
                },
                icon: const Icon(Icons.add_task_rounded),
                label: const Text(
                  'Rutina complementaria en días libres',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orangeAccent,
                  side: const BorderSide(color: Colors.orangeAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _confirmResetCycle();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  'Reiniciar y Reemplazar ciclo actual',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Continuar con mi ciclo actual',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmResetCycle() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F192B),
        title: const Text('¿Reiniciar ciclo de entrenamiento?'),
        content: const Text(
          'Se borrarán las rutinas y días completados de esta semana para que puedas solicitar una planificación totalmente nueva en Coach IA.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await _service.clearWeeklyPlan();
              setState(() {
                _completed.clear();
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ciclo semanal reiniciado. Puedes solicitar tu nueva rutina.'),
                    backgroundColor: Color(0xFF173B45),
                  ),
                );
                _openCoach();
              }
            },
            child: const Text('Reiniciar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openCoach() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CoachScreen()),
    );
  }

  Widget _buildBody() {
    if (_service.isPlanExpired) {
      return _EmptyState(
        icon: Icons.event_repeat_rounded,
        title: '¡Ciclo Semanal Culminado! 🏁',
        message:
            'Tu semana de entrenamiento anterior ha finalizado con éxito.\n\nEs momento de diseñar tu nuevo plan de entrenamiento con el Coach IA para la semana en curso, adaptado a tu progreso y estado actual.',
        buttonLabel: 'Crear Nuevo Plan en Coach IA',
        onRetry: () async {
          await _service.clearWeeklyPlan();
          _openCoach();
        },
        isError: false,
      );
    }

    if (_service.week == null) {
      if (_service.isLoading) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF8BE0C0)),
              SizedBox(height: 14),
              Text('Sincronizando tu cronograma...',
                  style: TextStyle(color: Colors.white70)),
            ],
          ),
        );
      }

      return _EmptyState(
        message:
            'Aún no tienes rutinas programadas en esta semana.\n\nPresiona el botón de abajo para ir al módulo Coach IA, solicitar tu recomendación personalizada y agregarla a tu cronograma semanal.',
        onRetry: _openCoach,
        isError: false,
      );
    }

    final days = _service.days;
    final today = _service.todayIndex;
    final scheduledDays = days.where((d) {
      final ex = d['exercises'];
      return ex is List && ex.isNotEmpty;
    }).toList();
    final restDays = days.where((d) {
      final ex = d['exercises'];
      return ex is! List || ex.isEmpty;
    }).toList();

    final pendingScheduled =
        scheduledDays.where((d) => !_completed.contains(d['weekday'])).toList();
    final doneScheduled =
        scheduledDays.where((d) => _completed.contains(d['weekday'])).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Rutinas de la Semana',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF8BE0C0),
                backgroundColor: const Color(0xFF16233A),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _handleNewRoutinePress,
              icon: const Icon(Icons.smart_toy_rounded, size: 18),
              label: const Text(
                'Ir a Coach IA',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Hoy es ${_service.todayName} · '
          '${doneScheduled.length} de ${scheduledDays.length} sesiones programadas completadas',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 16),

        // Banner de Accesibilidad / Módulo de Ejercicios Adaptados
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF102820),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF8BE0C0).withOpacity(0.35)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8BE0C0).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.accessible_forward_rounded, color: Color(0xFF8BE0C0), size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '♿ Test Módulo Adaptado (Torso)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      'Ejercicios sentados para personas con discapacidad motora en piernas (3D & GIF).',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8BE0C0),
                  foregroundColor: const Color(0xFF0B1220),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdaptiveWorkoutScreen()),
                  );
                },
                child: const Text('Ver Test', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
              ),
            ],
          ),
        ),

        // Banner informativo del Ciclo Semanal Activo y Próxima Planificación
        _ActiveCycleCard(
          service: _service,
          completedCount: doneScheduled.length,
          totalCount: scheduledDays.length,
          onNewRoutinePressed: _handleNewRoutinePress,
        ),
        if (_service.hasUpcomingPlan) ...[
          const SizedBox(height: 12),
          _UpcomingCycleCard(
            service: _service,
            onOpenCoach: _openCoach,
            onExerciseTap: (ex, allEx) => _openExerciseIn3D(context, ex, allEx),
          ),
        ],
        const SizedBox(height: 18),

        if (pendingScheduled.isNotEmpty) ...[
          const _SectionLabel('RUTINAS PROGRAMADAS EN LA SEMANA'),
          ...pendingScheduled.map((day) => _DayCard(
                day: day,
                isToday: day['weekday'] == today,
                isDone: false,
                onToggle: () => _handleToggleCompletion(day),
                onExerciseTap: (ex, allEx) => _openExerciseIn3D(context, ex, allEx),
              )),
        ],
        if (doneScheduled.isNotEmpty) ...[
          const SizedBox(height: 10),
          const _SectionLabel('SESIONES COMPLETADAS'),
          ...doneScheduled.map((day) => _DayCard(
                day: day,
                isToday: day['weekday'] == today,
                isDone: true,
                onToggle: () => _handleToggleCompletion(day),
                onExerciseTap: (ex, allEx) => _openExerciseIn3D(context, ex, allEx),
              )),
        ],
        if (restDays.isNotEmpty) ...[
          const SizedBox(height: 14),
          const _SectionLabel('DÍAS DE RECUPERACIÓN MUSCULAR (48-72H) / DISPONIBLES'),
          ...restDays.map((day) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: const Color(0xFF101929),
                child: ListTile(
                  leading: const Icon(Icons.self_improvement_rounded,
                      color: Color(0xFF8BE0C0)),
                  title: Text(
                    '${day['weekday_name']} · ${day['title']}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Descanso muscular o disponible para rutina complementaria en Coach IA.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  trailing: TextButton(
                    onPressed: _handleNewRoutinePress,
                    child: const Text(
                      '+ Complementar',
                      style: TextStyle(
                          color: Color(0xFF8BE0C0),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  void _openExerciseIn3D(
    BuildContext context,
    Map<String, dynamic> item,
    List<dynamic> exercises,
  ) {
    final List<AnatomyExercise> dyn = [];
    for (var e in exercises) {
      final ex = Map<String, dynamic>.from(e as Map);
      final exName = ex['name'] as String? ?? 'Ejercicio';
      final primary = ex['primary_muscle'] as String? ?? 'General';
      final secondary = ex['secondary_muscle'] as String? ?? '';
      final intensityLvl =
          ex['intensity_level'] as String? ?? 'Básico (Intensidad Baja)';
      final gifUrl = ex['gif_url'] as String? ?? '';

      dyn.add(AnatomyExercise(
        id: exName,
        name: exName,
        shortName: exName,
        gifUrl: resolveGuaranteedGifUrl(
          name: exName,
          agonist: primary,
          intensityLevel: intensityLvl,
          existingUrl: gifUrl,
        ),
        agonist: primary,
        synergists: secondary.isNotEmpty ? [secondary] : [],
        intensityLevel: intensityLvl,
        biomechanics: ex['biomechanics'] as String? ??
            'Movimiento controlado con técnica biomecánica estricta.',
        tempo: ex['tempo'] as String? ?? '3-1-1',
        posture: ex['posture'] as String? ??
            'Mantén columna alineada y respiración constante.',
        warning: ex['warning'] as String? ??
            'Detén la ejecución si experimentas dolor articular o mareo.',
      ));
    }

    final targetName = (item['name'] as String? ?? '').trim();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnatomyWorkoutScreen(
          initialExerciseId: targetName.isNotEmpty
              ? targetName
              : (dyn.isNotEmpty ? dyn.first.id : 'squat'),
          dynamicExercises: dyn.isNotEmpty ? dyn : null,
        ),
      ),
    );
  }
}

class _UpcomingCycleCard extends StatefulWidget {
  const _UpcomingCycleCard({
    required this.service,
    required this.onOpenCoach,
    required this.onExerciseTap,
  });

  final WeeklyPlanService service;
  final VoidCallback onOpenCoach;
  final void Function(Map<String, dynamic> exercise, List<dynamic> allExercises) onExerciseTap;

  @override
  State<_UpcomingCycleCard> createState() => _UpcomingCycleCardState();
}

class _UpcomingCycleCardState extends State<_UpcomingCycleCard> {
  bool _isExpanded = false;

  void _confirmActivateNow() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF101C2F),
        title: const Text('¿Activar próximo ciclo ahora?'),
        content: Text(
          'El plan programado para ${widget.service.upcomingCycleRangeStr} pasará a ser tu ciclo activo inmediatamente.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8BE0C0)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await widget.service.activateUpcomingPlanNow();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('¡Próximo ciclo activado como ciclo actual!'),
                    backgroundColor: Color(0xFF173B45),
                  ),
                );
              }
            },
            child: const Text('Activar ahora', style: TextStyle(color: Color(0xFF0D1B2A), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDiscard() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF101C2F),
        title: const Text('¿Descartar próximo ciclo?'),
        content: const Text(
          'Se eliminará la planificación futura guardada. Tu ciclo activo actual no se verá afectado.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await widget.service.clearUpcomingPlan();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Próximo ciclo descartado.'),
                    backgroundColor: Color(0xFF173B45),
                  ),
                );
              }
            },
            child: const Text('Descartar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final upcomingDays = widget.service.upcomingDays;
    final trainingDays = upcomingDays.where((d) => (d['exercises'] as List?)?.isNotEmpty == true).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF132238),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFB340).withOpacity(0.55),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF332612),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 14, color: Color(0xFFFFB340)),
                        const SizedBox(width: 5),
                        Text(
                          'PRÓXIMO CICLO: ${widget.service.upcomingCycleRangeStr}',
                          style: const TextStyle(
                            color: Color(0xFFFFB340),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: const Color(0xFFFFB340),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Programado para la semana del ${widget.service.upcomingCycleRangeStr}. Se activará automáticamente al comenzar esa fecha.',
                    style: const TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (_isExpanded) ...[
            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Días y rutinas planificadas para el próximo ciclo:',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                  const SizedBox(height: 8),
                  ...trainingDays.map((d) {
                    final dName = d['weekday_name'] ?? 'Día';
                    final dTitle = d['title'] ?? 'Rutina';
                    final exs = (d['exercises'] as List?) ?? [];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E1826),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF173B45),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              dName,
                              style: const TextStyle(color: Color(0xFF8BE0C0), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$dTitle (${exs.length} ejercicios)',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF8BE0C0)),
                            foregroundColor: const Color(0xFF8BE0C0),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: _confirmActivateNow,
                          icon: const Icon(Icons.flash_on_rounded, size: 16),
                          label: const Text('Activar como ciclo actual ahora', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Descartar próximo ciclo',
                        onPressed: _confirmDiscard,
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.white54, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ActiveCycleCard extends StatelessWidget {
  const _ActiveCycleCard({
    required this.service,
    required this.completedCount,
    required this.totalCount,
    required this.onNewRoutinePressed,
  });

  final WeeklyPlanService service;
  final int completedCount;
  final int totalCount;
  final VoidCallback onNewRoutinePressed;

  @override
  Widget build(BuildContext context) {
    final trainingDays = service.activeTrainingDayNames;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101C2F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8BE0C0).withOpacity(0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF173B45),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 14, color: Color(0xFF8BE0C0)),
                    const SizedBox(width: 5),
                    Text(
                      'CICLO ACTIVO: ${service.cycleDateRangeStr}',
                      style: const TextStyle(
                        color: Color(0xFF8BE0C0),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '$completedCount de $totalCount hechos',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '🏋️ Días de entrenamiento programados:\n${trainingDays.isNotEmpty ? trainingDays.join(' · ') : 'Sin rutinas fijas'}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF16253B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.timer_outlined,
                    size: 16, color: Color(0xFFFFB340)),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11.5, height: 1.35),
                      children: [
                        const TextSpan(
                          text: 'Próxima planificación completa: ',
                          style: TextStyle(
                            color: Color(0xFFFFB340),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text:
                              'A partir del ${service.nextCycleDateStr} para respetar el ciclo semanal y la recuperación neuromuscular.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (service.currentStreak > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF231A12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFB340).withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    'Racha Activa: ${service.currentStreak} ${service.currentStreak == 1 ? "sesión consecutiva" : "sesiones consecutivas"}',
                    style: const TextStyle(
                      color: Color(0xFFFFB340),
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.message,
    required this.onRetry,
    this.title = 'Rutinas Programadas',
    this.icon = Icons.smart_toy_rounded,
    this.buttonLabel = 'Crear mi rutina en Coach IA',
    this.isError = true,
  });

  final String message;
  final VoidCallback onRetry;
  final String title;
  final IconData icon;
  final String buttonLabel;
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
              icon,
              size: 58,
              color: const Color(0xFF2DD4BF),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, height: 1.5)),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2DD4BF),
                foregroundColor: const Color(0xFF0B1220),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              onPressed: onRetry,
              icon: Icon(icon),
              label: Text(
                buttonLabel,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
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
    required this.onExerciseTap,
  });

  final Map<String, dynamic> day;
  final bool isToday;
  final bool isDone;
  final VoidCallback onToggle;
  final void Function(Map<String, dynamic> exercise, List<dynamic> all) onExerciseTap;

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
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          if (isToday)
                            const Text(
                              'HOY',
                              style: TextStyle(
                                color: Color(0xFF8BE0C0),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          if (day['is_home_workout'] == true)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B4332),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF40916C)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.home_rounded, size: 12, color: Color(0xFF8BE0C0)),
                                  SizedBox(width: 4),
                                  Text(
                                    'RUTINA EN CASA',
                                    style: TextStyle(
                                      color: Color(0xFF8BE0C0),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
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
            if (day['is_home_workout'] == true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF162E25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2D6A4F)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.home_work_rounded, size: 16, color: Color(0xFF8BE0C0)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rutina adaptada a peso corporal / sin equipo por aviso de inasistencia del entrenador.',
                        style: TextStyle(color: Color(0xFFD8F3DC), fontSize: 11.5),
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
                  label: const Text('Ver Atlas'),
                  onPressed: () => onExerciseTap(item, exercises),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}