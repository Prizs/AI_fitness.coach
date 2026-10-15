import os

path = 'mobile_app/lib/screens/coach_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Make sure we import the plan_options_sheet
if "import 'package:mobile_app/widgets/plan_options_sheet.dart';" not in text:
    text = text.replace("import 'package:mobile_app/screens/anatomy_workout_screen.dart';", "import 'package:mobile_app/screens/anatomy_workout_screen.dart';\nimport 'package:mobile_app/widgets/plan_options_sheet.dart';")


old_btn = '''label: const Text('Agregar a Cronograma', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                                      onPressed: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutScheduleScreen()));
                                      },'''

new_btn = '''label: const Text('Configurar Intensidad y Generar Plan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                                      onPressed: () {
                                        final aiSuggestedText = msg['text'] as String? ?? '';
                                        String prompt = 'Quiero seguir el plan sugerido: ';
                                        if (plan != null && plan['exercises'] != null) {
                                          final exNames = (plan['exercises'] as List).map((e) => e['name']).join(', ');
                                          prompt += exNames;
                                        } else {
                                          prompt += aiSuggestedText.length > 80 ? aiSuggestedText.substring(0, 80) : aiSuggestedText;
                                        }
                                        showPlanOptionsSheet(context, initialPrompt: prompt);
                                      },'''

text = text.replace(old_btn, new_btn)

old_quick = '''  final List<String> _quickPrompts = [
    'Mejorar resistencia pulmonar',
    'Registrar entrenamiento completado',
    'Tengo una molestia / cambiar ejercicio',
    'Ajustar plan nutricional',
  ];'''

new_quick = '''  final List<String> _quickPrompts = [
    'Crear nueva rutina de entrenamiento',
    'Registrar entrenamiento completado',
    'Tengo una molestia / cambiar ejercicio',
    'Ajustar plan nutricional',
  ];'''

text = text.replace(old_quick, new_quick)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
