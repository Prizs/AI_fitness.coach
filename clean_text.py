import os

path = 'mobile_app/lib/screens/trainer/client_detail_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

replacements = {
    'Ã­': 'í',
    'Ã³': 'ó',
    'Ã¡': 'á',
    'Ã©': 'é',
    'Ãº': 'ú',
    'Ã±': 'ñ',
    'Ã': 'í', # sometimes it's just this
    'NutriciÃ³n': 'Nutrición',
    'AnÃ¡lisis': 'Análisis',
    'biografÃ­a': 'biografía',
    'InformaciÃ³n': 'Información',
    'aÃ±os': 'años',
    'PatologÃ­as': 'Patologías',
    'DÃ­a': 'Día',
    'GlÃºteos': 'Glúteos',
    'MÃ¡quinas': 'Máquinas',
    'CuÃ¡driceps': 'Cuádriceps',
    'maÃ±ana': 'mañana',
    'AlimentaciÃ³n': 'Alimentación',
    'CalorÃ­as': 'Calorías',
    'ProteÃ­na': 'Proteína',
    'plÃ¡tano': 'plátano',
    'progresiÃ³n': 'progresión',
    'Ã“ptima': 'Óptima',
    'sustituyÃ³': 'sustituyó',
    'menÃºs': 'menús',
    'ConsultorÃ­a': 'Consultoría',
    'Â¿QuÃ©': '¿Qué',
    'especÃ­fico': 'específico',
    'elÃ­ptica': 'elíptica',
    'lubricaciÃ³n': 'lubricación'
}

for k, v in replacements.items():
    text = text.replace(k, v)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
