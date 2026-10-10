import sys

path = 'mobile_app/lib/screens/user_profile_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

import_stmt = "import 'package:mobile_app/screens/progress_screen.dart';"
if import_stmt not in text:
    text = text.replace("import 'package:mobile_app/main.dart';", "import 'package:mobile_app/main.dart';\n" + import_stmt)

new_section = '''
          const SizedBox(height: 24),
          const Text('Funciones B2B y Análisis', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            tileColor: const Color(0xFF101B2D),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF8BE0C0)),
            title: const Text('Mi Progreso Fotográfico', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text('Análisis por IA de composición corporal', style: TextStyle(color: Colors.white70)),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen()));
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            tileColor: const Color(0xFF101B2D),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: const Icon(Icons.fitness_center_rounded, color: Colors.orangeAccent),
            title: const Text('Entrenador Asignado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text('Vincular cuenta con tu instructor', style: TextStyle(color: Colors.white70)),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
            onTap: () {
              // TODO show dialog to link trainer
            },
          ),
          const SizedBox(height: 32),
'''

if "Funciones B2B y Análisis" not in text:
    # Insert it right before the active goal section
    text = text.replace("          // Seccion: Meta Actual", new_section + "          // Seccion: Meta Actual")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
