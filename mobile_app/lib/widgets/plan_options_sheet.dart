import 'package:flutter/material.dart';
import 'package:mobile_app/services/weekly_plan_service.dart';
import 'package:mobile_app/services/auth_service.dart';

void showPlanOptionsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF101B2D),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) => const _PlanOptionsForm(),
  );
}

class _PlanOptionsForm extends StatefulWidget {
  const _PlanOptionsForm();

  @override
  State<_PlanOptionsForm> createState() => _PlanOptionsFormState();
}

class _PlanOptionsFormState extends State<_PlanOptionsForm> {
  String _experience = 'Intermedio';
  String _intensity = 'Medio';
  bool _equipment = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Configura tu plan', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
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
          const SizedBox(height: 16),
          const Text('Intensidad de Rutina', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Bajo', label: Text('Bajo')),
              ButtonSegment(value: 'Medio', label: Text('Medio')),
              ButtonSegment(value: 'Alto', label: Text('Alto')),
            ],
            selected: {_intensity},
            onSelectionChanged: (set) => setState(() => _intensity = set.first),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFF8BE0C0) : Colors.transparent),
              foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFF0B1220) : Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('¿Cuentas con equipo de ejercicio?', style: TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: Text(_equipment ? 'Gym / Pesas' : 'Solo peso corporal (Sin herramientas)', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            value: _equipment,
            activeColor: const Color(0xFF8BE0C0),
            onChanged: (val) => setState(() => _equipment = val),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              WeeklyPlanService.instance.refresh(
                AuthService.instance.loggedInUser,
                experienceLevel: _experience,
                intensityPreference: _intensity,
                equipmentAvailable: _equipment,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8BE0C0),
              foregroundColor: const Color(0xFF0B1220),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Generar Plan Semanal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
    );
  }
}
