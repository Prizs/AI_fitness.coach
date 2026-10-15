import os

path = 'mobile_app/lib/widgets/plan_options_sheet.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_state_vars = '''class _PlanOptionsFormState extends State<_PlanOptionsForm> {
  String _experience = 'Intermedio';
  String _intensity = 'Medio';
  bool _equipment = true;'''

new_state_vars = '''class _PlanOptionsFormState extends State<_PlanOptionsForm> {
  final TextEditingController _promptController = TextEditingController();
  String _experience = 'Intermedio';
  String _intensity = 'Medio';
  bool _equipment = true;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }'''

text = text.replace(old_state_vars, new_state_vars)

old_build = '''        children: [
          const Text('Configura tu plan', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          const Text('Nivel de Experiencia', style: TextStyle(color: Colors.white70, fontSize: 14)),'''

new_build = '''        children: [
          const Text('Pídele a la IA tu rutina', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _promptController,
            maxLines: 3,
            minLines: 1,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Ej: Quiero entrenar 4 días pecho y espalda, solo tengo mancuernas...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Nivel de Experiencia', style: TextStyle(color: Colors.white70, fontSize: 14)),'''

text = text.replace(old_build, new_build)


old_refresh = '''              WeeklyPlanService.instance.refresh(
                AuthService.instance.loggedInUser,
                experienceLevel: _experience,
                intensityPreference: _intensity,
                equipmentAvailable: _equipment,
              );'''

new_refresh = '''              final prompt = _promptController.text.trim();
              WeeklyPlanService.instance.refresh(
                AuthService.instance.loggedInUser,
                goal: prompt.isNotEmpty ? prompt : 'Mejorar condición física general',
                experienceLevel: _experience,
                intensityPreference: _intensity,
                equipmentAvailable: _equipment,
              );'''

text = text.replace(old_refresh, new_refresh)

# also fix height to prevent overflow (make it scrollable)
old_padding = '''    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,'''

new_padding = '''    return Padding(
      padding: EdgeInsets.only(
        left: 24.0, right: 24.0, top: 24.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,'''

text = text.replace(old_padding, new_padding)
text = text.replace('          ElevatedButton(\n', '          )\n        ],\n      ),\n    );\n  }\n}\n')

# Actually, replacing the padding logic is tricky with string replacement. I will rewrite the widget.
