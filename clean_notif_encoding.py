import os

files = [
    'mobile_app/lib/screens/notifications_screen.dart',
    'mobile_app/lib/screens/trainer/trainer_agenda_tab.dart'
]

replacements = {
    'atenciÃ³n': 'atención',
    'MediodÃ­a': 'Mediodía',
    'VERSIÃ“N': 'VERSIÓN'
}

for path in files:
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            text = f.read()
        for k, v in replacements.items():
            text = text.replace(k, v)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(text)
