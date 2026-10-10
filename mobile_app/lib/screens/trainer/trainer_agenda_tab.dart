import 'package:flutter/material.dart';

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
            const Text('Agenda de Hoy', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildTimeBlock('12:00 PM - 2:00 PM', '2/2 Cupos Llenos', [
                    {'name': 'Juan PÃ©rez', 'workout': 'Pecho e hipertrofia'},
                    {'name': 'Ana GÃ³mez', 'workout': 'Cardio intenso'},
                  ], Colors.redAccent),
                  _buildTimeBlock('2:00 PM - 4:00 PM', '1/2 Cupos Libres', [
                    {'name': 'Carlos Ruiz', 'workout': 'Piernas'},
                  ], Colors.orangeAccent),
                  _buildTimeBlock('4:00 PM - 6:00 PM', '2/2 Cupos Libres', [], Colors.greenAccent),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBlock(String time, String capacity, List<Map<String, String>> students, Color capacityColor) {
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
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Color(0xFF1FAE87), size: 18),
                    const SizedBox(width: 8),
                    Text(s['name']!, style: const TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(child: Text('- ', style: const TextStyle(color: Colors.white54, fontSize: 14), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }
}
