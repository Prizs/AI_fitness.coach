import 'package:mobile_app/widgets/performance_report_modal.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/weekly_plan_service.dart';
import 'package:mobile_app/database/db_helper.dart';
import 'package:mobile_app/screens/coach_screen.dart';
import 'package:mobile_app/screens/body_metrics_screen.dart';
import 'package:mobile_app/screens/admin_console_screen.dart';
import 'package:mobile_app/screens/adaptive_workout_screen.dart';
import 'package:mobile_app/screens/auth/onboarding_quiz_screen.dart';
import 'package:mobile_app/models/user_profile.dart';
import 'package:mobile_app/main.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final WeeklyPlanService _planService = WeeklyPlanService.instance;
  final List<String> _allergies = ['Lácteos', 'Mariscos'];
  final List<String> _injuries = ['Molestia en manguito rotador derecho'];
  final _allergyController = TextEditingController();
  final _injuryController = TextEditingController();
  List<Map<String, dynamic>> _sessionHistory = [];
  int _adminTapCount = 0;
  DateTime? _lastAdminTapTime;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _handleAdminVersionTap() {
    final now = DateTime.now();
    if (_lastAdminTapTime == null || now.difference(_lastAdminTapTime!).inSeconds > 3) {
      _adminTapCount = 1;
    } else {
      _adminTapCount++;
    }
    _lastAdminTapTime = now;

    if (_adminTapCount >= 7) {
      _adminTapCount = 0;
      _showAdminPinDialog();
    }
  }

  void _showAdminPinDialog() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF101C2F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.security_rounded, color: Color(0xFF8BE0C0), size: 24),
            SizedBox(width: 10),
            Text('Acceso Maestro Dev', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa el PIN de soporte técnico o desarrollador para acceder a la consola de diagnóstico.',
              style: TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              autofocus: true,
              style: const TextStyle(color: Colors.white, letterSpacing: 4, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'PIN Maestro',
                hintStyle: const TextStyle(color: Colors.white38, letterSpacing: 1),
                filled: true,
                fillColor: const Color(0xFF16253B),
                prefixIcon: const Icon(Icons.key_rounded, color: Color(0xFF8BE0C0)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8BE0C0), foregroundColor: const Color(0xFF0B1220)),
            onPressed: () {
              final pin = pinController.text.trim();
              if (pin == '2026' || pin == 'admin818') {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminConsoleScreen()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⛔ PIN maestro incorrecto.'),
                    backgroundColor: Color(0xFFFF6B6B),
                  ),
                );
              }
            },
            child: const Text('Entrar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadBitacoraPdf() async {
    final user = AuthService.instance.loggedInUser;
    final cedula = user?.cedula ?? 'default';
    final baseUrl = AuthService.apiBaseUrl;
    final url = '$baseUrl/api/coach/bitacora/export?cedula=$cedula&print_auto=true';
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir la bitácora: $e'),
            backgroundColor: const Color(0xFFFF6B6B),
          ),
        );
      }
    }
  }


  Future<void> _loadData() async {
    await _planService.refreshWorkoutStats();
    final history = await DBHelper.instance.getSessionHistory();
    if (mounted) {
      setState(() {
        _sessionHistory = history;
      });
    }
  }

  void _addTag(List<String> list, TextEditingController ctrl) {
    if (ctrl.text.trim().isNotEmpty) {
      setState(() {
        list.add(ctrl.text.trim());
        ctrl.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restricción sincronizada con el Coach IA')),
      );
    }
  }

  void _showChangeGoalDialog() {
    final goals = [
      'Aumentar masa muscular',
      'Pérdida de grasa y definición',
      'Mejorar resistencia cardiovascular',
      'Ganar fuerza funcional',
      'Salud integral y movilidad',
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0F192B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
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
              'Selecciona tu Meta Principal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Se actualizará de inmediato en Inicio, Perfil y en el Coach IA.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 14),
            ...goals.map((g) {
              final isCurrent = g.toLowerCase() == _planService.userGoal.toLowerCase();
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
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _planService.updateUserPreferences(goal: g);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🎯 Meta actualizada a: $g'),
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
    final user = AuthService.instance.loggedInUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        title: const Text('Mi Perfil Atlético & Salud', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: const Color(0xFF0F192B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              AuthService.instance.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthGate()),
                (r) => false,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _planService,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Resumen de Métricas
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF173B45),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8BE0C0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.person_rounded, size: 36, color: Color(0xFF0B1220)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${user?.name ?? 'Atleta'} ${user?.lastName ?? ''}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cédula: ${user?.cedula ?? 'V-Local'} · ${user?.age ?? 25} años · ${user?.weight ?? 70.0} kg · ${user?.gender == 'femenino' ? 'Femenino ♀' : 'Masculino ♂'}',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tarjeta de Racha de Entrenamiento (Streak) - Incentivo Atlético
              _StreakCard(
                currentStreak: _planService.currentStreak,
                bestStreak: _planService.bestStreak,
                totalSessions: _planService.totalCompletedSessions,
                adherence: _planService.adherenceRate,
                burnedKcal: _planService.estimatedBurnedCaloriesTotal,
                burnedFatGrams: _planService.estimatedBurnedFatGramsTotal,
              ),
              const SizedBox(height: 12),

              // Bitacora de Ejercicios Omitidos / Dejados por Alto
              _SkippedExercisesCard(planService: _planService),
              const SizedBox(height: 12),

              // Botón de Reporte Detallado de Rendimiento
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF173B45),
                  foregroundColor: const Color(0xFF8BE0C0),
                  side: const BorderSide(color: Color(0xFF8BE0C0), width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.assessment_rounded, size: 22),
                label: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ver Reporte Detallado de Rendimiento', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  ],
                ),
                onPressed: () => PerformanceReportModal.show(context),
              ),
              const SizedBox(height: 10),

              // Botón de Descargar Bitácora de Rendimiento (PDF)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF102820),
                  foregroundColor: const Color(0xFF8BE0C0),
                  side: const BorderSide(color: Color(0xFF8BE0C0), width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 22, color: Color(0xFF8BE0C0)),
                label: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Descargar Bitácora Oficial (PDF)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    Icon(Icons.open_in_new_rounded, size: 14),
                  ],
                ),
                onPressed: _downloadBitacoraPdf,
              ),
              const SizedBox(height: 10),

              // Botón de Test Biopsicosocial & Adherencia (Estilo FitCraft)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF142436),
                  foregroundColor: const Color(0xFF8BE0C0),
                  side: const BorderSide(color: Color(0xFF8BE0C0), width: 1.1),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.psychology_rounded, size: 22, color: Color(0xFF8BE0C0)),
                label: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Test Biopsicosocial & Adherencia (FitCraft)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  ],
                ),
                onPressed: () {
                  final u = AuthService.instance.loggedInUser ??
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
                        userProfile: u,
                        onComplete: () {
                          Navigator.pop(context);
                          setState(() {});
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              // Botón de Test Módulo Adaptado (Torso Sentado & Inclusivo)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF132034),
                  foregroundColor: const Color(0xFF8BE0C0),
                  side: const BorderSide(color: Color(0xFF8BE0C0), width: 1.1),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.accessible_forward_rounded, size: 22, color: Color(0xFF8BE0C0)),
                label: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Test Módulo Adaptado (Torso Sentado)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  ],
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdaptiveWorkoutScreen()),
                ),
              ),
              const SizedBox(height: 10),

              // Botón de Evolución Corporal & Métricas (Peso, Grasa, Medidas)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F192B),
                  foregroundColor: const Color(0xFF1FAE87),
                  side: const BorderSide(color: Color(0xFF1FAE87), width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.show_chart_rounded, size: 22),
                label: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Evolución Corporal, Peso & Medidas', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  ],
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BodyMetricsScreen()),
                ),
              ),
              const SizedBox(height: 16),

              // Metas Atléticas y Nivel Sincronizado con Coach IA
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F192B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Metas y Nivel del Atleta',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF8BE0C0),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          onPressed: _showChangeGoalDialog,
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text('Cambiar', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.track_changes_rounded, color: Color(0xFF8BE0C0)),
                      title: const Text('Meta Activa (Fase en Curso)', style: TextStyle(fontSize: 12, color: Colors.white60)),
                      subtitle: Text(
                        _planService.userGoal,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                    const Divider(color: Colors.white10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.bolt_rounded, color: Color(0xFFFFB340)),
                      title: const Text('Nivel e Intensidad en Coach IA', style: TextStyle(fontSize: 12, color: Colors.white60)),
                      subtitle: Text(
                        '${_planService.userLevel} · Intensidad ${_planService.userIntensity}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      trailing: TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CoachScreen()));
                        },
                        child: const Text('Ir a Coach IA', style: TextStyle(color: Color(0xFF8BE0C0), fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Historial de Sesiones Registradas para Análisis del Coach IA
              if (_sessionHistory.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F192B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.history_rounded, size: 18, color: Color(0xFF8BE0C0)),
                          SizedBox(width: 8),
                          Text(
                            'Historial de Sesiones (Datos para la IA)',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._sessionHistory.take(5).map((s) {
                        final rpe = s['rpe'] ?? 7;
                        final feeling = s['feeling'] ?? 'Con energía';
                        final title = s['title'] ?? 'Sesión completada';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141F32),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF8BE0C0)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Esfuerzo: RPE $rpe/10 · $feeling',
                                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Gestión de Alergias
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F192B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.no_food_rounded, color: Color(0xFF8BE0C0)),
                        SizedBox(width: 8),
                        Text('Alergias y Exclusiones Alimentarias', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: _allergies
                          .map((a) => Chip(
                                label: Text(a),
                                onDeleted: () => setState(() => _allergies.remove(a)),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _allergyController,
                            decoration: const InputDecoration(hintText: 'Agregar alergia...'),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF8BE0C0)),
                          onPressed: () => _addTag(_allergies, _allergyController),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Lesiones
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F192B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.healing_rounded, color: Color(0xFF8BE0C0)),
                        SizedBox(width: 8),
                        Text('Condiciones y Lesiones Físicas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: _injuries
                          .map((i) => Chip(
                                label: Text(i),
                                onDeleted: () => setState(() => _injuries.remove(i)),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _injuryController,
                            decoration: const InputDecoration(hintText: 'Agregar lesión o dolor...'),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF8BE0C0)),
                          onPressed: () => _addTag(_injuries, _injuryController),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: _handleAdminVersionTap,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        Text(
                          'AI Fitness Coach v1.0.58+59',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Plataforma Biométrica Inteligente',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.18),
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.currentStreak,
    required this.bestStreak,
    required this.totalSessions,
    required this.adherence,
    this.burnedKcal = 0,
    this.burnedFatGrams = 0.0,
  });

  final int currentStreak;
  final int bestStreak;
  final int totalSessions;
  final double adherence;
  final int burnedKcal;
  final double burnedFatGrams;

  @override
  Widget build(BuildContext context) {
    String badgeText = '🌱 Construyendo Hábito';
    Color badgeColor = const Color(0xFF8BE0C0);
    if (currentStreak >= 6) {
      badgeText = '⚡ Atleta Imparable';
      badgeColor = const Color(0xFFFF6B6B);
    } else if (currentStreak >= 3) {
      badgeText = '🔥 En Racha Fuerte';
      badgeColor = const Color(0xFFFFB340);
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF101C2F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFB340).withOpacity(0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Racha de Entrenamientos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeColor.withOpacity(0.5)),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metricColumn('Racha Actual', '$currentStreak', const Color(0xFFFFB340), 'sesiones'),
              Container(width: 1, height: 40, color: Colors.white12),
              _metricColumn('Récord Racha', '$bestStreak', const Color(0xFF8BE0C0), 'máxima'),
              Container(width: 1, height: 40, color: Colors.white12),
              _metricColumn('Total Hechas', '$totalSessions', Colors.white, 'sesiones'),
              Container(width: 1, height: 40, color: Colors.white12),
              _metricColumn('Adherencia', '${adherence.toStringAsFixed(0)}%', const Color(0xFF8BE0C0), 'semanal'),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF142436),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department_rounded, size: 16, color: Color(0xFFFFB340)),
                    const SizedBox(width: 4),
                    Text(
                      '~$burnedKcal kcal quemadas',
                      style: const TextStyle(color: Color(0xFFFFB340), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(width: 1, height: 16, color: Colors.white12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.water_drop_rounded, size: 16, color: Color(0xFF8BE0C0)),
                    const SizedBox(width: 4),
                    Text(
                      '~${burnedFatGrams.toStringAsFixed(1)} g grasa oxidada',
                      style: const TextStyle(color: Color(0xFF8BE0C0), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricColumn(String label, String value, Color color, String sub) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600)),
        Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 9.5)),
      ],
    );
  }
}


class _SkippedExercisesCard extends StatelessWidget {
  const _SkippedExercisesCard({required this.planService});

  final WeeklyPlanService planService;

  @override
  Widget build(BuildContext context) {
    final skipped = planService.skippedExercises;
    final missedDays = planService.skippedOrMissedDays;
    final missedKcal = planService.estimatedMissedCaloriesTotal;
    final missedFat = planService.estimatedMissedFatGramsTotal;

    if (skipped.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F2228),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF8BE0C0).withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8BE0C0).withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF8BE0C0), size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bitcora al Da: Cero Ejercicios Omitidos',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'No dejaste ejercicios por alto en los das programados.',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF22161A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.event_busy_rounded, color: Color(0xFFFF6B6B), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bitcora: ${skipped.length} Ejercicios Dejados por Alto',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
                    ),
                    Text(
                      '${missedDays.length} sesin(es) programada(s) sin completar esta semana',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF141F32),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Impacto calrico no alcanzado:',
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8)),
                ),
                Text(
                  '-$missedKcal kcal (~${missedFat.toStringAsFixed(1)}g grasa)',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFF6B6B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Detalle de ejercicios no realizados:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white60),
          ),
          const SizedBox(height: 6),
          ...skipped.map((item) {
            final name = item['name'] ?? 'Ejercicio';
            final day = item['missed_day'] ?? 'Da pasado';
            final sets = item['sets'] ?? 3;
            final reps = item['reps'] ?? '12';
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF16233A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.close_rounded, size: 16, color: Color(0xFFFF6B6B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$name',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        Text(
                          'Programado el $day  $sets series  $reps reps',
                          style: const TextStyle(fontSize: 10.5, color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
