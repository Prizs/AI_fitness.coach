import re
import sys

path = 'mobile_app/lib/screens/workout_schedule_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Fix the import dart:convert at the top
if "import 'dart:convert';" not in text:
    text = "import 'dart:convert';\n" + text

# Remove the inline import dart:convert inside the block
text = text.replace("import 'dart:convert';", "", text.count("import 'dart:convert';") - 1)

# Fix DaySchedule creation (meals instead of nutrition)
text = text.replace("List<NutritionItem> nutrition = [];", "Map<String, String> meals = {};")
text = text.replace("if (nut['desayuno'] != null) nutrition.add(NutritionItem(meal: 'Desayuno', description: nut['desayuno']));", "if (nut['desayuno'] != null) meals['Desayuno'] = nut['desayuno'];")
text = text.replace("if (nut['almuerzo'] != null) nutrition.add(NutritionItem(meal: 'Almuerzo', description: nut['almuerzo']));", "if (nut['almuerzo'] != null) meals['Almuerzo'] = nut['almuerzo'];")
text = text.replace("if (nut['cena'] != null) nutrition.add(NutritionItem(meal: 'Cena', description: nut['cena']));", "if (nut['cena'] != null) meals['Cena'] = nut['cena'];")
text = text.replace("if (nut['snack'] != null) nutrition.add(NutritionItem(meal: 'Snack', description: nut['snack']));", "if (nut['snack'] != null) meals['Snack'] = nut['snack'];")
text = text.replace("nutrition: nutrition,", "meals: meals,")
text = text.replace("nutrition: [],", "meals: {},")

# I also introduced syntax errors:
# lib/screens/workout_schedule_screen.dart:174:43: Error: Can't find ']' to match '['.
#             if (!currentDay.isRestDay) ...[
#                                           ^
# Let's fix the syntax errors. The issue was that the e.sub(r"builder: \(ctx\) => _Interactive3DViewer\(exercise: ex\),", ...) 
# was done on top of a replaced onPressed: () { ... } but maybe my ix_workout_schedule3.py regex ate too much or too little!
# Let's see what it looks like around line 174!
