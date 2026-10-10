import os

base_path = 'mobile_app/lib/screens'

# 1. New Notifications Screen
notif_code = '''import 'package:flutter/material.dart';

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
'''
with open(os.path.join(base_path, 'notifications_screen.dart'), 'w', encoding='utf-8') as f:
    f.write(notif_code)

# 2. Update HomeScreen
home_path = os.path.join(base_path, 'home_screen.dart')
with open(home_path, 'r', encoding='utf-8') as f:
    home_text = f.read()

home_text = home_text.replace(
    "import 'package:mobile_app/screens/progress_screen.dart';",
    "import 'package:mobile_app/screens/progress_screen.dart';\nimport 'package:mobile_app/screens/notifications_screen.dart';"
)

appbar_old = '''        title: const Text(
          'Inicio (VERSIÓN 1.0.40 - Render Activo)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserProfileScreen(),
                ),
              );
            },
          ),
        ],'''

appbar_new = '''        title: const Text(
          'Inicio (V1.0.40)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                  child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserProfileScreen(),
                ),
              );
            },
          ),
        ],'''

home_text = home_text.replace(appbar_old, appbar_new)

with open(home_path, 'w', encoding='utf-8') as f:
    f.write(home_text)


# ----------------- TRAINER AGENDA EDIT -----------------
# 3. Update TrainerAgendaTab
agenda_path = 'mobile_app/lib/screens/trainer/trainer_agenda_tab.dart'
with open(agenda_path, 'r', encoding='utf-8') as f:
    agenda_text = f.read()

agenda_old = '''            const Text('Agenda de Hoy', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded('''

agenda_new = '''            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Agenda de Hoy', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => _showEditScheduleModal(context),
                  icon: const Icon(Icons.edit_calendar, color: Color(0xFF1FAE87), size: 20),
                  label: const Text('Editar Horarios', style: TextStyle(color: Color(0xFF1FAE87))),
                  style: TextButton.styleFrom(backgroundColor: const Color(0xFF1FAE87).withOpacity(0.1)),
                )
              ],
            ),
            const SizedBox(height: 16),
            Expanded('''

modal_function = '''
  void _showEditScheduleModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F192B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Configurar Horarios', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Modifica tus bloques de atención para que tus alumnos lo sepan. Se enviará una notificación a todos.', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 24),
                
                // Demo Sliders/Fields
                _buildScheduleEditor('Bloque Mañana', '08:00 AM', '11:00 AM'),
                _buildScheduleEditor('Bloque Mediodía', '12:00 PM', '02:00 PM'),
                _buildScheduleEditor('Bloque Tarde', '04:00 PM', '07:00 PM'),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Horarios actualizados. Notificando a los alumnos...')));
                    },
                    icon: const Icon(Icons.notifications_active, color: Colors.white),
                    label: const Text('Guardar y Notificar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1FAE87),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildScheduleEditor(String title, String start, String end) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF1FAE87), fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(start, style: const TextStyle(color: Colors.white)),
                      const Icon(Icons.access_time, color: Colors.white54, size: 16)
                    ],
                  ),
                ),
              ),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('a', style: TextStyle(color: Colors.white54))),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(end, style: const TextStyle(color: Colors.white)),
                      const Icon(Icons.access_time, color: Colors.white54, size: 16)
                    ],
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
'''

agenda_text = agenda_text.replace(agenda_old, agenda_new)
# Insert the modal function right before the last closing brace
last_brace_index = agenda_text.rfind('}')
agenda_text = agenda_text[:last_brace_index] + modal_function + agenda_text[last_brace_index:]

with open(agenda_path, 'w', encoding='utf-8') as f:
    f.write(agenda_text)
