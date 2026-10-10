import sys
import re
path = 'mobile_app/lib/screens/workout_schedule_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

replacement_builder = '''onPressed: () async {
                          showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                          List<AnatomyExercise> dyn = [];
                          for (var e in currentDay.exercises) {
                            String url = '';
                            try {
                              final res = await http.get(Uri.parse('https://ai-fitness-coach-818a.onrender.com/api/exercises/gif?query=' + Uri.encodeComponent(e.name)));
                              if (res.statusCode == 200) {
                                import 'dart:convert';
                                url = jsonDecode(res.body)['url'] ?? '';
                              }
                            } catch (_) {}
                            dyn.add(AnatomyExercise(
                              id: e.name,
                              name: e.name,
                              shortName: e.name,
                              gifUrl: url,
                              agonist: e.primaryMuscle,
                              synergists: [e.secondaryMuscle],
                              biomechanics: 'Activación dinámica sugerida por IA.',
                              tempo: '3-1-1',
                              posture: 'Mantén la postura natural.',
                              warning: 'Consulta a tu entrenador si sientes dolor.',
                            ));
                          }
                          Navigator.pop(context); // close dialog
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: const Color(0xFF0F192B),
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                            builder: (ctx) => _Interactive3DViewer(exercise: ex, dynamicExercises: dyn),
                          );
                        }'''

# Replace the whole onPressed block inside the label: const Text('3D') button
text = re.sub(r"onPressed: \(\) \{.*?(?=,\n                      \),)", replacement_builder, text, flags=re.DOTALL)

if "import 'package:http/http.dart' as http;" not in text:
    text = "import 'package:http/http.dart' as http;\nimport 'dart:convert';\n" + text

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
