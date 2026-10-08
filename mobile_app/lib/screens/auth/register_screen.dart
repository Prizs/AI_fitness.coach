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
  
  bool _isTrainer = false;
  final _specialtyController = TextEditingController();
  final _experienceController = TextEditingController();
  final _certificationsController = TextEditingController();

  final _cedula = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _lastName = TextEditingController();
  final _age = TextEditingController();
  final _weight = TextEditingController();
  final _notes = TextEditingController();
  final _securityAnswer = TextEditingController();
  String _securityQuestion = '¿Cuál es tu color favorito?';
  final List<String> _questions = [
    '¿Cuál es tu color favorito?',
    '¿Cuál es tu postre favorito?',
    '¿Cuál es el apellido de tu mamá?',
    '¿Dónde estudiaste primaria?',
    '¿El nombre de tu hermano?'
  ];
  final _allergyInput = TextEditingController();
  final _injuryInput = TextEditingController();
  final _disabilityInput = TextEditingController();
  final _avoidInput = TextEditingController();
  final _allergies = <String>[];
  final _injuries = <String>[];
  final _disabilities = <String>[];
  final _avoidAreas = <String>[];
  bool _isLoading = false;

  static const _corrections = <String, String>{
    'nuezes': 'nueces',
    'nuez': 'nueces',
    'camarrones': 'camarones',
    'camaron': 'camarones',
    'lacteo': 'lácteos',
    'lacteos': 'lácteos',
    'tobillo ': 'tobillo',
    'rodilla ': 'rodilla',
  };

  String _correct(String value) {
    final clean = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.isEmpty) return clean;
    final corrected = _corrections[clean.toLowerCase()] ?? clean;
    return corrected[0].toUpperCase() + corrected.substring(1);
  }

  void _addTags(TextEditingController input, List<String> target) {
    final values = input.text
        .split(',')
        .map(_correct)
        .where((value) => value.isNotEmpty);
    setState(() {
      for (final value in values) {
        if (!target.any((item) => item.toLowerCase() == value.toLowerCase())) {
          target.add(value);
        }
      }
      input.clear();
    });
  }

  String _join(List<String> values) => values.join(', ');

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? 'Este campo es obligatorio'
      : null;

  String? _nameValidator(String? value) {
    if (_required(value) != null) return _required(value);
    return RegExp(r'^[A-Za-zÁÉÍÓÚáéíóúÑñ ]+$').hasMatch(value!.trim())
        ? null
        : 'Solo se permiten letras y espacios';
  }

  String? _cedulaValidator(String? value) =>
      value != null && RegExp(r'^\d{6,9}$').hasMatch(value.trim())
      ? null
      : 'Cédula de 6 a 9 dígitos';
  String? _passwordValidator(String? value) =>
      value != null && value.length >= 8 ? null : 'Mínimo 8 caracteres';
  String? _ageValidator(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    return parsed != null && parsed >= 12 && parsed <= 100
        ? null
        : 'Edad entre 12 y 100 años';
  }

  String? _weightValidator(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    return parsed != null && parsed > 0 && parsed <= 300
        ? null
        : 'Ingrese un peso válido';
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: const Color(0xFF101B2D),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _addTags(_allergyInput, _allergies);
    _addTags(_injuryInput, _injuries);
    _addTags(_disabilityInput, _disabilities);
    _addTags(_avoidInput, _avoidAreas);
    setState(() => _isLoading = true);
    final profile = UserProfile(
      cedula: _cedula.text.trim(),
      password: _password.text,
      name: _name.text.trim(),
      lastName: _lastName.text.trim(),
      age: int.parse(_age.text.trim()),
      weight: double.parse(_weight.text.trim()),
      pathologyOrAllergies: _notes.text.trim().isEmpty
          ? null
          : _notes.text.trim(),
      foodAllergies: _join(_allergies),
      currentInjuries: _join(_injuries),
      motorDisability: _join(_disabilities),
      areasToAvoid: _join(_avoidAreas),
    );
    final registered = await AuthService.instance.register(profile);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (!registered) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.instance.lastError ?? 'Error de registro.'),
        ),
      );
      return;
    }
    widget.onRegisterSuccess();
  }

  @override
  void dispose() {
    for (final controller in [
      _cedula,
      _password,
      _name,
      _lastName,
      _age,
      _weight,
      _notes,
      _allergyInput,
      _injuryInput,
      _disabilityInput,
      _avoidInput,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              _hero(),
              const SizedBox(height: 18),
              _section('Tu perfil', Icons.person_outline_rounded, [
                TextFormField(
                  controller: _cedula,
                  keyboardType: TextInputType.number,
                  decoration: _decoration(
                    'Cédula venezolana',
                    Icons.badge_outlined,
                  ),
                  validator: _cedulaValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: _decoration(
                    'Contraseña',
                    Icons.lock_outline_rounded,
                  ),
                  validator: _passwordValidator,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _name,
                        decoration: _decoration('Nombre', Icons.person_outline),
                        validator: _nameValidator,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _lastName,
                        decoration: _decoration(
                          'Apellido',
                          Icons.person_outline,
                        ),
                        validator: _nameValidator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _age,
                        keyboardType: TextInputType.number,
                        decoration: _decoration('Edad', Icons.cake_outlined),
                        validator: _ageValidator,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _weight,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _decoration(
                          'Peso kg',
                          Icons.monitor_weight_outlined,
                        ),
                        validator: _weightValidator,
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 14),
              _section('Salud y adaptación', Icons.accessibility_new_rounded, [
                TextFormField(
                  controller: _notes,
                  maxLines: 2,
                  decoration: _decoration(
                    'Patología o alergias generales',
                    Icons.health_and_safety_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                _TagField(
                  label: 'Alergias alimentarias',
                  hint: 'camarones, nuezes + Enter',
                  icon: Icons.no_food_rounded,
                  controller: _allergyInput,
                  tags: _allergies,
                  onAdd: () => _addTags(_allergyInput, _allergies),
                  onRemove: (tag) => setState(() => _allergies.remove(tag)),
                ),
                const SizedBox(height: 12),
                _TagField(
                  label: 'Lesiones o dolor actual',
                  hint: 'tobillo derecho + Enter',
                  icon: Icons.healing_rounded,
                  controller: _injuryInput,
                  tags: _injuries,
                  onAdd: () => _addTags(_injuryInput, _injuries),
                  onRemove: (tag) => setState(() => _injuries.remove(tag)),
                ),
                const SizedBox(height: 12),
                _TagField(
                  label: 'Discapacidad o limitación motora',
                  hint: 'movilidad reducida + Enter',
                  icon: Icons.accessible_rounded,
                  controller: _disabilityInput,
                  tags: _disabilities,
                  onAdd: () => _addTags(_disabilityInput, _disabilities),
                  onRemove: (tag) => setState(() => _disabilities.remove(tag)),
                ),
                const SizedBox(height: 12),
                _TagField(
                  label: 'Zonas a evitar temporalmente',
                  hint: 'rodilla, saltos + Enter',
                  icon: Icons.block_rounded,
                  controller: _avoidInput,
                  tags: _avoidAreas,
                  onAdd: () => _addTags(_avoidInput, _avoidAreas),
                  onRemove: (tag) => setState(() => _avoidAreas.remove(tag)),
                ),
              ]),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: Text(
                  _isLoading ? 'Creando cuenta...' : 'Crear mi perfil',
                ),
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
    );
  }

  Widget _hero() => Container(
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
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 5),
              Text(
                'Cuéntanos cómo cuidarte mejor.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _section(String title, IconData icon, List<Widget> children) =>
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
            Row(
              children: [
                Icon(icon, color: const Color(0xFF8BE0C0)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      );
}

class _TagField extends StatelessWidget {
  const _TagField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.tags,
    required this.onAdd,
    required this.onRemove,
  });
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final List<String> tags;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFF101B2D),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
    child: Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        ...tags.map(
          (tag) => Chip(
            label: Text(tag),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () => onRemove(tag),
          ),
        ),
        SizedBox(
          width: 190,
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onAdd(),
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              suffixIcon: IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
