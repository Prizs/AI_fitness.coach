import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_app/models/user_profile.dart';
import 'package:mobile_app/screens/auth/onboarding_quiz_screen.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/daily_notification_service.dart';
import 'package:mobile_app/widgets/fatigue_checkin_dialog.dart';
import 'package:mobile_app/widgets/app_update.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/screens/anatomy_workout_screen.dart';
import 'package:mobile_app/screens/user_profile_screen.dart';
import 'package:mobile_app/screens/coach_screen.dart';
import 'package:mobile_app/screens/workouts_screen.dart';
import 'package:mobile_app/screens/progress_screen.dart';
import 'package:mobile_app/screens/notifications_screen.dart';
import 'package:mobile_app/screens/nutrition_screen.dart';
import 'package:mobile_app/services/weekly_plan_service.dart';
import 'package:mobile_app/database/db_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = const FlutterSecureStorage();
  String? _archetype;
  bool _checkedArchetype = false;

  @override
  void initState() {
    super.initState();
    _loadArchetype();
  }

  Future<void> _loadArchetype() async {
    try {
      final user = AuthService.instance.loggedInUser;
      final cedula = user?.cedula;
      String? arch;

      // 1. Verificar si ya está en el modelo UserProfile
      if (user?.archetype != null && user!.archetype!.isNotEmpty) {
        arch = user.archetype;
      }

      // 2. Verificar en DBHelper por usuario
      if (arch == null || arch.isEmpty) {
        arch = await DBHelper.instance.getUserArchetype(cedula);
      }

      // 3. Verificar en SecureStorage por cédula y clave general
      if (arch == null || arch.isEmpty) {
        if (cedula != null && cedula.isNotEmpty) {
          arch = await _storage.read(key: 'biopsycho_archetype_$cedula');
        }
      }
      if (arch == null || arch.isEmpty) {
        arch = await _storage.read(key: 'biopsycho_archetype');
      }

      // 4. Si aun no esta en local, consultar al backend por si ya fue registrado previamente
      if ((arch == null || arch.isEmpty) && cedula != null && cedula.isNotEmpty) {
        try {
          final res = await http.get(
            Uri.parse('${AuthService.apiBaseUrl}/api/auth/profile/archetype/$cedula'),
          ).timeout(const Duration(seconds: 4));
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            final serverArch = data['archetype'] as String?;
            if (serverArch != null && serverArch.isNotEmpty) {
              arch = serverArch;
              user?.archetype = serverArch;
              await DBHelper.instance.saveUserArchetype(cedula, serverArch);
            }
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _archetype = arch;
          _checkedArchetype = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _checkedArchetype = true);
    }
  }


  void _openQuiz() {
    final user = AuthService.instance.loggedInUser ??
        UserProfile(
          cedula: '0000000',
          name: 'Usuario',
          lastName: '',
          age: 25,
          weight: 70,
        );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingQuizScreen(
          userProfile: user,
          onComplete: () {
            Navigator.pop(context);
            _loadArchetype();
          },
        ),
      ),
    );
  }

  void _showChangeGoalDialog(BuildContext ctx, WeeklyPlanService planService) {
    showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: const Color(0xFF0F192B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '🎯 Selecciona tu Meta Mensual',
              style: TextStyle(
                color: Color(0xFF8BE0C0),
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Esta meta guía tu plan durante todo el mes. Puedes cambiarla cuando desees.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 14),
            ...WeeklyPlanService.availableGoals.map((g) {
              final isCurrent = g.toLowerCase() == planService.userGoal.toLowerCase();
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: isCurrent ? const Color(0xFF173B45) : null,
                leading: Icon(
                  isCurrent ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                  color: isCurrent ? const Color(0xFF8BE0C0) : Colors.white38,
                ),
                title: Text(
                  g,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent ? const Color(0xFF8BE0C0) : Colors.white,
                    fontSize: 13.5,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(bCtx);
                  await planService.updateUserPreferences(goal: g);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🎯 Meta mensual fijada a: $g'),
                        backgroundColor: const Color(0xFF16253B),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }

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
          'Inicio (VERSIÓN 1.0.52 - Render Activo)',
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
              Icons.system_update_rounded,
              color: Color(0xFF8BE0C0),
              size: 26,
            ),
            tooltip: 'Actualizar App (APK Oficial)',
            onPressed: () => checkForAppUpdate(context, force: true),
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
              AnimatedBuilder(
                animation: planService,
                builder: (context, _) {
                  final levelText = planService.userLevel;
                  final intensityText = planService.userIntensity;
                  final goalText = planService.userGoal;
                  final streak = planService.currentStreak;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      InkWell(
                        onTap: () => _showChangeGoalDialog(context, planService),
                        borderRadius: BorderRadius.circular(999),
                        child: _StatusChip(
                          label: '🎯 Meta: $goalText ✏️',
                          color: const Color(0xFF8BE0C0),
                        ),
                      ),
                      _StatusChip(label: 'Nivel: $levelText'),
                      _StatusChip(
                        label: 'Intensidad: $intensityText',
                        color: const Color(0xFF60A5FA),
                      ),
                      if (streak > 0)
                        _StatusChip(
                          label: '🔥 Racha: $streak ${streak == 1 ? "sesión" : "sesiones"}',
                          color: const Color(0xFFFFB340),
                        ),
                      if (_archetype != null)
                        InkWell(
                          onTap: _openQuiz,
                          borderRadius: BorderRadius.circular(12),
                          child: _StatusChip(
                            label: '🧠 $_archetype',
                            color: const Color(0xFF8BE0C0),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              if (_checkedArchetype && _archetype == null)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF132B36), Color(0xFF0F1A2A)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF8BE0C0).withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8BE0C0).withOpacity(0.12),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8BE0C0).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.psychology_rounded, color: Color(0xFF8BE0C0), size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Test Biopsicosocial Pendiente',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Descubre tu arquetipo, vence la procrastinación y calibra la IA.',
                              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _openQuiz,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8BE0C0),
                          foregroundColor: const Color(0xFF0B1220),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Iniciar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                )
              else if (_archetype != null)
                Builder(
                  builder: (context) {
                    final int s = planService.currentStreak;
                    final bool isOptimal = s >= 3;
                    final bool isActive = s >= 1;
                    final Color mentalColor = isOptimal
                        ? const Color(0xFF8BE0C0)
                        : (isActive ? const Color(0xFFFFB340) : const Color(0xFF60A5FA));
                    final String stateTitle = isOptimal
                        ? 'Enfocado y en Racha'
                        : (isActive ? 'Construcción Activa' : 'Pausa Estratégica (Recalibrando)');
                    final String stateMsg = isOptimal
                        ? 'Tu disciplina física y neural está en su punto más alto. ¡El hábito está consolidado!'
                        : (isActive
                            ? 'Avanzando paso a paso con constancia. Mantén el ritmo de entrenamiento.'
                            : 'Tranquilo, la adherencia se construye día a día. Una sesión suave hoy reactiva tu energía.');
                    final double progressVal = isOptimal ? 0.95 : (isActive ? 0.75 : 0.55);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF142436), Color(0xFF0D1726)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: mentalColor.withOpacity(0.35)),
                        boxShadow: [
                          BoxShadow(
                            color: mentalColor.withOpacity(0.08),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: mentalColor.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.psychology_rounded, color: mentalColor, size: 22),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          _archetype!,
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13.5),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: mentalColor.withOpacity(0.18),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: mentalColor.withOpacity(0.5), width: 0.8),
                                          ),
                                          child: Text(
                                            stateTitle,
                                            style: TextStyle(color: mentalColor, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      stateMsg,
                                      style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7)),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.tune_rounded, color: Colors.white38, size: 18),
                                tooltip: 'Ver arquetipo',
                                onPressed: _openQuiz,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progressVal,
                              backgroundColor: Colors.white10,
                              valueColor: AlwaysStoppedAnimation<Color>(mentalColor),
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              FutureBuilder<bool>(
                future: DailyNotificationService.instance.isFollowupCheckinDue(DateTime.now()),
                builder: (context, snapshot) {
                  if (snapshot.data == true) {
                    final todayPlan = planService.today;
                    final title = todayPlan?['title'] ?? 'Entrenamiento del día';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2A1B10), Color(0xFF1E293B)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amberAccent.withOpacity(0.6)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.help_outline_rounded, color: Colors.amberAccent, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '¿Realizaste tu ejercicio de hoy?',
                                  style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 13.5),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Sesión: ' + title + '. Responde tu encuesta de fatiga.',
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amberAccent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => FatigueCheckinDialog.show(context),
                            child: const Text('Responder', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
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
  const _StatusChip({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF122033),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color?.withOpacity(0.5) ?? Colors.white10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color ?? Colors.white70,
        ),
      ),
    );
  }
}
