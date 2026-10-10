import sys

path = 'mobile_app/lib/screens/auth/login_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_code = '''    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthService.instance.lastError ?? 'Error')),
      );
      return;
    }
    widget.onLoginSuccess();'''

new_code = '''    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthService.instance.lastError ?? 'Error')),
      );
      return;
    }
    
    // DEBUG ALERT
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('DEBUG LOGIN'),
        content: Text('Rol detectado por la app: \'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onLoginSuccess();
            },
            child: const Text('Continuar'),
          )
        ]
      )
    );
'''

text = text.replace(old_code, new_code)
with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
