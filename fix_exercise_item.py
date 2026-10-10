import sys

path = 'mobile_app/lib/models/schedule_models.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_fields = '''class ExerciseItem {
  final String name;
  final String sets;
  final String reps;
  final String primaryMuscle;
  final String secondaryMuscle;
  final String animationKey;

  ExerciseItem({
    required this.name,
    required this.sets,
    required this.reps,
    required this.primaryMuscle,
    required this.secondaryMuscle,
    required this.animationKey,
  });

  factory ExerciseItem.fromJson(Map<String, dynamic> json) {
    return ExerciseItem(
      name: json['name']?.toString() ?? 'Ejercicio',
      sets: json['sets']?.toString() ?? '3',
      reps: json['reps']?.toString() ?? '10',
      primaryMuscle: json['primary_muscle']?.toString() ?? 'Musculo',
      secondaryMuscle: json['secondary_muscle']?.toString() ?? 'General',
      animationKey: json['animation_key']?.toString() ?? 'generic',
    );
  }
}'''

new_fields = '''class ExerciseItem {
  final String name;
  final String sets;
  final String reps;
  final String primaryMuscle;
  final String secondaryMuscle;
  final String animationKey;
  final String biomechanics;
  final String posture;

  ExerciseItem({
    required this.name,
    required this.sets,
    required this.reps,
    required this.primaryMuscle,
    required this.secondaryMuscle,
    required this.animationKey,
    required this.biomechanics,
    required this.posture,
  });

  factory ExerciseItem.fromJson(Map<String, dynamic> json) {
    return ExerciseItem(
      name: json['name']?.toString() ?? 'Ejercicio',
      sets: json['sets']?.toString() ?? '3',
      reps: json['reps']?.toString() ?? '10',
      primaryMuscle: json['primary_muscle']?.toString() ?? 'Musculo',
      secondaryMuscle: json['secondary_muscle']?.toString() ?? 'General',
      animationKey: json['animation_key']?.toString() ?? 'generic',
      biomechanics: json['biomechanics']?.toString() ?? 'Activación sugerida por IA.',
      posture: json['posture']?.toString() ?? 'Mantén la postura natural.',
    );
  }
}'''

text = text.replace(old_fields, new_fields)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
