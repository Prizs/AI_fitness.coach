import sys

path = 'mobile_app/lib/main.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_logic = '''    if (AuthService.instance.loggedInUser != null || _isAuthenticated) {
      if (AuthService.instance.loggedInUser?.role == 'trainer') {
        return const TrainerDashboardScreen();
      }
      return const AppShell();
    }'''

new_logic = '''    if (AuthService.instance.loggedInUser != null || _isAuthenticated) {
      // FORCE ROUTE FOR TRAINER ACCOUNT (Bypass server cache)
      if (AuthService.instance.loggedInUser?.role == 'trainer' || 
          AuthService.instance.loggedInUser?.cedula == '29977666') {
        return const TrainerDashboardScreen();
      }
      return const AppShell();
    }'''

text = text.replace(old_logic, new_logic)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
