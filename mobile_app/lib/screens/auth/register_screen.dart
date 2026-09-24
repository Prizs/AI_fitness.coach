import 'package:flutter/material.dart';
import 'package:mobile_app/models/user_profile.dart';
import 'package:mobile_app/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.onRegisterSuccess,
    required this.onBackToLogin,
  });

  final VoidCallback onRegisterSuccess;
  final VoidCallback onBackToLogin;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cedulaController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  bool _containsEmoji(String value) {
    return RegExp(r'[\u{1F300}-\u{1FAFF}\u2600-\u27BF]', unicode: true)
        .hasMatch(value);
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    if (_containsEmoji(value)) {
      return 'No se permiten emojis';
    }
    if (!RegExp(r'^[A-Za-zÁÉÍÓÚáéíóúÑñ ]+$').hasMatch(value.trim())) {
      return 'Solo se permiten letras, espacios, tildes y ñ';
    }
    return null;
  }

  String? _validateCedula(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La cédula es obligatoria';
    }
    final clean = value.trim();
    if (!RegExp(r'^\d{6,9}$').hasMatch(clean)) {
      return 'Debe ser una cédula venezolana válida';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (value.length < 8) {
      return 'La contraseña debe tener mínimo 8 caracteres';
    }
    if (_containsEmoji(value)) {
      return 'No se permiten emojis';
    }
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La edad es obligatoria';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 12 || parsed > 100) {
      return 'Ingrese una edad válida entre 12 y 100 años';
    }
    return null;
  }

  String? _validateWeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El peso es obligatorio';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0 || parsed > 300) {
      return 'Ingrese un peso válido';
    }
    return null;
  }

  String? _validateOptionalNotes(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (_containsEmoji(value)) {
      return 'No se permiten emojis';
    }
    if (!RegExp(r'^[A-Za-zÁÉÍÓÚáéíóúÑñ0-9 ,./-]+$').hasMatch(value.trim())) {
      return 'Solo se permiten letras, números y caracteres básicos';
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

    final profile = UserProfile(
      cedula: _cedulaController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      weight: double.parse(_weightController.text.trim()),
      pathologyOrAllergies: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    final registered = await AuthService.instance.register(profile);
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
    });
    if (!registered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya existe un usuario registrado con esa cédula.'),
        ),
      );
      return;
    }

    widget.onRegisterSuccess();
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
                const SizedBox(height: 20),
                const Text(
                  'Crear cuenta',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Completa tus datos para iniciar tu plan personalizado.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _cedulaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cédula venezolana',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateCedula,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateName,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Apellido',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateName,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Edad',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateAge,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Peso (kg)',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateWeight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Patología o alergias (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateOptionalNotes,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: const Icon(Icons.person_add_rounded),
                  label: Text(_isLoading ? 'Creando cuenta...' : 'Registrarme'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: widget.onBackToLogin,
                  child: const Text('Ya tengo cuenta. Iniciar sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
