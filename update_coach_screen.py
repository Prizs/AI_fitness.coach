import re

path = 'mobile_app/lib/screens/coach_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Update initial welcome message to invite defining current state
old_welcome = "'text': '¡Hola! Soy tu Coach Inteligente. Puedo adaptar tus fases de entrenamiento, diseñar cronogramas para resistencia pulmonar, fuerza o recomposición y modular tu nutrición. ¿En qué objetivo trabajamos hoy?',"
new_welcome = "'text': '¡Hola! Soy tu Coach Inteligente. Puedo adaptar tus fases de entrenamiento, diseñar cronogramas para fuerza, resistencia o recomposición y modular tu nutrición. Para calibrar tu entrenamiento con máxima precisión, por favor completa tu estado actual.',\n      'isWelcome': true,"

text = text.replace(old_welcome, new_welcome)

# 2. Add _openStateSheet method and remove _defaultQuickPrompts and _currentQuickPrompts
old_prompts_block = '''  final List<String> _defaultQuickPrompts = [
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

new_helper = '''  void _openStateSheet([String initialPrompt = '']) {
    showPlanOptionsSheet(
      context,
      initialPrompt: initialPrompt,
      onSendState: (summary) => _sendMessage(summary),
    );
  }'''

text = text.replace(old_prompts_block, new_helper)

# 3. In AppBar, add button to open state sheet
old_appbar_actions = '''        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF8BE0C0)),
            tooltip: 'Cronograma Semanal',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WorkoutScheduleScreen()),
            ),
          ),
        ],'''

new_appbar_actions = '''        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF8BE0C0)),
            tooltip: 'Enviar Estado Actual',
            onPressed: () => _openStateSheet(),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: Colors.white70),
            tooltip: 'Cronograma Semanal',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WorkoutScheduleScreen()),
            ),
          ),
        ],'''

text = text.replace(old_appbar_actions, new_appbar_actions)

# 4. In message builder, show 'Completar Mi Estado Actual' button if isWelcome == true and messages.length == 1
old_msg_container = '''                        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      ),'''

new_msg_container = '''                        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      ),
                      if (msg['isWelcome'] == true && _messages.length == 1) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF173B45),
                              foregroundColor: const Color(0xFF8BE0C0),
                              side: const BorderSide(color: Color(0xFF8BE0C0), width: 1.2),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.assignment_turned_in_rounded, size: 18),
                            label: const Text('📋 Completar Mi Estado Actual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            onPressed: () => _openStateSheet(),
                          ),
                        ),
                      ],'''

text = text.replace(old_msg_container, new_msg_container)

# 5. In plan card button, update onPressed to call _openStateSheet(prompt)
old_plan_btn = "showPlanOptionsSheet(context, initialPrompt: prompt);"
new_plan_btn = "_openStateSheet(prompt);"
text = text.replace(old_plan_btn, new_plan_btn)

# 6. Remove the ActionChips container completely
chips_pattern = r'// Píldoras de Preguntas Rápidas\s*Container\(\s*padding: const EdgeInsets\.symmetric\(horizontal: 16, vertical: 8\),\s*child: SingleChildScrollView\(.*?children: _currentQuickPrompts\.map\(.*?\}\)\.toList\(\),\s*\),\s*\),\s*\),'
text = re.sub(chips_pattern, '', text, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

print("Updated coach_screen.dart successfully")
