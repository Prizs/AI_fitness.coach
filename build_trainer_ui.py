import os

base_path = 'mobile_app/lib/screens/trainer'

# 1. Trainer Shell (Bottom Navigation)
shell_code = '''import 'package:flutter/material.dart';
import 'package:mobile_app/screens/trainer/trainer_clients_tab.dart';
import 'package:mobile_app/screens/trainer/trainer_agenda_tab.dart';
import 'package:mobile_app/screens/trainer/trainer_announcements_tab.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/main.dart';

class TrainerShell extends StatefulWidget {
  const TrainerShell({super.key});

  @override
  State<TrainerShell> createState() => _TrainerShellState();
}

class _TrainerShellState extends State<TrainerShell> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    TrainerAgendaTab(),
    TrainerClientsTab(),
    TrainerAnnouncementsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        title: const Text('Panel Pro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: const Color(0xFF0F192B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Cerrar SesiÃ³n',
            onPressed: () {
              AuthService.instance.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthGate()), 
                (r) => false
              );
            },
          )
        ],
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0F192B),
        selectedItemColor: const Color(0xFF1FAE87),
        unselectedItemColor: Colors.white54,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Agenda'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt), label: 'Alumnos'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Anuncios'),
        ],
      ),
    );
  }
}
'''
with open(os.path.join(base_path, 'trainer_shell.dart'), 'w', encoding='utf-8') as f:
    f.write(shell_code)

# 2. Trainer Clients Tab
clients_code = '''import 'package:flutter/material.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/screens/trainer/client_detail_screen.dart';

class TrainerClientsTab extends StatelessWidget {
  const TrainerClientsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final String trainerCode = AuthService.instance.loggedInUser?.cedula ?? 'Desconocido';
    final List<Map<String, dynamic>> mockClients = [
      {'id': '1', 'name': 'Juan PÃ©rez', 'goal': 'Ganar MÃºsculo', 'status': 'Activo', 'last_photo': 'Hace 2 dÃ­as'},
      {'id': '2', 'name': 'Ana GÃ³mez', 'goal': 'Perder Peso', 'status': 'Requiere revisiÃ³n', 'last_photo': 'Hoy'},
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
                  const Text('Tu CÃ³digo de VinculaciÃ³n', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    trainerCode,
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                  const SizedBox(height: 12),
                  const Text('Comparte este cÃ³digo con tus alumnos para que te asignen.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 13)),
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
                                Text(client['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('Meta: \', style: const TextStyle(color: Colors.white70, fontSize: 14)),
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
'''
with open(os.path.join(base_path, 'trainer_clients_tab.dart'), 'w', encoding='utf-8') as f:
    f.write(clients_code)

# 3. Trainer Agenda Tab
agenda_code = '''import 'package:flutter/material.dart';

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
                    Expanded(child: Text('- \', style: const TextStyle(color: Colors.white54, fontSize: 14), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }
}
'''
with open(os.path.join(base_path, 'trainer_agenda_tab.dart'), 'w', encoding='utf-8') as f:
    f.write(agenda_code)

# 4. Trainer Announcements Tab
announcements_code = '''import 'package:flutter/material.dart';

class TrainerAnnouncementsTab extends StatelessWidget {
  const TrainerAnnouncementsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Muro de Anuncios', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('EnvÃ­a avisos globales a todos tus alumnos.', style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 20),
            TextField(
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Escribe un nuevo anuncio o recomendaciÃ³n general...',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text('Publicar Anuncio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1FAE87),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Anuncios Recientes', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              color: const Color(0xFF1E293B),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Hoy, 9:00 AM', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    SizedBox(height: 8),
                    Text('Chicos, el gimnasio estarÃ¡ cerrado maÃ±ana en la maÃ±ana. Ãšnanse al chat en lÃ­nea para asesorÃ­a.', style: TextStyle(color: Colors.white, fontSize: 15)),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
'''
with open(os.path.join(base_path, 'trainer_announcements_tab.dart'), 'w', encoding='utf-8') as f:
    f.write(announcements_code)

# 5. Client Detail Screen (AI Profile)
client_detail_code = '''import 'package:flutter/material.dart';

class ClientDetailScreen extends StatelessWidget {
  final String clientName;
  const ClientDetailScreen({super.key, required this.clientName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        title: Text('Expediente: \', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F192B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen AI
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1FAE87).withOpacity(0.5), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.smart_toy, color: Color(0xFF1FAE87)),
                      SizedBox(width: 8),
                      Text('AnÃ¡lisis IA del Rendimiento', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Basado en los Ãºltimos entrenamientos y fotos de progreso de este alumno, la IA detecta lo siguiente:', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 12),
                  _buildAiTip('Progreso Positivo', 'Ha aumentado 5kg en Press de Banca en 2 semanas.'),
                  _buildAiTip('Alerta de Estancamiento', 'La pÃ©rdida de grasa corporal se detuvo (estÃ¡ en 18%). Revisar nutriciÃ³n.'),
                  _buildAiTip('Sugerencia IA', 'Asignar rutina de fuerza mÃ¡xima para romper el estancamiento e invitar a charla motivacional.'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.chat, color: Colors.white),
                    label: const Text('Chat Privado', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text('Ver Progreso', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1FAE87), padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAiTip(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Color(0xFF1FAE87), fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(desc, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
'''
with open(os.path.join(base_path, 'client_detail_screen.dart'), 'w', encoding='utf-8') as f:
    f.write(client_detail_code)
