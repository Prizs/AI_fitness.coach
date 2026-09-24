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
    _plan = profile == null ? Future.value(null) : PlanService().generate(profile);
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
              final sessions = (snapshot.data?['sessions'] as List<dynamic>?) ?? [];
              if (sessions.isEmpty) {
                return const Center(child: Text('No se pudo cargar el plan.'));
              }
              return ListView(
                children: [
                  const Text('Rutinas', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text('Generado por ${snapshot.data?['provider'] ?? 'IA'}', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 18),
                  ...sessions.map((session) => _SessionCard(session: session as Map<String, dynamic>)),
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${session['day']} · ${session['title']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...exercises.map((exercise) {
            final item = exercise as Map<String, dynamic>;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.play_circle_outline_rounded),
              title: Text(item['name'] as String? ?? 'Ejercicio'),
              subtitle: Text('${item['sets']} series · ${item['reps']} · guía 3D: ${item['animation_key']}'),
            );
          }),
        ]),
      ),
    );
  }
}
