import os

path = 'mobile_app/lib/services/weekly_plan_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace('Aviso: La generaciÃ³n de IA tomÃ³ mucho tiempo o fallÃ³. Vuelve a intentarlo.', 'Aviso: La generación de la rutina tomó mucho tiempo o falló la conexión. Vuelve a intentarlo.')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
