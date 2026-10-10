import sys
import re

path = 'mobile_app/pubspec.yaml'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

if 'speech_to_text:' not in text:
    text = text.replace('http: ^1.2.2', 'http: ^1.2.2\\n  speech_to_text: ^6.6.1')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

path2 = 'mobile_app/lib/screens/coach_screen.dart'
with open(path2, 'r', encoding='utf-8') as f:
    text2 = f.read()

import_stmt = "import 'package:speech_to_text/speech_to_text.dart' as stt;"
if import_stmt not in text2:
    text2 = text2.replace("import 'package:lottie/lottie.dart';", "import 'package:lottie/lottie.dart';\\n" + import_stmt)

old_state_vars = '''  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;'''

new_state_vars = '''  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  
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
            _controller.text = val.recognizedWords;
          }),
          localeId: 'es_ES', // Español
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }'''

if "_speech = stt.SpeechToText();" not in text2:
    text2 = text2.replace(old_state_vars, new_state_vars)

old_input = '''                      IconButton(
                        onPressed: () => _sendMessage(_controller.text),
                        icon: const Icon(Icons.send_rounded, color: Color(0xFF8BE0C0)),
                      ),'''

new_input = '''                      IconButton(
                        onPressed: _listen,
                        icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.redAccent : const Color(0xFF8BE0C0)),
                      ),
                      IconButton(
                        onPressed: () => _sendMessage(_controller.text),
                        icon: const Icon(Icons.send_rounded, color: Color(0xFF8BE0C0)),
                      ),'''

if "onPressed: _listen," not in text2:
    text2 = text2.replace(old_input, new_input)

with open(path2, 'w', encoding='utf-8') as f:
    f.write(text2)
