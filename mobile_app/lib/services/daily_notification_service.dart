import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_app/database/db_helper.dart';
import 'package:mobile_app/services/weekly_plan_service.dart';

class DailyNotificationService extends ChangeNotifier {
  static final DailyNotificationService instance = DailyNotificationService._init();
  DailyNotificationService._init();

  static const String _blockTimeKey = 'user_workout_block_time_v1';
  static const String _lastAnsweredDateKey = 'user_last_answered_survey_date_v1';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  TimeOfDay _workoutBlockTime = const TimeOfDay(hour: 18, minute: 0); // 18:00 por defecto
  bool _isInitialized = false;

  TimeOfDay get workoutBlockTime => _workoutBlockTime;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final stored = await _storage.read(key: _blockTimeKey);
      if (stored != null && stored.contains(':')) {
        final parts = stored.split(':');
        final h = int.tryParse(parts[0]) ?? 18;
        final m = int.tryParse(parts[1]) ?? 0;
        _workoutBlockTime = TimeOfDay(hour: h, minute: m);
      }
    } catch (_) {}
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setWorkoutBlockTime(TimeOfDay time) async {
    _workoutBlockTime = time;
    notifyListeners();
    try {
      await _storage.write(key: _blockTimeKey, value: '${time.hour}:${time.minute}');
    } catch (_) {}
  }

  String get formattedBlockTime {
    final h = _workoutBlockTime.hour.toString().padLeft(2, '0');
    final m = _workoutBlockTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get formatted3hPriorTime {
    int h = _workoutBlockTime.hour - 3;
    if (h < 0) h += 24;
    final hStr = h.toString().padLeft(2, '0');
    final mStr = _workoutBlockTime.minute.toString().padLeft(2, '0');
    return '$hStr:$mStr';
  }

  String get formattedFollowupTime {
    int totalMins = _workoutBlockTime.hour * 60 + _workoutBlockTime.minute + 90;
    int h = (totalMins ~/ 60) % 24;
    int m = totalMins % 60;
    final hStr = h.toString().padLeft(2, '0');
    final mStr = m.toString().padLeft(2, '0');
    return '$hStr:$mStr';
  }

  DateTime _getBlockDateTimeForToday(DateTime now) {
    return DateTime(
      now.year,
      now.month,
      now.day,
      _workoutBlockTime.hour,
      _workoutBlockTime.minute,
    );
  }

  /// Verifica si la encuesta de fatiga y completitud ya fue respondida hoy
  Future<bool> isSurveyAnsweredToday() async {
    try {
      final lastDate = await _storage.read(key: _lastAnsweredDateKey);
      if (lastDate == null) return false;
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month}-${now.day}';
      return lastDate == todayStr;
    } catch (_) {
      return false;
    }
  }

  Future<void> markSurveyAnsweredToday() async {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    try {
      await _storage.write(key: _lastAnsweredDateKey, value: todayStr);
    } catch (_) {}
    notifyListeners();
  }

  /// Notificación 1: Recordatorio con 3 horas de anticipación
  bool is3hReminderActive(DateTime now) {
    final plan = WeeklyPlanService.instance.today;
    if (plan == null) return false;
    final isTraining = (plan['exercises'] as List?)?.isNotEmpty == true || plan['is_training'] == true;
    if (!isTraining) return false;

    final blockTime = _getBlockDateTimeForToday(now);
    final reminderStart = blockTime.subtract(const Duration(hours: 3));
    return now.isAfter(reminderStart) && now.isBefore(blockTime);
  }

  /// Notificación 2: Seguimiento 1h30 (90 min) después si no se ha marcado completado
  Future<bool> isFollowupCheckinDue(DateTime now) async {
    final plan = WeeklyPlanService.instance.today;
    if (plan == null) return false;
    final isTraining = (plan['exercises'] as List?)?.isNotEmpty == true || plan['is_training'] == true;
    if (!isTraining) return false;

    // Verificar si ya completó la sesión hoy
    final isCompleted = WeeklyPlanService.instance.completedDays.contains(WeeklyPlanService.instance.todayIndex);
    if (isCompleted) return false;

    // Verificar si ya respondió la encuesta hoy
    final answered = await isSurveyAnsweredToday();
    if (answered) return false;

    final blockTime = _getBlockDateTimeForToday(now);
    final followupTime = blockTime.add(const Duration(minutes: 90));

    return now.isAfter(followupTime);
  }

  /// Cálculo promedio de calorías verificables para una sesión
  int calculateEstimatedCalories({
    required double userWeightKg,
    required int durationMinutes,
    required int rpe,
  }) {
    // Fórmula basada en METs verificables según RPE (5.0 a 7.5 METs)
    double met = 5.0;
    if (rpe >= 8) {
      met = 7.0;
    } else if (rpe >= 6) {
      met = 6.0;
    }
    final hours = durationMinutes / 60.0;
    return (met * userWeightKg * hours).round();
  }

  /// Registra el resultado del check-in de fatiga post-entreno
  Future<void> submitCheckinSurvey({
    required bool completed,
    required int rpe,
    required String feeling,
    required int caloriesBurned,
    String? notes,
  }) async {
    final weekday = WeeklyPlanService.instance.todayIndex;
    final todayPlan = WeeklyPlanService.instance.today;
    final title = todayPlan?['title'] ?? 'Entrenamiento del día';

    if (completed) {
      await DBHelper.instance.recordWorkoutSession(
        weekday: weekday,
        title: title,
        rpe: rpe,
        feeling: feeling,
        notes: notes != null ? '$notes | Calorías estimadas: $caloriesBurned kcal' : 'Calorías: $caloriesBurned kcal',
      );
      await WeeklyPlanService.instance.refreshWorkoutStats();
    }

    await markSurveyAnsweredToday();
  }
}
