import os
import re

path = 'mobile_app/lib/screens/trainer/client_detail_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

if "import 'package:speech_to_text/speech_to_text.dart' as stt;" not in text:
    text = text.replace("import 'package:mobile_app/services/auth_service.dart';", "import 'package:mobile_app/services/auth_service.dart';\nimport 'package:speech_to_text/speech_to_text.dart' as stt;")

old_state_vars = '''  final TextEditingController _chatController = TextEditingController();
  bool _isLoadingAi = false;'''

new_state_vars = '''  final TextEditingController _chatController = TextEditingController();
  bool _isLoadingAi = false;
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
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
            _chatController.text = val.recognizedWords;
          }),
          localeId: 'es_ES',
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }'''

if "late stt.SpeechToText _speech;" not in text:
    text = text.replace(old_state_vars, new_state_vars)


old_btn = '''                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _isLoadingAi ? null : _sendAiMessage,
                      color: const Color(0xFF8BE0C0),
                    ),'''

new_btn = '''                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                      onPressed: _listen,
                      color: _isListening ? Colors.redAccent : Colors.white54,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _isLoadingAi ? null : _sendAiMessage,
                      color: const Color(0xFF8BE0C0),
                    ),'''

if "Icons.mic_none" not in text:
    text = text.replace(old_btn, new_btn)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
