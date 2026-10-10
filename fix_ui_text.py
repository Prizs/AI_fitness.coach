import sys

path = 'mobile_app/lib/screens/workout_schedule_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_dyn = '''                            id: e.name,
                            name: e.name,
                            shortName: e.name,
                            gifUrl: url,
                            agonist: e.primaryMuscle,
                            synergists: [e.secondaryMuscle],
                            biomechanics: 'Activación dinámica sugerida por IA.',
                            tempo: '3-1-1',
                            posture: 'Mantén la postura natural.',
                            warning: 'Consulta a tu entrenador si sientes dolor.''''

new_dyn = '''                            id: e.name,
                            name: e.name,
                            shortName: e.name,
                            gifUrl: url,
                            agonist: e.primaryMuscle,
                            synergists: [e.secondaryMuscle],
                            biomechanics: e.biomechanics,
                            tempo: '3-1-1',
                            posture: e.posture,
                            warning: 'Si experimentas dolor articular, detén el ejercicio.''''

text = text.replace(old_dyn, new_dyn)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
