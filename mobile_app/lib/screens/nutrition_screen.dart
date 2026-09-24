import 'package:flutter/material.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/plan_service.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
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
              final meals = (snapshot.data?['nutrition'] as List<dynamic>?) ?? [];
              if (meals.isEmpty) {
                return const Center(child: Text('No se pudo cargar la nutrición.'));
              }
              return ListView(
                children: [
                  const Text('Nutrición', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('Plan diario orientativo generado para tu perfil.', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 18),
                  ...meals.map((meal) => _MealCard(meal: meal as Map<String, dynamic>)),
                  if (snapshot.data?['safety_note'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(snapshot.data!['safety_note'] as String, style: const TextStyle(color: Colors.white54)),
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

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal});
  final Map<String, dynamic> meal;

  @override
  Widget build(BuildContext context) {
    final items = (meal['items'] as List<dynamic>?) ?? [];
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(meal['title'] as String? ?? 'Comida', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF2DD4BF))),
          const SizedBox(height: 8),
          ...items.map((item) => Text('• $item', style: const TextStyle(color: Colors.white70))),
        ]),
      ),
    );
  }
}
