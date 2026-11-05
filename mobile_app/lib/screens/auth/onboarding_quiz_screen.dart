import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/database/db_helper.dart';
import 'package:mobile_app/models/user_profile.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/weekly_plan_service.dart';

class OnboardingQuizScreen extends StatefulWidget {
  const OnboardingQuizScreen({
    super.key,
    required this.userProfile,
    required this.onComplete,
  });

  final UserProfile userProfile;
  final VoidCallback onComplete;

  @override
  State<OnboardingQuizScreen> createState() => _OnboardingQuizScreenState();
}

class _OnboardingQuizScreenState extends State<OnboardingQuizScreen> {
  int _currentStep = 0;
  bool _isAnalyzing = false;
  bool _showResults = false;

  // Respuestas del usuario
  String? _selectedGoal;
  String? _activityLevel;
  String? _energyPattern;
  String? _mainObstacle;
  String? _mindsetPattern;
  String? _preferredSessionTime;
  String? _coachingStyle;

  // Arquetipo diagnosticado
  String _archetypeTitle = 'El Estratega Progresivo';
  String _archetypeDesc = '';
  String _archetypeRisk = 'Bajo';
  int _adherenceScore = 88;
  List<String> _antiProcrastinationRules = [];

  final _storage = const FlutterSecureStorage();

  final List<Map<String, dynamic>> _questions = [
    {
      'title': '¿Cuál es tu Objetivo Principal para este mes?',
      'subtitle': 'Tu plan se estructurará con descansos y cargas basadas en este objetivo.',
      'icon': Icons.track_changes_rounded,
      'options': [
        {
          'title': 'Pérdida de grasa y definición',
          'desc': 'Reducir porcentaje graso manteniendo masa muscular magra y activa.',
          'val': 'Pérdida de grasa y definición',
          'icon': Icons.local_fire_department_rounded,
        },
        {
          'title': 'Aumentar masa muscular',
          'desc': 'Estimular hipertrofia muscular progresiva y ganancia de masa magra.',
          'val': 'Aumentar masa muscular',
          'icon': Icons.fitness_center_rounded,
        },
        {
          'title': 'Ganar fuerza funcional',
          'desc': 'Incrementar potencia, reclutamiento neuromuscular y capacidad atlética.',
          'val': 'Ganar fuerza funcional',
          'icon': Icons.bolt_rounded,
        },
        {
          'title': 'Salud integral y movilidad',
          'desc': 'Aliviar tensiones, mejorar flexibilidad articular y bienestar postural.',
          'val': 'Salud integral y movilidad',
          'icon': Icons.self_improvement_rounded,
        },
      ],
    },
    {
      'title': '¿Cómo es tu ritmo de vida y movimiento diario?',
      'subtitle': 'Evaluación de tu punto de partida biológico real.',
      'icon': Icons.directions_walk_rounded,
      'options': [
        {
          'title': 'Sedentario',
          'desc': 'Trabajo sentado frente a pantallas la mayor parte del día (>7h).',
          'val': 'sedentary',
          'icon': Icons.computer_rounded,
        },
        {
          'title': 'Moderadamente activo',
          'desc': 'Me muevo a pie, tareas del hogar o desplazamientos diarios.',
          'val': 'moderate',
          'icon': Icons.directions_walk_rounded,
        },
        {
          'title': 'Muy activo físicamente',
          'desc': 'Trabajo de pie, alta demanda física o deportes regulares.',
          'val': 'high_active',
          'icon': Icons.bolt_rounded,
        },
      ],
    },
    {
      'title': '¿Cómo se comporta tu nivel de energía en el día?',
      'subtitle': 'El biorritmo nos dice cuándo tu fuerza de voluntad es máxima.',
      'icon': Icons.battery_charging_full_rounded,
      'options': [
        {
          'title': 'Pico en la mañana, bajón en la tarde',
          'desc': 'Rindo mejor temprano; en la noche ya no tengo energía mental.',
          'val': 'morning_peak',
          'icon': Icons.wb_sunny_rounded,
        },
        {
          'title': 'Cuesta arrancar, rindo más en la tarde/noche',
          'desc': 'Las mañanas son pesadas, mi cuerpo se activa tarde.',
          'val': 'evening_peak',
          'icon': Icons.nightlight_round,
        },
        {
          'title': 'Agotamiento mental constante',
          'desc': 'Llego al final del día con el cerebro saturado y cero ganas.',
          'val': 'mental_fatigue',
          'icon': Icons.psychology_alt_rounded,
        },
        {
          'title': 'Energía estable y constante',
          'desc': 'Mantengo un nivel balanceado sin bajones extremos.',
          'val': 'balanced',
          'icon': Icons.balance_rounded,
        },
      ],
    },
    {
      'title': '¿Qué te ha frenado o hecho abandonar en el pasado?',
      'subtitle': 'Identificar la raíz del autosabotaje es el 80% del éxito.',
      'icon': Icons.crisis_alert_rounded,
      'options': [
        {
          'title': 'Falta de tiempo e imprevistos',
          'desc': 'La rutina laboral o familiar se come mi día y no me queda espacio.',
          'val': 'time_scarcity',
          'icon': Icons.hourglass_disabled_rounded,
        },
        {
          'title': 'Pereza mental al empezar',
          'desc': 'La fricción de comenzar es enorme; pospongo hasta que ya es tarde.',
          'val': 'friction_start',
          'icon': Icons.bed_rounded,
        },
        {
          'title': 'Frustración por resultados lentos',
          'desc': 'Si no veo cambios evidentes en 2 semanas, pierdo la motivación.',
          'val': 'impatience',
          'icon': Icons.trending_down_rounded,
        },
        {
          'title': 'Miedo al dolor muscular o lesiones',
          'desc': 'Quedar adolorido días enteros me desanima a continuar.',
          'val': 'soreness_fear',
          'icon': Icons.healing_rounded,
        },
      ],
    },
    {
      'title': 'Cuando no puedes hacer tu sesión completa, ¿qué piensas?',
      'subtitle': 'Evaluamos el patrón psicológico de "Todo o Nada".',
      'icon': Icons.psychology_rounded,
      'options': [
        {
          'title': '“Para hacer 15 min mejor no hago nada”',
          'desc': 'Patrón perfeccionista: si no es perfecto, siento que no cuenta.',
          'val': 'all_or_nothing',
          'icon': Icons.highlight_off_rounded,
        },
        {
          'title': '“Hago 15 min de lo que pueda”',
          'desc': 'Patrón flexible: cualquier movimiento suma más que cero.',
          'val': 'flexible',
          'icon': Icons.check_circle_outline_rounded,
        },
        {
          'title': 'Siento culpa y procrastino varios días',
          'desc': 'Un fallo aislado desencadena una racha de inactividad.',
          'val': 'guilt_spiral',
          'icon': Icons.sentiment_dissatisfied_rounded,
        },
      ],
    },
    {
      'title': '¿Cuánto tiempo por sesión puedes comprometer SIN estrés?',
      'subtitle': 'La adherencia nace de metas que tu mente no perciba como amenaza.',
      'icon': Icons.timer_rounded,
      'options': [
        {
          'title': '15 a 25 minutos',
          'desc': 'Micro-sesiones de alta efectividad, sin fatiga excesiva.',
          'val': '15_25',
          'icon': Icons.flash_on_rounded,
        },
        {
          'title': '30 a 45 minutos',
          'desc': 'El punto dulce entre estímulo muscular y tiempo disponible.',
          'val': '30_45',
          'icon': Icons.fitness_center_rounded,
        },
        {
          'title': '50 a 60 minutos',
          'desc': 'Entrenamientos tradicionales completos y estructurados.',
          'val': '50_60',
          'icon': Icons.sports_gymnastics_rounded,
        },
      ],
    },
    {
      'title': '¿Qué estilo de Coach IA saca tu mejor versión?',
      'subtitle': 'Personalizaremos la voz y la psicología de tu entrenador.',
      'icon': Icons.support_agent_rounded,
      'options': [
        {
          'title': 'Empático y Comprensivo',
          'desc': 'Celebra pequeños avances, cero culpa, prioriza salud mental.',
          'val': 'empathic',
          'icon': Icons.favorite_rounded,
        },
        {
          'title': 'Disciplinado y Firme',
          'desc': 'Cero excusas, me empuja a cumplir y mantiene la vara alta.',
          'val': 'firm',
          'icon': Icons.military_tech_rounded,
        },
        {
          'title': 'Científico y Analítico',
          'desc': 'Explícame el porqué biomecánico, métricas y datos precisos.',
          'val': 'scientific',
          'icon': Icons.biotech_rounded,
        },
      ],
    },
  ];

  void _selectOption(String val) {
    setState(() {
      switch (_currentStep) {
        case 0:
          _selectedGoal = val;
          WeeklyPlanService.instance.updateUserPreferences(goal: val);
          break;
        case 1:
          _activityLevel = val;
          break;
        case 2:
          _energyPattern = val;
          break;
        case 3:
          _mainObstacle = val;
          break;
        case 4:
          _mindsetPattern = val;
          break;
        case 5:
          _preferredSessionTime = val;
          break;
        case 6:
          _coachingStyle = val;
          break;
      }
    });

    // Avanza automáticamente al siguiente paso tras una selección
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      if (_currentStep < _questions.length - 1) {
        setState(() {
          _currentStep++;
        });
      } else {
        _finishAndAnalyze();
      }
    });
  }

  String? _getCurrentSelection() {
    switch (_currentStep) {
      case 0:
        return _activityLevel;
      case 1:
        return _energyPattern;
      case 2:
        return _mainObstacle;
      case 3:
        return _mindsetPattern;
      case 4:
        return _preferredSessionTime;
      case 5:
        return _coachingStyle;
      default:
        return null;
    }
  }

  Future<void> _finishAndAnalyze() async {
    setState(() {
      _isAnalyzing = true;
    });

    // Diagnóstico del Arquetipo Bioconductual
    if (_mindsetPattern == 'all_or_nothing' || _mindsetPattern == 'guilt_spiral') {
      _archetypeTitle = 'El Perfeccionista Procrastinador';
      _archetypeDesc = 'Tu mente busca resultados impecables o rutinas largas. Cuando surge un imprevisto, prefieres posponer antes que hacer una versión reducida. Tu plan debe blindarse contra el "todo o nada".';
      _archetypeRisk = 'Medio-Alto (Abandono por autoexigencia)';
      _adherenceScore = 82;
      _antiProcrastinationRules = [
        'Regla de los 2 Minutos: Si no tienes ganas o tiempo, haz solo 1 ejercicio. El 90% de las veces completarás 15 minutos.',
        'La Regla "Mejor imperfecto que postergado": Una sesión de 15 min mantiene encendido tu metabolismo y tu racha psicológica.',
        'Cero Culpa: Si un imprevisto ocurre, no compenses al día siguiente. Sigue el calendario sin remordimiento.',
      ];
    } else if (_mainObstacle == 'friction_start' || _energyPattern == 'mental_fatigue') {
      _archetypeTitle = 'El Profesional con Fatiga Mental';
      _archetypeDesc = 'Tienes la capacidad física pero tu jornada laboral consume tu ancho de banda cerebral. La fricción de decidir qué hacer o preparar equipo te drena.';
      _archetypeRisk = 'Medio (Abandono por agotamiento cognitivo)';
      _adherenceScore = 86;
      _antiProcrastinationRules = [
        'Cero Decisiones: Tu rutina diaria estará pre-configurada. Solo dale a "Comenzar" sin pensar.',
        'Desconexión Activa: No entrenes para quemar calorías, entrena para lavar el cortisol de tu cerebro.',
        'Micro-Victorias: 20 minutos de estímulo muscular guiado renuevan tu energía en lugar de agotarte.',
      ];
    } else if (_mainObstacle == 'impatience') {
      _archetypeTitle = 'El Buscador de Resultados Rápidos';
      _archetypeDesc = 'Tu motor es la motivación de ver cambios tangibles. Si el espejo o la báscula tardan en responder, la mente cuestiona si el esfuerzo vale la pena.';
      _archetypeRisk = 'Medio (Desánimo a las 2 semanas)';
      _adherenceScore = 85;
      _antiProcrastinationRules = [
        'Métricas de Rendimiento: Mide cuántas repeticiones ganas o cómo duermes, no solo el peso.',
        'Compuesto Biológico: Los cambios neuromusculares ocurren en la semana 1; la remodelación visible en la semana 4.',
        'Fotografías de Control: Tomaremos registros objetivos cada 14 días para mostrar avances que el ojo diario no percibe.',
      ];
    } else if (_mainObstacle == 'soreness_fear') {
      _archetypeTitle = 'El Cauteloso Sensible al Dolor';
      _archetypeDesc = 'Valoras tu bienestar y temes que el ejercicio interfiera con tus actividades cotidianas por dolor muscular extremo o riesgo de lesión.';
      _archetypeRisk = 'Bajo-Medio (Resistencia al esfuerzo intenso)';
      _adherenceScore = 89;
      _antiProcrastinationRules = [
        'RPE Controlado: Mantendremos la escala de esfuerzo entre 6 y 7 sobre 10 sin llegar al fallo extremo.',
        'Calentamiento Progresivo: Cada sesión incluye movilidad biomecánica para lubricar articulaciones.',
        'Recuperación Prioritaria: Nutrición e hidratación adaptadas para amanecer sin pesadez.',
      ];
    } else {
      _archetypeTitle = 'El Constructor Constante';
      _archetypeDesc = 'Posees una base realista de constancia. Tu objetivo principal es optimizar tu tiempo, sostener la disciplina a largo plazo y evitar estancamientos.';
      _archetypeRisk = 'Bajo (Alta adherencia natural)';
      _adherenceScore = 94;
      _antiProcrastinationRules = [
        'Sobrecarga Progresiva: Registra tus pesos y descansos para un estímulo eficiente.',
        'Periodización Inteligente: Alterna semanas de estímulo con semanas de descarga.',
        'Hábito Ancla: Asocia tu rutina siempre a la misma hora para automatizar la disciplina.',
      ];
    }

    // Guardar en almacenamiento seguro y en base de datos por usuario
    final cedula = widget.userProfile.cedula;
    final quizData = {
      'completed': true,
      'date': DateTime.now().toIso8601String(),
      'goal': _selectedGoal ?? WeeklyPlanService.instance.userGoal,
      'archetype': _archetypeTitle,
      'archetypeDesc': _archetypeDesc,
      'adherenceScore': _adherenceScore,
      'activityLevel': _activityLevel,
      'energyPattern': _energyPattern,
      'mainObstacle': _mainObstacle,
      'mindsetPattern': _mindsetPattern,
      'preferredSessionTime': _preferredSessionTime,
      'coachingStyle': _coachingStyle,
      'rules': _antiProcrastinationRules,
    };
    final quizDataJson = jsonEncode(quizData);

    try {
      // 1. Guardar en DBHelper y secure storage asociado a la cédula
      await DBHelper.instance.saveUserArchetype(cedula, _archetypeTitle, quizDataJson: quizDataJson);

      // 2. Actualizar perfiles activos en memoria
      widget.userProfile.archetype = _archetypeTitle;
      if (AuthService.instance.loggedInUser != null) {
        AuthService.instance.loggedInUser!.archetype = _archetypeTitle;
      }

      // 3. Persistir en backend Supabase de forma asíncrona con fallback
      try {
        final res = await http.post(
          Uri.parse('${AuthService.apiBaseUrl}/api/auth/profile/archetype'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'cedula': cedula,
            'archetype': _archetypeTitle,
            'archetype_data': quizDataJson,
          }),
        ).timeout(const Duration(seconds: 5));
        if (res.statusCode != 200) {
          final altUrl = AuthService.apiBaseUrl.contains('localhost')
              ? 'https://ai-fitness-coach-818a.onrender.com'
              : 'http://localhost:8000';
          await http.post(
            Uri.parse('$altUrl/api/auth/profile/archetype'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'cedula': cedula,
              'archetype': _archetypeTitle,
              'archetype_data': quizDataJson,
            }),
          ).timeout(const Duration(seconds: 5));
        }
      } catch (_) {}
    } catch (_) {}


    // Simulación de análisis estilo FitCraft
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    setState(() {
      _isAnalyzing = false;
      _showResults = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isAnalyzing) {
      return _buildAnalyzingView();
    }
    if (_showResults) {
      return _buildResultsView();
    }
    return _buildQuizView();
  }

  Widget _buildAnalyzingView() {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8BE0C0).withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8BE0C0)),
                  ),
                ),
                const SizedBox(height: 36),
                const Text(
                  'Analizando tu perfil biopsicosocial...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Cruzando biorritmo, barreras psicológicas y estrategia anti-procrastinación con la IA...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.white60, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizView() {
    final q = _questions[_currentStep];
    final options = q['options'] as List<Map<String, dynamic>>;
    final currentSelection = _getCurrentSelection();
    final progress = (_currentStep + 1) / _questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1220),
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
              )
            : null,
        title: Text(
          'Paso ${_currentStep + 1} de ${_questions.length}',
          style: const TextStyle(fontSize: 16, color: Color(0xFF8BE0C0), fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8BE0C0)),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF173B45),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(q['icon'] as IconData, color: const Color(0xFF8BE0C0), size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          q['title'] as String,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    q['subtitle'] as String,
                    style: const TextStyle(fontSize: 14, color: Colors.white60),
                  ),
                  const SizedBox(height: 24),
                  ...options.map((opt) {
                    final isSelected = currentSelection == opt['val'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14.0),
                      child: InkWell(
                        onTap: () => _selectOption(opt['val'] as String),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF142B3B) : const Color(0xFF0F192B),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF8BE0C0) : Colors.white12,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF8BE0C0).withOpacity(0.18),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF8BE0C0) : Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  opt['icon'] as IconData,
                                  color: isSelected ? const Color(0xFF0B1220) : Colors.white70,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      opt['title'] as String,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      opt['desc'] as String,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isSelected ? Colors.white70 : Colors.white54,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                color: isSelected ? const Color(0xFF8BE0C0) : Colors.white30,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8BE0C0).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF8BE0C0).withOpacity(0.4)),
                ),
                child: const Text(
                  'DIAGNÓSTICO BIOPSICOSOCIAL COMPLETADO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: Color(0xFF8BE0C0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Tu Arquetipo de Adherencia',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 6),
            Text(
              _archetypeTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 18),

            // Tarjeta de Arquetipo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F192B),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFF8BE0C0).withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8BE0C0).withOpacity(0.08),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MetricItem(
                        label: 'Adherencia IA',
                        value: '$_adherenceScore%',
                        color: const Color(0xFF8BE0C0),
                      ),
                      Container(height: 40, width: 1, color: Colors.white12),
                      _MetricItem(
                        label: 'Riesgo Abandono',
                        value: _archetypeRisk.split(' ').first,
                        color: const Color(0xFFFFB340),
                      ),
                      Container(height: 40, width: 1, color: Colors.white12),
                      const _MetricItem(
                        label: 'Calibración',
                        value: 'Óptima',
                        color: Color(0xFF60A5FA),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 14),
                  Text(
                    _archetypeDesc,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Reglas de Oro Anti-Procrastinación
            const Row(
              children: [
                Icon(Icons.shield_rounded, color: Color(0xFF8BE0C0), size: 24),
                SizedBox(width: 10),
                Text(
                  'Tus 3 Reglas de Oro Anti-Abandono',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ..._antiProcrastinationRules.map((rule) {
              final parts = rule.split(':');
              final ruleTitle = parts[0];
              final ruleBody = parts.length > 1 ? parts.sublist(1).join(':') : '';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF101B2D),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF173B45),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF8BE0C0)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ruleTitle,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8BE0C0),
                            ),
                          ),
                          if (ruleBody.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              ruleBody.trim(),
                              style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.35),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  widget.onComplete();
                },
                icon: const Icon(Icons.fitness_center_rounded, color: Color(0xFF0B1220)),
                label: const Text(
                  '¡Comenzar con mi Plan Personalizado!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0B1220),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8BE0C0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 6,
                  shadowColor: const Color(0xFF8BE0C0).withOpacity(0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white54),
        ),
      ],
    );
  }
}
