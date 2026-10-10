import os

base_path = 'mobile_app/lib/screens/trainer'

# 1. New Trainer Profile Screen
profile_code = '''import 'package:flutter/material.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/main.dart';

class TrainerProfileScreen extends StatefulWidget {
  const TrainerProfileScreen({super.key});

  @override
  State<TrainerProfileScreen> createState() => _TrainerProfileScreenState();
}

class _TrainerProfileScreenState extends State<TrainerProfileScreen> {
  final TextEditingController _specialtyCtrl = TextEditingController(text: AuthService.instance.loggedInUser?.specialty ?? '');
  final TextEditingController _certificationsCtrl = TextEditingController(text: AuthService.instance.loggedInUser?.certifications ?? '');
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        title: const Text('Mi Perfil Profesional', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F192B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFF1FAE87),
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                '\ \',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Especialidad Principal', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _specialtyCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ej: Hipertrofia, PÃ©rdida de Peso, RehabilitaciÃ³n...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Certificaciones y Estudios', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _certificationsCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ej: CertificaciÃ³n ISSA, Grado en Ciencias del Deporte...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado (Demo)')));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1FAE87),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Guardar Cambios', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  AuthService.instance.logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthGate()), 
                    (r) => false
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text('Cerrar SesiÃ³n', style: TextStyle(color: Colors.redAccent)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
'''
with open(os.path.join(base_path, 'trainer_profile_screen.dart'), 'w', encoding='utf-8') as f:
    f.write(profile_code)

# 2. Modify Trainer Shell to include Profile Button
shell_path = os.path.join(base_path, 'trainer_shell.dart')
with open(shell_path, 'r', encoding='utf-8') as f:
    shell_text = f.read()

shell_text = shell_text.replace(
    "import 'package:mobile_app/main.dart';",
    "import 'package:mobile_app/main.dart';\nimport 'package:mobile_app/screens/trainer/trainer_profile_screen.dart';"
)

old_actions = '''        actions: [
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
        ],'''

new_actions = '''        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Color(0xFF1FAE87)),
            tooltip: 'Mi Perfil',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TrainerProfileScreen()));
            },
          )
        ],'''

shell_text = shell_text.replace(old_actions, new_actions)
with open(shell_path, 'w', encoding='utf-8') as f:
    f.write(shell_text)

# 3. Modify Clients Tab to include the Motivational Progress Bar
clients_path = os.path.join(base_path, 'trainer_clients_tab.dart')
with open(clients_path, 'r', encoding='utf-8') as f:
    clients_text = f.read()

# Find the Tu CÃ³digo de VinculaciÃ³n container and insert the progress card right after it
old_card_end = '''              child: Column(
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
            const SizedBox(height: 32),'''

new_stats_card = '''              child: Column(
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
            const SizedBox(height: 32),'''

clients_text = clients_text.replace(old_card_end, new_stats_card)

with open(clients_path, 'w', encoding='utf-8') as f:
    f.write(clients_text)
