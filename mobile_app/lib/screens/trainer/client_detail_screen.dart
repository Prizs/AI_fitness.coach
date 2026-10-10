import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile_app/services/auth_service.dart';

class ClientDetailScreen extends StatefulWidget {
  final String clientName;
  const ClientDetailScreen({super.key, required this.clientName});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  final TextEditingController _chatController = TextEditingController();
  bool _isLoadingAi = false;
  final List<Map<String, String>> _aiChatHistory = [
    {'role': 'ai', 'text': 'Hola, soy el asistente IA. Puedes preguntarme sobre la biografía, lesiones, o pedirme que adapte la rutina de este alumno.'}
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        appBar: AppBar(
          title: Text('Ficha: ', style: const TextStyle(fontWeight: FontWeight.bold)),
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
              Tab(text: 'Análisis IA & Chat'),
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
              _infoRow('Alergias', 'Intolerante a la lactosa'),
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
              const Text('Evolución de Peso (íšltimas 4 semanas)', style: TextStyle(color: Colors.white70, fontSize: 13)),
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
              const Text('Alerta Pre-Entreno:', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('El alumno reportó fatiga en la rodilla derecha esta mañana. Recomiendo calentamiento articular extra.', style: TextStyle(color: Colors.orangeAccent, fontStyle: FontStyle.italic)),
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
              const Text('Sugerencia para hoy (Sin Lactosa):', style: TextStyle(color: Color(0xFF1FAE87), fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Batido de proteína vegana post-entrenamiento con plátano.', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAiTab() {
    return Column(
      children: [
        Expanded(
          flex: 4,
          child: ListView(
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
                        Icon(Icons.auto_graph, color: Color(0xFF1FAE87)),
                        SizedBox(width: 8),
                        Text('Resumen de Rendimiento', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildAiTip('Físico', 'Excelente progresión de cargas en tren inferior. Adaptación al volumen: í“ptima.'),
                    _buildAiTip('Riesgos Detectados', 'Reporte de molestias en rodilla derecha. Se sustituyó sentadilla libre por prensa hoy.'),
                    _buildAiTip('Nutrición', 'Cumplimiento del 90%. Alergia a lactosa mitigada correctamente en los menús.'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Consultoría IA con el Entrenador', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              // Chat AI History
              ..._aiChatHistory.map((msg) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: msg['role'] == 'ai' ? MainAxisAlignment.start : MainAxisAlignment.end,
                  children: [
                    if (msg['role'] == 'ai') const CircleAvatar(radius: 14, backgroundColor: Color(0xFF1FAE87), child: Icon(Icons.smart_toy, size: 16, color: Colors.white)),
                    if (msg['role'] == 'ai') const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: msg['role'] == 'ai' ? const Color(0xFF1E293B) : const Color(0xFF2C3E50),
                          borderRadius: BorderRadius.circular(12),
                          border: msg['role'] == 'ai' ? Border.all(color: const Color(0xFF1FAE87).withOpacity(0.3)) : null,
                        ),
                        child: Text(msg['text']!, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ),
        ),
        // Chat Input Field
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF0F192B),
            border: Border(top: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  minLines: 1,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Ej: Â¿Qué calentamiento específico recomiendas hoy?',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: const Color(0xFF1FAE87),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                  onPressed: _sendMessageToAi,
                ),
              )
            ],
          ),
        )
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

  Future<void> _sendMessageToAi() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _isLoadingAi) return;

    setState(() {
      _aiChatHistory.add({'role': 'trainer', 'text': text});
      _chatController.clear();
      _isLoadingAi = true;
    });

    try {
      final response = await http.post(
        Uri.parse('\/api/coach/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
        'message': 'Soy el entrenador de este alumno. Te consulto sobre él: ',
        'history': _aiChatHistory
            .where((msg) => msg['role'] != 'trainer' || msg['text'] != text) // Excluir el reciÃ©n aÃ±adido para el historial previo si es necesario o formatearlo bien
            .map((msg) => {
                  'role': msg['role'] == 'trainer' ? 'user' : 'assistant',
                  'content': msg['text']
                })
            .toList(),
        'user_goal': 'Ganancia Muscular',
        'allergies': 'Intolerante a la lactosa',
        'injuries': 'Molestia en rodilla derecha reportada hoy',
      }));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _aiChatHistory.add({
            'role': 'ai', 
            'text': data['response'] ?? 'Sin respuesta de la IA'
          });
        });
      } else {
        throw Exception('Error del servidor');
      }
    } catch (e) {
      setState(() {
        _aiChatHistory.add({'role': 'ai', 'text': 'Error de conexión con la IA.'});
      });
    } finally {
      setState(() {
        _isLoadingAi = false;
      });
    }
  }
}
