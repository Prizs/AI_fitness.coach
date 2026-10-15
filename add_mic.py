import os

path = 'mobile_app/lib/screens/coach_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_buttons = '''                    const SizedBox(width: 8),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: _controller.text.trim().isEmpty
                            ? const Color(0xFF2A3A4A)'''

new_buttons = '''                    const SizedBox(width: 8),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: _isListening ? Colors.redAccent : const Color(0xFF2A3A4A),
                        foregroundColor: _isListening ? Colors.white : Colors.white54,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                      onPressed: _listen,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: _controller.text.trim().isEmpty
                            ? const Color(0xFF2A3A4A)'''

text = text.replace(old_buttons, new_buttons)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
