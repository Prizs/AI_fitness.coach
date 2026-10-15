import os

# 1. FIX CLIENT TRAINER TAB (SAVE TRAINER STATE)
client_path = 'mobile_app/lib/screens/client_trainer_tab.dart'
with open(client_path, 'r', encoding='utf-8') as f:
    client_text = f.read()

# Add shared_preferences import if not exists
if "import 'package:shared_preferences/shared_preferences.dart';" not in client_text:
    client_text = client_text.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:shared_preferences/shared_preferences.dart';")

# Make state persistent
init_state = '''  @override
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
  }
'''

if 'void initState()' not in client_text:
    client_text = client_text.replace('bool _requestPending = false;', 'bool _requestPending = false;\n' + init_state)

# Replace the setState calls in _showTrainerProfile and _buildPendingState
client_text = client_text.replace(
    '''setState(() => _requestPending = true);''',
    '''setState(() {
                      _requestPending = true;
                      _saveState(_hasTrainer, true);
                    });'''
)
client_text = client_text.replace(
    '''setState(() {
                  _requestPending = false;
                  _hasTrainer = true; // Para simular que aceptÃ³ en la demo
                })''',
    '''setState(() {
                  _requestPending = false;
                  _hasTrainer = true; // Para simular que aceptÃ³ en la demo
                  _saveState(true, false);
                })'''
)

with open(client_path, 'w', encoding='utf-8') as f:
    f.write(client_text)

# 2. FIX WEEKLY PLAN SERVICE ERROR HANDLING
weekly_path = 'mobile_app/lib/services/weekly_plan_service.dart'
with open(weekly_path, 'r', encoding='utf-8') as f:
    weekly_text = f.read()

# Replace jsonDecode without try-catch to have a try-catch for better error handling
decode_old = '''      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          week = data;
          loadedFromCache = false;
          lastError = null;
          await DBHelper.instance.saveWeeklyPlan(response.body);
        } else {
          if (week == null) lastError = 'Formato de plan inesperado.';
        }
      } else {
        if (week == null) lastError = 'El servidor respondió \.';
      }
    } catch (error) {
      if (week == null) lastError = 'Error local: \';
    } finally {'''

decode_new = '''      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) {
            week = data;
            loadedFromCache = false;
            lastError = null;
            await DBHelper.instance.saveWeeklyPlan(response.body);
          } else {
            if (week == null) lastError = 'Formato de plan inesperado (no es un objeto JSON).';
          }
        } catch (e) {
          if (week == null) lastError = 'Error procesando rutina: La IA no respondió con JSON válido. Intenta nuevamente.';
        }
      } else {
        if (week == null) lastError = 'El servidor devolvió un error: \. \';
      }
    } catch (error) {
      if (week == null) lastError = 'Error de conexión: Verifica tu internet e intenta de nuevo.';
    } finally {'''

weekly_text = weekly_text.replace(decode_old, decode_new)

# Also fix the previous error string
weekly_text = weekly_text.replace("lastError = 'Error local: \.';", "lastError = 'Error local: \';")

with open(weekly_path, 'w', encoding='utf-8') as f:
    f.write(weekly_text)

