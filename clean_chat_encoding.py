import os

files = [
    'mobile_app/lib/screens/client_trainer_tab.dart',
    'mobile_app/lib/screens/trainer/trainer_messages_tab.dart'
]

replacements = {
    'PÃ©rez': 'Pérez',
    'GÃ³mez': 'Gómez',
    'PÃ©rdida': 'Pérdida',
    'RehabilitaciÃ³n': 'Rehabilitación',
    'RincÃ³n': 'Rincón',
    'diseÃ±e': 'diseñe',
    'NutriciÃ³n': 'Nutrición',
    'aprobaciÃ³n': 'aprobación',
    'LÃ­nea': 'línea',
    'en lÃ­nea': 'en línea'
}

for path in files:
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            text = f.read()
        for k, v in replacements.items():
            text = text.replace(k, v)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(text)
