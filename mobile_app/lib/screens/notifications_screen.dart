import 'package:flutter/material.dart';
import 'package:mobile_app/services/weekly_plan_service.dart';
import 'package:mobile_app/screens/coach_screen.dart';
import 'package:mobile_app/screens/workout_schedule_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = WeeklyPlanService.instance;
    final now = DateTime.now();
    final weekday = now.weekday; // 1 = Monday, 7 = Sunday
    final todayDay = service.today;

    final List<Map<String, dynamic>> dynamicNotifs = [];

    // 1. Alerta si no hay plan activo en el cronograma
    if (service.week == null) {
      dynamicNotifs.add({
        'title': '⚠️ Cronograma Sin Plan Activo',
        'body': 'No tienes entrenamientos programados para esta semana. Diseña tu rutina con el Coach IA.',
        'time': 'Acción requerida',
        'icon': Icons.event_busy_rounded,
        'color': Colors.orangeAccent,
        'target': const CoachScreen(),
      });
    } else {
      // 2. Alerta con anticipación de caducidad (Viernes, Sábado o Domingo)
      if (weekday >= 5) {
        dynamicNotifs.add({
          'title': '⏰ Próximo Ciclo de Entrenamiento',
          'body': 'Tu plan de ejercicios de esta semana está próximo a finalizar este fin de semana. ¡Ya puedes programar con el Coach IA tu rutina de la próxima semana con antelación!',
          'time': 'Aviso anticipado',
          'icon': Icons.alarm_on_rounded,
          'color': const Color(0xFF2DD4BF),
          'target': const CoachScreen(),
        });
      }

      // 3. Alerta de la sesión de hoy
      if (todayDay != null) {
        final title = todayDay['title'] ?? 'Entrenamiento del día';
        final exCount = (todayDay['exercises'] as List?)?.length ?? 0;
        dynamicNotifs.add({
          'title': '🏋️ Sesión Programada para Hoy',
          'body': 'Hoy te corresponde: "$title" ($exCount ejercicios). ¡Mantén la constancia!',
          'time': 'Hoy',
          'icon': Icons.fitness_center_rounded,
          'color': const Color(0xFF1FAE87),
          'target': const WorkoutScheduleScreen(),
        });
      }
    }

    // 4. Notificaciones generales
    dynamicNotifs.addAll([
      {
        'title': 'Horario Actualizado',
        'body': 'Tu entrenador ha revisado y validado tus bloques de atención.',
        'time': 'Reciente',
        'icon': Icons.calendar_today_rounded,
        'color': Colors.blueAccent,
        'target': null,
      },
      {
        'title': 'Consejo de Hidratación IA',
        'body': 'Mantente hidratado durante tus sesiones. Una hidratación óptima acelera la recuperación neuromuscular.',
        'time': 'Consejo IA',
        'icon': Icons.water_drop_rounded,
        'color': const Color(0xFF38BDF8),
        'target': null,
      },
    ]);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        title: const Text('Notificaciones y Avisos', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F192B),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: dynamicNotifs.length,
        itemBuilder: (context, index) {
          final n = dynamicNotifs[index];
          return Card(
            color: const Color(0xFF1E293B),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: (n['color'] as Color).withOpacity(0.2),
                child: Icon(n['icon'] as IconData, color: n['color'] as Color),
              ),
              title: Text(
                n['title'],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n['body'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(n['time'], style: const TextStyle(color: Colors.white38, fontSize: 12)),
                        if (n['target'] != null) ...[
                          const Spacer(),
                          const Text(
                            'Ir ahora →',
                            style: TextStyle(color: Color(0xFF1FAE87), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
              onTap: n['target'] != null
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => n['target'] as Widget),
                      )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
