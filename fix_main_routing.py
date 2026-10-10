import sys

path = 'mobile_app/lib/main.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_build = '''  @override
  Widget build(BuildContext context) {
    if (AuthService.instance.loggedInUser != null || _isAuthenticated) {
      return const AppShell();
    }'''

new_build = '''  @override
  Widget build(BuildContext context) {
    if (AuthService.instance.loggedInUser != null || _isAuthenticated) {
      if (AuthService.instance.loggedInUser?.role == 'trainer') {
        return const TrainerDashboardScreen();
      }
      return const AppShell();
    }'''

text = text.replace(old_build, new_build)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
