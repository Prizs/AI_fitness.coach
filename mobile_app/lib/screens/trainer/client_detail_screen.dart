import 'package:mobile_app/widgets/performance_report_modal.dart';
import 'package:mobile_app/services/weekly_plan_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile_app/services/auth_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ClientDetailScreen extends StatefulWidget {
  final String clientName;
  const ClientDetailScreen({super.key, required this.clientName});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  final TextEditingController _chatController = TextEditingController();
  bool _isLoadingAi = false;
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
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
        const SizedBox(height: 16),

        // Botón de Reporte Detallado de Rendimiento para el Entrenador
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
              Text('Ver Reporte Detallado de Rendimiento', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              Icon(Icons.arrow_forward_ios_rounded, size: 14),
            ],
          ),
          onPressed: () => PerformanceReportModal.show(context, clientName: widget.clientName),
        ),
      ],
    );
  }

  Widget _buildEntrenamientoTab() {
    final service = WeeklyPlanService.instance;
    final days = service.days;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Cronograma del Alumno', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1FAE87).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1FAE87)),
              ),
              child: const Text('Vigente / En Curso', style: TextStyle(color: Color(0xFF1FAE87), fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Alerta de Chequeo
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2D1515),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
          ),
          child: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Estado Reportado: El alumno completó su cuestionario de estado actual. Revisa los ejercicios y cargas antes de iniciar.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (days.isEmpty) ...[
          _buildInfoCard(
            title: 'Sin Rutina Sincronizada',
            icon: Icons.info_outline,
            content: const Text(
              'El alumno aún no ha sincronizado un cronograma semanal con el Coach IA.',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ] else ...[
          ...days.map((day) {
            final dayTitle = day['title'] ?? 'Sesión';
            final dayExercises = (day['exercises'] as List?) ?? [];
            final weekdayName = day['weekday'] is int && day['weekday'] >= 0 && day['weekday'] < 7
                ? ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'][day['weekday']]
                : 'Día';

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
                        const Icon(Icons.fitness_center_rounded, color: Color(0xFF1FAE87), size: 20),
                        const SizedBox(width: 8),
                        Text('$weekdayName · $dayTitle', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 20),
                    if (dayExercises.isEmpty)
                      const Text('Día de descanso o recuperación activa.', style: TextStyle(color: Colors.white54, fontSize: 13, fontStyle: FontStyle.italic))
                    else
                      ...dayExercises.map((ex) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, color: Color(0xFF1FAE87), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(ex['name'] ?? 'Ejercicio', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              ),
                              Text('${ex['sets'] ?? 3}x${ex['reps'] ?? 12}', style: const TextStyle(color: Color(0xFF1FAE87), fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildNutricionTab() {
    final service = WeeklyPlanService.instance;
    final days = service.days;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Plan Nutricional del Alumno', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (days.isEmpty) ...[
          _buildInfoCard(
            title: 'Sin Plan Nutricional Activo',
            icon: Icons.restaurant,
            content: const Text('El alumno aún no tiene un menú registrado esta semana.', style: TextStyle(color: Colors.white70)),
          ),
        ] else ...[
          ...days.where((d) {
            final nut = d['nutrition'];
            if (nut is Map) return nut.isNotEmpty;
            if (nut is List) return nut.isNotEmpty;
            return false;
          }).map((d) {
            final nut = d['nutrition'];
            final weekdayName = d['weekday'] is int && d['weekday'] >= 0 && d['weekday'] < 7
                ? ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'][d['weekday']]
                : 'Día';

            final List<Widget> mealWidgets = [];
            if (nut is Map) {
              if (nut['desayuno'] != null) {
                mealWidgets.add(Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('🍳 Desayuno: ${nut['desayuno']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ));
              }
              if (nut['almuerzo'] != null) {
                mealWidgets.add(Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('🍛 Almuerzo: ${nut['almuerzo']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ));
              }
              if (nut['cena'] != null) {
                mealWidgets.add(Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('🍲 Cena: ${nut['cena']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ));
              }
              nut.forEach((k, v) {
                final keyLower = k.toString().toLowerCase();
                if (keyLower != 'desayuno' && keyLower != 'almuerzo' && keyLower != 'cena') {
                  mealWidgets.add(Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('🥗 ${k.toString()}: $v', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ));
                }
              });
            } else if (nut is List) {
              for (final m in nut) {
                if (m is Map) {
                  final title = m['title'] ?? 'Comida';
                  final items = (m['items'] as List<dynamic>?)?.join(', ') ?? '';
                  mealWidgets.add(Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('🍽️ $title: $items', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ));
                }
              }
            }

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
                        Text('$weekdayName · Menú Recomendado', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 16),
                    ...mealWidgets,
                  ],
                ),
              ),
            );
          }),
        ],
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
