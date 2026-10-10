import sys
import re

# 1. Fix workouts_screen.dart
path1 = 'mobile_app/lib/screens/workouts_screen.dart'
with open(path1, 'r', encoding='utf-8') as f:
    t1 = f.read()

t1 = t1.replace("ex.get('biomechanics', 'Biomecánica sugerida por IA.')", "ex['biomechanics'] as String? ?? 'Biomecánica sugerida por IA.'")
t1 = t1.replace("ex.get('posture', 'Mantén la postura natural.')", "ex['posture'] as String? ?? 'Mantén la postura natural.'")
with open(path1, 'w', encoding='utf-8') as f:
    f.write(t1)

# 2. Fix schedule_models.dart
path2 = 'mobile_app/lib/models/schedule_models.dart'
with open(path2, 'r', encoding='utf-8') as f:
    t2 = f.read()

old_fields = '''  final String secondaryMuscle;
  bool isCompleted;'''

new_fields = '''  final String secondaryMuscle;
  final String biomechanics;
  final String posture;
  bool isCompleted;'''

t2 = t2.replace(old_fields, new_fields)

old_ctor = '''    this.secondaryMuscle = 'Secundario',
    this.isCompleted = false,'''

new_ctor = '''    this.secondaryMuscle = 'Secundario',
    this.biomechanics = 'Activación dinámica sugerida por IA.',
    this.posture = 'Mantén la postura natural.',
    this.isCompleted = false,'''

t2 = t2.replace(old_ctor, new_ctor)

old_json = '''      secondaryMuscle: json['secondary_muscle'] as String? ?? 'Secundario',
      isCompleted: json['is_completed'] as bool? ?? false,'''

new_json = '''      secondaryMuscle: json['secondary_muscle'] as String? ?? 'Secundario',
      biomechanics: json['biomechanics'] as String? ?? 'Activación dinámica sugerida por IA.',
      posture: json['posture'] as String? ?? 'Mantén la postura natural.',
      isCompleted: json['is_completed'] as bool? ?? false,'''

t2 = t2.replace(old_json, new_json)

old_tojson = '''    'secondary_muscle': secondaryMuscle,
    'is_completed': isCompleted,'''

new_tojson = '''    'secondary_muscle': secondaryMuscle,
    'biomechanics': biomechanics,
    'posture': posture,
    'is_completed': isCompleted,'''

t2 = t2.replace(old_tojson, new_tojson)

with open(path2, 'w', encoding='utf-8') as f:
    f.write(t2)
