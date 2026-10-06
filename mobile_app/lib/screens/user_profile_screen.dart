import 'package:flutter/material.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/widgets/app_update.dart';
import 'package:mobile_app/main.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final List<String> _allergies = ['Lácteos', 'Mariscos'];
  final List<String> _injuries = ['Molestia en manguito rotador derecho'];
  final _allergyController = TextEditingController();
  final _injuryController = TextEditingController();

  final String _activeGoal = 'Mejorar resistencia cardiovascular y pulmonar';
  final String _secondaryGoal = 'Hipertrofia en tren superior (Fase 2)';
  final int _completedSessions = 14;
  final double _adherenceRate = 87.5;

  void _addTag(List<String> list, TextEditingController ctrl) {
    if (ctrl.text.trim().isNotEmpty) {
      setState(() {
        list.add(ctrl.text.trim());
        ctrl.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restricción sincronizada con el Coach IA')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.loggedInUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        title: const Text('Mi Perfil Atlético & Salud', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: const Color(0xFF0F192B),
        elevation: 0, actions: [ IconButton(icon: Icon(Icons.logout, color: Colors.redAccent), onPressed: () { AuthService.instance.logout(); Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => AuthGate()), (r) => false); }) ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Resumen de Métricas
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF173B45),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8BE0C0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.person_rounded, size: 36, color: Color(0xFF0B1220)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${user?.name ?? 'Atleta'} ${user?.lastName ?? ''}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('Cédula: ${user?.cedula ?? 'V-Local'} · ${user?.age ?? 25} años · ${user?.weight ?? 70.0} kg', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Adherencia y Sesiones
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0F192B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Historial y Rendimiento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text('$_completedSessions', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF8BE0C0))),
                          const SizedBox(height: 4),
                          const Text('Sesiones Hechas', style: TextStyle(color: Colors.white60, fontSize: 12)),
                        ],
                      ),
                      Container(width: 1, height: 40, color: Colors.white12),
                      Column(
                        children: [
                          Text('$_adherenceRate%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF8BE0C0))),
                          const SizedBox(height: 4),
                          const Text('Adherencia al Plan', style: TextStyle(color: Colors.white60, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Objetivos
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0F192B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Metas Atléticas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.track_changes_rounded, color: Color(0xFF8BE0C0)),
                    title: const Text('Meta Activa (Fase en Curso)', style: TextStyle(fontSize: 12, color: Colors.white60)),
                    subtitle: Text(_activeGoal, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  const Divider(color: Colors.white10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.next_plan_rounded, color: Colors.amber),
                    title: const Text('Plan Secundario / Próxima Meta', style: TextStyle(fontSize: 12, color: Colors.white60)),
                    subtitle: Text(_secondaryGoal, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Gestión de Alergias
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0F192B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.no_food_rounded, color: Color(0xFF8BE0C0)),
                      SizedBox(width: 8),
                      Text('Alergias y Exclusiones Alimentarias', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _allergies.map((a) => Chip(
                      label: Text(a),
                      onDeleted: () => setState(() => _allergies.remove(a)),
                    )).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _allergyController,
                          decoration: const InputDecoration(hintText: 'Agregar alergia...'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF8BE0C0)),
                        onPressed: () => _addTag(_allergies, _allergyController),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Gestión de Lesiones
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0F192B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.healing_rounded, color: Color(0xFFFF3B30)),
                      SizedBox(width: 8),
                      Text('Registro de Lesiones o Dolor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _injuries.map((i) => Chip(
                      backgroundColor: const Color(0xFF2A151B),
                      label: Text(i, style: const TextStyle(color: Color(0xFFFF3B30))),
                      onDeleted: () => setState(() => _injuries.remove(i)),
                    )).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _injuryController,
                          decoration: const InputDecoration(hintText: 'Agregar molestia (ej. hombro)...'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_rounded, color: Color(0xFFFF3B30)),
                        onPressed: () => _addTag(_injuries, _injuryController),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),


            // Configuracion del servidor
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF173B45),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Conexión con la IA (Servidor)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(AuthService.apiBaseUrl, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8BE0C0), foregroundColor: Colors.black),
                      icon: const Icon(Icons.link, size: 18),
                      label: const Text('Cambiar Servidor'),
                      onPressed: () {
                        final ctrl = TextEditingController(text: AuthService.apiBaseUrl);
                        showDialog(context: context, builder: (_) => AlertDialog(
                          backgroundColor: const Color(0xFF101B2D),
                          title: const Text('Cambiar Servidor', style: TextStyle(color: Colors.white)),
                          content: TextField(controller: ctrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'https://...', hintStyle: TextStyle(color: Colors.white38))),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
                            TextButton(onPressed: () async { await AuthService.instance.saveServerConfig(ctrl.text); if(context.mounted){Navigator.pop(context); setState((){});} }, child: const Text('Guardar', style: TextStyle(color: Color(0xFF8BE0C0)))),
                          ]
                        ));
                      },
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Verificador de actualizaciones de la app
            const AppUpdatePanel(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
