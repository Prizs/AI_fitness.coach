import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> notifs = [
      {
        'title': 'Horario Actualizado',
        'body': 'Tu entrenador Nelvis ha modificado sus bloques de atención. Revisa tu agenda.',
        'time': 'Hace 5 min',
        'icon': Icons.calendar_today,
        'color': Colors.blueAccent
      },
      {
        'title': 'Consejo IA',
        'body': 'Recuerda mantenerte hidratado. Hoy te toca pierna y el desgaste será mayor.',
        'time': 'Hace 2 horas',
        'icon': Icons.smart_toy,
        'color': const Color(0xFF1FAE87)
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        title: const Text('Notificaciones', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F192B),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: notifs.length,
        itemBuilder: (context, index) {
          final n = notifs[index];
          return Card(
            color: const Color(0xFF1E293B),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: (n['color'] as Color).withOpacity(0.2),
                child: Icon(n['icon'] as IconData, color: n['color'] as Color),
              ),
              title: Text(n['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n['body'], style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text(n['time'], style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1FAE87),
        icon: const Icon(Icons.sim_card_alert, color: Colors.white),
        label: const Text('Simular Alerta Flotante', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Cambio de Horario', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('El coach acaba de modificar su agenda.', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF107055),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.all(20),
              duration: const Duration(seconds: 8), // 8 SECONDS FADE AS REQUESTED
            )
          );
        },
      ),
    );
  }
}
