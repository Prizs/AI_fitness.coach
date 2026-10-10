import sys

path = 'mobile_app/lib/screens/workouts_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_subtitle = '''                    Text(
                      '\ series · \ repeticiones',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],'''

new_subtitle = '''                    Text(
                      '\ series · \ repeticiones',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF173B45), borderRadius: BorderRadius.circular(8)),
                      child: Text('Equipo: \', style: const TextStyle(color: Color(0xFF8BE0C0), fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],'''

text = text.replace(old_subtitle, new_subtitle)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
