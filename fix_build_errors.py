import os

# 1. Fix client_trainer_tab.dart
client_path = 'mobile_app/lib/screens/client_trainer_tab.dart'
with open(client_path, 'r', encoding='utf-8') as f:
    text = f.read()

# Remove shared_preferences import
text = text.replace("import 'package:shared_preferences/shared_preferences.dart';", "")

# Replace state loading with a static variable for session persistence
text = text.replace('''  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasTrainer = prefs.getBool('has_trainer') ?? false;
      _requestPending = prefs.getBool('request_pending') ?? false;
    });
  }

  Future<void> _saveState(bool hasTrainer, bool requestPending) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_trainer', hasTrainer);
    await prefs.setBool('request_pending', requestPending);
  }''', '''
  static bool _hasTrainerGlobal = false;
  static bool _requestPendingGlobal = false;

  @override
  void initState() {
    super.initState();
    _hasTrainer = _hasTrainerGlobal;
    _requestPending = _requestPendingGlobal;
  }

  void _saveState(bool hasTrainer, bool requestPending) {
    _hasTrainerGlobal = hasTrainer;
    _requestPendingGlobal = requestPending;
  }''')

with open(client_path, 'w', encoding='utf-8') as f:
    f.write(text)

# 2. Fix client_detail_screen.dart
detail_path = 'mobile_app/lib/screens/trainer/client_detail_screen.dart'
with open(detail_path, 'r', encoding='utf-8') as f:
    text = f.read()

# Remove api_service import and add http import
text = text.replace("import 'package:mobile_app/services/api_service.dart';", "import 'package:http/http.dart' as http;\nimport 'dart:convert';\nimport 'package:mobile_app/services/auth_service.dart';")

# Replace ApiService call with http.post
api_old = '''final response = await ApiService.instance.post('/coach/chat', {'''
api_new = '''final response = await http.post(
        Uri.parse('\/api/coach/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'''

text = text.replace(api_old, api_new)

# The response from ApiService was parsed as a map, http response needs jsonDecode
resp_old = '''      setState(() {
        _aiChatHistory.add({
          'role': 'ai', 
          'text': response['response'] ?? 'Sin respuesta de la IA'
        });
      });'''

resp_new = '''      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _aiChatHistory.add({
            'role': 'ai', 
            'text': data['response'] ?? 'Sin respuesta de la IA'
          });
        });
      } else {
        throw Exception('Error del servidor');
      }'''

text = text.replace(resp_old, resp_new)

# Fix the end of the http.post call (it didn't have ody: jsonEncode({ ... }) closed properly if I just replaced the start)
# Actually, the original was:
# final response = await ApiService.instance.post('/coach/chat', { ... });
# Now it is: final response = await http.post( ... body: jsonEncode({ ... }); 
# So I need to replace }); at the end of the payload with }));

text = text.replace("        'injuries': 'Molestia en rodilla derecha reportada hoy',\n      });", "        'injuries': 'Molestia en rodilla derecha reportada hoy',\n      }));")


with open(detail_path, 'w', encoding='utf-8') as f:
    f.write(text)
