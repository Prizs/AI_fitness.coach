import 'package:flutter/material.dart';
import 'package:mobile_app/models/user_profile.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/screens/auth/onboarding_quiz_screen.dart';

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
  final _pathologyInput = TextEditingController();
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
  final _pathologies = <String>[];
  final _allergies = <String>[];
  final _injuries = <String>[];
  final _disabilities = <String>[];
  final _avoidAreas = <String>[];
  String _gender = 'masculino';
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
    _addTags(_pathologyInput, _pathologies);
    _addTags(_allergyInput, _allergies);
    _addTags(_injuryInput, _injuries);
    _addTags(_disabilityInput, _disabilities);
    _addTags(_avoidInput, _avoidAreas);
    setState(() => _isLoading = true);

    try {
      final profile = UserProfile(
        cedula: _cedula.text.trim(),
        password: _password.text,
        name: _name.text.trim(),
        lastName: _lastName.text.trim(),
        age: int.tryParse(_age.text.trim()) ?? 25,
        weight: double.tryParse(_weight.text.trim()) ?? 70.0,
        gender: _gender,
        pathologyOrAllergies: _pathologies.isEmpty
            ? null
            : _join(_pathologies),
        foodAllergies: _join(_allergies),
        currentInjuries: _join(_injuries),
        motorDisability: _join(_disabilities),
        areasToAvoid: _join(_avoidAreas),
        role: _isTrainer ? 'trainer' : 'client',
        specialty: _isTrainer ? _specialtyController.text.trim() : null,
        experienceYears: _isTrainer ? int.tryParse(_experienceController.text.trim()) : null,
        certifications: _isTrainer ? _certificationsController.text.trim() : null,
      );

      final registered = await AuthService.instance.register(profile);
      if (!mounted) return;

      if (!registered) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AuthService.instance.lastError ?? 'Error de registro.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
        return;
      }
      
      // Si es un Alumno, lanzar el Test Biopsicosocial y de Adherencia (estilo FitCraft)
      if (!_isTrainer) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OnboardingQuizScreen(
              userProfile: profile,
              onComplete: () {
                Navigator.of(context).pop();
                widget.onRegisterSuccess();
              },
            ),
          ),
        );
      } else {
        widget.onRegisterSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent.shade700,
            behavior: SnackBarBehavior.floating,
            content: Text('Error inesperado al registrar: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
      _pathologyInput,
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
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Alumno / Cliente')),
                  ButtonSegment(value: true, label: Text('Entrenador Pro')),
                ],
                selected: {_isTrainer},
                onSelectionChanged: (set) => setState(() => _isTrainer = set.first),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFF8BE0C0) : Colors.transparent),
                  foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFF0B1220) : Colors.white),
                ),
              ),
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
                    if (!_isTrainer) const SizedBox(width: 10),
                    if (!_isTrainer) Expanded(
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
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4.0, bottom: 6.0),
                      child: Text(
                        'Sexo biológico (calibración metabólica & BMR)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'masculino',
                          label: Text('Masculino'),
                          icon: Icon(Icons.male_rounded, size: 18),
                        ),
                        ButtonSegment(
                          value: 'femenino',
                          label: Text('Femenino'),
                          icon: Icon(Icons.female_rounded, size: 18),
                        ),
                      ],
                      selected: {_gender},
                      onSelectionChanged: (set) => setState(() => _gender = set.first),
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith((states) =>
                            states.contains(WidgetState.selected)
                                ? const Color(0xFF8BE0C0)
                                : const Color(0xFF101B2D)),
                        foregroundColor: WidgetStateProperty.resolveWith((states) =>
                            states.contains(WidgetState.selected)
                                ? const Color(0xFF0B1220)
                                : Colors.white),
                        side: WidgetStateProperty.all(BorderSide.none),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 14),
              if (!_isTrainer) _section('Salud y adaptación', Icons.accessibility_new_rounded, [
                _TagField(
                  label: 'Patología o alergias generales',
                  hint: 'Asma, Hipertensión, Polvo + Enter',
                  icon: Icons.health_and_safety_outlined,
                  controller: _pathologyInput,
                  tags: _pathologies,
                  onAdd: () => _addTags(_pathologyInput, _pathologies),
                  onRemove: (tag) => setState(() => _pathologies.remove(tag)),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    'Sugerencias rápidas (toca para añadir):',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.65)),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    'Asma',
                    'Hipertensión',
                    'Diabetes',
                    'Alergia al polvo',
                    'Rinitis alérgica',
                    'Hipotiroidismo',
                    'Ninguna',
                  ].map((suggestion) {
                    final isSelected = _pathologies.contains(suggestion);
                    return ActionChip(
                      backgroundColor: isSelected ? const Color(0xFF173B45) : const Color(0xFF101B2D),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF8BE0C0) : Colors.white24,
                      ),
                      avatar: Icon(
                        isSelected ? Icons.check_rounded : Icons.add_rounded,
                        size: 15,
                        color: isSelected ? const Color(0xFF8BE0C0) : Colors.white70,
                      ),
                      label: Text(
                        suggestion,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? const Color(0xFF8BE0C0) : Colors.white70,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          if (suggestion == 'Ninguna') {
                            _pathologies.clear();
                            _pathologies.add('Ninguna');
                          } else {
                            _pathologies.remove('Ninguna');
                            if (_pathologies.contains(suggestion)) {
                              _pathologies.remove(suggestion);
                            } else {
                              _pathologies.add(suggestion);
                            }
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    'ℹ️ ¿Qué va aquí? Condiciones de salud o alergias ambientales (polvo, polen, picaduras). Sirve para que la IA calibre tu esfuerzo cardiovascular y no sature tus pulmones.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: const Color(0xFF8BE0C0).withOpacity(0.85),
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
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
              if (_isTrainer) const SizedBox(height: 14),
              if (_isTrainer) _section('Perfil Profesional', Icons.work_outline_rounded, [
                DropdownButtonFormField<String>(
                  value: _specialtyController.text.isEmpty ? null : _specialtyController.text,
                  decoration: _decoration('Especialidad Principal', Icons.star_border),
                  dropdownColor: const Color(0xFF101B2D),
                  items: ['Hipertrofia', 'Pérdida de Grasa', 'Calistenia', 'Rehabilitación', 'Crossfit']
                      .map((String value) => DropdownMenuItem<String>(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (val) => setState(() => _specialtyController.text = val ?? ''),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _experienceController,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('Años de Experiencia', Icons.timeline),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _certificationsController,
                  decoration: _decoration('Certificaciones / Títulos', Icons.card_membership),
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
