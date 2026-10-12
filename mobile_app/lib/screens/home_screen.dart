import 'package:flutter/material.dart';
import 'package:mobile_app/screens/anatomy_workout_screen.dart';
import 'package:mobile_app/screens/user_profile_screen.dart';
import 'package:mobile_app/screens/coach_screen.dart';
import 'package:mobile_app/screens/workouts_screen.dart';
import 'package:mobile_app/screens/progress_screen.dart';
import 'package:mobile_app/screens/notifications_screen.dart';
import 'package:mobile_app/screens/nutrition_screen.dart';
import 'package:mobile_app/services/weekly_plan_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final planService = WeeklyPlanService.instance;
    final hasNotification = planService.week == null || DateTime.now().weekday >= 5;
    final modules = [
      _ModuleTile(
        title: 'Coach IA',
        subtitle: 'Asistente adaptativo para objetivos, energía y recuperación.',
        icon: Icons.smart_toy_rounded,
        accent: const Color(0xFF2DD4BF),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoachScreen())),
      ),
      _ModuleTile(
        title: 'Rutinas',
        subtitle: 'Planes por nivel, días de entrenamiento y metas concretas.',
        icon: Icons.fitness_center_rounded,
        accent: const Color(0xFF60A5FA),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutsScreen())),
      ),
      _ModuleTile(
        title: 'Progreso',
        subtitle: 'Recalibración del plan y seguimiento del avance semanal.',
        icon: Icons.trending_up_rounded,
        accent: const Color(0xFFF59E0B),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen())),
      ),
      _ModuleTile(
        title: 'Nutrición',
        subtitle: 'Recomendaciones simples y adaptadas a la meta y tolerancias.',
        icon: Icons.restaurant_rounded,
        accent: const Color(0xFFFB7185),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NutritionScreen())),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F192B),
        elevation: 0,
        title: const Text(
          'Inicio (VERSIÓN 1.0.40 - Render Activo)',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(
                  Icons.notifications_rounded,
                  color: Color(0xFF8BE0C0),
                  size: 26,
                ),
                if (hasNotification)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                    ),
                  ),
              ],
            ),
            tooltip: 'Notificaciones y Avisos',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.view_in_ar_rounded,
              color: Color(0xFF8BE0C0),
              size: 28,
            ),
            tooltip: 'Anatomía 3D',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AnatomyWorkoutScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.account_circle_rounded,
              color: Color(0xFF8BE0C0),
              size: 32,
            ),
            tooltip: 'Mi Perfil y Salud',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserProfileScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      backgroundColor: const Color(0xFF0A0F1D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tu entrenador inteligente',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              const Text(
                'Seguimiento deportivo, nutrición, descanso y adaptación continua.',
                style: TextStyle(fontSize: 15, color: Colors.white70),
              ),
              const SizedBox(height: 24),
              Row(
                children: const [
                  _StatusChip(label: 'Meta: Ganar fuerza'),
                  SizedBox(width: 10),
                  _StatusChip(label: 'Nivel: Intermedio'),
                ],
              ),
              const SizedBox(height: 26),
              Expanded(
                child: ListView.separated(
                  itemCount: modules.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) => modules[index],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF111B2D),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.17),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: accent, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF122033),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
        ),
      ),
    );
  }
}
