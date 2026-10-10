import os

base_path = 'mobile_app/lib/screens/trainer'

# 1. Trainer Shell
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
            tooltip: 'Cerrar Sesión',
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
      {'id': '1', 'name': 'Juan Pérez', 'goal': 'Ganar Músculo', 'status': 'Activo', 'last_photo': 'Hace 2 días'},
      {'id': '2', 'name': 'Ana Gómez', 'goal': 'Perder Peso', 'status': 'Requiere revisión', 'last_photo': 'Hoy'},
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
'''
with open(os.path.join(base_path, 'trainer_clients_tab.dart'), 'w', encoding='utf-8') as f:
    f.write(clients_code)

# 3. Trainer Agenda Tab
agenda_code = '''import 'package:flutter/material.dart';
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
            const Text('Agenda de Hoy', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
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
            const Text('Envía avisos globales a todos tus alumnos.', style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 20),
            TextField(
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Escribe un nuevo anuncio o recomendación general...',
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
                    Text('Chicos, el gimnasio estará cerrado mañana en la mañana. Únanse al chat en línea para asesoría.', style: TextStyle(color: Colors.white, fontSize: 15)),
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
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        appBar: AppBar(
          title: Text('Ficha: \', style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF0F192B),
          elevation: 0,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Color(0xFF1FAE87),
            labelColor: Color(0xFF1FAE87),
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Perfil & Progreso'),
              Tab(text: 'Entrenamiento'),
              Tab(text: 'Nutrición'),
              Tab(text: 'Análisis IA'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPerfilTab(),
            _buildEntrenamientoTab(),
            _buildNutricionTab(),
            _buildAiTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPerfilTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildInfoCard(
          title: 'Información Personal',
          icon: Icons.person,
          content: Column(
            children: [
              _infoRow('Edad', '28 años'),
              _infoRow('Peso Actual', '75 kg'),
              _infoRow('Objetivo', 'Ganancia Muscular'),
              _infoRow('Patologías', 'Ninguna'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: 'Progreso y Ritmo',
          icon: Icons.trending_up,
          content: Column(
            children: [
              _infoRow('Frecuencia', '4 días a la semana'),
              _infoRow('Consistencia', '85% este mes'),
              const SizedBox(height: 12),
              const Text('Evolución de Peso (Últimas 4 semanas)', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('72 kg', style: TextStyle(color: Colors.white54)),
                  Icon(Icons.arrow_right_alt, color: Color(0xFF1FAE87)),
                  Text('75 kg', style: TextStyle(color: Color(0xFF1FAE87), fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEntrenamientoTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Rutina Programada para Hoy', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: 'Día de Piernas y Glúteos',
          icon: Icons.fitness_center,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Máquinas y Equipos a utilizar:', style: TextStyle(color: Color(0xFF1FAE87), fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _machineItem('Prensa de Piernas (Leg Press)'),
              _machineItem('Máquina de Extensión de Cuádriceps'),
              _machineItem('Mancuernas (Pesos Libres)'),
              const Divider(color: Colors.white24, height: 24),
              const Text('El alumno espera asistencia en la Prensa de Piernas.', style: TextStyle(color: Colors.orangeAccent, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNutricionTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildInfoCard(
          title: 'Plan de Alimentación',
          icon: Icons.restaurant,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Calorías Diarias', '2,800 kcal'),
              _infoRow('Proteína', '160g'),
              _infoRow('Carbohidratos', '350g'),
              _infoRow('Grasas', '85g'),
              const Divider(color: Colors.white24, height: 24),
              const Text('Sugerencia para hoy:', style: TextStyle(color: Color(0xFF1FAE87), fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Batido de proteína post-entrenamiento con plátano.', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAiTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
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
                  Text('Recomendaciones de la IA', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Resumen generado automáticamente basándose en el historial reciente del alumno:', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              _buildAiTip('Rendimiento', 'Excelente progresión de cargas en las últimas 2 semanas. El usuario se está adaptando muy bien al volumen actual.'),
              _buildAiTip('Punto a Mejorar', 'La asimetría en el hombro derecho reportada persiste. Recomiendo que hoy verifiques su postura durante los ejercicios de tren superior.'),
              _buildAiTip('Ajuste Sugerido', 'Incrementar las calorías diarias a 3,000 kcal la próxima semana si el peso se estanca, ya que su gasto energético ha subido considerablemente.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 15)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _machineItem(String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white54, size: 16),
          const SizedBox(width: 8),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required Widget content}) {
    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1FAE87)),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            content,
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
        width: double.infinity,
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
