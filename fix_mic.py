import os

path = 'mobile_app/lib/screens/coach_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_block = '''                    const SizedBox(width: 8),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: _controller.text.trim().isEmpty
                            ? const Color(0xFF2A3A4A)
                            : const Color(0xFF8BE0C0),
                        foregroundColor: const Color(0xFF0B1220),
                        minimumSize: const Size(48, 48),
                      ),
                      icon: const Icon(Icons.send_rounded),
                      onPressed: _controller.text.trim().isEmpty
                          ? null
                          : () => _sendMessage(_controller.text),
                    ),'''

new_block = '''                    const SizedBox(width: 8),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: _isListening ? Colors.redAccent : const Color(0xFF2A3A4A),
                        foregroundColor: _isListening ? Colors.white : Colors.white54,
                        minimumSize: const Size(48, 48),
                      ),
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                      onPressed: _listen,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: _controller.text.trim().isEmpty
                            ? const Color(0xFF2A3A4A)
                            : const Color(0xFF8BE0C0),
                        foregroundColor: const Color(0xFF0B1220),
                        minimumSize: const Size(48, 48),
                      ),
                      icon: const Icon(Icons.send_rounded),
                      onPressed: _controller.text.trim().isEmpty
                          ? null
                          : () => _sendMessage(_controller.text),
                    ),'''

text = text.replace(old_block, new_block)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
