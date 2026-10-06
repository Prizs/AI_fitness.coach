import 'package:flutter/material.dart';
import 'package:mobile_app/screens/anatomy_workout_screen.dart';
import 'package:mobile_app/models/anatomy_exercise.dart';

/// Reemplazo del "muneñco 3D horrible" y las pestañas separadas.
/// Ahora redirige directamente al Visor Biomecánico Unificado (modelo .glb real con musculatura).
class ExerciseDetailView extends StatelessWidget {
  const ExerciseDetailView({
    super.key,
    required this.animationKey,
    this.primaryMuscle,
    this.secondaryMuscle,
    this.height = 320,
    this.dynamicExercises,
  });

  final String animationKey;
  final String? primaryMuscle;
  final String? secondaryMuscle;
  final double height;
  final List<AnatomyExercise>? dynamicExercises;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF0F192B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8BE0C0).withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.accessibility_new_rounded, size: 48, color: Color(0xFF8BE0C0)),
          const SizedBox(height: 16),
          const Text(
            'Visor Anatómico 3D Unificado',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Musculatura en movimiento en tiempo real.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8BE0C0),
              foregroundColor: Colors.black,
            ),
            icon: const Icon(Icons.threed_rotation_rounded),
            label: const Text('Abrir Modelo 3D'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AnatomyWorkoutScreen(
                    initialExerciseId: (dynamicExercises != null && dynamicExercises!.isNotEmpty) ? animationKey : _mapAnimKeyToAnatomyId(animationKey),
                    dynamicExercises: dynamicExercises,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _mapAnimKeyToAnatomyId(String key) {
    // Mapeo simple de las rutinas de la base de datos a los IDs del atlas 3D.
    final lower = key.toLowerCase();
    if (lower.contains('squat') || lower.contains('sentadilla')) return 'squat';
    if (lower.contains('push') || lower.contains('flexion')) return 'pushup';
    if (lower.contains('deadlift') || lower.contains('peso_muerto')) return 'deadlift';
    if (lower.contains('plank') || lower.contains('plancha')) return 'plank';
    if (lower.contains('pull') || lower.contains('dominada')) return 'pullup';
    if (lower.contains('lunge') || lower.contains('zancada')) return 'lunge';
    // Por defecto squat para visualizar
    return 'squat';
  }
}
