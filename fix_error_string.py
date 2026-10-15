import os

path = 'mobile_app/lib/services/weekly_plan_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("lastError = 'Error local: \.';", "lastError = 'Hubo un error local cargando la rutina (Caché). Intenta crear una nueva.';")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
