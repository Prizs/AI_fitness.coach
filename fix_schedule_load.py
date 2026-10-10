import sys

path = 'mobile_app/lib/screens/workout_schedule_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Make sure AuthService is imported
if "import 'package:mobile_app/services/auth_service.dart';" not in text:
    text = "import 'package:mobile_app/services/auth_service.dart';\n" + text

replacement = '''@override
  void initState() {
    super.initState();
    _selectedDayIndex = _service.todayIndex;
    _service.addListener(_onServiceUpdate);
    _service.ensureLoaded(AuthService.instance.loggedInUser);
  }'''

text = text.replace('''@override
  void initState() {
    super.initState();
    _selectedDayIndex = _service.todayIndex;
    _service.addListener(_onServiceUpdate);
  }''', replacement)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
