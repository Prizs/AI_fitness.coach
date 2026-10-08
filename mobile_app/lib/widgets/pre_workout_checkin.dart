import 'package:flutter/material.dart';

void showPreWorkoutCheckin(BuildContext context, {required VoidCallback onProceed}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF101B2D),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) => _PreWorkoutCheckinForm(onProceed: onProceed),
  );
}

class _PreWorkoutCheckinForm extends StatefulWidget {
  final VoidCallback onProceed;
  const _PreWorkoutCheckinForm({required this.onProceed});

  @override
  State<_PreWorkoutCheckinForm> createState() => _PreWorkoutCheckinFormState();
}

class _PreWorkoutCheckinFormState extends State<_PreWorkoutCheckinForm> {
  int _step = 0; // 0: Feel good?, 1: Warmed up?, 2: Final Advice
  bool _hasDiscomfort = false;
  bool _hasWarmedUp = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Check-in de Seguridad', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          if (_step == 0) ...[
            const Text('¿Cómo te sientes físicamente hoy?', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() { _hasDiscomfort = false; _step = 1; }),
              icon: const Icon(Icons.fitness_center),
              label: const Text('¡Al 100%!'),
              style: _btnStyle(const Color(0xFF8BE0C0), const Color(0xFF0B1220)),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => setState(() { _hasDiscomfort = true; _step = 2; }),
              icon: const Icon(Icons.healing),
              label: const Text('Tengo una molestia/dolor'),
              style: _btnStyle(const Color(0xFF173B45), Colors.white),
            ),
          ] else if (_step == 1) ...[
            const Text('¿Ya realizaste tu pre-calentamiento?', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                widget.onProceed();
              },
              icon: const Icon(Icons.local_fire_department),
              label: const Text('Sí, ya calenté'),
              style: _btnStyle(const Color(0xFF8BE0C0), const Color(0xFF0B1220)),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => setState(() { _hasWarmedUp = false; _step = 2; }),
              icon: const Icon(Icons.ac_unit),
              label: const Text('Aún no'),
              style: _btnStyle(const Color(0xFF173B45), Colors.white),
            ),
          ] else if (_step == 2) ...[
            if (_hasDiscomfort) ...[
              const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 48),
              const SizedBox(height: 16),
              const Text('Entrenamiento Modificado Requerido', style: TextStyle(color: Colors.orangeAccent, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text('Si sientes dolor agudo, es mejor descansar. Si es una molestia leve, ve a la pestaña "Coach" y pídele a la IA que adapte tu rutina evitando la zona afectada.', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
            ] else if (!_hasWarmedUp) ...[
              const Icon(Icons.sports_gymnastics_rounded, color: Color(0xFF8BE0C0), size: 48),
              const SizedBox(height: 16),
              const Text('¡Calienta antes de empezar!', style: TextStyle(color: Color(0xFF8BE0C0), fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text('Haz 3 minutos de movimientos articulares (círculos con los brazos, rotación de cadera, rodillas al pecho).', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (!_hasDiscomfort) widget.onProceed();
              },
              style: _btnStyle(const Color(0xFF8BE0C0), const Color(0xFF0B1220)),
              child: Text(_hasDiscomfort ? 'Entendido' : 'Hecho, ¡A entrenar!'),
            ),
          ]
        ],
      ),
    );
  }

  ButtonStyle _btnStyle(Color bg, Color fg) {
    return ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      minimumSize: const Size(double.infinity, 50),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
