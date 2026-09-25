import 'package:flutter/material.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/plan_service.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  late Future<Map<String, dynamic>?> _plan;

  @override
  void initState() {
    super.initState();
    final profile = AuthService.instance.loggedInUser;
    _plan = PlanService().generate(profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FutureBuilder<Map<String, dynamic>?>(
            future: _plan,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final sessions =
                  (snapshot.data?['sessions'] as List<dynamic>?) ?? [];
              if (sessions.isEmpty) {
                return const Center(child: Text('No se pudo cargar el plan.'));
              }
              return ListView(
                children: [
                  const Text(
                    'Rutinas',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Generado por ${snapshot.data?['provider'] ?? 'IA'}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 18),
                  ...sessions.map(
                    (session) =>
                        _SessionCard(session: session as Map<String, dynamic>),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});
  final Map<String, dynamic> session;

  @override
  Widget build(BuildContext context) {
    final exercises = (session['exercises'] as List<dynamic>?) ?? [];
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${session['day']} · ${session['title']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ...exercises.map((exercise) {
              final item = exercise as Map<String, dynamic>;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF173B45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.view_in_ar_rounded, color: Color(0xFF8BE0C0)),
                ),
                title: Text(
                  item['name'] as String? ?? 'Ejercicio',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${item['sets']} series · ${item['reps']}',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF101B2D),
                    foregroundColor: const Color(0xFF8BE0C0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Ver 3D'),
                  onPressed: () => _openExercisePreview(context, item),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _openExercisePreview(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F192B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _Exercise3DPreviewSheet(exercise: item),
    );
  }
}

class _Exercise3DPreviewSheet extends StatefulWidget {
  const _Exercise3DPreviewSheet({required this.exercise});
  final Map<String, dynamic> exercise;

  @override
  State<_Exercise3DPreviewSheet> createState() => _Exercise3DPreviewSheetState();
}

class _Exercise3DPreviewSheetState extends State<_Exercise3DPreviewSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.exercise['name'] as String? ?? 'Ejercicio';
    final sets = widget.exercise['sets']?.toString() ?? '3';
    final reps = widget.exercise['reps']?.toString() ?? '12';
    final animKey = widget.exercise['animation_key'] as String? ?? 'generic_exercise';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8BE0C0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.fitness_center_rounded, color: Color(0xFF0B1220)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '$sets series · $reps repeticiones',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: const Color(0xFF0A101D),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF173B45), width: 1.5),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    final progress = _animController.value;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Transform.translate(
                          offset: Offset(0, -15 * progress),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF8BE0C0).withValues(alpha: 0.8),
                                  const Color(0xFF173B45),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8BE0C0).withValues(alpha: 0.3 * progress),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.accessibility_new_rounded,
                              size: 60,
                              color: Color(0xFF0B1220),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Tutorial Guiado: $animKey',
                          style: const TextStyle(
                            color: Color(0xFF8BE0C0),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fase: ${(progress * 100).toInt()}% de recorrido',
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    );
                  },
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF173B45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.threed_rotation_rounded, size: 16, color: Color(0xFF8BE0C0)),
                        SizedBox(width: 4),
                        Text('Vista 3D Activa', style: TextStyle(fontSize: 11, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8BE0C0),
              foregroundColor: const Color(0xFF0B1220),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Entendido, continuar rutina', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
