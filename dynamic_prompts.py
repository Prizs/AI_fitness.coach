import os
import re

path = 'mobile_app/lib/screens/coach_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Replace the hardcoded _quickPrompts with _defaultQuickPrompts and a getter.
old_list = '''  final List<String> _quickPrompts = [
    'Crear nueva rutina de entrenamiento',
    'Registrar entrenamiento completado',
    'Tengo una molestia / cambiar ejercicio',
    'Ajustar plan nutricional',
  ];'''

new_list = '''  final List<String> _defaultQuickPrompts = [
    'Crear nueva rutina de entrenamiento',
    'Registrar entrenamiento completado',
    'Ajustar plan nutricional',
  ];

  List<String> get _currentQuickPrompts {
    if (_messages.isEmpty) return _defaultQuickPrompts;
    
    // Buscar el ultimo mensaje de la IA
    final aiMessages = _messages.where((m) => m['isUser'] == false).toList();
    if (aiMessages.isEmpty) return _defaultQuickPrompts;
    
    final lastAiMsg = aiMessages.last;
    final text = (lastAiMsg['text'] as String).toLowerCase();
    
    if (text.contains('dónde') && (text.contains('duele') || text.contains('molestia'))) {
      return ['Rodilla', 'Espalda baja', 'Hombro', 'Cuello', 'Ninguna'];
    }
    if (text.contains('sientes') || text.contains('física') || text.contains('molestia') || text.contains('dolor')) {
      return ['Me siento al 100%', 'Tengo una molestia', 'Estoy cansado'];
    }
    if (text.contains('equipo') || text.contains('gimnasio') || text.contains('pesas')) {
      return ['Gym Completo', 'Herramientas en Casa', 'Sin herramientas'];
    }
    if (text.contains('intensidad') || text.contains('esfuerzo')) {
      return ['Intensidad Baja', 'Intensidad Media', 'Intensidad Alta'];
    }
    
    return _defaultQuickPrompts;
  }'''

text = text.replace(old_list, new_list)

# 2. Re-enable sending 'Crear nueva rutina...' to AI
old_send = '''    if (text == 'Crear nueva rutina de entrenamiento') {
      showPlanOptionsSheet(context);
      return;
    }'''

text = text.replace(old_send, "")

# 3. Update the builder to use _currentQuickPrompts
text = text.replace('_quickPrompts.map', '_currentQuickPrompts.map')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
