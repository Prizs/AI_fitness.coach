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
  String _userLevel = 'Principiante';
  String _userIntensity = 'Baja';
  
  late stt.SpeechToText _speech;
  bool _isListening = false;
  
  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    final prefLvl = WeeklyPlanService.instance.userLevel;
    if (prefLvl.isNotEmpty) _userLevel = prefLvl;
    final prefInt = WeeklyPlanService.instance.userIntensity;
    if (prefInt.isNotEmpty) _userIntensity = prefInt;
    WeeklyPlanService.instance.addListener(_onWeeklyPlanUpdated);
  }

  void _onWeeklyPlanUpdated() {
    if (mounted) {
      setState(() {
        _userLevel = WeeklyPlanService.instance.userLevel;
        _userIntensity = WeeklyPlanService.instance.userIntensity;
      });
    }
  }

  @override
  void dispose() {
    WeeklyPlanService.instance.removeListener(_onWeeklyPlanUpdated);
    _controller.dispose();
    super.dispose();
  }
  
  void _listen() async {
    if (_isListening) {
      setState(() => _isListening = false);
      _speech.stop();
      return;
    }

    try {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (val) {
          if (mounted) setState(() => _isListening = false);
        },
      );
      if (available) {
        if (mounted) setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _controller.text = val.recognizedWords;
          }),
          localeId: 'es_ES', // Español
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Permiso de micrófono no habilitado o no soportado en tu navegador.'),
              backgroundColor: Color(0xFF332020),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isListening = false);
    }
  }

  void _openStateSheet([String initialPrompt = '']) {
    showPlanOptionsSheet(
      context,
      initialPrompt: initialPrompt,
      initialIntensity: _userIntensity,
      initialLevel: _userLevel,
      onPreferenceChanged: (lvl, intn) {
        setState(() {
          _userLevel = lvl;
          _userIntensity = intn;
        });
      },
      onSendState: (summary) => _sendMessage(summary),
    );
  }

  Map<String, dynamic>? _sanitizeClientPlan(dynamic rawPlan, String userMsg) {
    if (rawPlan is! Map) return null;
    final plan = Map<String, dynamic>.from(rawPlan);
    final msgLower = userMsg.toLowerCase();
    final isCompRequest = msgLower.contains('martes y jueves') ||
        msgLower.contains('días intermedios') ||
        msgLower.contains('dias intermedios') ||
        msgLower.contains('relacionarlo con') ||
        msgLower.contains('rutina complementaria');

    String? compFocus;
    if (msgLower.contains('tren superior') || msgLower.contains('espalda, pecho')) {
      compFocus = 'tren_superior';
    } else if (msgLower.contains('movilidad') || msgLower.contains('cardio suave')) {
      compFocus = 'movilidad_cardio';
    } else if (msgLower.contains('core') || msgLower.contains('abdomen') || msgLower.contains('estabilidad')) {
      compFocus = 'core';
    }

    if (isCompRequest && compFocus != null) {
      plan['is_complementary_days'] = true;
      plan['recommended_days'] = ['Martes', 'Jueves'];
      final String intBadge = _userIntensity.toLowerCase() == 'baja'
          ? 'Básico (Intensidad Baja)'
          : (_userIntensity.toLowerCase() == 'alta' ? 'Avanzado (Intensidad Alta)' : 'Intermedio (Intensidad Media)');

      if (compFocus == 'tren_superior') {
        plan['title'] = 'Rutina Complementaria: Tren Superior ($_userLevel · Intensidad $_userIntensity)';
      } else if (compFocus == 'core') {
        plan['title'] = 'Rutina Complementaria: Core, Abdomen y Postura ($_userLevel · Intensidad $_userIntensity)';
      } else if (compFocus == 'movilidad_cardio') {
        plan['title'] = 'Rutina Complementaria: Movilidad y Cardio Suave ($_userLevel · Intensidad $_userIntensity)';
      }

      final List<Map<String, dynamic>> fallbackPool = compFocus == 'tren_superior'
          ? [
              {'name': 'Flexiones inclinadas con apoyo en banco o pared', 'sets': 3, 'reps': '10-12', 'primary_muscle': 'Pectorales, Deltoides', 'secondary_muscle': 'Tríceps, Core', 'intensity_level': intBadge},
              {'name': 'Remo sentado con banda elástica o tracción controlada', 'sets': 3, 'reps': '12', 'primary_muscle': 'Espalda Media, Dorsales', 'secondary_muscle': 'Bíceps', 'intensity_level': intBadge},
              {'name': 'Press de hombros sentado controlado', 'sets': 3, 'reps': '10-12', 'primary_muscle': 'Hombros (Deltoides)', 'secondary_muscle': 'Tríceps', 'intensity_level': intBadge},
              {'name': 'Elevaciones laterales suaves de hombros', 'sets': 3, 'reps': '12-15', 'primary_muscle': 'Deltoides Lateral', 'secondary_muscle': 'Trapecio', 'intensity_level': intBadge},
              {'name': 'Curl de bíceps controlado sin impulso', 'sets': 3, 'reps': '12', 'primary_muscle': 'Bíceps Braquial', 'secondary_muscle': 'Antebrazo', 'intensity_level': intBadge},
            ]
          : compFocus == 'core'
              ? [
                  {'name': 'Dead Bug / Estabilización lumbopélvica en suelo', 'sets': 3, 'reps': '10 por lado', 'primary_muscle': 'Core Profundo, Transverso', 'secondary_muscle': 'Zona Lumbar', 'intensity_level': intBadge},
                  {'name': 'Plancha abdominal controlada', 'sets': 3, 'reps': '30 seg', 'primary_muscle': 'Abdomen, Core', 'secondary_muscle': 'Hombros, Glúteos', 'intensity_level': intBadge},
                  {'name': 'Crunch abdominal corto controlado en suelo', 'sets': 3, 'reps': '12-15', 'primary_muscle': 'Recto Abdominal', 'secondary_muscle': 'Oblicuos', 'intensity_level': intBadge},
                  {'name': 'Remo postural con retracción escapular', 'sets': 3, 'reps': '12', 'primary_muscle': 'Espalda Media, Postura', 'secondary_muscle': 'Romboides', 'intensity_level': intBadge},
                ]
              : [
                  {'name': 'Bicicleta estática o marcha suave sin impacto (Zona 2)', 'sets': 1, 'reps': '15 min', 'primary_muscle': 'Sistema Cardiovascular, Movilidad', 'secondary_muscle': 'Recuperación Activa', 'intensity_level': intBadge},
                  {'name': 'Dead Bug respiratorio de movilidad lumbopélvica', 'sets': 3, 'reps': '10 lentas', 'primary_muscle': 'Core, Movilidad de Cadera y Hombro', 'secondary_muscle': 'Columna Lumbar', 'intensity_level': intBadge},
                  {'name': 'Movilidad escapular y tracción suave con banda', 'sets': 3, 'reps': '12-15', 'primary_muscle': 'Movilidad Torácica, Espalda Alta', 'secondary_muscle': 'Deltoides Posterior', 'intensity_level': intBadge},
                  {'name': 'Plancha suave de activación postural', 'sets': 3, 'reps': '25 seg', 'primary_muscle': 'Core, Estabilidad Articular', 'secondary_muscle': 'Cintura Escapular', 'intensity_level': intBadge},
                ];

      final rawExList = plan['exercises'];
      if (rawExList is List && rawExList.isNotEmpty) {
        final List<Map<String, dynamic>> cleaned = [];
        for (int i = 0; i < rawExList.length; i++) {
          final item = rawExList[i] is Map ? Map<String, dynamic>.from(rawExList[i]) : <String, dynamic>{};
          final exText = '${item['name'] ?? ''} ${item['primary_muscle'] ?? ''}'.toLowerCase();
          final isLegEx = exText.contains('sentadilla') ||
              exText.contains('squat') ||
              exText.contains('puente de gl') ||
              exText.contains('glute bridge') ||
              exText.contains('zancada') ||
              exText.contains('lunge') ||
              exText.contains('talones') ||
              exText.contains('gemelo') ||
              exText.contains('cuádriceps') ||
              exText.contains('cuadriceps') ||
              exText.contains('isquiotibial') ||
              exText.contains('abducción de cadera');
          if (isLegEx) {
            cleaned.add(Map<String, dynamic>.from(fallbackPool[i % fallbackPool.length]));
          } else {
            item['intensity_level'] = item['intensity_level'] ?? intBadge;
            cleaned.add(item);
          }
        }
        plan['exercises'] = cleaned;
      } else {
        plan['exercises'] = fallbackPool;
      }
    }
    return plan;
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final lowerUser = text.toLowerCase();
    if (lowerUser.contains('novato') || lowerUser.contains('principiante')) {
      _userLevel = 'Principiante';
    } else if (lowerUser.contains('avanzado')) {
      _userLevel = 'Avanzado';
    } else if (lowerUser.contains('intermedio')) {
      _userLevel = 'Intermedio';
    }

    if (lowerUser.contains('intensidad deseada: baja') ||
        lowerUser.contains('intensidad baja') ||
        lowerUser.contains('intensidad bajo') ||
        lowerUser.contains('suave')) {
      _userIntensity = 'Baja';
    } else if (lowerUser.contains('intensidad deseada: alta') ||
        lowerUser.contains('intensidad alta') ||
        lowerUser.contains('intenso')) {
      _userIntensity = 'Alta';
    } else if (lowerUser.contains('intensidad deseada: media') ||
        lowerUser.contains('intensidad media') ||
        lowerUser.contains('moderada')) {
      _userIntensity = 'Media';
    }

    final isSubmission = lowerUser.contains('mi estado actual para la sesión') ||
        lowerUser.contains('mi estado actual para la sesion') ||
        lowerUser.contains('📋 mi estado actual') ||
        lowerUser.contains('me impide entrenar') ||
        lowerUser.contains('descanso total') ||
        lowerUser.contains('reporte de descanso') ||
        (lowerUser.contains('estado físico:') && (lowerUser.contains('equipo disponible:') || lowerUser.contains('motivo') || lowerUser.contains('decisión'))) ||
        (lowerUser.contains('estado fisico:') && (lowerUser.contains('equipo disponible:') || lowerUser.contains('motivo') || lowerUser.contains('decision')));

    setState(() {
      if (isSubmission) {
        for (var m in _messages) {
          m['suggest_questionnaire'] = false;
        }
      }
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
      final nextMonday = monday.add(const Duration(days: 7));
      final formatDate = (DateTime d) => '${d.day}/${d.month}/${d.year}';
      final hasPlan = WeeklyPlanService.instance.hasActivePlan;
      final startStr = hasPlan ? formatDate(monday) : null;
      final endStr = hasPlan ? formatDate(sunday) : null;
      final nextStartStr = hasPlan ? formatDate(nextMonday) : null;
      final activeDays = hasPlan ? WeeklyPlanService.instance.activeTrainingDayNames : <String>[];

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
              'user_goal': WeeklyPlanService.instance.userGoal,
              'user_level': _userLevel,
              'user_intensity': _userIntensity,
              'user_streak': WeeklyPlanService.instance.currentStreak,
              'total_completed_sessions': WeeklyPlanService.instance.totalCompletedSessions,
              'rpe_feedback': WeeklyPlanService.instance.lastRpe,
              'allergies': profile?.foodAllergies,
              'injuries': profile?.currentInjuries,
              'motor_disability': profile?.motorDisability,
              'areas_to_avoid': profile?.areasToAvoid,
              'age': profile?.age,
              'weight': profile?.weight,
              'active_plan_start': startStr,
              'active_plan_end': endStr,
              'next_cycle_start': nextStartStr,
              'active_training_days': activeDays,
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
        final bool showStateBtn = !isSubmission && data['suggest_questionnaire'] == true;

        setState(() {
          _messages.add({
            'isUser': false,
            'text': replyText,
            'plan': data['has_plan'] == true ? _sanitizeClientPlan(data['structured_plan'], text) : null,
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
            // Barra interactiva de Categorización de Nivel e Intensidad
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF0F192B),
                border: Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Icon(Icons.tune_rounded, size: 15, color: Color(0xFF8BE0C0)),
                    const SizedBox(width: 6),
                    const Text('Categoría:', style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    ...[
                      {'label': '🟢 Básico (Baja)', 'level': 'Principiante', 'intensity': 'Baja', 'color': const Color(0xFF8BE0C0)},
                      {'label': '🟠 Intermedio (Media)', 'level': 'Intermedio', 'intensity': 'Media', 'color': const Color(0xFFFFB340)},
                      {'label': '🔴 Avanzado (Alta)', 'level': 'Avanzado', 'intensity': 'Alta', 'color': const Color(0xFFFF6B6B)},
                    ].map((tier) {
                      final bool isSelected = _userIntensity.toLowerCase() == (tier['intensity'] as String).toLowerCase();
                      final Color tierColor = tier['color'] as Color;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            setState(() {
                              _userLevel = tier['level'] as String;
                              _userIntensity = tier['intensity'] as String;
                            });
                            WeeklyPlanService.instance.updateUserPreferences(
                              level: tier['level'] as String,
                              intensity: tier['intensity'] as String,
                            );
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('⚡ Modo ${tier['label']} seleccionado y sincronizado en Inicio y Perfil'),
                                backgroundColor: const Color(0xFF16253B),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSelected ? tierColor.withValues(alpha: 0.22) : const Color(0xFF16253B),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? tierColor : Colors.white12,
                                width: isSelected ? 1.3 : 1.0,
                              ),
                            ),
                            child: Text(
                              tier['label'] as String,
                              style: TextStyle(
                                color: isSelected ? tierColor : Colors.white60,
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            if (WeeklyPlanService.instance.hasActivePlan)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: const BoxDecoration(
                  color: Color(0xFF132238),
                  border: Border(bottom: BorderSide(color: Color(0xFF8BE0C0), width: 0.8)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF8BE0C0)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Plan Activo: ${WeeklyPlanService.instance.cycleDateRangeStr} · Próximo ciclo: ${WeeklyPlanService.instance.nextCycleDateStr}',
                        style: const TextStyle(
                          color: Color(0xFF8BE0C0),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '🏋️ Días programados: ${WeeklyPlanService.instance.activeTrainingDayNames.join(", ")}\n'
                              '⏳ Próxima planificación general completa: ${WeeklyPlanService.instance.nextCycleDateStr}.\n'
                              '💡 Para esta semana puedes solicitar rutinas complementarias para tus días libres.',
                            ),
                            backgroundColor: const Color(0xFF16253B),
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F3A4B),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Info', style: TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
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
                      if (msg['suggest_questionnaire'] == true ||
                          (msg['isWelcome'] == true && _messages.length == 1)) ...[
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
                              if (plan['recommended_days'] is List && (plan['recommended_days'] as List).isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF173B45),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF8BE0C0).withValues(alpha: 0.4)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '📅 Días Óptimos (48-72h recuperación): ${(plan['recommended_days'] as List).join(' y ')}',
                                        style: const TextStyle(color: Color(0xFF8BE0C0), fontSize: 12, fontWeight: FontWeight.w800),
                                      ),
                                      if (plan['complementary_days'] is Map && (plan['complementary_days'] as Map).isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          '🔄 Días intermedios sugeridos: ${(plan['complementary_days'] as Map).entries.map((e) => '${e.key} (${e.value})').join(' · ')}',
                                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                                        ),
                                      ],
                                      if (plan['is_complementary_days'] != true) ...[
                                        const SizedBox(height: 8),
                                        const Text(
                                          '🤝 ¿Con qué ejercicio/área relacionamos los días intermedios (Martes y Jueves) para no fatigar el músculo?',
                                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            ActionChip(
                                              backgroundColor: const Color(0xFF0F1E2E),
                                              side: const BorderSide(color: Color(0xFF8BE0C0), width: 1),
                                              label: const Text('💪 Tren Superior (Mar/Jue)', style: TextStyle(color: Color(0xFF8BE0C0), fontSize: 10.5, fontWeight: FontWeight.w700)),
                                              onPressed: _isLoading
                                                  ? null
                                                  : () => _sendMessage(
                                                        'Para los días intermedios (Martes y Jueves), quiero relacionarlo con una rutina complementaria enfocada 100% en Tren Superior (Espalda, Pecho, Hombros y Brazos) para nivel $_userLevel con intensidad $_userIntensity.',
                                                      ),
                                            ),
                                            ActionChip(
                                              backgroundColor: const Color(0xFF0F1E2E),
                                              side: const BorderSide(color: Color(0xFF8BE0C0), width: 1),
                                              label: const Text('🧘 Core y Postura (Mar/Jue)', style: TextStyle(color: Color(0xFF8BE0C0), fontSize: 10.5, fontWeight: FontWeight.w700)),
                                              onPressed: _isLoading
                                                  ? null
                                                  : () => _sendMessage(
                                                        'Para los días intermedios (Martes y Jueves), quiero relacionarlo con una rutina complementaria enfocada 100% en Core, Abdomen y Estabilidad Lumbar para nivel $_userLevel con intensidad $_userIntensity.',
                                                      ),
                                            ),
                                            ActionChip(
                                              backgroundColor: const Color(0xFF0F1E2E),
                                              side: const BorderSide(color: Color(0xFF8BE0C0), width: 1),
                                              label: const Text('🏃 Movilidad y Cardio Suave (Mar/Jue)', style: TextStyle(color: Color(0xFF8BE0C0), fontSize: 10.5, fontWeight: FontWeight.w700)),
                                              onPressed: _isLoading
                                                  ? null
                                                  : () => _sendMessage(
                                                        'Para los días intermedios (Martes y Jueves), quiero relacionarlo con una rutina complementaria enfocada 100% en Movilidad Articular y Cardio Suave de bajo impacto para nivel $_userLevel con intensidad $_userIntensity.',
                                                      ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                              
                              // Listado de Ejercicios
                              if (plan['exercises'] is List && (plan['exercises'] as List).isNotEmpty) ...[
                                const SizedBox(height: 14),
                                const Text('🏋️ Ejercicios Recomendados (Categorizados por Intensidad):', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 8),
                                ...(plan['exercises'] as List).take(5).map((ex) {
                                  final String intLabel = (ex['intensity_level'] ?? 'Básico (Intensidad Baja)').toString();
                                  final String primaryM = (ex['primary_muscle'] ?? 'Piernas').toString();
                                  final bool isLow = intLabel.toLowerCase().contains('baja') || intLabel.toLowerCase().contains('básico');
                                  final bool isHigh = intLabel.toLowerCase().contains('alta') || intLabel.toLowerCase().contains('avanzado');
                                  final Color badgeColor = isLow
                                      ? const Color(0xFF8BE0C0)
                                      : (isHigh ? const Color(0xFFFF6B6B) : const Color(0xFFFFB340));
                                  final String exName = (ex['name'] ?? 'Ejercicio').toString();
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () => _open3DViewer(plan, targetExerciseName: exName),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF16253B),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.white10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF8BE0C0), size: 22),
                                                tooltip: 'Ver en 3D',
                                                onPressed: () => _open3DViewer(plan, targetExerciseName: exName),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  exName,
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
                                          const SizedBox(height: 4),
                                          Padding(
                                            padding: const EdgeInsets.only(left: 30),
                                            child: Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              children: [
                                                Text(
                                                  '🎯 $primaryM',
                                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                  decoration: BoxDecoration(
                                                    color: badgeColor.withValues(alpha: 0.18),
                                                    borderRadius: BorderRadius.circular(5),
                                                    border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                                                  ),
                                                  child: Text(
                                                    '⚡ $intLabel',
                                                    style: TextStyle(color: badgeColor, fontSize: 10.5, fontWeight: FontWeight.w800),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
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
                                    child: Builder(
                                      builder: (context) {
                                        final bool isAdded = plan['is_added_to_schedule'] == true;
                                        return ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isAdded ? const Color(0xFF173B45) : const Color(0xFF8BE0C0),
                                            foregroundColor: isAdded ? const Color(0xFF8BE0C0) : Colors.black,
                                            side: isAdded ? const BorderSide(color: Color(0xFF8BE0C0), width: 1.2) : null,
                                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          icon: Icon(
                                            isAdded ? Icons.check_circle_rounded : Icons.bookmark_add_rounded,
                                            size: 16,
                                          ),
                                          label: Text(
                                            isAdded
                                                ? 'Añadido al cronograma el plan de nutrición y ejercicios'
                                                : 'Agregar a Cronograma y Nutrición',
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                                            textAlign: TextAlign.center,
                                          ),
                                          onPressed: () async {
                                            if (plan['is_added_to_schedule'] == true) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('ℹ️ Ya has añadido este plan de nutrición y ejercicios al cronograma.'),
                                                  backgroundColor: Color(0xFF173B45),
                                                  behavior: SnackBarBehavior.floating,
                                                  duration: Duration(seconds: 3),
                                                ),
                                              );
                                              return;
                                            }
                                            await WeeklyPlanService.instance.injectCustomPlanForToday(plan);
                                            if (!context.mounted) return;
                                            setState(() {
                                              plan['is_added_to_schedule'] = true;
                                            });
                                            final recDays = (plan['recommended_days'] is List)
                                                ? (plan['recommended_days'] as List).join(', ')
                                                : 'días alternos';
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('✅ ¡Añadido al cronograma el plan de nutrición y ejercicios en $recDays!'),
                                                backgroundColor: const Color(0xFF1B4D3E),
                                                behavior: SnackBarBehavior.floating,
                                                duration: const Duration(seconds: 4),
                                              ),
                                            );
                                          },
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
                                    onPressed: () => _open3DViewer(plan),
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
            if (_isListening)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.18),
                  border: const Border(top: BorderSide(color: Colors.redAccent, width: 1.0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.record_voice_over_rounded, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '🎙️ Escuchando... habla claramente para escribir en el chat',
                        style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    InkWell(
                      onTap: _listen,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('DETENER', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),

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
                              ? 'Escribe tu pregunta o usa el micrófono...'
                              : null,
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: const Color(0xFF0A0F1D),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isListening ? Icons.mic : Icons.mic_none_rounded,
                              color: _isListening ? Colors.redAccent : const Color(0xFF8BE0C0),
                            ),
                            tooltip: _isListening ? 'Detener dictado' : 'Hablar por micrófono',
                            onPressed: _listen,
                          ),
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
                      foregroundColor: _isListening ? Colors.white : const Color(0xFF8BE0C0),
                      minimumSize: const Size(48, 48),
                    ),
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_rounded),
                    tooltip: _isListening ? 'Detener dictado' : 'Dictar por voz',
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

  Future<void> _open3DViewer(Map<String, dynamic> plan, {String? targetExerciseName}) async {
    List<AnatomyExercise> dyn = [];
    if (plan['exercises'] != null) {
      for (var ex in plan['exercises']) {
        final String exName = (ex['name'] ?? 'Ejercicio').toString();
        final String primaryM = (ex['primary_muscle'] ?? 'Piernas').toString();
        final String secondaryM = (ex['secondary_muscle'] ?? '').toString();
        String gifUrl = (ex['gif_url'] ?? '').toString();
        String intLevel = (ex['intensity_level'] ?? 'Básico (Intensidad Baja)').toString();
        String biomech = (ex['biomechanics'] ?? 'Movimiento controlado respetando el rango articular.').toString();
        String tempoStr = (ex['tempo'] ?? '3-1-1').toString();
        String postureStr = (ex['posture'] ?? 'Mantén la columna neutra y abdomen activo.').toString();
        String warnStr = (ex['warning'] ?? 'Consulta a tu entrenador si sientes dolor.').toString();

        dyn.add(AnatomyExercise(
          id: exName,
          name: exName,
          shortName: exName,
          gifUrl: resolveGuaranteedGifUrl(
            name: exName,
            agonist: primaryM,
            intensityLevel: intLevel,
            existingUrl: gifUrl,
          ),
          agonist: primaryM,
          synergists: secondaryM.isNotEmpty ? [secondaryM] : [],
          intensityLevel: intLevel,
          biomechanics: biomech,
          tempo: tempoStr,
          posture: postureStr,
          warning: warnStr,
        ));
      }
    }

    String initialId = 'squat';
    if (targetExerciseName != null && dyn.isNotEmpty) {
      final tLower = targetExerciseName.toLowerCase().trim();
      final match = dyn.firstWhere(
        (e) => e.name.toLowerCase().trim() == tLower ||
               e.name.toLowerCase().contains(tLower) ||
               tLower.contains(e.name.toLowerCase().trim()) ||
               e.id.toLowerCase() == tLower,
        orElse: () => dyn.first,
      );
      initialId = match.id;
    } else if (dyn.isNotEmpty) {
      initialId = dyn.first.id;
    }

    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => AnatomyWorkoutScreen(
      initialExerciseId: initialId,
      dynamicExercises: dyn.isNotEmpty ? dyn : null,
    )));
  }
}
