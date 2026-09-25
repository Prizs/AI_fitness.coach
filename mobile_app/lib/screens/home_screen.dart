import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modules = [
      _ModuleTile(
        title: 'Coach IA',
        subtitle:
            'Asistente adaptativo para objetivos, energía y recuperación.',
        icon: Icons.smart_toy_rounded,
        accent: const Color(0xFF2DD4BF),
      ),
      _ModuleTile(
        title: 'Rutinas',
        subtitle: 'Planes por nivel, días de entrenamiento y metas concretas.',
        icon: Icons.fitness_center_rounded,
        accent: const Color(0xFF60A5FA),
      ),
      _ModuleTile(
        title: 'Progreso',
        subtitle: 'Recalibración del plan y seguimiento del avance semanal.',
        icon: Icons.trending_up_rounded,
        accent: const Color(0xFFF59E0B),
      ),
      _ModuleTile(
        title: 'Nutrición',
        subtitle:
            'Recomendaciones simples y adaptadas a la meta y tolerancias.',
        icon: Icons.restaurant_rounded,
        accent: const Color(0xFFFB7185),
      ),
    ];

    return Scaffold(
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
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              color: accent.withValues(alpha: 0.17),
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
