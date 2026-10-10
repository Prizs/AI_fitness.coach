import sys
import re

path = 'mobile_app/lib/screens/anatomy_workout_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

new_fallback = '''                : Center(
                    child: SingleChildScrollView(
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF101B2D),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF8BE0C0), width: 1.5),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.psychology_rounded, size: 56, color: Color(0xFF8BE0C0)),
                            const SizedBox(height: 16),
                            Text('Guía Textual Interactiva', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Text('Visualización 3D en desarrollo para este ejercicio.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: const Color(0xFF173B45), borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                children: [
                                  Text('1. Agonista: ' + exercise.agonist, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF8BE0C0), fontSize: 14, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 8),
                                  Text('2. Sinergistas: ' + exercise.synergists.join(', '), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                  const SizedBox(height: 8),
                                  Text('3. Postura: ' + exercise.posture, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                  const SizedBox(height: 8),
                                  Text('4. Tempo: ' + exercise.tempo, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),'''

text = re.sub(r': Center\(\s*child: Container\(\s*margin: const EdgeInsets\.all\(24\),.*?Enf.*?\),.*?\]\,\s*\)\,\s*\)\,\s*\)\,', new_fallback, text, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
