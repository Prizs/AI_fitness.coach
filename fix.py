import sys
path = 'mobile_app/lib/screens/coach_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("onPressed: () {\n                                          Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutScheduleScreen()));\n                                        },", "onPressed: () async {\n                                          if (plan != null) {\n                                            await WeeklyPlanService.instance.injectCustomPlanForToday(plan);\n                                            if (!context.mounted) return;\n                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Guardado! Ve a Rutinas o Nutrición.'), backgroundColor: Color(0xFF173B45)));\n                                          }\n                                        },")
text = text.replace("import 'package:mobile_app/models/user_profile.dart';", "import 'package:mobile_app/models/user_profile.dart';\nimport 'package:mobile_app/services/weekly_plan_service.dart';")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
