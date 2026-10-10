import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClientTrainerTab extends StatefulWidget {
  const ClientTrainerTab({super.key});

  @override
  State<ClientTrainerTab> createState() => _ClientTrainerTabState();
}

class _ClientTrainerTabState extends State<ClientTrainerTab> {
  // Estado falso para demo: false = no tiene entrenador, true = si tiene
  bool _hasTrainer = false;
  bool _requestPending = false;
  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasTrainer = prefs.getBool('has_trainer') ?? false;
      _requestPending = prefs.getBool('request_pending') ?? false;
    });
  }

  Future<void> _saveState(bool hasTrainer, bool requestPending) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_trainer', hasTrainer);
    await prefs.setBool('request_pending', requestPending);
  }


  final List<Map<String, dynamic>> _availableTrainers = [
    {'name': 'Nelvis Rincón', 'specialty': 'Hipertrofia y Fuerza', 'rating': '4.9'},
    {'name': 'Carlos Ruiz', 'specialty': 'Pérdida de Peso', 'rating': '4.7'},
    {'name': 'Ana Gómez', 'specialty': 'Rehabilitación', 'rating': '5.0'},
  ];

  @override
  Widget build(BuildContext context) {
    if (_hasTrainer) {
      return _buildActiveChat();
    }
    if (_requestPending) {
      return _buildPendingState();
    }
    return _buildSearchState();
  }

  Widget _buildSearchState() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mi Entrenador', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.redAccent.withOpacity(0.5))),
              child: Column(
                children: const [
                  Icon(Icons.person_off, color: Colors.redAccent, size: 40),
                  SizedBox(height: 12),
                  Text('No tienes un entrenador asignado', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Busca un profesional para que diseñe tu rutina, supervise tu progreso y asigne tus horarios.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Entrenadores Disponibles', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _availableTrainers.length,
                itemBuilder: (context, index) {
                  final t = _availableTrainers[index];
                  return Card(
                    color: const Color(0xFF1E293B),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Color(0xFF1FAE87), child: Icon(Icons.sports, color: Colors.white)),
                      title: Text(t['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(t['specialty'], style: const TextStyle(color: Colors.white70)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1FAE87)),
                        onPressed: () {
                          _showTrainerProfile(t);
                        },
                        child: const Text('Ver Perfil', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showTrainerProfile(Map<String, dynamic> trainer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F192B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(radius: 40, backgroundColor: Color(0xFF1FAE87), child: Icon(Icons.person, size: 40, color: Colors.white)),
              const SizedBox(height: 16),
              Text(trainer['name'], style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              Text(trainer['specialty'], style: const TextStyle(color: Color(0xFF1FAE87), fontSize: 16)),
              const SizedBox(height: 24),
              const Text('Certificaciones: ISSA Personal Trainer, Nutrición Deportiva Avanzada.', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1FAE87), padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _requestPending = true;
                      _saveState(_hasTrainer, true);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solicitud enviada al entrenador. Esperando aprobación.')));
                  },
                  child: const Text('Solicitar Entrenamiento', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      }
    );
  }

  Widget _buildPendingState() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_top, color: Colors.orangeAccent, size: 60),
              const SizedBox(height: 20),
              const Text('Solicitud Pendiente', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('El entrenador Nelvis Rincón está revisando tu solicitud. Recibirás una notificación cuando te acepte y podrás agendar tus horarios.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => setState(() {
                  _requestPending = false;
                  _hasTrainer = true; // Para simular que aceptó en la demo
                }),
                child: const Text('[Demo: Simular Aprobación]', style: TextStyle(color: Colors.white38)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveChat() {
    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF0F192B),
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: Color(0xFF1FAE87), child: Icon(Icons.person, color: Colors.white)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Coach: Nelvis Rincón', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('En línea', style: TextStyle(color: Color(0xFF1FAE87), fontSize: 12)),
                  ],
                ),
                const Spacer(),
                IconButton(icon: const Icon(Icons.calendar_month, color: Colors.white), onPressed: () {}),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _chatBubble('¡Hola! Bienvenido al equipo. Ya revisé tu perfil y la IA me pasó tu historial.', false),
                _chatBubble('Veo que quieres ganar masa muscular. ¿Tienes alguna duda con la rutina de hoy?', false),
                _chatBubble('¡Gracias coach! Todo claro, ya reservé el horario de las 2:00 PM.', true),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF0F192B),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    minLines: 1,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(backgroundColor: const Color(0xFF1FAE87), child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 18), onPressed: () {})),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _chatBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF1FAE87) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
      ),
    );
  }
}
