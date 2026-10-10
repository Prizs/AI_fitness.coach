import sys

path = 'mobile_app/lib/screens/auth/register_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

new_state_vars = '''  final _formKey = GlobalKey<FormState>();
  
  bool _isTrainer = false;
  final _specialtyController = TextEditingController();
  final _experienceController = TextEditingController();
  final _certificationsController = TextEditingController();
'''
if "bool _isTrainer = false;" not in text:
    text = text.replace("  final _formKey = GlobalKey<FormState>();", new_state_vars)

# Inject the toggle at the top of ListView
old_listview = '''        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.person_add_alt_1_rounded, size: 64, color: Color(0xFF8BE0C0)),
            const SizedBox(height: 16),
            const Text(
              'Crea tu cuenta',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 32),'''

new_listview = '''        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.person_add_alt_1_rounded, size: 64, color: Color(0xFF8BE0C0)),
            const SizedBox(height: 16),
            const Text(
              'Crea tu cuenta',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 24),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Alumno / Cliente')),
                ButtonSegment(value: true, label: Text('Soy Entrenador Pro')),
              ],
              selected: {_isTrainer},
              onSelectionChanged: (set) => setState(() => _isTrainer = set.first),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFF8BE0C0) : Colors.transparent),
                foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFF0B1220) : Colors.white),
              ),
            ),
            const SizedBox(height: 32),'''
if "SegmentedButton<bool>" not in text:
    text = text.replace(old_listview, new_listview)

# Conditional rendering of standard fields vs trainer fields
# I will use a simple regex replacement or find-replace

# In the form, I need to wrap weight/allergies in if (!_isTrainer)
# And add if (_isTrainer) fields.

old_fields = '''            _buildTextField(label: 'Edad', icon: Icons.cake, controller: _ageController, isNumber: true),
            const SizedBox(height: 16),
            _buildTextField(label: 'Peso (kg)', icon: Icons.monitor_weight_rounded, controller: _weightController, isNumber: true),
            const SizedBox(height: 32),
            
            const Text('Perfil de Salud (Opcional)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTextField(label: 'Alergias o Patologías', icon: Icons.medical_services_outlined, controller: _pathologyController),
            const SizedBox(height: 16),
            _buildTextField(label: 'Alergias Alimentarias', icon: Icons.restaurant_menu_rounded, controller: _foodAllergiesController),
            const SizedBox(height: 16),
            _buildTextField(label: 'Lesiones Actuales', icon: Icons.healing_rounded, controller: _injuriesController),
            const SizedBox(height: 16),
            _buildTextField(label: 'Discapacidad Motora', icon: Icons.accessible_forward_rounded, controller: _motorController),
            const SizedBox(height: 16),
            _buildTextField(label: 'Zonas a Evitar', icon: Icons.do_not_touch_rounded, controller: _areasController),
            const SizedBox(height: 32),'''

new_fields = '''            _buildTextField(label: 'Edad', icon: Icons.cake, controller: _ageController, isNumber: true),
            const SizedBox(height: 16),
            if (!_isTrainer) ...[
              _buildTextField(label: 'Peso (kg)', icon: Icons.monitor_weight_rounded, controller: _weightController, isNumber: true),
              const SizedBox(height: 32),
              const Text('Perfil de Salud (Opcional)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildTextField(label: 'Alergias o Patologías', icon: Icons.medical_services_outlined, controller: _pathologyController),
              const SizedBox(height: 16),
              _buildTextField(label: 'Alergias Alimentarias', icon: Icons.restaurant_menu_rounded, controller: _foodAllergiesController),
              const SizedBox(height: 16),
              _buildTextField(label: 'Lesiones Actuales', icon: Icons.healing_rounded, controller: _injuriesController),
              const SizedBox(height: 16),
              _buildTextField(label: 'Discapacidad Motora', icon: Icons.accessible_forward_rounded, controller: _motorController),
              const SizedBox(height: 16),
              _buildTextField(label: 'Zonas a Evitar', icon: Icons.do_not_touch_rounded, controller: _areasController),
              const SizedBox(height: 32),
            ] else ...[
              const Text('Perfil Profesional', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _specialtyController.text.isEmpty ? null : _specialtyController.text,
                decoration: InputDecoration(
                  labelText: 'Especialidad Principal',
                  prefixIcon: const Icon(Icons.star, color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF101B2D),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  labelStyle: const TextStyle(color: Colors.white54),
                ),
                dropdownColor: const Color(0xFF101B2D),
                style: const TextStyle(color: Colors.white),
                items: ['Hipertrofia', 'Pérdida de Grasa', 'Calistenia', 'Rehabilitación', 'Crossfit']
                    .map((String value) => DropdownMenuItem<String>(value: value, child: Text(value)))
                    .toList(),
                onChanged: (val) => setState(() => _specialtyController.text = val ?? ''),
              ),
              const SizedBox(height: 16),
              _buildTextField(label: 'Años de Experiencia', icon: Icons.timeline, controller: _experienceController, isNumber: true),
              const SizedBox(height: 16),
              _buildTextField(label: 'Certificaciones / Títulos', icon: Icons.card_membership, controller: _certificationsController),
              const SizedBox(height: 32),
            ],'''

if "if (!_isTrainer) ...[" not in text:
    text = text.replace(old_fields, new_fields)

# Update the submission logic
old_submit = '''      final user = UserProfile(
        cedula: _cedulaController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? 25,
        weight: double.tryParse(_weightController.text.trim()) ?? 70.0,
        pathologyOrAllergies: _pathologyController.text.trim(),
        foodAllergies: _foodAllergiesController.text.trim(),
        currentInjuries: _injuriesController.text.trim(),
        motorDisability: _motorController.text.trim(),
        areasToAvoid: _areasController.text.trim(),
      );'''

new_submit = '''      final user = UserProfile(
        cedula: _cedulaController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? 25,
        weight: double.tryParse(_weightController.text.trim()) ?? 70.0,
        pathologyOrAllergies: _pathologyController.text.trim(),
        foodAllergies: _foodAllergiesController.text.trim(),
        currentInjuries: _injuriesController.text.trim(),
        motorDisability: _motorController.text.trim(),
        areasToAvoid: _areasController.text.trim(),
        role: _isTrainer ? 'trainer' : 'client',
        specialty: _isTrainer ? _specialtyController.text.trim() : null,
        experienceYears: _isTrainer ? int.tryParse(_experienceController.text.trim()) : null,
        certifications: _isTrainer ? _certificationsController.text.trim() : null,
      );'''

text = text.replace(old_submit, new_submit)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
