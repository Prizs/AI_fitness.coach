import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/screens/workout_schedule_screen.dart';
import 'package:mobile_app/screens/user_profile_screen.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': '¡Hola! Soy tu Coach Inteligente. Puedo adaptar tus fases de entrenamiento, diseñar cronogramas para resistencia pulmonar, fuerza o recomposición y modular tu nutrición. ¿En qué objetivo trabajamos hoy?',
      'plan': null,
    }
  ];

  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  final List<String> _quickPrompts = [
    'Mejorar resistencia pulmonar',
    'Registrar entrenamiento completado',
    'Tengo una molestia / cambiar ejercicio',
    'Ajustar plan nutricional',
  ];

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({'isUser': true, 'text': text, 'plan': null});
      _isLoading = true;
    });
    _controller.clear();

    try {
      final baseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:8000');
      final response = await http.post(
        Uri.parse('$baseUrl/api/coach/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': text,
          'user_goal': 'Resistencia Pulmonar',
          'user_level': 'Intermedio',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _messages.add({
            'isUser': false,
            'text': data['reply'] ?? 'Plan actualizado según tus metas.',
            'plan': data['structured_plan'],
            'category': data['category'],
            'rule': data['progression_rule'],
          });
        });
      } else {
        setState(() {
          _messages.add({
            'isUser': false,
            'text': 'Hubo un inconveniente al conectar con el motor IA. Intenta nuevamente.',
            'plan': null,
          });
        });
      }
    } catch (_) {
      setState(() {
        _messages.add({
          'isUser': false,
          'text': 'No se pudo comunicar con el servidor backend.',
          'plan': null,
        });
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        title: const Text('Coach IA & Adaptación', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: const Color(0xFF0F192B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF8BE0C0)),
            tooltip: 'Cronograma Semanal',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WorkoutScheduleScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_rounded, color: Color(0xFF8BE0C0)),
            tooltip: 'Perfil y Salud',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserProfileScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Lista de Mensajes y Tarjetas
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['isUser'] as bool;
                  final text = msg['text'] as String;
                  final plan = msg['plan'] as Map<String, dynamic>?;

                  return Column(
                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isUser ? const Color(0xFF173B45) : const Color(0xFF101B2D),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      ),
                      if (plan != null) ...[
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1E2E),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF8BE0C0), width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.auto_awesome_rounded, color: Color(0xFF8BE0C0)),
                                  const SizedBox(width: 8),
                                  Text(
                                    msg['category'] ?? 'Fase Estructurada',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF8BE0C0)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Regla de progresión: ${msg['rule'] ?? 'Adaptación automática'}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF8BE0C0),
                                        foregroundColor: Colors.black,
                                      ),
                                      icon: const Icon(Icons.add_task_rounded, size: 16),
                                      label: const Text('Agregar a Cronograma', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                                      onPressed: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutScheduleScreen()));
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF173B45), foregroundColor: Colors.white),
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutScheduleScreen()));
                                    },
                                    child: const Text('Ver 3D'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF8BE0C0))),
              ),

            // Píldoras de Preguntas Rápidas
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _quickPrompts.map((p) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor: const Color(0xFF101B2D),
                      label: Text(p, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                      onPressed: () => _sendMessage(p),
                    ),
                  )).toList(),
                ),
              ),
            ),

            // Barra de Entrada de Texto
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF0F192B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Pregunta o pide un objetivo a tu Coach...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF0A0F1D),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF8BE0C0),
                      foregroundColor: const Color(0xFF0B1220),
                    ),
                    icon: const Icon(Icons.send_rounded),
                    onPressed: () => _sendMessage(_controller.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}