import 'package:flutter/material.dart';
import 'package:mobile_app/screens/coach_screen.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/weekly_plan_service.dart';
import 'package:mobile_app/data/nutrition_database.dart';

/// Nutrición de la semana diversificada por objetivos y guías nutricionales accesibles.
class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final WeeklyPlanService _service = WeeklyPlanService.instance;

  /// Día seleccionado (0 = Lunes ... 6 = Domingo).
  late int _selected = _service.todayIndex;

  /// Objetivo nutricional seleccionado. Por defecto 'musculo'.
  String _selectedGoal = 'musculo';

  @override
  void initState() {
    super.initState();
    _syncGoalFromService();
    _ensure();
  }

  void _syncGoalFromService() {
    final goalLower = (_service.userGoal).toLowerCase();
    if (goalLower.contains('perder') ||
        goalLower.contains('bajar') ||
        goalLower.contains('grasa') ||
        goalLower.contains('defin')) {
      _selectedGoal = 'grasa';
    } else if (goalLower.contains('resistencia') ||
        goalLower.contains('cardio') ||
        goalLower.contains('correr')) {
      _selectedGoal = 'resistencia';
    } else if (goalLower.contains('salud') ||
        goalLower.contains('energía') ||
        goalLower.contains('bienestar')) {
      _selectedGoal = 'salud';
    } else {
      _selectedGoal = 'musculo';
    }
  }

  void _ensure() {
    _service.ensureLoaded(AuthService.instance.loggedInUser);
  }

  void _openCoach() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CoachScreen()),
    );
  }

  Map<String, dynamic>? get _day {
    for (final day in _service.days) {
      if (day['weekday'] == _selected) return day;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _service,
          builder: (context, _) => _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_service.week == null) {
      if (_service.isLoading) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF8BE0C0)),
              SizedBox(height: 14),
              Text('Sincronizando tu semana...',
                  style: TextStyle(color: Colors.white70)),
            ],
          ),
        );
      }
      return _EmptyState(
        message:
            'Aún no tienes un plan nutricional semanal programado.\n\nPresiona el botón de abajo para ir al módulo Coach IA, solicitar tu rutina y agregar tu plan nutricional a la semana.',
        onRetry: _openCoach,
      );
    }

    final day = _day;
    if (day == null) return const SizedBox.shrink();

    final isTraining = day['is_training'] == true;
    final databasePlan = NutritionDatabase.getPlanForDay(
      goalId: _selectedGoal,
      weekday: _selected,
      isTrainingDay: isTraining,
    );

    // Los planes de alimentación de la semana se adaptan dinámicamente al objetivo seleccionado con ingredientes 100% de mercado venezolano
    final activeMeals = (databasePlan['meals'] as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final synergyText = databasePlan['synergy'] as String;


    final isToday = _selected == _service.todayIndex;
    final currentGoalMeta = NutritionDatabase.goals.firstWhere(
      (g) => g['id'] == _selectedGoal,
      orElse: () => NutritionDatabase.goals[0],
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Nutrición de la Semana',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF8BE0C0),
                backgroundColor: const Color(0xFF16233A),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _openCoach,
              icon: const Icon(Icons.smart_toy_rounded, size: 18),
              label: const Text(
                'Ir a Coach IA',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          isToday
              ? 'Hoy es ${_service.todayName} · Menú sugerido del día'
              : 'Menú de ${_weekdayName(_selected)}',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 16),

        // Selector Horizontal de Objetivos y Guías Nutricionales Accesibles
        const Text(
          'GUÍA NUTRICIONAL Y OBJETIVO DE ALIMENTACIÓN:',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: Color(0xFF8BE0C0),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: NutritionDatabase.goals.map((g) {
              final isSelected = g['id'] == _selectedGoal;
              final color = Color(g['color'] as int);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      _selectedGoal = g['id'] as String;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withOpacity(0.2)
                          : const Color(0xFF141F32),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : Colors.white12,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Text(
                      g['label'] as String,
                      style: TextStyle(
                        color: isSelected ? color : Colors.white70,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w500,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // Tarjeta Explicativa de la Guía Seleccionada
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF101C2F),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Color(currentGoalMeta['color'] as int).withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🥗 ${currentGoalMeta['title']}',
                style: TextStyle(
                  color: Color(currentGoalMeta['color'] as int),
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${currentGoalMeta['description']}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '💡 Pauta práctica: ${currentGoalMeta['principles']}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _WeekStrip(
          selected: _selected,
          trainingDays: _trainingDays(),
          onSelect: (index) => setState(() => _selected = index),
        ),
        const SizedBox(height: 18),
        _DayHeader(day: day, isToday: isToday),
        if (synergyText.isNotEmpty) ...[
          const SizedBox(height: 14),
          _SynergyCard(text: synergyText),
        ],
        const SizedBox(height: 18),
        ...activeMeals.map(
          (meal) => _MealCard(meal: Map<String, dynamic>.from(meal as Map)),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF141F32),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.eco_rounded, size: 16, color: Color(0xFF8BE0C0)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Alimentos venezolanos accesibles: Este plan prioriza ingredientes económicos y fáciles de conseguir en tu mercado local en Venezuela (arepa de maíz, huevos pericos, pollo, carne molida magra, atún, sardinas, caraotas/lentejas, arroz, batata, yuca, plátano verde o maduro, avena, cambur, lechosa y queso blanco criollo).',
                  style: TextStyle(color: Colors.white60, fontSize: 11.5, height: 1.35),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  List<int> _trainingDays() => _service.days
      .where((d) => d['is_training'] == true)
      .map((d) => d['weekday'] as int)
      .toList();

  String _weekdayName(int index) => const [
        'Lunes',
        'Martes',
        'Miércoles',
        'Jueves',
        'Viernes',
        'Sábado',
        'Domingo',
      ][index];
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.selected,
    required this.trainingDays,
    required this.onSelect,
  });

  final int selected;
  final List<int> trainingDays;
  final ValueChanged<int> onSelect;

  static const _labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  static const _names = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: Row(
        children: List.generate(7, (index) {
          final isSelected = index == selected;
          final trains = trainingDays.contains(index);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onSelect(index),
                child: Tooltip(
                  message: trains
                      ? '${_names[index]} · entrenamiento'
                      : '${_names[index]} · descanso',
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF8BE0C0)
                          : const Color(0xFF16233A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _labels[index],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? const Color(0xFF0B1220)
                                : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0B1220)
                                : (trains
                                    ? const Color(0xFF8BE0C0)
                                    : Colors.white24),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.isToday});

  final Map<String, dynamic> day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final title = '${day['title'] ?? 'Día'}';
    final isTraining = day['is_training'] == true;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (isToday)
          Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF8BE0C0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'HOY',
              style: TextStyle(
                color: Color(0xFF0B1220),
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isTraining
                ? const Color(0xFF173B45)
                : const Color(0xFF16233A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isTraining
                  ? const Color(0xFF8BE0C0).withOpacity(0.4)
                  : Colors.white12,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isTraining
                    ? Icons.fitness_center_rounded
                    : Icons.self_improvement_rounded,
                size: 14,
                color: isTraining
                    ? const Color(0xFF8BE0C0)
                    : Colors.white60,
              ),
              const SizedBox(width: 4),
              Text(
                isTraining ? 'Entrenamiento' : 'Descanso',
                style: TextStyle(
                  color: isTraining
                      ? const Color(0xFF8BE0C0)
                      : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SynergyCard extends StatelessWidget {
  const _SynergyCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF16233A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF8BE0C0).withOpacity(0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bolt_rounded, size: 20, color: Color(0xFF8BE0C0)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal});
  final Map<String, dynamic> meal;

  @override
  Widget build(BuildContext context) {
    final title = '${meal['title'] ?? 'Comida'}';
    final items = (meal['items'] as List<dynamic>?) ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF101B2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8BE0C0),
              ),
            ),
            const SizedBox(height: 10),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(
                          color: Color(0xFF8BE0C0),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '$item',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.restaurant_menu_rounded,
              size: 58,
              color: Color(0xFF8BE0C0),
            ),
            const SizedBox(height: 16),
            const Text(
              'Plan Nutricional',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.45),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8BE0C0),
                foregroundColor: const Color(0xFF0B1220),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.smart_toy_rounded),
              label: const Text(
                'Solicitar nutrición en Coach IA',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
