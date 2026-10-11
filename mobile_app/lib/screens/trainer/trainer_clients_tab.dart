import 'package:flutter/material.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/screens/trainer/client_detail_screen.dart';

class TrainerClientsTab extends StatelessWidget {
  const TrainerClientsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final String trainerCode = AuthService.instance.loggedInUser?.cedula ?? 'Desconocido';
    final List<Map<String, dynamic>> mockClients = [
      {'id': '1', 'name': 'Juan Pérez', 'goal': 'Ganar Músculo', 'status': 'Activo', 'last_photo': 'Hace 2 días', 'alert': null},
      {'id': '2', 'name': 'Ana Gómez', 'goal': 'Perder Peso', 'status': 'Requiere revisión', 'last_photo': 'Hoy', 'alert': '🔴 Molestia en Rodilla'},
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1FAE87), Color(0xFF107055)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF1FAE87).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.fitness_center_rounded, size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text('Tu Código de Vinculación', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    trainerCode,
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                  const SizedBox(height: 12),
                  const Text('Comparte este código con tus alumnos para que te asignen.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Motivational Stats Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1FAE87).withOpacity(0.3), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.military_tech, color: Colors.amber, size: 28),
                          SizedBox(width: 8),
                          Text('Nivel Élite', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Text('145 Viajes', style: TextStyle(color: Color(0xFF1FAE87), fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('145 Entrenamientos completados exitosamente con tus alumnos. ¡Sigue transformando vidas!', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: const LinearProgressIndicator(
                      value: 0.75, // 75% to next level
                      backgroundColor: Colors.black26,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text('55 sesiones más para Nivel Maestro', style: TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Tus Alumnos', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mockClients.length,
              itemBuilder: (context, index) {
                final client = mockClients[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ClientDetailScreen(clientName: client['name'] as String)));
                  },
                  child: Card(
                    color: const Color(0xFF1E293B),
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFF1FAE87).withOpacity(0.2),
                            child: Text((client['name'] as String)[0], style: const TextStyle(color: Color(0xFF1FAE87), fontWeight: FontWeight.bold, fontSize: 20)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(client['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                    if (client['alert'] != null) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.redAccent),
                                        ),
                                        child: Text(
                                          client['alert'] as String,
                                          style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('Meta: ' + (client['goal'] as String), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.white54)
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
