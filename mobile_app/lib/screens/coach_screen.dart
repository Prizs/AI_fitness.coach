import 'package:mobile_app/services/weekly_plan_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/screens/workout_schedule_screen.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile_app/services/voice_service.dart';
import 'package:mobile_app/models/anatomy_exercise.dart';
import 'package:mobile_app/screens/anatomy_workout_screen.dart';
import 'package:mobile_app/screens/adaptive_workout_screen.dart';
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
  bool _isListening = false;
  bool _showPreviousConversations = false;
  int? _initialSessionStartIndex;

  int _computeLastConversationStartIndex() {
    if (_messages.length <= 2) return 0;
    int lastAiIdx = -1;
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i]['isUser'] != true) {
        lastAiIdx = i;
        break;
      }
    }
    if (lastAiIdx != -1) {
      for (int i = lastAiIdx - 1; i >= 0; i--) {
        if (_messages[i]['isUser'] == true) {
          return i;
        }
      }
      return lastAiIdx;
    }
    return (_messages.length - 2).clamp(0, _messages.length - 1);
  }
  
  @override
  void initState() {
    super.initState();
    final prefLvl = WeeklyPlanService.instance.userLevel;
    if (prefLvl.isNotEmpty) _userLevel = prefLvl;
    final prefInt = WeeklyPlanService.instance.userIntensity;
    if (prefInt.isNotEmpty) _userIntensity = prefInt;
    WeeklyPlanService.instance.addListener(_onWeeklyPlanUpdated);
    _loadHistory();
  }

  void _onWeeklyPlanUpdated() {
    if (mounted) {
      setState(() {
        _userLevel = WeeklyPlanService.instance.userLevel;
        _userIntensity = WeeklyPlanService.instance.userIntensity;
      });
    }
  }

  Future<void> _loadHistory() async {
    final profile = AuthService.instance.loggedInUser;
    final cedula = profile?.cedula ?? 'default';
    const storage = FlutterSecureStorage();
    final localKey = 'coach_chat_history_$cedula';

    // 1. Restauración local instantánea (0ms de espera)
    try {
      final cachedStr = await storage.read(key: localKey);
      if (cachedStr != null && cachedStr.trim().isNotEmpty) {
        final decoded = jsonDecode(cachedStr);
        if (decoded is List && decoded.isNotEmpty) {
          if (mounted) {
            setState(() {
              _messages.clear();
              for (final item in decoded) {
                if (item is Map) {
                  _messages.add(Map<String, dynamic>.from(item));
                }
              }
              _initialSessionStartIndex = _computeLastConversationStartIndex();
            });
          }
        }
      }
    } catch (_) {}

    // 2. Sincronización en segundo plano con backend / Supabase
    try {
      final baseUrl = AuthService.apiBaseUrl;
      final uri = Uri.parse('$baseUrl/api/coach/history?cedula=$cedula');
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final serverList = jsonDecode(res.body);
        if (serverList is List && serverList.isNotEmpty) {
          final List<Map<String, dynamic>> restored = [];
          for (final item in serverList) {
            if (item is Map) {
              if (item['category'] == 'body_metric' || item['role'] == 'system') continue;
              final p = item['plan'];
              final bool hasValidPlan = p is Map &&
                  ((p['exercises'] is List && (p['exercises'] as List).isNotEmpty) || p.containsKey('days') || p.containsKey('routine_name'));
              restored.add({
                'isUser': item['isUser'] == true,
                'text': item['text'] ?? '',
                'plan': hasValidPlan ? p : null,
                'category': item['category'],
                'rule': item['rule'],
                'suggest_questionnaire': item['suggest_questionnaire'] == true,
                'quick_replies': item['quick_replies'],
                'recommended_intensity': item['recommended_intensity'],
              });
            }
          }
          if (mounted && restored.isNotEmpty) {
            setState(() {
              _messages.clear();
              _messages.addAll(restored);
              _initialSessionStartIndex = _computeLastConversationStartIndex();
            });
            await storage.write(key: localKey, value: jsonEncode(_messages));
          }
        }
      }
    } catch (_) {}

    // 3. Si no hay mensajes o solo queda el mensaje default inicial, disparar Saludo Contextual Hiperpersonalizado
    if (_messages.isEmpty || (_messages.length == 1 && _messages.first['isWelcome'] == true)) {
      _requestInitialGreeting();
    }
  }

  Future<void> _requestInitialGreeting() async {
    final profile = AuthService.instance.loggedInUser;
    final cedula = profile?.cedula ?? 'default';
    final userName = (profile != null && profile.name.trim().isNotEmpty)
        ? '${profile.name} ${profile.lastName}'.trim()
        : 'Atleta';
    final baseUrl = AuthService.apiBaseUrl;

    final planService = WeeklyPlanService.instance;
    final t = planService.today;
    final bool todayHasWorkout = (t != null && (t['exercises'] as List?)?.isNotEmpty == true);
    final bool todayIsCompleted = planService.completedDays.contains(planService.todayIndex);
    final String? todayTitle = (t?['title'] ?? t?['focus'])?.toString();
    final List<String> todayExercises = (t?['exercises'] as List?)
            ?.map((e) => (e is Map ? (e['name'] ?? '').toString() : e.toString()))
            .where((s) => s.isNotEmpty)
            .toList() ??
        [];
    final bool todayIsHome = planService.isTodayHomeWorkout;
    final String todayDayName = planService.todayName;
    final bool hasActivePlan = planService.hasActivePlan;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/coach/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': 'Hola Coach',
              'is_initial_greeting': true,
              'user_name': userName,
              'cedula': cedula,
              'user_id': cedula,
              'user_goal': planService.userGoal,
              'user_level': _userLevel,
              'user_intensity': _userIntensity,
              'has_active_plan': hasActivePlan,
              'today_has_workout': todayHasWorkout,
              'today_is_completed': todayIsCompleted,
              'today_title': todayTitle,
              'today_exercises': todayExercises,
              'today_day_name': todayDayName,
              'today_is_home': todayIsHome,
              'weekly_metrics': {
                'adherence_rate': planService.adherenceRate,
                'completed_sessions': planService.totalCompletedSessions,
                'date_range': planService.cycleDateRangeStr,
                'streak': planService.currentStreak,
                'last_rpe': planService.lastRpe,
                'last_feeling': planService.lastFeeling,
              },
            }),
          )
          .timeout(const Duration(seconds: 40));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final replyText = (data['reply'] ?? '¡Hola! Bienvenido a tu entrenamiento.').toString();
        final qReplies = data['quick_replies'] is List
            ? List<String>.from(data['quick_replies'])
            : <String>[
                '📋 Completar mi estado de salud',
                '🏋️ Ver ejercicios de hoy',
                '🏠 ¿Dónde vas a entrenar? (Gimnasio o Casa)',
                '💪 ¡Me siento al 100%, listo para entrenar!',
              ];

        if (mounted) {
          setState(() {
            _messages.clear();
            _messages.add({
              'isUser': false,
              'text': replyText,
              'plan': null,
              'category': data['category'] ?? 'Revisión Semanal y Adaptación',
              'suggest_questionnaire': data['suggest_questionnaire'] == true,
              'quick_replies': qReplies,
            });
          });
          _saveHistoryLocally();
        }
      }
    } catch (_) {
      if (mounted && (_messages.isEmpty || (_messages.length == 1 && _messages.first['isWelcome'] == true))) {
        String fallbackText;
        List<String> fallbackQuickReplies;
        if (todayHasWorkout && !todayIsCompleted) {
          final exStr = todayExercises.isNotEmpty ? ' (${todayExercises.take(3).join(', ')})' : '';
          final placeStr = todayIsHome ? 'en casa 🏠' : 'en el gimnasio 🏋️';
          fallbackText = '¡Hola, $userName! 👋 Para hoy $todayDayName tenemos programado: "${todayTitle ?? 'Entrenamiento'}"$exStr $placeStr.\n\n¿Cómo te sientes hoy para entrenar? Cuéntame si tienes alguna molestia física o si necesitas adaptar los ejercicios según tu estado actual y el lugar donde vas a entrenar.';
          fallbackQuickReplies = [
            '📋 Completar mi estado de salud',
            '🏋️ Ver ejercicios de hoy',
            '🏠 ¿Dónde vas a entrenar? (Gimnasio o Casa)',
            '💪 ¡Me siento al 100%, listo para entrenar!',
          ];
        } else if (todayIsCompleted) {
          fallbackText = '¡Hola, $userName! 🎉 ¡Excelente trabajo completando tu sesión de hoy $todayDayName! Recuerda hidratarte bien y permitir que tus fibras musculares descansen entre 48 y 72 horas para una supercompensación óptima. ¿Cómo terminaste?';
          fallbackQuickReplies = [
            'Terminé genial, descansando',
            'Siento algo de fatiga muscular',
            '📋 Registrar sensaciones de hoy',
          ];
        } else if (!hasActivePlan) {
          fallbackText = '¡Hola, $userName! 👋 ¡Bienvenido nuevamente a tu centro de entrenamiento inteligente! No tienes un ciclo activo programado para esta semana. ¿Cómo estuvo tu jornada anterior? Vamos a planificar tus sesiones.';
          fallbackQuickReplies = [
            '🚀 Planificar mi semana de entrenamiento',
            '📋 Completar mi estado actual',
            '💡 ¿Qué rutina me recomiendas hoy?',
          ];
        } else {
          fallbackText = '¡Hola, $userName! 👋 Hoy $todayDayName es tu día de recuperación activa. El descanso neuromuscular es fundamental para consolidar el progreso y prevenir sobrecargas. ¿Cómo te sientes?';
          fallbackQuickReplies = [
            'Me siento recuperado y con energía',
            'Siento algo de tensión muscular',
            '📋 Completar mi estado actual',
          ];
        }

        setState(() {
          _messages.clear();
          _messages.add({
            'isUser': false,
            'text': fallbackText,
            'isWelcome': true,
            'plan': null,
            'quick_replies': fallbackQuickReplies,
          });
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveHistoryLocally() async {
    try {
      final profile = AuthService.instance.loggedInUser;
      final cedula = profile?.cedula ?? 'default';
      const storage = FlutterSecureStorage();
      final localKey = 'coach_chat_history_$cedula';
      final toSave = _messages.length > 50 ? _messages.sublist(_messages.length - 50) : _messages;
      await storage.write(key: localKey, value: jsonEncode(toSave));
    } catch (_) {}
  }

  Future<void> _clearChatHistory() async {
    final profile = AuthService.instance.loggedInUser;
    final cedula = profile?.cedula ?? 'default';
    const storage = FlutterSecureStorage();
    final localKey = 'coach_chat_history_$cedula';

    setState(() {
      _messages.clear();
      _isLoading = true;
    });

    await storage.delete(key: localKey);

    try {
      final baseUrl = AuthService.apiBaseUrl;
      await http.delete(Uri.parse('$baseUrl/api/coach/history?cedula=$cedula'));
    } catch (_) {}

    await _requestInitialGreeting();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conversación reiniciada exitosamente.'),
          backgroundColor: Color(0xFF16253B),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showClearChatConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F192B),
        title: const Text('¿Reiniciar conversación?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Se borrará el historial de este chat y comenzarás una nueva sesión activa con el Coach IA.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF6B6B)),
            onPressed: () {
              Navigator.pop(ctx);
              _clearChatHistory();
            },
            child: const Text('Reiniciar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WeeklyPlanService.instance.removeListener(_onWeeklyPlanUpdated);
    _controller.dispose();
    super.dispose();
  }
  
  void _listen() async {
    // Si ya está escuchando -> Segundo clic: DETIENE Y ENVÍA DE INMEDIATO
    if (_isListening) {
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
      final recognizedText = await VoiceService.instance.stopListening();
      final textToSend = recognizedText.isNotEmpty ? recognizedText : _controller.text.trim();

      if (textToSend.isNotEmpty && !textToSend.startsWith('Transcribiendo')) {
        _controller.clear();
        _sendMessage(textToSend);
      } else {
        if (mounted && textToSend.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ℹ️ No se detectó voz. Vuelve a pulsar el micrófono para intentar de nuevo.'),
              backgroundColor: Color(0xFF16253B),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
      return;
    }

    // Primer clic: Inicia la captura de voz
    final started = await VoiceService.instance.startListening(
      onResult: (text) {
        if (mounted) {
          setState(() {
            _controller.text = text;
          });
        }
      },
      onListeningChanged: (listening) {
        if (mounted) setState(() => _isListening = listening);
      },
      onError: (errorMsg) {
        if (mounted) {
          setState(() => _isListening = false);
          final lower = errorMsg.toLowerCase();
          if (lower.contains('permiso') || lower.contains('not-allowed') || lower.contains('permission') || lower.contains('denied')) {
            _showMicrophoneHelpDialog(errorMsg);
          }
        }
      },
    );


    if (started && mounted) {
      setState(() => _isListening = true);
    }
  }

  void _showMicrophoneHelpDialog(String errorMsg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF101B2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.mic_off_rounded, color: Colors.amber, size: 24),
            SizedBox(width: 8),
            Text('Micrófono en Navegador', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalle: $errorMsg',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF16253B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF8BE0C0).withValues(alpha: 0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡 Cómo habilitarlo en tu Laptop / PC:', style: TextStyle(color: Color(0xFF8BE0C0), fontWeight: FontWeight.bold, fontSize: 12)),
                  SizedBox(height: 6),
                  Text('1. Haz clic en el ícono de Candado 🔒 a la izquierda del enlace en la barra de direcciones.', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                  SizedBox(height: 3),
                  Text('2. En la opción "Micrófono", selecciona "Permitir".', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                  SizedBox(height: 3),
                  Text('3. Te recomendamos usar Google Chrome o Microsoft Edge para la mejor compatibilidad de voz.', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8BE0C0),
              foregroundColor: const Color(0xFF0B1220),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
    _saveHistoryLocally();

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

      final today = WeeklyPlanService.instance.today;
      final todayRoutine = today != null
          ? {
              'day_name': WeeklyPlanService.instance.todayName,
              'is_rest': (today['exercises'] as List?)?.isEmpty ?? true,
              'focus': today['focus'] ?? today['title'] ?? 'Entrenamiento',
              'exercises': today['exercises'] ?? [],
              'nutrition': today['nutrition'],
            }
          : null;

      final weeklySchedule = WeeklyPlanService.instance.days.map((d) => {
            'day': d['weekday_name'] ?? '',
            'focus': d['focus'] ?? d['title'] ?? 'Descanso activo',
            'is_training': (d['exercises'] as List?)?.isNotEmpty == true,
          }).toList();

      final savedArchetype = await storage.read(key: 'biopsycho_archetype');
      final savedBiopsychoJson = await storage.read(key: 'biopsycho_data');

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/coach/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': text,
              'history': history,
              'cedula': profile?.cedula,
              'user_id': profile?.cedula,
              'user_goal': WeeklyPlanService.instance.userGoal,
              'user_level': _userLevel,
              'user_intensity': _userIntensity,
              'user_streak': WeeklyPlanService.instance.currentStreak,
              'total_completed_sessions': WeeklyPlanService.instance.totalCompletedSessions,
              'rpe_feedback': WeeklyPlanService.instance.lastRpe,
              'allergies': profile?.foodAllergies,
              'pathology_or_allergies': profile?.pathologyOrAllergies,
              'archetype': savedArchetype,
              'behavioral_profile': savedBiopsychoJson,
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
              'today_routine': todayRoutine,
              'weekly_schedule': weeklySchedule,
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
        final qReplies = data['quick_replies'] is List ? List<String>.from(data['quick_replies']) : null;
        final recIntensity = data['recommended_intensity'] as String?;

        if (recIntensity != null &&
            recIntensity.isNotEmpty &&
            recIntensity.toLowerCase() != _userIntensity.toLowerCase()) {
          setState(() {
            _userIntensity = recIntensity;
          });
          WeeklyPlanService.instance.updateUserPreferences(intensity: recIntensity);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                data['fatigue_detected'] == true
                    ? '🛡️ Ajuste por fatiga: Intensidad adaptada a $recIntensity para facilitar recuperación activa (Nivel $_userLevel conservado).'
                    : '⚡ Intensidad adaptada a $recIntensity según tu progreso (Nivel $_userLevel conservado).',
              ),
              backgroundColor: const Color(0xFF16253B),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }

        setState(() {
          _messages.add({
            'isUser': false,
            'text': replyText,
            'plan': data['has_plan'] == true ? _sanitizeClientPlan(data['structured_plan'], text) : null,
            'category': data['category'],
            'rule': data['progression_rule'],
            'suggest_questionnaire': showStateBtn,
            'quick_replies': qReplies,
            'recommended_intensity': recIntensity,
          });
        });
        _saveHistoryLocally();
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
    final int hiddenCount = _initialSessionStartIndex ?? _computeLastConversationStartIndex();
    final bool hasPrevious = hiddenCount > 0;
    final int startIndex = _showPreviousConversations ? 0 : hiddenCount;
    final List<Map<String, dynamic>> visibleMessages =
        startIndex < _messages.length ? _messages.sublist(startIndex) : _messages;
    final int totalCount = hasPrevious ? (visibleMessages.length + 1) : visibleMessages.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        title: const Text('Coach IA & Adaptación', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: const Color(0xFF0F192B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded, color: Colors.white70),
            tooltip: 'Reiniciar conversación',
            onPressed: _showClearChatConfirmation,
          ),
          IconButton(
            icon: const Icon(Icons.accessible_forward_rounded, color: Color(0xFF8BE0C0)),
            tooltip: 'Test Ejercicios Adaptados (Discapacidad Motora)',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdaptiveWorkoutScreen()),
            ),
          ),
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
            // Barra interactiva de Nivel e Intensidad 100% Desacoplados
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: const BoxDecoration(
                color: Color(0xFF0F192B),
                border: Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Selector de Nivel de Experiencia (Desacoplado)
                    const Icon(Icons.fitness_center_rounded, size: 14, color: Color(0xFF8BE0C0)),
                    const SizedBox(width: 4),
                    const Text('Nivel:', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    ...['Principiante', 'Intermedio', 'Avanzado'].map((lvl) {
                      final bool isSelected = _userLevel.toLowerCase() == lvl.toLowerCase();
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() => _userLevel = lvl);
                            WeeklyPlanService.instance.updateUserPreferences(level: lvl);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF8BE0C0).withValues(alpha: 0.22) : const Color(0xFF16253B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF8BE0C0) : Colors.white12,
                                width: isSelected ? 1.2 : 1.0,
                              ),
                            ),
                            child: Text(
                              lvl,
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF8BE0C0) : Colors.white60,
                                fontSize: 10.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 6),
                    Container(width: 1, height: 16, color: Colors.white12),
                    const SizedBox(width: 6),
                    // Selector de Intensidad (Desacoplado)
                    const Icon(Icons.bolt_rounded, size: 15, color: Color(0xFFFFB340)),
                    const SizedBox(width: 4),
                    const Text('Intensidad:', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    ...[
                      {'label': 'Baja', 'code': 'Baja', 'color': const Color(0xFF8BE0C0)},
                      {'label': 'Media', 'code': 'Media', 'color': const Color(0xFFFFB340)},
                      {'label': 'Alta', 'code': 'Alta', 'color': const Color(0xFFFF6B6B)},
                    ].map((tier) {
                      final bool isSelected = _userIntensity.toLowerCase() == (tier['code'] as String).toLowerCase();
                      final Color tierColor = tier['color'] as Color;
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() => _userIntensity = tier['code'] as String);
                            WeeklyPlanService.instance.updateUserPreferences(intensity: tier['code'] as String);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSelected ? tierColor.withValues(alpha: 0.22) : const Color(0xFF16253B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? tierColor : Colors.white12,
                                width: isSelected ? 1.2 : 1.0,
                              ),
                            ),
                            child: Text(
                              tier['label'] as String,
                              style: TextStyle(
                                color: isSelected ? tierColor : Colors.white60,
                                fontSize: 10.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
                itemCount: totalCount,
                itemBuilder: (context, index) {
                  if (hasPrevious && index == 0) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 12),
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFF142032),
                            foregroundColor: const Color(0xFF8BE0C0),
                            side: const BorderSide(color: Color(0xFF8BE0C0), width: 1.2),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          icon: Icon(
                            _showPreviousConversations
                                ? Icons.unfold_less_rounded
                                : Icons.history_rounded,
                            size: 18,
                            color: const Color(0xFF8BE0C0),
                          ),
                          label: Text(
                            _showPreviousConversations
                                ? 'Ocultar conversaciones anteriores'
                                : 'Mostrar conversaciones anteriores',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF8BE0C0),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _showPreviousConversations = !_showPreviousConversations;
                            });
                          },
                        ),
                      ),
                    );
                  }

                  final msgIndex = hasPrevious ? (index - 1) : index;
                  final msg = visibleMessages[msgIndex];
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
                      if (msg['quick_replies'] is List && (msg['quick_replies'] as List).isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: (msg['quick_replies'] as List).map<Widget>((qr) {
                              final qrText = qr.toString();
                              final lower = qrText.toLowerCase();
                              final isStateBtn = lower.contains('completar') || lower.contains('estado actual') || lower.contains('estado de salud');
                              final isWhereTrain = lower.contains('dónde vas a entrenar') || lower.contains('donde vas a entrenar') || lower.contains('gimnasio o casa');
                              final isViewEx = lower.contains('ver ejercicios');
                              final isReady = lower.contains('100%') || lower.contains('listo para entrenar');
                              final isFatigue = lower.contains('cansado') || lower.contains('bajemos') || lower.contains('descarga');
                              final isNextLvl = lower.contains('siguiente nivel') || lower.contains('alta');

                              final Color color = isStateBtn
                                  ? const Color(0xFF8BE0C0)
                                  : (isWhereTrain
                                      ? const Color(0xFF64B5F6)
                                      : (isViewEx
                                          ? const Color(0xFF8BE0C0)
                                          : (isReady
                                              ? const Color(0xFF81C784)
                                              : (isFatigue
                                                  ? const Color(0xFFFFB340)
                                                  : (isNextLvl
                                                      ? const Color(0xFFFF6B6B)
                                                      : const Color(0xFF8BE0C0))))));

                              final IconData icon = isStateBtn
                                  ? Icons.assignment_turned_in_rounded
                                  : (isWhereTrain
                                      ? Icons.home_work_rounded
                                      : (isViewEx
                                          ? Icons.fitness_center_rounded
                                          : (isReady
                                              ? Icons.bolt_rounded
                                              : (isFatigue
                                                  ? Icons.battery_charging_full_rounded
                                                  : (isNextLvl
                                                      ? Icons.trending_up_rounded
                                                      : Icons.flash_on_rounded)))));

                              return ActionChip(
                                backgroundColor: const Color(0xFF16253B),
                                side: BorderSide(color: color.withValues(alpha: 0.8), width: 1.1),
                                avatar: Icon(icon, size: 14, color: color),
                                label: Text(
                                  qrText,
                                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        if (isStateBtn || isWhereTrain) {
                                          _openStateSheet();
                                        } else {
                                          _sendMessage(qrText);
                                        }
                                      },
                              );
                            }).toList(),
                          ),
                        ),
                      ],
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
                      if (plan != null &&
                          msg['category'] != 'body_metric' &&
                          ((plan['exercises'] is List && (plan['exercises'] as List).isNotEmpty) ||
                           plan.containsKey('days') ||
                           plan.containsKey('routine_name'))) ...[
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
                                            final scheduleResult = await WeeklyPlanService.instance.injectCustomPlanForToday(plan);
                                            if (!context.mounted) return;
                                            setState(() {
                                              plan['is_added_to_schedule'] = true;
                                            });
                                            final assignedDays = (scheduleResult['assigned_days'] as List?)?.join(', ') ?? 'fechas disponibles';
                                            final bool preserved = (scheduleResult['preserved_routines_count'] as int? ?? 0) > 0;
                                            final String message = preserved
                                                ? '✅ ¡Rutinas y nutrición vigentes conservadas! Lo nuevo se programó en fechas disponibles: ' + assignedDays
                                                : '✅ ¡Añadido al cronograma en: ' + assignedDays + '!';
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(message),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E1515),
                  border: const Border(top: BorderSide(color: Colors.redAccent, width: 1.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.record_voice_over_rounded, color: Colors.redAccent, size: 22),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '🎙️ Grabando voz... Habla ahora',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Toca el micrófono otra vez para DETENER Y ENVIAR 🚀',
                            style: TextStyle(color: Color(0xFFFF8A80), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _listen,
                      icon: const Icon(Icons.send_rounded, size: 14),
                      label: const Text('ENVIAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            if (_isLoading)
              const LinearProgressIndicator(
                backgroundColor: Color(0xFF0F192B),
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8BE0C0)),
              ),
            _buildQuickRepliesBar(),
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

  List<String>? _getActiveQuickReplies() {
    if (_isLoading) return null;
    List<String> list = [];
    for (int i = _messages.length - 1; i >= 0; i--) {
      final m = _messages[i];
      if (m['isUser'] == false && m['quick_replies'] is List && (m['quick_replies'] as List).isNotEmpty) {
        list = List<String>.from(m['quick_replies']);
        break;
      }
    }
    if (list.isEmpty) {
      list = [
        '📋 Completar mi estado de salud',
        '🏋️ Ver ejercicios de hoy',
        '♿ Test Torso Adaptado (Discapacidad)',
        '💪 ¡Me siento al 100%, listo para entrenar!',
      ];
    }
    if (!list.any((e) => e.contains('♿') || e.toLowerCase().contains('adaptad'))) {
      list.add('♿ Test Torso Adaptado (Discapacidad)');
    }
    return list;
  }

  Widget _buildQuickRepliesBar() {
    final replies = _getActiveQuickReplies();
    if (replies == null || replies.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFF0F192B),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: replies.map((qrText) {
            final lower = qrText.toLowerCase();
            final isAdaptive = lower.contains('adaptad') || lower.contains('discapacidad') || lower.contains('♿');
            final isStateBtn = lower.contains('completar') || lower.contains('estado actual') || lower.contains('estado de salud');
            final isWhereTrain = lower.contains('dónde vas a entrenar') || lower.contains('donde vas a entrenar') || lower.contains('gimnasio o casa');
            final isViewEx = lower.contains('ver ejercicios');
            final isReady = lower.contains('100%') || lower.contains('listo para entrenar');
            final isFatigue = lower.contains('cansado') || lower.contains('bajemos') || lower.contains('descarga');
            final isNextLvl = lower.contains('siguiente nivel') || lower.contains('alta');

            final Color color = isAdaptive
                ? const Color(0xFF8BE0C0)
                : (isStateBtn
                    ? const Color(0xFF8BE0C0)
                    : (isWhereTrain
                        ? const Color(0xFF64B5F6)
                        : (isViewEx
                            ? const Color(0xFF8BE0C0)
                            : (isReady
                                ? const Color(0xFF81C784)
                                : (isFatigue
                                    ? const Color(0xFFFFB340)
                                    : (isNextLvl
                                        ? const Color(0xFFFF6B6B)
                                        : const Color(0xFF8BE0C0)))))));

            final IconData icon = isAdaptive
                ? Icons.accessible_forward_rounded
                : (isStateBtn
                    ? Icons.assignment_turned_in_rounded
                    : (isWhereTrain
                        ? Icons.home_work_rounded
                        : (isViewEx
                            ? Icons.fitness_center_rounded
                            : (isReady
                                ? Icons.bolt_rounded
                                : (isFatigue
                                    ? Icons.battery_charging_full_rounded
                                    : (isNextLvl
                                        ? Icons.trending_up_rounded
                                        : Icons.flash_on_rounded))))));

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                backgroundColor: const Color(0xFF16253B),
                side: BorderSide(color: color.withValues(alpha: 0.8), width: 1.1),
                avatar: Icon(icon, size: 15, color: color),
                label: Text(
                  qrText,
                  style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
                onPressed: _isLoading
                    ? null
                    : () {
                        if (isAdaptive) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AdaptiveWorkoutScreen()),
                          );
                        } else if (isStateBtn || isWhereTrain) {
                          _openStateSheet();
                        } else {
                          _sendMessage(qrText);
                        }
                      },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

