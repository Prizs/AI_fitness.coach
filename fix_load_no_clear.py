import os

path = 'mobile_app/lib/services/weekly_plan_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace('await DBHelper.instance.clearWeeklyPlan();', '// ignore invalid cache\n            print("Cache invalido");')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
