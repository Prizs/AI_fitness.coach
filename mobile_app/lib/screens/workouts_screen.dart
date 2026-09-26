import 'package:flutter/material.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/plan_service.dart';
import 'package:mobile_app/widgets/exercise_detail.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  late Future<Map<String, dynamic>?> _plan;
  final PlanService _service = PlanService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load({bool forceRefresh = false}) {
    final profile = AuthService.instance.loggedInUser;
    setState(() {
      _plan = _service.generate(profile, forceRefresh: forceRefresh);
    });
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
                return _ErrorState(
                  message: _service.lastError ?? 'No se pudo cargar el plan.',
                  onRetry: _load,
                );
              }
              return ListView(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Rutinas',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Generar un plan nuevo',
                        onPressed: () => _load(forceRefresh: true),
                        icon: const Icon(Icons.refresh_rounded,
                            color: Color(0xFF8BE0C0)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _service.lastFromCache
                        ? 'Mostrando tu plan guardado · toca el icono para generar uno nuevo'
                        : 'Generado por ${snapshot.data?['provider'] ?? 'IA'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 46, color: Color(0xFFFF7A7A)),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8BE0C0),
              foregroundColor: const Color(0xFF0B1220),
            ),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
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
                  child: const Icon(Icons.view_in_ar_rounded,
                      color: Color(0xFF8BE0C0)),
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
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
  State<_Exercise3DPreviewSheet> createState() =>
      _Exercise3DPreviewSheetState();
}

class _Exercise3DPreviewSheetState extends State<_Exercise3DPreviewSheet> {
  @override
  Widget build(BuildContext context) {
    final name = widget.exercise['name'] as String? ?? 'Ejercicio';
    final sets = widget.exercise['sets']?.toString() ?? '3';
    final reps = widget.exercise['reps']?.toString() ?? '12';
    final animKey =
        widget.exercise['animation_key'] as String? ?? 'generic_exercise';

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
                child: const Icon(Icons.fitness_center_rounded,
                    color: Color(0xFF0B1220)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800),
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
          ExerciseDetailView(
            animationKey: animKey,
            primaryMuscle: widget.exercise['primary_muscle'] as String?,
            secondaryMuscle: widget.exercise['secondary_muscle'] as String?,
            height: 300,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8BE0C0),
              foregroundColor: const Color(0xFF0B1220),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Entendido, continuar rutina',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}