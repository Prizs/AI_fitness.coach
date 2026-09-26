import 'package:flutter/material.dart';
import 'package:mobile_app/services/app_update_service.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/widgets/app_update.dart';

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
        const SnackBar(content: Text('Cédula o contraseña incorrectos.')),
      );
      return;
    }

    widget.onLoginSuccess();
  }

  InputDecoration _inputStyle(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF8BE0C0)),
        filled: true,
        fillColor: const Color(0xFF101B2D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      );

  /// Permite cambiar la direccion del backend sin reinstalar la app, util
  /// cuando el mismo APK se instala en varios telefonos con redes distintas.
  Future<void> _editServer() async {
    final controller = TextEditingController(text: AuthService.apiBaseUrl);
    final saved = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Dirección del servidor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                hintText: 'http://192.168.1.10:8000',
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'En un telefono real usa la IP local de tu computadora, '
              'por ejemplo http://192.168.1.10:8000',
              style: TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (saved == null) return;
    await AuthService.instance.saveServerConfig(saved);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Servidor actualizado: ${AuthService.apiBaseUrl}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF173B45),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8BE0C0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.fitness_center_rounded,
                            color: Color(0xFF0B1220),
                            size: 34,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tu plan empieza aquí',
                                style: TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Accede para continuar tu entrenamiento.',
                                style: TextStyle(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F192B),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              color: Color(0xFF8BE0C0),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Tu perfil',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _cedulaController,
                          keyboardType: TextInputType.number,
                          decoration: _inputStyle(
                            'Cédula venezolana',
                            Icons.badge_outlined,
                          ),
                          validator: _validateCedula,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: _inputStyle(
                            'Contraseña',
                            Icons.lock_outline_rounded,
                          ),
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF8BE0C0),
                              foregroundColor: const Color(0xFF0B1220),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _isLoading ? null : _submit,
                            icon: const Icon(Icons.login_rounded),
                            label: Text(
                              _isLoading ? 'Conectando...' : 'Entrar a entrenar',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: widget.onGoToRegister,
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('¿No tienes cuenta? Regístrate aquí'),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: TextButton.icon(
                      onPressed: _editServer,
                      icon: const Icon(Icons.dns_rounded, size: 16),
                      label: Text(
                        'Servidor: ${AuthService.apiBaseUrl}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => checkForAppUpdate(context),
                      icon: const Icon(Icons.system_update_rounded, size: 16),
                      label: const Text(
                        'Buscar actualizaciones',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: FutureBuilder<InstalledVersion>(
                      future: AppUpdateService().installedVersion(),
                      builder: (context, snapshot) {
                        final version = snapshot.data;
                        return Text(
                          version == null
                              ? ''
                              : 'Version ${version.versionName} '
                                  '(${version.versionCode})',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white38,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
