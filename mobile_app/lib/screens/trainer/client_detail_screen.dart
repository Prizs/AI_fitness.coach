import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/widgets/performance_report_modal.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ClientDetailScreen extends StatefulWidget {
  final String clientName;
  const ClientDetailScreen({super.key, required this.clientName});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  final TextEditingController _chatController = TextEditingController();
  bool _isLoadingData = true;
  bool _isLoadingAi = false;
  Map<String, dynamic>? _clientData;
  List<dynamic> _daysData = [];

  late stt.SpeechToText _speech;
  bool _isListening = false;

  final List<Map<String, String>> _aiChatHistory = [
    {
      'role': 'ai',
      'text': 'Hola, soy el asistente IA del entrenador. Conozco el historial, lesiones y cronograma de este alumno. ¿Qué deseas consultar o ajustar?'
    }
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _loadClientDetail();
  }

  Future<void> _loadClientDetail() async {
    setState(() => _isLoadingData = true);
    final baseUrl = AuthService.apiBaseUrl;
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/trainer/client-detail/${Uri.encodeComponent(widget.clientName)}'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        if (data is Map && mounted) {
          setState(() {
            _clientData = data['client'];
            _daysData = data['days'] ?? [];
            _isLoadingData = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error cargando detalle del alumno: $e');
    }
    if (mounted) setState(() => _isLoadingData = false);
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done') setState(() => _isListening = false);
        },
        onError: (val) => setState(() => _isListening = false),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _chatController.text = val.recognizedWords;
          }),
          localeId: 'es_ES',
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleName = _clientData?['fullName'] ?? widget.clientName;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        appBar: AppBar(
          title: Text('Ficha: $titleName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
        body: _isLoadingData
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1FAE87)))
            : TabBarView(
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
    final client = _clientData ?? {};
    final bool hasRisk = client['has_risk'] == true;
    final String riskLabel = client['risk_label'] ?? 'Sin lesiones reportadas';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Personal Info Card
        _buildInfoCard(
          title: 'Información Personal',
          icon: Icons.person,
          content: Column(
            children: [
              _infoRow('Nombre Completo', client['fullName'] ?? widget.clientName),
              _infoRow('Cédula de Identidad', client['cedula'] ?? 'No registrada'),
              _infoRow('Edad', '${client['edad'] ?? 25} años'),
              _infoRow('Peso Actual', '${client['peso'] ?? 70.0} kg'),
              _infoRow('Objetivo Principal', client['objetivo'] ?? 'Ganancia Muscular'),
              _infoRow('Alergias Alimentarias', client['alergias'] ?? 'Ninguna'),
              _infoRow('Patologías Médicas', client['patologias'] ?? 'Ninguna'),
              _infoRow('Lesiones o Molestias', client['lesiones'] ?? 'Ninguna'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Health Alert Banner if applicable
        if (hasRisk)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Alerta Física Activa', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(riskLabel, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Progress Card
        _buildInfoCard(
          title: 'Progreso y Consistencia',
          icon: Icons.trending_up,
          content: Column(
            children: [
              _infoRow('Frecuencia de Entrenamiento', client['frecuencia'] ?? '4 días a la semana'),
              _infoRow('Consistencia Mensual', client['consistencia'] ?? '92%'),
              const SizedBox(height: 12),
              const Text('Evolución de Peso Registrada', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${client['peso_inicial'] ?? 68.0} kg', style: const TextStyle(color: Colors.white54, fontSize: 14)),
                  const Icon(Icons.arrow_right_alt, color: Color(0xFF1FAE87), size: 24),
                  Text('${client['peso_actual'] ?? 70.0} kg', style: const TextStyle(color: Color(0xFF1FAE87), fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Performance Report Button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF173B45),
            foregroundColor: const Color(0xFF8BE0C0),
            side: const BorderSide(color: Color(0xFF8BE0C0), width: 1.2),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: const Icon(Icons.assessment_rounded, size: 22),
          label: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ver Reporte Detallado de Rendimiento (ACSM)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              Icon(Icons.arrow_forward_ios_rounded, size: 14),
            ],
          ),
          onPressed: () => PerformanceReportModal.show(context, clientName: widget.clientName),
        ),
      ],
    );
  }

  Widget _buildEntrenamientoTab() {
    if (_daysData.isEmpty) {
      return const Center(child: Text('Sin cronograma cargado.', style: TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _daysData.length,
      itemBuilder: (context, dayIdx) {
        final day = _daysData[dayIdx];
        final dayName = day['day_name'] ?? 'Día ${dayIdx + 1}';
        final title = day['title'] ?? 'Rutina';
        final exercises = (day['exercises'] as List<dynamic>?) ?? [];

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
                    Text(
                      '$dayName · $title',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1FAE87).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${exercises.length} ejercicios',
                        style: const TextStyle(color: Color(0xFF1FAE87), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white12, height: 20),
                ...exercises.map((ex) {
                  final exName = ex['name'] ?? 'Ejercicio';
                  final sets = ex['sets'] ?? 3;
                  final reps = ex['reps'] ?? '10-12';
                  final muscle = ex['primary_muscle'] ?? 'General';
                  final biomech = ex['biomechanics'] ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F192B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(exName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            Text('$sets x $reps', style: const TextStyle(color: Color(0xFF1FAE87), fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('Músculo: $muscle', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                        if (biomech.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text('💡 $biomech', style: const TextStyle(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic)),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNutricionTab() {
    if (_daysData.isEmpty) {
      return const Center(child: Text('Sin plan de nutrición cargado.', style: TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _daysData.length,
      itemBuilder: (context, dayIdx) {
        final day = _daysData[dayIdx];
        final dayName = day['day_name'] ?? 'Día ${dayIdx + 1}';
        final nut = day['nutrition'] as Map<String, dynamic>? ?? {};

        return Card(
          color: const Color(0xFF1E293B),
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.restaurant_rounded, color: Color(0xFF1FAE87), size: 18),
                    const SizedBox(width: 8),
                    Text('$dayName · Menú Nutricional', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const Divider(color: Colors.white12, height: 16),
                if (nut['desayuno'] != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text('🍳 Desayuno: ${nut['desayuno']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
                if (nut['almuerzo'] != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text('🍛 Almuerzo: ${nut['almuerzo']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
                if (nut['merienda'] != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text('🥪 Merienda: ${nut['merienda']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
                if (nut['cena'] != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text('🍲 Cena: ${nut['cena']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAiTab() {
    final client = _clientData ?? {};

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1FAE87).withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.auto_graph, color: Color(0xFF1FAE87)),
                        SizedBox(width: 8),
                        Text('Resumen Clínico para Entrenador', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildAiTip('Objetivo', client['objetivo'] ?? 'Ganancia Muscular'),
                    _buildAiTip('Estado Físico / Lesiones', client['lesiones'] ?? 'Sin lesiones reportadas'),
                    _buildAiTip('Nutrición & Alergias', client['alergias'] ?? 'Ninguna'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Consultoría con el Coach IA', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              ..._aiChatHistory.map((msg) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: msg['role'] == 'ai' ? MainAxisAlignment.start : MainAxisAlignment.end,
                      children: [
                        if (msg['role'] == 'ai')
                          const CircleAvatar(
                            radius: 14,
                            backgroundColor: Color(0xFF1FAE87),
                            child: Icon(Icons.smart_toy, size: 16, color: Colors.white),
                          ),
                        if (msg['role'] == 'ai') const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: msg['role'] == 'ai' ? const Color(0xFF1E293B) : const Color(0xFF107055),
                              borderRadius: BorderRadius.circular(12),
                              border: msg['role'] == 'ai' ? Border.all(color: const Color(0xFF1FAE87).withOpacity(0.3)) : null,
                            ),
                            child: Text(msg['text']!, style: const TextStyle(color: Colors.white, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  )),
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
              IconButton(
                icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.redAccent : const Color(0xFF1FAE87)),
                onPressed: _listen,
              ),
              Expanded(
                child: TextField(
                  controller: _chatController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Pregunta al coach sobre este alumno...',
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
                  icon: _isLoadingAi
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send, color: Colors.white, size: 18),
                  onPressed: _isLoadingAi ? null : _sendMessageToAi,
                ),
              )
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
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required Widget content}) {
    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1FAE87), size: 20),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 14),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildAiTip(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Color(0xFF1FAE87), fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 2),
            Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessageToAi() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _isLoadingAi) return;

    final client = _clientData ?? {};
    final clientName = client['fullName'] ?? widget.clientName;

    setState(() {
      _aiChatHistory.add({'role': 'trainer', 'text': text});
      _chatController.clear();
      _isLoadingAi = true;
    });

    final baseUrl = AuthService.apiBaseUrl;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/coach/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': 'Soy el entrenador personal de $clientName. Te consulto sobre su rutina y salud: $text',
          'history': _aiChatHistory
              .where((msg) => msg['text'] != text)
              .map((msg) => {
                    'role': msg['role'] == 'trainer' ? 'user' : 'assistant',
                    'content': msg['text']
                  })
              .toList(),
          'user_goal': client['objetivo'] ?? 'Ganancia muscular',
          'allergies': client['alergias'] ?? 'Ninguna',
          'injuries': client['lesiones'] ?? 'Ninguna',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (mounted) {
          setState(() {
            _aiChatHistory.add({
              'role': 'ai',
              'text': data['response'] ?? 'Entendido. Como recomendación técnica, mantén la supervisión del rango articular.'
            });
          });
        }
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiChatHistory.add({'role': 'ai', 'text': 'El asistente IA no pudo responder en este momento. Revisa la conexión al servidor.'});
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAi = false;
        });
      }
    }
  }
}
