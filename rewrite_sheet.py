import os

path = 'mobile_app/lib/widgets/plan_options_sheet.dart'
code = '''import 'package:flutter/material.dart';
import 'package:mobile_app/services/weekly_plan_service.dart';
import 'package:mobile_app/services/auth_service.dart';

void showPlanOptionsSheet(BuildContext context, {String initialPrompt = ''}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF101B2D),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) => _PlanOptionsForm(initialPrompt: initialPrompt),
  );
}

class _PlanOptionsForm extends StatefulWidget {
  final String initialPrompt;
  const _PlanOptionsForm({this.initialPrompt = ''});

  @override
  State<_PlanOptionsForm> createState() => _PlanOptionsFormState();
}

class _PlanOptionsFormState extends State<_PlanOptionsForm> {
  late final TextEditingController _promptController;
  final TextEditingController _molestiaController = TextEditingController();
  
  String _estado = 'Bien';
  String _equipo = 'Gym Completo';
  String _intensity = 'Medio';
  String _experience = 'Intermedio';

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(text: widget.initialPrompt);
  }

  @override
  void dispose() {
    _promptController.dispose();
    _molestiaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24.0, right: 24.0, top: 24.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Configuración Rápida de Rutina', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            // 1. Estado Fisico
            const Text('¿Cómo te sientes físicamente?', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Bien', label: Text('Bien (100%)', style: TextStyle(fontSize: 12))),
                ButtonSegment(value: 'Molestia', label: Text('Tengo una molestia', style: TextStyle(fontSize: 12))),
              ],
              selected: {_estado},
              onSelectionChanged: (set) => setState(() => _estado = set.first),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFF8BE0C0) : Colors.transparent),
                foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFF0B1220) : Colors.white),
              ),
            ),
            
            if (_estado == 'Molestia') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _molestiaController,
                maxLines: 2,
                minLines: 1,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '¿Dónde te duele? (Ej: Rodilla derecha, evita saltos)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF4A1A1A).withOpacity(0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
                ),
              ),
            ],

            const SizedBox(height: 20),
            
            // 2. Equipo
            const Text('¿Dónde entrenarás / Equipo?', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Gym Completo', label: Text('Gym Completo', style: TextStyle(fontSize: 11))),
                ButtonSegment(value: 'Herramientas en Casa', label: Text('Herramientas\nen Casa', textAlign: TextAlign.center, style: TextStyle(fontSize: 10))),
                ButtonSegment(value: 'Sin Herramientas', label: Text('Sin\nHerramientas', textAlign: TextAlign.center, style: TextStyle(fontSize: 10))),
              ],
              selected: {_equipo},
              onSelectionChanged: (set) => setState(() => _equipo = set.first),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFF8BE0C0) : Colors.transparent),
                foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFF0B1220) : Colors.white),
              ),
            ),

            const SizedBox(height: 20),

            // 3. Intensidad
            const Text('Nivel de Intensidad', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Bajo', label: Text('Bajo')),
                ButtonSegment(value: 'Medio', label: Text('Medio')),
                ButtonSegment(value: 'Alto', label: Text('Intenso')),
              ],
              selected: {_intensity},
              onSelectionChanged: (set) => setState(() => _intensity = set.first),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFF8BE0C0) : Colors.transparent),
                foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFF0B1220) : Colors.white),
              ),
            ),

            const SizedBox(height: 20),
            
            // 4. Experiencia (Oculto en un ExpansionTile para ahorrar espacio o lo dejamos igual)
            const Text('Nivel de Experiencia', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Principiante', label: Text('Principiante', style: TextStyle(fontSize: 12))),
                ButtonSegment(value: 'Intermedio', label: Text('Intermedio', style: TextStyle(fontSize: 12))),
                ButtonSegment(value: 'Avanzado', label: Text('Avanzado', style: TextStyle(fontSize: 12))),
              ],
              selected: {_experience},
              onSelectionChanged: (set) => setState(() => _experience = set.first),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFF8BE0C0) : Colors.transparent),
                foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFF0B1220) : Colors.white),
              ),
            ),

            const SizedBox(height: 20),

            // Peticion libre
            const Text('Detalles adicionales (Opcional)', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _promptController,
              maxLines: 2,
              minLines: 1,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ej: Solo tengo 30 min, enfocate en piernas...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8BE0C0),
                  foregroundColor: const Color(0xFF0B1220),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  
                  final buffer = StringBuffer();
                  if (_estado == 'Molestia' && _molestiaController.text.isNotEmpty) {
                    buffer.writeln('IMPORTANTE: Tengo una molestia/dolor en: . Toma la decisión pertinente de si tomar un descanso o recomendar ejercicios que NO afecten esa área.');
                  }
                  buffer.writeln('Equipo disponible: .');
                  
                  final prompt = _promptController.text.trim();
                  if (prompt.isNotEmpty) {
                    buffer.writeln('Preferencias adicionales: ');
                  }
                  
                  final finalGoal = buffer.toString().trim();

                  WeeklyPlanService.instance.refresh(
                    AuthService.instance.loggedInUser,
                    goal: finalGoal.isNotEmpty ? finalGoal : 'Mejorar condición física general',
                    experienceLevel: _experience,
                    intensityPreference: _intensity,
                    equipmentAvailable: _equipo != 'Sin Herramientas',
                  );
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generar Plan Inteligente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
'''
with open(path, 'w', encoding='utf-8') as f:
    f.write(code)
