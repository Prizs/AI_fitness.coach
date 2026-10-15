import os
import re

path = 'mobile_app/lib/screens/coach_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Make sure we import the plan_options_sheet
if "import 'package:mobile_app/widgets/plan_options_sheet.dart';" not in text:
    text = text.replace("import 'package:mobile_app/screens/anatomy_workout_screen.dart';", "import 'package:mobile_app/screens/anatomy_workout_screen.dart';\nimport 'package:mobile_app/widgets/plan_options_sheet.dart';")

# Find the row with Agregar a Cronograma and the Ver 3D button.
# Let's completely rewrite the Row that contains the button.
pattern = r'Row\(\s*children: \[\s*Expanded\(\s*child: ElevatedButton\.icon\(\s*style: ElevatedButton\.styleFrom\(\s*backgroundColor: const Color\(0xFF8BE0C0\),\s*foregroundColor: Colors\.black,\s*\),\s*icon: const Icon\(Icons\.add_task_rounded, size: 16\),\s*label: const Text\(\'Agregar a Cronograma\'.*?\}\s*\),\s*\]\s*\)'

new_row = '''Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF8BE0C0),
                                        foregroundColor: Colors.black,
                                      ),
                                      icon: const Icon(Icons.settings_suggest_rounded, size: 16),
                                      label: const Text('Configurar Intensidad y Generar Plan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                                      onPressed: () {
                                        final aiSuggestedText = msg['text'] ?? '';
                                        // Extraemos un resumen de los ejercicios sugeridos si existe plan
                                        String prompt = 'Genera un cronograma basado en esto: ';
                                        if (plan != null && plan['exercises'] != null) {
                                          final exNames = (plan['exercises'] as List).map((e) => e['name']).join(', ');
                                          prompt += exNames;
                                        } else {
                                          prompt += aiSuggestedText.length > 100 ? aiSuggestedText.substring(0, 100) : aiSuggestedText;
                                        }
                                        
                                        showPlanOptionsSheet(context, initialPrompt: prompt);
                                      },
                                    ),
                                  ),
                                ],
                              )'''

text = re.sub(pattern, new_row, text, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
