import os
import re

path = 'mobile_app/lib/widgets/plan_options_sheet.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

if "import 'package:speech_to_text/speech_to_text.dart' as stt;" not in text:
    text = text.replace("import 'package:mobile_app/services/auth_service.dart';", "import 'package:mobile_app/services/auth_service.dart';\nimport 'package:speech_to_text/speech_to_text.dart' as stt;")

old_state_vars = '''  late final TextEditingController _promptController;
  final TextEditingController _molestiaController = TextEditingController();
  
  String _estado = 'Bien';'''

new_state_vars = '''  late final TextEditingController _promptController;
  final TextEditingController _molestiaController = TextEditingController();
  
  late stt.SpeechToText _speech;
  bool _isListening = false;
  
  String _estado = 'Bien';'''

if "late stt.SpeechToText _speech;" not in text:
    text = text.replace(old_state_vars, new_state_vars)

old_init = '''  void initState() {
    super.initState();
    _promptController = TextEditingController(text: widget.initialPrompt);
  }'''

new_init = '''  void initState() {
    super.initState();
    _promptController = TextEditingController(text: widget.initialPrompt);
    _speech = stt.SpeechToText();
  }
  
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
           if (val == 'done') setState(() => _isListening = false);
        },
        onError: (val) => setState(() => _isListening = false),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            if (_estado == 'Molestia') {
              _molestiaController.text = val.recognizedWords;
            } else {
              _promptController.text = val.recognizedWords;
            }
          }),
          localeId: 'es_ES',
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }'''

if "void _listen() async {" not in text:
    text = text.replace(old_init, new_init)

old_title = '''const Text('Configuración Rápida de Rutina', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),'''

new_title = '''Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Configuración Rápida', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                  color: _isListening ? Colors.redAccent : const Color(0xFF8BE0C0),
                  onPressed: _listen,
                  tooltip: 'Dictar por voz',
                ),
              ],
            ),
            const SizedBox(height: 16),'''

if "Row(" not in text and "Configuración Rápida" in text:
    text = text.replace(old_title, new_title)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
