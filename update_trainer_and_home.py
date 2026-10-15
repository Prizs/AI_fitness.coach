import re

# 1. Update home_screen.dart to add notification bell icon with badge
path_home = 'mobile_app/lib/screens/home_screen.dart'
with open(path_home, 'r', encoding='utf-8') as f:
    text_home = f.read()

bell_action = """          IconButton(
            icon: Stack(
              children: [
                const Icon(
                  Icons.notifications_rounded,
                  color: Color(0xFF8BE0C0),
                  size: 26,
                ),
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
              Icons.view_in_ar_rounded,"""

text_home = text_home.replace("""          IconButton(
            icon: const Icon(
              Icons.view_in_ar_rounded,""", bell_action)

with open(path_home, 'w', encoding='utf-8') as f:
    f.write(text_home)
print("Updated home_screen.dart with notification bell")

# 2. Update coach_screen.dart to send active plan dates to /api/coach/chat
path_coach = 'mobile_app/lib/screens/coach_screen.dart'
with open(path_coach, 'r', encoding='utf-8') as f:
    text_coach = f.read()

old_post_call = """      final baseUrl = AuthService.apiBaseUrl;
      final profile = AuthService.instance.loggedInUser;
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/coach/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': text,
              'history': history,
              'user_goal': 'Rendimiento general',
              'user_level': 'Intermedio',
              'allergies': profile?.foodAllergies,
              'injuries': profile?.currentInjuries,
              'motor_disability': profile?.motorDisability,
              'areas_to_avoid': profile?.areasToAvoid, 'age': profile?.age, 'weight': profile?.weight,
            }),
          )"""

new_post_call = """      final baseUrl = AuthService.apiBaseUrl;
      final profile = AuthService.instance.loggedInUser;
      
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      final formatDate = (DateTime d) => '${d.day}/${d.month}/${d.year}';
      final hasPlan = WeeklyPlanService.instance.week != null;
      final startStr = hasPlan ? formatDate(monday) : null;
      final endStr = hasPlan ? formatDate(sunday) : null;

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/coach/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': text,
              'history': history,
              'user_goal': 'Rendimiento general',
              'user_level': 'Intermedio',
              'allergies': profile?.foodAllergies,
              'injuries': profile?.currentInjuries,
              'motor_disability': profile?.motorDisability,
              'areas_to_avoid': profile?.areasToAvoid,
              'age': profile?.age,
              'weight': profile?.weight,
              'active_plan_start': startStr,
              'active_plan_end': endStr,
            }),
          )"""

text_coach = text_coach.replace(old_post_call, new_post_call)

with open(path_coach, 'w', encoding='utf-8') as f:
    f.write(text_coach)
print("Updated coach_screen.dart with active plan date awareness")

# 3. Update client_detail_screen.dart to render real WeeklyPlanService data
path_client = 'mobile_app/lib/screens/trainer/client_detail_screen.dart'
with open(path_client, 'r', encoding='utf-8') as f:
    text_client = f.read()

if "import 'package:mobile_app/services/weekly_plan_service.dart';" not in text_client:
    text_client = "import 'package:mobile_app/services/weekly_plan_service.dart';\n" + text_client

old_entrenamiento = """  Widget _buildEntrenamientoTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Rutina Programada para Hoy', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: 'Día de Piernas y Glúteos',
          icon: Icons.fitness_center,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Máquinas y Equipos a utilizar:', style: TextStyle(color: Color(0xFF1FAE87), fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _machineItem('Prensa de Piernas (Leg Press)'),
              _machineItem('Máquina de Extensión de Cuádriceps'),
              _machineItem('Mancuernas (Pesos Libres)'),
              const Divider(color: Colors.white24, height: 24),
              const Text('Alerta Pre-Entreno:', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('El alumno reportó fatiga en la rodilla derecha esta mañana. Recomiendo calentamiento articular extra.', style: TextStyle(color: Colors.orangeAccent, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ],
    );
  }"""

new_entrenamiento = """  Widget _buildEntrenamientoTab() {
    final service = WeeklyPlanService.instance;
    final days = service.days;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Cronograma del Alumno', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1FAE87).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1FAE87)),
              ),
              child: const Text('Vigente / En Curso', style: TextStyle(color: Color(0xFF1FAE87), fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Alerta de Chequeo
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2D1515),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
          ),
          child: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Estado Reportado: El alumno completó su cuestionario de estado actual. Revisa los ejercicios y cargas antes de iniciar.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (days.isEmpty) ...[
          _buildInfoCard(
            title: 'Sin Rutina Sincronizada',
            icon: Icons.info_outline,
            content: const Text(
              'El alumno aún no ha sincronizado un cronograma semanal con el Coach IA.',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ] else ...[
          ...days.map((day) {
            final dayTitle = day['title'] ?? 'Sesión';
            final dayExercises = (day['exercises'] as List?) ?? [];
            final weekdayName = day['weekday'] is int && day['weekday'] >= 0 && day['weekday'] < 7
                ? ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'][day['weekday']]
                : 'Día';

            return Card(
              color: const Color(0xFF1E293B),
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.fitness_center_rounded, color: Color(0xFF1FAE87), size: 20),
                        const SizedBox(width: 8),
                        Text('$weekdayName · $dayTitle', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 20),
                    if (dayExercises.isEmpty)
                      const Text('Día de descanso o recuperación activa.', style: TextStyle(color: Colors.white54, fontSize: 13, fontStyle: FontStyle.italic))
                    else
                      ...dayExercises.map((ex) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, color: Color(0xFF1FAE87), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(ex['name'] ?? 'Ejercicio', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              ),
                              Text('${ex['sets'] ?? 3}x${ex['reps'] ?? 12}', style: const TextStyle(color: Color(0xFF1FAE87), fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }"""

text_client = text_client.replace(old_entrenamiento, new_entrenamiento)

# Also update _buildNutricionTab in client_detail_screen.dart
old_nutricion = """  Widget _buildNutricionTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildInfoCard(
          title: 'Plan de Alimentación',
          icon: Icons.restaurant,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Calorías Diarias', '2,800 kcal'),
              _infoRow('Proteína', '160g'),
              _infoRow('Carbohidratos', '350g'),
              _infoRow('Grasas', '85g'),
              const Divider(color: Colors.white24, height: 24),
              const Text('Sugerencia para hoy (Sin Lactosa):', style: TextStyle(color: Color(0xFF1FAE87), fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Batido de proteína vegana post-entrenamiento con plátano.', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }"""

new_nutricion = """  Widget _buildNutricionTab() {
    final service = WeeklyPlanService.instance;
    final days = service.days;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Plan Nutricional del Alumno', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (days.isEmpty) ...[
          _buildInfoCard(
            title: 'Sin Plan Nutricional Activo',
            icon: Icons.restaurant,
            content: const Text('El alumno aún no tiene un menú registrado esta semana.', style: TextStyle(color: Colors.white70)),
          ),
        ] else ...[
          ...days.where((d) => d['nutrition'] is Map && (d['nutrition'] as Map).isNotEmpty).map((d) {
            final nut = d['nutrition'] as Map;
            final weekdayName = d['weekday'] is int && d['weekday'] >= 0 && d['weekday'] < 7
                ? ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'][d['weekday']]
                : 'Día';

            return Card(
              color: const Color(0xFF1E293B),
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.restaurant_rounded, color: Color(0xFF1FAE87), size: 18),
                        const SizedBox(width: 8),
                        Text('$weekdayName · Menú Recomendado', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 16),
                    if (nut['desayuno'] != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('🍳 Desayuno: ${nut['desayuno']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ),
                    if (nut['almuerzo'] != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('🍛 Almuerzo: ${nut['almuerzo']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ),
                    if (nut['cena'] != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('🍲 Cena: ${nut['cena']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }"""

text_client = text_client.replace(old_nutricion, new_nutricion)

with open(path_client, 'w', encoding='utf-8') as f:
    f.write(text_client)
print("Updated client_detail_screen.dart with dynamic workout & nutrition tabs!")
