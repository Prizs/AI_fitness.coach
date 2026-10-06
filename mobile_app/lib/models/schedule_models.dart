  class ExerciseItem {
  final String name;
  final int sets;
  final String reps;
  final String animationKey;
  final String primaryMuscle;
  final String secondaryMuscle;
  final String biomechanics;
  final String posture;
  bool isCompleted;
  int? rpe;

  ExerciseItem({
    required this.name,
    required this.sets,
    required this.reps,
    required this.animationKey,
    this.primaryMuscle = 'General',
    this.secondaryMuscle = 'Secundario',
    this.biomechanics = 'Activación dinámica sugerida por IA.',
    this.posture = 'Mantén la postura natural.',
    this.isCompleted = false,
    this.rpe,
  });

  factory ExerciseItem.fromJson(Map<String, dynamic> json) {
    return ExerciseItem(
      name: json['name'] as String? ?? 'Ejercicio',
      sets: json['sets'] is int ? json['sets'] as int : int.tryParse('${json['sets']}') ?? 3,
      reps: json['reps']?.toString() ?? '10',
      animationKey: json['animation_key'] as String? ?? 'generic',
      primaryMuscle: json['primary_muscle'] as String? ?? 'General',
      secondaryMuscle: json['secondary_muscle'] as String? ?? 'Secundario',
      biomechanics: json['biomechanics'] as String? ?? 'Activación dinámica sugerida por IA.',
      posture: json['posture'] as String? ?? 'Mantén la postura natural.',
      isCompleted: json['is_completed'] as bool? ?? false,
      rpe: json['rpe'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'sets': sets,
    'reps': reps,
    'animation_key': animationKey,
    'primary_muscle': primaryMuscle,
    'secondary_muscle': secondaryMuscle,
    'biomechanics': biomechanics,
    'posture': posture,
    'is_completed': isCompleted,
    'rpe': rpe,
  };
}

class DaySchedule {
  final String dayName;
  final String title;
  final String focus;
  final bool isRestDay;
  final List<ExerciseItem> exercises;
  final Map<String, String> meals;
  bool isSessionCompleted;

  DaySchedule({
    required this.dayName,
    required this.title,
    this.focus = 'General',
    this.isRestDay = false,
    required this.exercises,
    required this.meals,
    this.isSessionCompleted = false,
  });
}