import 'package:flutter/material.dart';
import 'package:mobile_app/services/weekly_plan_service.dart';

/// Modal estilo Calendario de Windows para visualizar los días del mes,
/// días de entrenamiento programados (con punto indicador), hoy resaltado en azul cyan,
/// y detalle de la rutina del día seleccionado.
class WindowsCalendarDialog extends StatefulWidget {
  const WindowsCalendarDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (ctx) => const WindowsCalendarDialog(),
    );
  }

  @override
  State<WindowsCalendarDialog> createState() => _WindowsCalendarDialogState();
}

class _WindowsCalendarDialogState extends State<WindowsCalendarDialog> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;
  final WeeklyPlanService _service = WeeklyPlanService.instance;

  final List<String> _weekHeaders = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  final List<String> _monthNames = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  /// Verifica si una fecha corresponde al ciclo activo actual
  bool _isInActiveCycle(DateTime d) {
    final start = _service.currentWeekMonday;
    final end = _service.currentWeekSunday;
    final dOnly = DateTime(d.year, d.month, d.day);
    final sOnly = DateTime(start.year, start.month, start.day);
    final eOnly = DateTime(end.year, end.month, end.day);
    return (dOnly.isAfter(sOnly) || dOnly.isAtSameMomentAs(sOnly)) &&
           (dOnly.isBefore(eOnly) || dOnly.isAtSameMomentAs(eOnly));
  }

  /// Verifica si una fecha corresponde al próximo ciclo planificado
  bool _isInUpcomingCycle(DateTime d) {
    if (!_service.hasUpcomingPlan) return false;
    final nextM = _service.nextCycleMonday;
    final nextEnd = nextM.add(const Duration(days: 6));
    final dOnly = DateTime(d.year, d.month, d.day);
    final sOnly = DateTime(nextM.year, nextM.month, nextM.day);
    final eOnly = DateTime(nextEnd.year, nextEnd.month, nextEnd.day);
    return (dOnly.isAfter(sOnly) || dOnly.isAtSameMomentAs(sOnly)) &&
           (dOnly.isBefore(eOnly) || dOnly.isAtSameMomentAs(eOnly));
  }

  /// Obtiene la información del día (ejercicios, título, descanso)
  Map<String, dynamic>? _getDayDataForDate(DateTime d) {
    final dWeekday = (d.weekday - 1); // 0=Lunes, 6=Domingo

    if (_isInActiveCycle(d)) {
      final days = _service.days;
      for (var day in days) {
        if (day['weekday'] == dWeekday) {
          return Map<String, dynamic>.from(day);
        }
      }
    } else if (_isInUpcomingCycle(d)) {
      final upcomingDays = _service.upcomingDays;
      for (var day in upcomingDays) {
        if (day['weekday'] == dWeekday) {
          return Map<String, dynamic>.from(day);
        }
      }
    }
    return null;
  }

  bool _hasWorkoutOnDate(DateTime d) {
    final data = _getDayDataForDate(d);
    if (data == null) return false;
    final exs = data['exercises'];
    return exs is List && exs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Calcular días de la cuadrícula (estilo Windows: 6 filas x 7 columnas)
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final prevOffset = (firstDayOfMonth.weekday - 1) % 7;
    final startDate = firstDayOfMonth.subtract(Duration(days: prevOffset));

    final List<DateTime> gridDates = [];
    for (int i = 0; i < 42; i++) {
      gridDates.add(startDate.add(Duration(days: i)));
    }

    final selectedDayData = _getDayDataForDate(_selectedDate);
    final bool isSelectedDateInActive = _isInActiveCycle(_selectedDate);
    final bool isSelectedDateInUpcoming = _isInUpcomingCycle(_selectedDate);
    final bool hasWorkout = selectedDayData != null &&
        selectedDayData['exercises'] is List &&
        (selectedDayData['exercises'] as List).isNotEmpty;

    final String monthHeaderStr =
        '${_monthNames[_currentMonth.month - 1]} de ${_currentMonth.year}';

    return Dialog(
      backgroundColor: const Color(0xFF1E242B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white12, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra superior: Mes y Año con flechas arriba/abajo como Windows
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    monthHeaderStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white70, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: _prevMonth,
                        tooltip: 'Mes anterior',
                      ),
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: _nextMonth,
                        tooltip: 'Mes siguiente',
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Cabecera de días de la semana: L  M  X  J  V  S  D
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _weekHeaders.map((header) {
                  return SizedBox(
                    width: 36,
                    child: Center(
                      child: Text(
                        header,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),

              // Cuadrícula de 6 filas x 7 columnas
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 42,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (ctx, index) {
                  final date = gridDates[index];
                  final isCurrentMonth = date.month == _currentMonth.month;
                  final isToday = date.year == today.year &&
                                  date.month == today.month &&
                                  date.day == today.day;
                  final isSelected = date.year == _selectedDate.year &&
                                     date.month == _selectedDate.month &&
                                     date.day == _selectedDate.day;
                  final hasWorkout = _hasWorkoutOnDate(date);
                  final inActive = _isInActiveCycle(date);
                  final inUpcoming = _isInUpcomingCycle(date);

                  // Días anteriores a la fecha actual si ya terminó ciclo
                  final isPastCompletedCycle = date.isBefore(today) && !inActive;

                  Color textColor;
                  if (!isCurrentMonth || isPastCompletedCycle) {
                    textColor = Colors.white24;
                  } else if (isToday) {
                    textColor = Colors.white;
                  } else {
                    textColor = Colors.white;
                  }

                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // El día HOY tiene un círculo azul cyan sólido (#38BDF8 / #00B4D8) exactamente como Windows
                        color: isToday
                            ? const Color(0xFF38BDF8)
                            : (isSelected && !isToday
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.transparent),
                        border: isSelected && !isToday
                            ? Border.all(color: const Color(0xFF38BDF8), width: 1.5)
                            : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              color: isToday ? Colors.white : textColor,
                              fontSize: 13.5,
                              fontWeight: isToday ? FontWeight.w900 : FontWeight.w500,
                            ),
                          ),
                          // Indicador de entrenamiento (punto o badge) si tiene rutina pautada
                          if (hasWorkout && !isPastCompletedCycle)
                            Positioned(
                              bottom: 4,
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isToday
                                      ? Colors.white
                                      : (inUpcoming
                                          ? const Color(0xFFFFB340)
                                          : const Color(0xFF8BE0C0)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 14),

              // Detalle del día seleccionado
              _buildSelectedDayDetail(
                selectedDate: _selectedDate,
                data: selectedDayData,
                isToday: _selectedDate.year == today.year &&
                         _selectedDate.month == today.month &&
                         _selectedDate.day == today.day,
                inActiveCycle: isSelectedDateInActive,
                inUpcomingCycle: isSelectedDateInUpcoming,
                hasWorkout: hasWorkout,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDayDetail({
    required DateTime selectedDate,
    required Map<String, dynamic>? data,
    required bool isToday,
    required bool inActiveCycle,
    required bool inUpcomingCycle,
    required bool hasWorkout,
  }) {
    final daysNames = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final weekdayName = daysNames[(selectedDate.weekday - 1) % 7];
    final dateStr = '$weekdayName ${selectedDate.day} de ${_monthNames[selectedDate.month - 1]}';

    String cycleBadge = '';
    Color cycleBadgeColor = const Color(0xFF8BE0C0);
    if (inActiveCycle) {
      cycleBadge = 'Ciclo Activo (${_service.cycleDateRangeStr})';
      cycleBadgeColor = const Color(0xFF8BE0C0);
    } else if (inUpcomingCycle) {
      cycleBadge = 'Próximo Ciclo (${_service.upcomingCycleRangeStr})';
      cycleBadgeColor = const Color(0xFFFFB340);
    } else {
      cycleBadge = 'Sin ciclo pautado';
      cycleBadgeColor = Colors.white38;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141A22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dateStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF38BDF8), width: 1),
                  ),
                  child: const Text(
                    'HOY',
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.flag_rounded, size: 13, color: cycleBadgeColor),
              const SizedBox(width: 5),
              Text(
                cycleBadge,
                style: TextStyle(
                  color: cycleBadgeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (hasWorkout && data != null) ...[
            Text(
              '🏋️ ${data['title'] ?? 'Entrenamiento Programado'}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            ...((data['exercises'] as List? ?? []).take(5).map((e) {
              final ex = Map<String, dynamic>.from(e as Map);
              final exName = ex['name'] ?? 'Ejercicio';
              final sets = ex['sets'] ?? 3;
              final reps = ex['reps'] ?? '10-12';
              final muscle = ex['primary_muscle'] ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Text('• ', style: TextStyle(color: Color(0xFF8BE0C0), fontSize: 13)),
                    Expanded(
                      child: Text(
                        '$exName ($sets × $reps)',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (muscle.isNotEmpty)
                      Text(
                        muscle,
                        style: const TextStyle(color: Colors.white38, fontSize: 10.5),
                      ),
                  ],
                ),
              );
            })),
          ] else if (inActiveCycle || inUpcomingCycle) ...[
            const Row(
              children: [
                Icon(Icons.self_improvement_rounded, size: 16, color: Color(0xFF8BE0C0)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '🧘 Día Libre / Descanso y Recuperación Muscular (48-72h)',
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                  ),
                ),
              ],
            ),
          ] else ...[
            const Text(
              'No hay entrenamientos asignados en esta fecha.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
