import 'package:flutter/material.dart';
import 'package:mobile_app/screens/trainer/client_detail_screen.dart';

class TrainerAgendaTab extends StatelessWidget {
  const TrainerAgendaTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            Expanded(
              child: ListView(
                children: [
                  _buildTimeBlock(context, '12:00 PM - 2:00 PM', '2/2 Cupos Llenos', [
                    {'name': 'Juan Pérez', 'workout': 'Pecho e hipertrofia'},
                    {'name': 'Ana Gómez', 'workout': 'Cardio intenso'},
                  ], Colors.redAccent),
                  _buildTimeBlock(context, '2:00 PM - 4:00 PM', '1/2 Cupos Libres', [
                    {'name': 'Carlos Ruiz', 'workout': 'Piernas'},
                  ], Colors.orangeAccent),
                  _buildTimeBlock(context, '4:00 PM - 6:00 PM', '2/2 Cupos Libres', [], Colors.greenAccent),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBlock(BuildContext context, String time, String capacity, List<Map<String, String>> students, Color capacityColor) {
    return Card(
      color: const Color(0xFF1E293B),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(time, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(capacity, style: TextStyle(color: capacityColor, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            if (students.isEmpty)
              const Text('No hay alumnos inscritos en este bloque.', style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic))
            else
              ...students.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ClientDetailScreen(clientName: s['name']!)));
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Color(0xFF1FAE87), size: 18),
                      const SizedBox(width: 8),
                      Text(s['name']!, style: const TextStyle(color: Colors.white, fontSize: 16, decoration: TextDecoration.underline)),
                      const SizedBox(width: 8),
                      Expanded(child: Text('- ' + s['workout']!, style: const TextStyle(color: Colors.white54, fontSize: 14), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

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
}
