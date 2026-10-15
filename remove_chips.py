path = 'mobile_app/lib/screens/coach_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

target = """            // Píldoras de Preguntas Rápidas
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _currentQuickPrompts.map((p) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor: const Color(0xFF101B2D),
                      label: Text(p, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                      onPressed: () => _sendMessage(p),
                    ),
                  )).toList(),
                ),
              ),
            ),"""

if target in text:
    text = text.replace(target, '')
    print("Replaced target successfully")
else:
    # Try normalizing line endings
    text_norm = text.replace('\r\n', '\n')
    target_norm = target.replace('\r\n', '\n')
    if target_norm in text_norm:
        text_norm = text_norm.replace(target_norm, '')
        text = text_norm
        print("Replaced target with norm line endings")
    else:
        print("Target not found!")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
