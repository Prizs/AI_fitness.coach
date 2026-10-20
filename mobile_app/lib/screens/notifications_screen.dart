import 'package:flutter/material.dart';
import 'package:mobile_app/services/weekly_plan_service.dart';
import 'package:mobile_app/services/daily_notification_service.dart';
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

  @override
  void initState() {
    super.initState();
    _notifService.init();
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
    );
  }
}
