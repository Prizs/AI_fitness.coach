import 'package:mobile_app/services/weekly_plan_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/screens/workout_schedule_screen.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:lottie/lottie.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:mobile_app/models/anatomy_exercise.dart';
import 'package:mobile_app/screens/anatomy_workout_screen.dart';
import 'package:mobile_app/widgets/plan_options_sheet.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': '¡Hola! Soy tu Coach Inteligente. Puedo adaptar tus fases de entrenamiento, diseñar cronogramas para fuerza, resistencia o recomposición y modular tu nutrición. Para calibrar tu entrenamiento con máxima precisión, por favor completa tu estado actual.',
      'isWelcome': true,
      'plan': null,
    }
  ];

  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  
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
            _controller.text = val.recognizedWords;
          }),
          localeId: 'es_ES', // Español
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _openStateSheet([String initialPrompt = '']) {
    showPlanOptionsSheet(
      context,
      initialPrompt: initialPrompt,
      onSendState: (summary) => _sendMessage(summary),
    );
  }

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
      
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      final formatDate = (DateTime d) => '${d.day}/${d.month}/${d.year}';
      final hasPlan = WeeklyPlanService.instance.week != null;
      final startStr = hasPlan ? formatDate(monday) : null;
      final endStr = hasPlan ? formatDate(sunday) : null;

      const storage = FlutterSecureStorage();
      final userKey = 'user_equipment_${profile?.cedula ?? "default"}';
      final savedEquipment = await storage.read(key: userKey) ?? await storage.read(key: 'user_equipment');

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
              'areas_to_avoid': profile?.areasToAvoid,
              'age': profile?.age,
              'weight': profile?.weight,
              'active_plan_start': startStr,
              'active_plan_end': endStr,
              'equipment_details': savedEquipment,
            }),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (data['extracted_equipment'] != null &&
            data['extracted_equipment'].toString().isNotEmpty &&
            data['extracted_equipment'].toString() != 'null') {
          final eqStr = data['extracted_equipment'].toString();
          await storage.write(key: userKey, value: eqStr);
          await storage.write(key: 'user_equipment', value: eqStr);
        }

        final replyText = (data['reply'] ?? 'Sin respuesta del Coach.').toString();
        final lowerUser = text.toLowerCase();
        final lowerReply = replyText.toLowerCase();

        final isAskingState = lowerUser.contains('estado actual') ||
            lowerUser.contains('cuestionario') ||
            lowerUser.contains('formulario') ||
            lowerUser.contains('me equivoque') ||
            lowerUser.contains('me equivoqué') ||
            lowerUser.contains('llenar de nuevo') ||
            lowerUser.contains('volver a llenar');

        final aiSuggestsState = data['suggest_questionnaire'] == true ||
            lowerReply.contains('completar mi estado actual') ||
            lowerReply.contains('completa tu estado actual') ||
            lowerReply.contains('indicarme tu estado actual');

        final showStateBtn = isAskingState || aiSuggestsState;

        setState(() {
          _messages.add({
            'isUser': false,
            'text': replyText,
            'plan': data['has_plan'] == true ? data['structured_plan'] : null,
            'category': data['category'],
            'rule': data['progression_rule'],
            'suggest_questionnaire': showStateBtn,
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
            icon: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF8BE0C0)),
            tooltip: 'Enviar Estado Actual',
            onPressed: () => _openStateSheet(),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: Colors.white70),
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
                      if (msg['suggest_questionnaire'] == true || msg['isWelcome'] == true) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF173B45),
                              foregroundColor: const Color(0xFF8BE0C0),
                              side: const BorderSide(color: Color(0xFF8BE0C0), width: 1.2),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.assignment_turned_in_rounded, size: 18),
                            label: const Text('📋 Completar Mi Estado Actual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            onPressed: () => _openStateSheet(),
                          ),
                        ),
                      ],
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
                                  const Icon(Icons.fitness_center_rounded, color: Color(0xFF8BE0C0), size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      plan['title'] ?? msg['category'] ?? 'Rutina y Plan Alimenticio',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF8BE0C0)),
                                    ),
                                  ),
                                ],
                              ),
                              if (msg['rule'] != null) ...[
                                const SizedBox(height: 6),
                                Text('Regla de progresión: ${msg['rule']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                              
                              // Listado de Ejercicios
                              if (plan['exercises'] is List && (plan['exercises'] as List).isNotEmpty) ...[
                                const SizedBox(height: 14),
                                const Text('🏋️ Ejercicios Recomendados:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 8),
                                ...(plan['exercises'] as List).take(5).map((ex) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16253B),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF8BE0C0), size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            ex['name'] ?? 'Ejercicio',
                                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1F3A4B),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${ex['sets'] ?? 3} × ${ex['reps'] ?? '12'}',
                                            style: const TextStyle(color: Color(0xFF8BE0C0), fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],

                              // Plan Nutricional
                              if (plan['nutrition'] is Map && (plan['nutrition'] as Map).isNotEmpty) ...[
                                const SizedBox(height: 14),
                                const Text('🥗 Plan Alimenticio Recomendado:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16253B),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if ((plan['nutrition'] as Map)['desayuno'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: Text('🍳 Desayuno: ${(plan['nutrition'] as Map)['desayuno']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                        ),
                                      if ((plan['nutrition'] as Map)['almuerzo'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: Text('🍛 Almuerzo: ${(plan['nutrition'] as Map)['almuerzo']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                        ),
                                      if ((plan['nutrition'] as Map)['cena'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 2),
                                          child: Text('🍲 Cena: ${(plan['nutrition'] as Map)['cena']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                        ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF8BE0C0),
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      icon: const Icon(Icons.bookmark_add_rounded, size: 16),
                                      label: const Text('Agregar a Cronograma y Nutrición', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                                      onPressed: () async {
                                        await WeeklyPlanService.instance.injectCustomPlanForToday(plan);
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('✅ ¡Rutina y Nutrición agregadas a tu semana con éxito!'),
                                            backgroundColor: Color(0xFF1B4D3E),
                                            behavior: SnackBarBehavior.floating,
                                            duration: Duration(seconds: 4),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF173B45),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () async {
                                      List<AnatomyExercise> dyn = [];
                                      if (plan['exercises'] != null) {
                                        for (var ex in plan['exercises']) {
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
                                    child: const Text('Ver 3D', style: TextStyle(fontSize: 12)),
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
                        backgroundColor: _isListening ? Colors.redAccent : const Color(0xFF2A3A4A),
                        foregroundColor: _isListening ? Colors.white : Colors.white54,
                        minimumSize: const Size(48, 48),
                      ),
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                      onPressed: _listen,
                    ),
                    const SizedBox(width: 4),
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

