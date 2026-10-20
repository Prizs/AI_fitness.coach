import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _cedula = TextEditingController();
  final _answer = TextEditingController();
  final _newPassword = TextEditingController();

  String? _question;
  bool _isLoading = false;
  String? _error;

  Future<void> _fetchQuestion() async {
    final ced = _cedula.text.trim();
    if (ced.isEmpty) {
      setState(() => _error = 'Ingresa tu cédula');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await http.get(Uri.parse('${AuthService.apiBaseUrl}/api/auth/security_question/$ced'));
      if (res.statusCode == 200) {
        setState(() {
          _question = jsonDecode(res.body)['question'];
        });
      } else {
        setState(() => _error = 'Usuario no encontrado o error del servidor');
      }
    } catch (e) {
      setState(() => _error = 'Error de conexión');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _resetPassword() async {
    final ced = _cedula.text.trim();
    final ans = _answer.text.trim();
    final pwd = _newPassword.text.trim();
    if (ans.isEmpty || pwd.length < 8) {
      setState(() => _error = 'Respuesta vacía o contraseña muy corta (min 8)');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await http.post(
        Uri.parse('${AuthService.apiBaseUrl}/api/auth/recover_password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'cedula': ced, 'security_answer': ans, 'new_password': pwd}),
      );
      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseña restablecida exitosamente')));
          Navigator.pop(context);
        }
      } else {
        setState(() => _error = jsonDecode(res.body)['detail'] ?? 'Error desconocido');
      }
    } catch (e) {
      setState(() => _error = 'Error de conexión');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1C),
      appBar: AppBar(title: const Text('Recuperar Contraseña', style: TextStyle(color: Colors.white)), backgroundColor: Colors.transparent, iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                ),
              if (_question == null) ...[
                TextFormField(
                  controller: _cedula,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Cédula de Identidad',
                    prefixIcon: const Icon(Icons.badge_rounded, color: Color(0xFF8BE0C0)),
                    filled: true,
                    fillColor: const Color(0xFF101B2D),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _fetchQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8BE0C0),
                    foregroundColor: const Color(0xFF0A0F1C),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading ? const CircularProgressIndicator() : const Text('Buscar Pregunta de Seguridad', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                )
              ] else ...[
                Text('Pregunta Secreta', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text(_question!, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _answer,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Tu Respuesta',
                    prefixIcon: const Icon(Icons.question_answer, color: Color(0xFF8BE0C0)),
                    filled: true,
                    fillColor: const Color(0xFF101B2D),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newPassword,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nueva Contraseña',
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFF8BE0C0)),
                    filled: true,
                    fillColor: const Color(0xFF101B2D),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8BE0C0),
                    foregroundColor: const Color(0xFF0A0F1C),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading ? const CircularProgressIndicator() : const Text('Guardar y Entrar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                TextButton(
                  onPressed: () => setState(() => _question = null),
                  child: const Text('Intentar con otra cédula', style: TextStyle(color: Colors.white70)),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
