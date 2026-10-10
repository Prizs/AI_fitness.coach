import sys

path = 'mobile_app/lib/screens/trainer_dashboard_screen.dart'
code = '''import 'package:flutter/material.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/main.dart';

class TrainerDashboardScreen extends StatefulWidget {
  const TrainerDashboardScreen({super.key});

  @override
  State<TrainerDashboardScreen> createState() => _TrainerDashboardScreenState();
}

class _TrainerDashboardScreenState extends State<TrainerDashboardScreen> {
  final String _trainerCode = AuthService.instance.loggedInUser?.cedula ?? 'Desconocido';

  final List<Map<String, dynamic>> _mockClients = [
    {'name': 'Juan PÃ©rez', 'goal': 'Ganar MÃºsculo', 'status': 'Activo', 'last_photo': 'Hace 2 dÃ­as'},
    {'name': 'Ana GÃ³mez', 'goal': 'Perder Peso', 'status': 'Requiere revisiÃ³n', 'last_photo': 'Hoy'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        title: const Text('Panel de Entrenador Pro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
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
      body: SafeArea(
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
                      _trainerCode,
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                    const SizedBox(height: 12),
                    const Text('Comparte este cÃ³digo con tus alumnos para que te asignen como su entrenador principal.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text('Tus Alumnos', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _mockClients.length,
                itemBuilder: (context, index) {
                  final client = _mockClients[index];
                  final clientGoal = client['goal'] as String;
                  final clientPhoto = client['last_photo'] as String;
                  return Card(
                    color: const Color(0xFF1E293B),
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFF1FAE87).withOpacity(0.2),
                                child: Text(client['name'][0], style: const TextStyle(color: Color(0xFF1FAE87), fontWeight: FontWeight.bold, fontSize: 20)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(client['name'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('Meta: ' + clientGoal, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: client['status'] == 'Activo' ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  client['status'],
                                  style: TextStyle(
                                    color: client['status'] == 'Activo' ? Colors.greenAccent : Colors.orangeAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Colors.white12),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton.icon(
                                onPressed: () {}, 
                                icon: const Icon(Icons.camera_alt_outlined, color: Colors.white70, size: 18),
                                label: Text('Foto: ' + clientPhoto, style: const TextStyle(color: Colors.white70)),
                              ),
                              TextButton.icon(
                                onPressed: () {}, 
                                icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF1FAE87), size: 18),
                                label: const Text('Chat & Estrategia IA', style: TextStyle(color: Color(0xFF1FAE87))),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
'''
with open(path, 'w', encoding='utf-8') as f:
    f.write(code)
