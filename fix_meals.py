import sys

path = 'mobile_app/lib/screens/workout_schedule_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("meals['Desayuno'] = nut['desayuno'];", "meals['Desayuno'] = nut['desayuno'].toString();")
text = text.replace("meals['Almuerzo'] = nut['almuerzo'];", "meals['Almuerzo'] = nut['almuerzo'].toString();")
text = text.replace("meals['Cena'] = nut['cena'];", "meals['Cena'] = nut['cena'].toString();")
text = text.replace("meals['Snack'] = nut['snack'];", "meals['Snack'] = nut['snack'].toString();")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
