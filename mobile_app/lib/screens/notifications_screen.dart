import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/services/weekly_plan_service.dart';
import 'package:mobile_app/services/daily_notification_service.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/sound_service.dart';
import 'package:mobile_app/widgets/fatigue_checkin_dialog.dart';
import 'package:mobile_app/screens/coach_screen.dart';
import 'package:mobile_app/screens/workout_schedule_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final DailyNotificationService _notifService = DailyNotificationService.instance;
  final WeeklyPlanService _planService = WeeklyPlanService.instance;

  Map<String, dynamic>? _pendingSession;
  bool _isLoadingSession = true;

  @override
  void initState() {
    super.initState();
    _notifService.init();
    _loadPendingSession();
  }

  Future<void> _loadPendingSession() async {
    final uid = AuthService.instance.loggedInUser?.cedula ?? '';
    if (uid.isEmpty) {
      if (mounted) setState(() => _isLoadingSession = false);
      return;
    }
    final baseUrl = AuthService.apiBaseUrl;
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/trainer/client-pending-session/$uid'));
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        if (mounted) {
          setState(() {
            _pendingSession = (data is Map && data['has_session'] == true) ? data['session'] : null;
            _isLoadingSession = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingSession = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSession = false);
    }
  }

  Future<void> _confirmSession(String sessionId, String startTime) async {
    final uid = AuthService.instance.loggedInUser?.cedula ?? '';
    final baseUrl = AuthService.apiBaseUrl;

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/trainer/session-response'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'session_id': sessionId,
          'client_id': uid,
          'action': 'accept',
        }),
      );

      if (res.statusCode == 200) {
        SoundService.playChime();
        // Actualizar bloque diario a la hora acordada
        if (startTime.contains(':')) {
          final parts = startTime.split(':');
          final h = int.tryParse(parts[0]) ?? 8;
          final m = int.tryParse(parts[1]) ?? 0;
          await _notifService.setWorkoutBlockTime(TimeOfDay(hour: h, minute: m));
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF1FAE87),
              content: Text('✅ ¡Asistencia confirmada! Tu bloque diario se actualizó a las $startTime hrs.'),
            ),
          );
        }
        await _loadPendingSession();
      }
    } catch (e) {
      debugPrint('Error confirmando sesión: $e');
    }
  }

  void _showRejectOrCounterModal(Map<String, dynamic> session) {
    final sessionStartTime = (session['start_time']?.toString() ?? '').split(':').take(2).join(':');
    final noteController = TextEditingController();

    final blockOptions = [
      {'time': '08:00', 'label': '08:00 - 10:00'},
      {'time': '10:30', 'label': '10:30 - 12:30'},
      {'time': '13:00', 'label': '13:00 - 15:00'},
      {'time': '15:30', 'label': '15:30 - 17:30'},
      {'time': '18:00', 'label': '18:00 - 20:00'},
      {'time': '20:30', 'label': '20:30 - 22:30'},
    ].where((b) => b['time'] != sessionStartTime).toList();

    String selectedTime = blockOptions.isNotEmpty ? blockOptions.first['time']! : '10:30';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F192B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ajuste de Horario / Opciones',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'No puedes a las ${session['start_time']} hrs. ¿A qué bloque de tu coach te gustaría asistir hoy?',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  const Text('Bloques de atención (2h de sesión + 30m descanso):', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: blockOptions.map((b) {
                      final time = b['time']!;
                      final label = b['label']!;
                      final isSel = selectedTime == time;
                      return ChoiceChip(
                        label: Text(label),
                        selected: isSel,
                        selectedColor: const Color(0xFF38BDF8),
                        backgroundColor: const Color(0xFF1E293B),
                        labelStyle: TextStyle(
                          color: isSel ? Colors.black : Colors.white70,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: isSel ? const Color(0xFF38BDF8) : Colors.white24),
                        ),
                        onSelected: (val) {
                          if (val) setModalState(() => selectedTime = time);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Comentario para tu coach (ej: Trabajo en la mañana)...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38BDF8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _sendCounterProposal(session['id'], selectedTime, noteController.text.trim());
                      },
                      child: Text(
                        'Proponer a las $selectedTime hrs al Coach',
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 10),
                  // Tarjeta alternativa de Casa
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA855F7).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.home_rounded, color: Color(0xFFA855F7), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('¿Prefieres entrenar en casa hoy?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              SizedBox(height: 2),
                              Text('Sustituye por ejercicios validados de peso corporal de la misma intensidad.', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA855F7),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showHomeWorkoutDialog();
                          },
                          child: const Text('En Casa', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _sendCounterProposal(String sessionId, String time, String note) async {
    final uid = AuthService.instance.loggedInUser?.cedula ?? '';
    final baseUrl = AuthService.apiBaseUrl;

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/trainer/session-response'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'session_id': sessionId,
          'client_id': uid,
          'action': 'counter',
          'counter_time': time,
          'counter_note': note,
        }),
      );

      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF38BDF8),
              content: Text('🔄 Propuesta de $time hrs enviada a tu coach.'),
            ),
          );
        }
        await _loadPendingSession();
      }
    } catch (e) {
      debugPrint('Error enviando contrapropuesta: $e');
    }
  }

  Future<void> _showHomeWorkoutDialog() async {
    final shouldSwitch = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F192B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.home_rounded, color: Color(0xFFA855F7)),
            SizedBox(width: 8),
            Text('Entrenamiento en Casa', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: const Text(
          '¿Quieres que te asignemos una rutina adaptada para el día de hoy en casa?\n\n'
          'Buscamos en nuestra base de datos ejercicios validados sin equipo (peso corporal / calistenia) con la misma intensidad y grupo muscular programado.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA855F7)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('¡Sí, asignar en casa!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldSwitch != true) return;

    final uid = AuthService.instance.loggedInUser?.cedula ?? '';
    final baseUrl = AuthService.apiBaseUrl;

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/trainer/assign-home-workout'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'client_id': uid,
          'intensity': 'Media',
        }),
      );

      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        final title = data['routine_title'] ?? 'Entrenamiento en Casa';
        final exercises = data['exercises'] as List<dynamic>? ?? [];

        // Sustituir en plan semanal
        _planService.substituteTodayWithHomeWorkout(title: title, exercises: exercises);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFA855F7),
              content: Text('🏠 ¡Rutina de casa activada! $title (${exercises.length} ejercicios).'),
            ),
          );
        }
        await _loadPendingSession();
      }
    } catch (e) {
      debugPrint('Error asignando rutina en casa: $e');
    }
  }

  Future<void> _selectBlockTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _notifService.workoutBlockTime,
      helpText: 'Selecciona tu hora habitual de entrenamiento',
      cancelText: 'Cancelar',
      confirmText: 'Guardar',
    );
    if (picked != null) {
      await _notifService.setWorkoutBlockTime(picked);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Bloque de entrenamiento actualizado a las ${_notifService.formattedBlockTime}. Avisos configurados con 3h de antelación.'),
            backgroundColor: const Color(0xFF1B4D3E),
          ),
        );
      }
    }
  }

  Widget _buildSessionProposalCard() {
    if (_pendingSession == null) return const SizedBox.shrink();

    final s = _pendingSession!;
    final status = s['status']?.toString() ?? 'pending_confirmation';
    final st = s['start_time'] ?? '08:00';
    final et = s['end_time'] ?? '10:00';
    final trainerName = s['trainer_name'] ?? 'Tu Coach';
    final workoutTitle = s['workout_title'] ?? 'Entrenamiento del día';

    if (status == 'pending_confirmation' || status == 'scheduled') {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amberAccent, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.amberAccent.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.schedule_send_rounded, color: Colors.amberAccent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Propuesta de Sesión Presencial',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amberAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Confirmación Requerida',
                    style: TextStyle(color: Colors.amberAccent, fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '¡$trainerName te ha asignado una sesión presencial en el gimnasio!',
              style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time_filled, color: Color(0xFF1FAE87), size: 16),
                const SizedBox(width: 6),
                Text(
                  'Horario propuesto: $st - $et hrs (Hoy)',
                  style: const TextStyle(color: Color(0xFF1FAE87), fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.fitness_center, color: Color(0xFF38BDF8), size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Plan: $workoutTitle',
                    style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F192B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Nota: Tu bloque diario actual está fijado a las ${_notifService.formattedBlockTime} hrs. Si confirmas asistencia, tu hora se ajustará automáticamente a las $st hrs.',
                style: const TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _showRejectOrCounterModal(s),
                    child: const Text('No puedo a esta hora', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1FAE87),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _confirmSession(s['id'], st),
                    child: const Text('Confirmar Asistencia', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (status == 'confirmed') {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1FAE87), width: 1.5),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFF1FAE87),
              radius: 18,
              child: Icon(Icons.check, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sesión Presencial Confirmada', style: TextStyle(color: Color(0xFF1FAE87), fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('Asistirás hoy de $st a $et hrs con $trainerName en el gimnasio.', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'counter_proposed') {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFF38BDF8),
              radius: 18,
              child: Icon(Icons.swap_horiz, color: Colors.black87, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contrapropuesta de Horario Enviada', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('Has propuesto entrenar a las ${s['counter_time'] ?? 'otro horario'} hrs. Esperando confirmación de tu coach.', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'home_assigned') {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFA855F7), width: 1.5),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFA855F7),
              radius: 18,
              child: Icon(Icons.home_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Entrenamiento en Casa Activo', style: TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('Rutina adaptada para realizar en casa con tu peso corporal.', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekday = now.weekday;
    final todayDay = _planService.today;
    final isCompletedToday = _planService.completedDays.contains(_planService.todayIndex);

    final List<Map<String, dynamic>> dynamicNotifs = [];

    // 1. Notificación de Seguimiento / Verificación (1 hora y media después si no está marcado completado)
    if (todayDay != null) {
      final title = todayDay['title'] ?? 'Entrenamiento del día';
      final exCount = (todayDay['exercises'] as List?)?.length ?? 0;
      final blockTime = _notifService.formattedBlockTime;
      final followupTime = _notifService.formattedFollowupTime;
      final priorTime = _notifService.formatted3hPriorTime;

      if (!isCompletedToday) {
        dynamicNotifs.add({
          'title': '❓ ¿Realizaste el ejercicio planificado para hoy?',
          'body': 'Tu bloque era a las $blockTime (seguimiento activo desde $followupTime). ¿Realizaste "$title" ($exCount ejercicios)? Toca aquí para responder la encuesta de fatiga y registrar tu rendimiento.',
          'time': 'Seguimiento 1h30 post-bloque',
          'icon': Icons.help_outline_rounded,
          'color': Colors.amberAccent,
          'action': () => FatigueCheckinDialog.show(context, onCompleted: () => setState(() {})),
        });

        // 2. Notificación con 3 horas de anticipación
        dynamicNotifs.add({
          'title': '⏰ Recordatorio Diario (3 Horas de Anticipación)',
          'body': 'Aviso programado para las $priorTime (3h antes de tu sesión de las $blockTime). Hoy te corresponde: "$title". Prepara tu hidratación y pre-entreno.',
          'time': 'Anticipación 3h ($priorTime)',
          'icon': Icons.alarm_on_rounded,
          'color': const Color(0xFF38BDF8),
          'action': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutScheduleScreen())),
        });
      } else {
        dynamicNotifs.add({
          'title': '✅ Sesión de Hoy Completada y Verificada',
          'body': 'Completaste exitosamente: "$title". Tu informe de fatiga, RPE y gasto calórico ya fueron sincronizados.',
          'time': 'Completado hoy',
          'icon': Icons.check_circle_rounded,
          'color': const Color(0xFF1FAE87),
          'action': null,
        });
      }
    }

    // 3. Alerta si no hay plan activo
    if (_planService.week == null) {
      dynamicNotifs.add({
        'title': '⚠️ Cronograma Sin Plan Activo',
        'body': 'No tienes entrenamientos programados para esta semana. Diseña tu rutina con el Coach IA.',
        'time': 'Acción requerida',
        'icon': Icons.event_busy_rounded,
        'color': Colors.orangeAccent,
        'action': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoachScreen())),
      });
    } else if (weekday >= 5) {
      // 4. Alerta con anticipación de caducidad de ciclo
      dynamicNotifs.add({
        'title': '⏰ Próximo Ciclo de Entrenamiento',
        'body': 'Tu plan de ejercicios de esta semana está próximo a finalizar. ¡Ya puedes programar con el Coach IA tu rutina para la próxima semana con antelación conservando tu historial!',
        'time': 'Aviso anticipado',
        'icon': Icons.alarm_on_rounded,
        'color': const Color(0xFF2DD4BF),
        'action': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoachScreen())),
      });
    }

    // 5. Notificaciones generales
    dynamicNotifs.addAll([
      {
        'title': 'Horario de Notificaciones Adaptativo',
        'body': 'Las notificaciones móviles te alertan 3 horas antes de entrenar y verifican tu fatiga 1h30 después de tu hora fijada.',
        'time': 'Sistema Móvil',
        'icon': Icons.phonelink_ring_rounded,
        'color': const Color(0xFFA78BFA),
        'action': null,
      },
      {
        'title': 'Consejo de Hidratación IA',
        'body': 'Mantente hidratado durante tus sesiones. Una hidratación óptima acelera la recuperación neuromuscular.',
        'time': 'Consejo IA',
        'icon': Icons.water_drop_rounded,
        'color': const Color(0xFF38BDF8),
        'action': null,
      },
    ]);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        title: const Text('Notificaciones y Avisos', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F192B),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadPendingSession,
        color: const Color(0xFF1FAE87),
        backgroundColor: const Color(0xFF0F192B),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSessionProposalCard(),
            // Tarjeta de Configuración del Bloque Horario
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF141F32),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF8BE0C0).withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF173B45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.access_time_filled_rounded, color: Color(0xFF8BE0C0), size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tu Bloque Diario de Entrenamiento',
                        style: TextStyle(color: Colors.white60, fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_notifService.formattedBlockTime} hrs',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Aviso 3h antes: ${_notifService.formatted3hPriorTime} | Encuesta: ${_notifService.formattedFollowupTime}',
                        style: const TextStyle(color: Color(0xFF8BE0C0), fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF173B45),
                    foregroundColor: const Color(0xFF8BE0C0),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _selectBlockTime,
                  child: const Text('Cambiar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Avisos y Recordatorios en Vivo',
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),

          ...dynamicNotifs.map((n) {
            final color = n['color'] as Color;
            final VoidCallback? action = n['action'] as VoidCallback?;

            return Card(
              color: const Color(0xFF1E293B),
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: action,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: color.withOpacity(0.2),
                        child: Icon(n['icon'] as IconData, color: color, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    n['title'],
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  n['time'],
                                  style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              n['body'],
                              style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.3),
                            ),
                            if (action != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    'Toca para responder encuesta o ver detalles',
                                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded, color: color, size: 13),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    ),
  );
  }
}
