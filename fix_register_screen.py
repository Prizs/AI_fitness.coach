import sys
import re

path = 'mobile_app/lib/screens/auth/register_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_vars = '''  final _notes = TextEditingController();'''
new_vars = '''  final _notes = TextEditingController();
  final _securityAnswer = TextEditingController();
  String _securityQuestion = '¿Cuál es tu color favorito?';
  final List<String> _questions = [
    '¿Cuál es tu color favorito?',
    '¿Cuál es tu postre favorito?',
    '¿Cuál es el apellido de tu mamá?',
    '¿Dónde estudiaste primaria?',
    '¿El nombre de tu hermano?'
  ];'''
text = text.replace(old_vars, new_vars)

old_ui = '''                const SizedBox(height: 14),
                _section('Salud y adaptación', Icons.accessibility_new_rounded, ['''
new_ui = '''                const SizedBox(height: 18),
                _section('Seguridad (Recuperar contraseña)', Icons.security_rounded, [
                  DropdownButtonFormField<String>(
                    value: _securityQuestion,
                    dropdownColor: const Color(0xFF101B2D),
                    style: const TextStyle(color: Colors.white),
                    decoration: _decoration('Pregunta de seguridad', Icons.help_outline),
                    items: _questions.map((q) => DropdownMenuItem(value: q, child: Text(q, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (val) => setState(() => _securityQuestion = val!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _securityAnswer,
                    style: const TextStyle(color: Colors.white),
                    decoration: _decoration('Respuesta secreta', Icons.vpn_key_rounded),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                ]),
                const SizedBox(height: 14),
                _section('Salud y adaptación', Icons.accessibility_new_rounded, ['''
text = text.replace(old_ui, new_ui)

old_call = '''        patologia: _notes.text.trim().isEmpty ? null : _notes.text.trim(),'''
new_call = '''        patologia: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        securityQuestion: _securityQuestion,
        securityAnswer: _securityAnswer.text.trim(),'''
text = text.replace(old_call, new_call)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
