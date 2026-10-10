import sys

path = 'mobile_app/lib/main.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

import_stmt = "import 'package:mobile_app/screens/trainer_dashboard_screen.dart';"
if import_stmt not in text:
    text = text.replace("import 'package:mobile_app/screens/auth/login_screen.dart';", "import 'package:mobile_app/screens/auth/login_screen.dart';\n" + import_stmt)

old_authgate = '''class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        if (AuthService.instance.loggedInUser == null) {
          return const LoginScreen();
        }
        return const MainNavigation();
      },
    );
  }
}'''

new_authgate = '''class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        if (AuthService.instance.loggedInUser == null) {
          return const LoginScreen();
        }
        if (AuthService.instance.loggedInUser?.role == 'trainer') {
          return const TrainerDashboardScreen();
        }
        return const MainNavigation();
      },
    );
  }
}'''

text = text.replace(old_authgate, new_authgate)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
