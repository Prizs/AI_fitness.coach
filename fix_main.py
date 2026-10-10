import sys

path = 'mobile_app/lib/main.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Replace TrainerDashboardScreen with TrainerShell
text = text.replace("import 'package:mobile_app/screens/trainer_dashboard_screen.dart';", "import 'package:mobile_app/screens/trainer/trainer_shell.dart';")
text = text.replace("return const TrainerDashboardScreen();", "return const TrainerShell();")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
