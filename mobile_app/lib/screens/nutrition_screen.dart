import 'package:flutter/material.dart';
import 'package:mobile_app/screens/coach_screen.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/weekly_plan_service.dart';

/// Nutricion del dia de la semana en el que esta el telefono.
///
/// Al abrir muestra siempre el dia actual (por ejemplo, el viernes) y permite
/// moverse a cualquier otro dia. Cada dia trae su propio menu, y arriba se
/// explica la sinergia entre el entrenamiento y la comida de ese dia.
class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final WeeklyPlanService _service = WeeklyPlanService.instance;

  /// Dia seleccionado. Arranca en el dia real del telefono.
  late int _selected = _service.todayIndex;

  @override
  void initState() {
    super.initState();
    _ensure();
  }

  void _ensure() {
    // ensureLoaded no vuelve a pedir el plan si ya esta en memoria, por lo que
    // la pantalla aparece de inmediato en lugar de quedarse en blanco.
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
              CircularProgressIndicator(),
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

    final rawNutrition = day['nutrition'];
    final List<Map<String, dynamic>> meals = [];
    if (rawNutrition is List) {
      for (final m in rawNutrition) {
        if (m is Map) {
          meals.add(Map<String, dynamic>.from(m));
        }
      }
    } else if (rawNutrition is Map) {
      rawNutrition.forEach((key, val) {
        final keyStr = key.toString();
        final title = keyStr.isEmpty
            ? 'Comida'
            : keyStr[0].toUpperCase() + keyStr.substring(1);
        List<dynamic> items = [];
        if (val is List) {
          items = val;
        } else if (val != null) {
          final str = val.toString().trim();
          if (str.isNotEmpty) {
            items = str
                .split('\n')
                .map((s) => s.trim().replaceAll(RegExp(r'^[•\-\*]\s*'), ''))
                .where((s) => s.isNotEmpty)
                .toList();
          }
        }
        meals.add({
          'title': title,
          'items': items,
        });
      });
    }
    final isToday = _selected == _service.todayIndex;

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
              ? 'Hoy es ${_service.todayName} · menu de hoy'
              : 'Menu de ${_weekdayName(_selected)}',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        _WeekStrip(
          selected: _selected,
          trainingDays: _trainingDays(),
          onSelect: (index) => setState(() => _selected = index),
        ),
        const SizedBox(height: 18),
        _DayHeader(day: day, isToday: isToday),
        if (day['synergy'] != null && '${day['synergy']}'.isNotEmpty) ...[
          const SizedBox(height: 14),
          _SynergyCard(text: '${day['synergy']}'),
        ],
        const SizedBox(height: 18),
        ...meals.map(
          (meal) => _MealCard(meal: Map<String, dynamic>.from(meal as Map)),
        ),
        if (meals.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text('No hay menu para este dia.',
                style: TextStyle(color: Colors.white54)),
          ),
        const SizedBox(height: 8),
        const Text(
          'Plan general orientativo. Suspende si aparece dolor y consulta a un '
          'profesional de salud.',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  /// Dias marcados como entrenamiento, para distinguirlos en la tira.
  List<int> _trainingDays() => _service.days
      .where((d) => d['is_training'] == true)
      .map((d) => d['weekday'] as int)
      .toList();

  String _weekdayName(int index) => const [
        'Lunes',
        'Martes',
        'Miercoles',
        'Jueves',
        'Viernes',
        'Sabado',
        'Domingo',
      ][index];
}

/// Tira de los 7 dias. El punto verde marca los dias con entrenamiento.
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
    'Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado', 'Domingo',
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
                      : _names[index],
                  child: Container(
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
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? const Color(0xFF0B1220)
                                : Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: trains
                                ? (isSelected
                                    ? const Color(0xFF0B1220)
                                    : const Color(0xFF8BE0C0))
                                : Colors.transparent,
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

/// Encabezado del dia: que toca entrenar y si hoy es el dia actual.
class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.isToday});

  final Map<String, dynamic> day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final trains = day['is_training'] == true;
    return Row(
      children: [
        Expanded(
          child: Text(
            '${day['title']}',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        if (isToday)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF8BE0C0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('HOY',
                style: TextStyle(
                    color: Color(0xFF0B1220),
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
          ),
        if (!trains)
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text('Descanso',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
          ),
      ],
    );
  }
}

/// Explica como se combinan entrenamiento y alimentacion ese dia.
class _SynergyCard extends StatelessWidget {
  const _SynergyCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D3557), Color(0xFF16233A)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8BE0C0), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bolt_rounded, color: Color(0xFF8BE0C0)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sinergia del dia',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF8BE0C0))),
                const SizedBox(height: 6),
                Text(text, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.restaurant_menu_rounded,
                size: 56, color: Color(0xFF8BE0C0)),
            const SizedBox(height: 14),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, height: 1.5)),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2DD4BF),
                foregroundColor: const Color(0xFF0B1220),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.smart_toy_rounded),
              label: const Text(
                'Crear mi plan en Coach IA',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal});
  final Map<String, dynamic> meal;

  @override
  Widget build(BuildContext context) {
    final items = (meal['items'] as List<dynamic>?) ?? [];
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              meal['title'] as String? ?? 'Comida',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2DD4BF),
              ),
            ),
            const SizedBox(height: 8),
            ...items.map(
              (item) => Text(
                '• $item',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
