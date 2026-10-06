import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/screens/workout_schedule_screen.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile_app/models/anatomy_exercise.dart';
import 'package:mobile_app/screens/anatomy_workout_screen.dart';

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

    final history = _messages
        .where((m) => (m['text'] as String?)?.isNotEmpty ?? false)
        .map((m) => {
              'role': (m['isUser'] as bool) ? 'user' : 'assistant',
              'content': m['text'] as String,
            })
        .toList();

    try {
      final baseUrl = AuthService.apiBaseUrl;
      final profile = AuthService.instance.loggedInUser;
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/coach/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': text,
              'history': history,
              'user_goal': 'Rendimiento general',
              'user_level': 'Intermedio',
              'allergies': profile?.foodAllergies,
              'injuries': profile?.currentInjuries,
              'motor_disability': profile?.motorDisability,
              'areas_to_avoid': profile?.areasToAvoid, 'age': profile?.age, 'weight': profile?.weight,
            }),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _messages.add({
            'isUser': false,
            'text': data['reply'] ?? 'Sin respuesta del Coach.',
            'plan': data['has_plan'] == true ? data['structured_plan'] : null,
            'category': data['category'],
            'rule': data['progression_rule'],
          });
        });
      } else {
        String detail =
            'El motor IA respondió con un error (${response.statusCode}).';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody['detail'] is String) {
            detail = errorBody['detail'] as String;
          }
        } catch (_) {}
        setState(() {
          _messages.add({
            'isUser': false,
            'text': detail,
            'plan': null,
          });
        });
      }
    } catch (error) {
      setState(() {
        _messages.add({
          'isUser': false,
          'text': 'No se pudo comunicar con el servidor backend (${error.runtimeType}).',
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

                                    onPressed: () async {
                                      List<AnatomyExercise> dyn = [];
                                      if (plan != null && plan['exercises'] != null) {
                                        for (var ex in plan['exercises']) {
                                          // fetch from api
                                          try {
                                            final res = await http.get(Uri.parse(AuthService.apiBaseUrl + '/api/exercises/gif?query=' + Uri.encodeComponent(ex['name'])));
                                            if (res.statusCode == 200) {
                                              final url = jsonDecode(res.body)['url'];
                                              dyn.add(AnatomyExercise(
                                                id: ex['name'],
                                                name: ex['name'],
                                                shortName: ex['name'],
                                                gifUrl: url ?? '',
                                                agonist: ex['primary_muscle'] ?? 'Músculo Principal',
                                                synergists: [ex['secondary_muscle'] ?? 'Sinergistas'],
                                                biomechanics: 'Activación dinámica sugerida por IA.',
                                                tempo: '3-1-1',
                                                posture: 'Mantén la postura natural.',
                                                warning: 'Consulta a tu entrenador si sientes dolor.'
                                              ));
                                            }
                                          } catch (e) {}
                                        }
                                      }
                                      if (!context.mounted) return;
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => AnatomyWorkoutScreen(
                                        dynamicExercises: dyn.isNotEmpty ? dyn : null,
                                      )));
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Lottie.network(
                          'https://assets9.lottiefiles.com/packages/lf20_1idq1nbf.json', // Placeholder de animaciÃƒÂ³n
                          errorBuilder: (context, error, stackTrace) => const CircularProgressIndicator(color: Color(0xFF8BE0C0)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('La IA está estructurando tu plan...', style: TextStyle(color: Color(0xFF8BE0C0), fontSize: 12)),
                    ],
                  ),
                ),
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

            // Barra de entrada: el cuadro crece hacia abajo al escribir y
            // empuja los mensajes hacia arriba para poder leerlos.
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
              decoration: const BoxDecoration(
                color: Color(0xFF0F192B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: _controller.text.isEmpty
                              ? 'Escribe tu pregunta...'
                              : null,
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: const Color(0xFF0A0F1D),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: _controller.text.trim().isEmpty
                          ? const Color(0xFF2A3A4A)
                          : const Color(0xFF8BE0C0),
                      foregroundColor: const Color(0xFF0B1220),
                      minimumSize: const Size(48, 48),
                    ),
                    icon: const Icon(Icons.send_rounded),
                    onPressed: _controller.text.trim().isEmpty
                        ? null
                        : () => _sendMessage(_controller.text),
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

