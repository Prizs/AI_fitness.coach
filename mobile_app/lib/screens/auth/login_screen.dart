import 'package:flutter/material.dart';
import 'package:mobile_app/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
    required this.onGoToRegister,
  });

  final VoidCallback onLoginSuccess;
  final VoidCallback onGoToRegister;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cedulaController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  String? _validateCedula(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La cédula es obligatoria';
    }

    final clean = value.trim();
    if (!RegExp(r'^\d{6,9}$').hasMatch(clean)) {
      return 'Debe ingresar una cédula venezolana válida de 6 a 9 dígitos';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }

    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }

    if (RegExp(r'[\u{1F300}-\u{1FAFF}]', unicode: true).hasMatch(value)) {
      return 'No se permiten emojis en la contraseña';
    }

    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final cedula = _cedulaController.text.trim();
    final password = _passwordController.text;

    final ok = await AuthService.instance.login(cedula, password);
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cédula o contraseña incorrectos.'),
        ),
      );
      return;
    }

    widget.onLoginSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 26),
                const Text(
                  'Iniciar sesión',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Accede con tu cédula y contraseña para continuar con tu plan.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _cedulaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cédula venezolana',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateCedula,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 26),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: const Icon(Icons.login_rounded),
                  label: Text(_isLoading ? 'Conectando...' : 'Entrar'),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: widget.onGoToRegister,
                  child: const Text('No tengo cuenta. Registrarme'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
