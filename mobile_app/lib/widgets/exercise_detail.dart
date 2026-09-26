import 'package:flutter/material.dart';
import 'package:mobile_app/services/muscle_map.dart';
import 'package:mobile_app/widgets/exercise_3d_viewer.dart';
import 'package:mobile_app/widgets/muscle_map_view.dart';

/// Detalle de un ejercicio con dos vistas:
///
/// - **Musculos**: atlas anatomico real con el agonista y el sinergista
///   resaltados. Es la vista principal porque se lee de un vistazo.
/// - **3D**: figura humanoide animada y giratoria del movimiento.
///
/// Si el ejercicio no tiene musculos reconocidos se abre en la vista 3D.
class ExerciseDetailView extends StatelessWidget {
  const ExerciseDetailView({
    super.key,
    required this.animationKey,
    this.primaryMuscle,
    this.secondaryMuscle,
    this.height = 320,
  });

  final String animationKey;
  final String? primaryMuscle;
  final String? secondaryMuscle;
  final double height;

  @override
  Widget build(BuildContext context) {
    final hasMuscles = MuscleMap.idsFor(primaryMuscle).isNotEmpty ||
        MuscleMap.idsFor(secondaryMuscle).isNotEmpty;
    final initialIndex = hasMuscles ? 1 : 0;

    return DefaultTabController(
      length: 2,
      initialIndex: initialIndex,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F192B),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(4),
            child: TabBar(
              indicator: BoxDecoration(
                color: const Color(0xFF8BE0C0),
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: const Color(0xFF0B1220),
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              tabs: const [
                Tab(text: '3D', icon: Icon(Icons.threed_rotation_rounded, size: 16)),
                Tab(
                  text: 'Musculos',
                  icon: Icon(Icons.accessibility_new_rounded, size: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: height + 70,
            child: TabBarView(
              children: [
                SingleChildScrollView(
                  child: Exercise3DViewer(
                    animationKey: animationKey,
                    primaryMuscle: primaryMuscle,
                    secondaryMuscle: secondaryMuscle,
                    height: height,
                    showMuscleLegend: false,
                  ),
                ),
                SingleChildScrollView(
                  child: MuscleMapView(
                    primaryMuscle: primaryMuscle,
                    secondaryMuscle: secondaryMuscle,
                    height: height,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
