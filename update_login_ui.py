path = 'mobile_app/lib/screens/auth/login_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_server_btn = """          Center(
            child: TextButton.icon(
              onPressed: _editServer,
              icon: const Icon(Icons.dns_rounded, size: 16),
              label: Text(
                'Servidor: ${AuthService.apiBaseUrl}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white54,
                ),
              ),
            ),
          ),"""

new_server_btn = """          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ActionChip(
                backgroundColor: AuthService.apiBaseUrl.contains('localhost') || AuthService.apiBaseUrl.contains('8000')
                    ? const Color(0xFF1FAE87).withOpacity(0.25)
                    : const Color(0xFF101B2D),
                side: BorderSide(
                  color: AuthService.apiBaseUrl.contains('localhost') || AuthService.apiBaseUrl.contains('8000')
                      ? const Color(0xFF1FAE87)
                      : Colors.white24,
                ),
                label: const Text('🏠 Local (8000)', style: TextStyle(fontSize: 11, color: Colors.white)),
                onPressed: () async {
                  await AuthService.instance.saveServerConfig('http://localhost:8000');
                  setState(() {});
                },
              ),
              const SizedBox(width: 8),
              ActionChip(
                backgroundColor: AuthService.apiBaseUrl.contains('onrender.com')
                    ? const Color(0xFF1FAE87).withOpacity(0.25)
                    : const Color(0xFF101B2D),
                side: BorderSide(
                  color: AuthService.apiBaseUrl.contains('onrender.com')
                      ? const Color(0xFF1FAE87)
                      : Colors.white24,
                ),
                label: const Text('☁️ Nube Render', style: TextStyle(fontSize: 11, color: Colors.white)),
                onPressed: () async {
                  await AuthService.instance.saveServerConfig('https://ai-fitness-coach-818a.onrender.com');
                  setState(() {});
                },
              ),
            ],
          ),
          Center(
            child: TextButton.icon(
              onPressed: _editServer,
              icon: const Icon(Icons.dns_rounded, size: 14),
              label: Text(
                'Activo: ${AuthService.apiBaseUrl}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white38,
                ),
              ),
            ),
          ),"""

text = text.replace(old_server_btn, new_server_btn)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

print("Updated LoginScreen with 1-click server switcher!")
