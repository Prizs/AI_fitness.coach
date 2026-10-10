import sys

path = 'mobile_app/lib/screens/auth/register_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Add SegmentedButton
old_hero = '''              _hero(),
              const SizedBox(height: 18),
              _section('Tu perfil', Icons.person_outline_rounded, ['''

new_hero = '''              _hero(),
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
              _section('Tu perfil', Icons.person_outline_rounded, ['''

text = text.replace(old_hero, new_hero)

# 2. Tu Perfil modifications (hide weight/age partially or keep them?)
old_age_weight = '''                Row(
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
                ),'''

new_age_weight = '''                Row(
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
                ),'''

text = text.replace(old_age_weight, new_age_weight)

# 3. Salud section modification
old_salud = '''              ]),
              const SizedBox(height: 14),
              _section('Salud y adaptación', Icons.accessibility_new_rounded, ['''

new_salud = '''              ]),
              const SizedBox(height: 14),
              if (!_isTrainer) _section('Salud y adaptación', Icons.accessibility_new_rounded, ['''

text = text.replace(old_salud, new_salud)

# 4. Add Professional Profile section
old_submit_button = '''              ]),
              const SizedBox(height: 20),
              FilledButton.icon('''

new_submit_button = '''              ]),
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
              FilledButton.icon('''

text = text.replace(old_submit_button, new_submit_button)

# 5. Fix submit logic payload
old_payload = '''    final profile = UserProfile(
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
    );'''

new_payload = '''    final profile = UserProfile(
      cedula: _cedula.text.trim(),
      password: _password.text,
      name: _name.text.trim(),
      lastName: _lastName.text.trim(),
      age: int.tryParse(_age.text.trim()) ?? 25,
      weight: double.tryParse(_weight.text.trim()) ?? 70.0,
      pathologyOrAllergies: _notes.text.trim().isEmpty
          ? null
          : _notes.text.trim(),
      foodAllergies: _join(_allergies),
      currentInjuries: _join(_injuries),
      motorDisability: _join(_disabilities),
      areasToAvoid: _join(_avoidAreas),
      role: _isTrainer ? 'trainer' : 'client',
      specialty: _isTrainer ? _specialtyController.text.trim() : null,
      experienceYears: _isTrainer ? int.tryParse(_experienceController.text.trim()) : null,
      certifications: _isTrainer ? _certificationsController.text.trim() : null,
    );'''

text = text.replace(old_payload, new_payload)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
