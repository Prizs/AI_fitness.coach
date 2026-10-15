import os

path = 'mobile_app/lib/screens/trainer/client_detail_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# First, we need to import ApiService
if "import 'package:mobile_app/services/api_service.dart';" not in text:
    text = text.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:mobile_app/services/api_service.dart';")

# We need to change the dummy chat to an actual async function.
# Look for the IconButton onPressed inside _buildAiTab()
old_on_pressed = '''                  onPressed: () {
                    if (_chatController.text.isNotEmpty) {
                      setState(() {
                        _aiChatHistory.add({'role': 'trainer', 'text': _chatController.text});
                        _chatController.clear();
                        // Fake AI response
                        _aiChatHistory.add({'role': 'ai', 'text': 'Basado en su historial, recomiendo 10 mins de elíptica suave, y movilidad articular de cadera y rodilla (lubricación sin carga) antes de ir a la Prensa.'});
                      });
                    }
                  },'''

new_on_pressed = '''                  onPressed: _sendMessageToAi,'''

# Add _isLoading boolean to state
if 'bool _isLoadingAi = false;' not in text:
    text = text.replace('final TextEditingController _chatController = TextEditingController();', 'final TextEditingController _chatController = TextEditingController();\n  bool _isLoadingAi = false;')

# Inject the _sendMessageToAi function
send_method = '''
  Future<void> _sendMessageToAi() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _isLoadingAi) return;

    setState(() {
      _aiChatHistory.add({'role': 'trainer', 'text': text});
      _chatController.clear();
      _isLoadingAi = true;
    });

    try {
      final response = await ApiService.instance.post('/coach/chat', {
        'message': 'Soy el entrenador de este alumno. Te consulto sobre él: \',
        'history': _aiChatHistory
            .where((msg) => msg['role'] != 'trainer' || msg['text'] != text) // Excluir el reciÃ©n aÃ±adido para el historial previo si es necesario o formatearlo bien
            .map((msg) => {
                  'role': msg['role'] == 'trainer' ? 'user' : 'assistant',
                  'content': msg['text']
                })
            .toList(),
        'user_goal': 'Ganancia Muscular',
        'allergies': 'Intolerante a la lactosa',
        'injuries': 'Molestia en rodilla derecha reportada hoy',
      });

      setState(() {
        _aiChatHistory.add({
          'role': 'ai', 
          'text': response['response'] ?? 'Sin respuesta de la IA'
        });
      });
    } catch (e) {
      setState(() {
        _aiChatHistory.add({'role': 'ai', 'text': 'Error de conexión con la IA.'});
      });
    } finally {
      setState(() {
        _isLoadingAi = false;
      });
    }
  }
'''

text = text.replace(old_on_pressed, new_on_pressed)

# Put the function before the last brace
last_brace = text.rfind('}')
text = text[:last_brace] + send_method + text[last_brace:]

# Also show a loading indicator instead of the send button when loading
send_button_old = '''                CircleAvatar(
                  backgroundColor: const Color(0xFF1FAE87),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: _sendMessageToAi,
                  ),
                )'''

send_button_new = '''                CircleAvatar(
                  backgroundColor: const Color(0xFF1FAE87),
                  child: _isLoadingAi 
                    ? const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : IconButton(
                        icon: const Icon(Icons.send, color: Colors.white, size: 18),
                        onPressed: _sendMessageToAi,
                      ),
                )'''

text = text.replace(send_button_old, send_button_new)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
