path = 'mobile_app/lib/screens/coach_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

import re

# We will locate the Container inside if (plan != null) ...[ ... ]
old_card_pattern = r'if \(plan != null\) \.\.\.\[\s*Container\(\s*margin: const EdgeInsets\.symmetric\(vertical: 8\),.*?child: const Text\(\'Ver 3D\'\),\s*\),\s*\],\s*\),\s*\],\s*\),\s*\),\s*\],'

new_card = """if (plan != null) ...[
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1E2E),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF8BE0C0), width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.fitness_center_rounded, color: Color(0xFF8BE0C0), size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      plan['title'] ?? msg['category'] ?? 'Rutina y Plan Alimenticio',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF8BE0C0)),
                                    ),
                                  ),
                                ],
                              ),
                              if (msg['rule'] != null) ...[
                                const SizedBox(height: 6),
                                Text('Regla de progresión: ${msg['rule']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                              
                              // Listado de Ejercicios
                              if (plan['exercises'] is List && (plan['exercises'] as List).isNotEmpty) ...[
                                const SizedBox(height: 14),
                                const Text('🏋️ Ejercicios Recomendados:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 8),
                                ...(plan['exercises'] as List).take(5).map((ex) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16253B),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF8BE0C0), size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            ex['name'] ?? 'Ejercicio',
                                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1F3A4B),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${ex['sets'] ?? 3} × ${ex['reps'] ?? '12'}',
                                            style: const TextStyle(color: Color(0xFF8BE0C0), fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],

                              // Plan Nutricional
                              if (plan['nutrition'] is Map && (plan['nutrition'] as Map).isNotEmpty) ...[
                                const SizedBox(height: 14),
                                const Text('🥗 Plan Alimenticio Recomendado:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16253B),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if ((plan['nutrition'] as Map)['desayuno'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: Text('🍳 Desayuno: ${(plan['nutrition'] as Map)['desayuno']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                        ),
                                      if ((plan['nutrition'] as Map)['almuerzo'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: Text('🍛 Almuerzo: ${(plan['nutrition'] as Map)['almuerzo']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                        ),
                                      if ((plan['nutrition'] as Map)['cena'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 2),
                                          child: Text('🍲 Cena: ${(plan['nutrition'] as Map)['cena']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                        ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF8BE0C0),
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      icon: const Icon(Icons.bookmark_add_rounded, size: 16),
                                      label: const Text('Agregar a Cronograma y Nutrición', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                                      onPressed: () async {
                                        await WeeklyPlanService.instance.injectCustomPlanForToday(plan);
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('✅ ¡Rutina y Nutrición agregadas a tu semana con éxito!'),
                                            backgroundColor: Color(0xFF1B4D3E),
                                            behavior: SnackBarBehavior.floating,
                                            duration: Duration(seconds: 4),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF173B45),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () async {
                                      List<AnatomyExercise> dyn = [];
                                      if (plan['exercises'] != null) {
                                        for (var ex in plan['exercises']) {
                                          try {
                                            final res = await http.get(Uri.parse(AuthService.apiBaseUrl + '/api/exercises/gif?query=' + Uri.encodeComponent(ex['name'])));
                                            if (res.statusCode == 200) {
                                              final url = jsonDecode(res.body)['url'];
                                              dyn.add(AnatomyExercise(
                                                id: ex['name'],
                                                name: ex['name'],
                                                shortName: ex['name'],
                                                gifUrl: url ?? '',
                                                agonist: ex['primary_muscle'] ?? 'Músculo Principal',
                                                synergists: [ex['secondary_muscle'] ?? 'Sinergistas'],
                                                biomechanics: 'Activación dinámica sugerida por IA.',
                                                tempo: '3-1-1',
                                                posture: 'Mantén la postura natural.',
                                                warning: 'Consulta a tu entrenador si sientes dolor.'
                                              ));
                                            }
                                          } catch (e) {}
                                        }
                                      }
                                      if (!context.mounted) return;
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => AnatomyWorkoutScreen(
                                        dynamicExercises: dyn.isNotEmpty ? dyn : null,
                                      )));
                                    },
                                    child: const Text('Ver 3D', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],"""

text, count = re.subn(old_card_pattern, new_card, text, flags=re.DOTALL)
print(f"Replaced card occurrences: {count}")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
