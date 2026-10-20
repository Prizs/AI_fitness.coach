import 'package:flutter/material.dart';
import 'package:mobile_app/services/daily_notification_service.dart';
import 'package:mobile_app/services/weekly_plan_service.dart';

class FatigueCheckinDialog extends StatefulWidget {
  final VoidCallback? onCompleted;
  const FatigueCheckinDialog({super.key, this.onCompleted});

  static Future<void> show(BuildContext context, {VoidCallback? onCompleted}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F192B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FatigueCheckinDialog(onCompleted: onCompleted),
    );
  }

  @override
  State<FatigueCheckinDialog> createState() => _FatigueCheckinDialogState();
}

class _FatigueCheckinDialogState extends State<FatigueCheckinDialog> {
  bool? _didComplete;
  int _rpe = 7;
  String _feeling = 'Con energía';
  String _notCompletedReason = 'Falta de tiempo';
  int _durationMinutes = 45;
  bool _isSaving = false;

  final List<String> _feelings = [
    'Con energía',
    'Normal / Óptimo',
    'Cansado / Fatiga moderada',
    'Exhausto / Muy fatigado',
    'Molestia o sobrecarga',
  ];

  final List<String> _skipReasons = [
    'Falta de tiempo',
    'Fatiga acumulada / Descanso',
    'Molestia física / Dolor',
    'Imprevisto personal',
  ];

  @override
  Widget build(BuildContext context) {
    final todayPlan = WeeklyPlanService.instance.today;
    final title = todayPlan?['title'] ?? 'Entrenamiento del día';
    final blockTime = DailyNotificationService.instance.formattedBlockTime;
    final int estimatedKcal = DailyNotificationService.instance.calculateEstimatedCalories(
      userWeightKg: 75.0,
      durationMinutes: _durationMinutes,
      rpe: _rpe,
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
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
            const Row(
              children: [
                Icon(Icons.rate_review_rounded, color: Color(0xFF8BE0C0), size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Seguimiento Diario de Entrenamiento',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Tu sesión planificada para hoy era a las $blockTime:',
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF8BE0C0).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fitness_center_rounded, color: Color(0xFF8BE0C0), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Pregunta principal
            const Text(
              '¿Realizaste este ejercicio planificado para hoy?',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _didComplete == true ? const Color(0xFF1FAE87) : const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(
                        color: _didComplete == true ? const Color(0xFF8BE0C0) : Colors.white12,
                        width: 1.5,
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 20),
                    label: const Text('Sí, lo realicé', style: TextStyle(fontWeight: FontWeight.w700)),
                    onPressed: () => setState(() => _didComplete = true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _didComplete == false ? const Color(0xFF882233) : const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(
                        color: _didComplete == false ? Colors.redAccent : Colors.white12,
                        width: 1.5,
                      ),
                    ),
                    icon: const Icon(Icons.cancel_rounded, size: 20),
                    label: const Text('No pude hoy', style: TextStyle(fontWeight: FontWeight.w700)),
                    onPressed: () => setState(() => _didComplete = false),
                  ),
                ),
              ],
            ),

            if (_didComplete == true) ...[
              const SizedBox(height: 20),
              const Divider(color: Colors.white12),
              const SizedBox(height: 12),

              // Encuesta de fatiga y RPE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Esfuerzo Percibido (RPE):',
                    style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF173B45),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF8BE0C0)),
                    ),
                    child: Text(
                      '$_rpe / 10 · ${_getRpeLabel(_rpe)}',
                      style: const TextStyle(color: Color(0xFF8BE0C0), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _rpe.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: const Color(0xFF8BE0C0),
                inactiveColor: Colors.white24,
                onChanged: (val) => setState(() => _rpe = val.round()),
              ),

              const SizedBox(height: 10),
              const Text(
                '¿Cómo te sentiste? (Encuesta de Fatiga):',
                style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _feelings.map((f) {
                  final isSelected = _feeling == f;
                  return ChoiceChip(
                    label: Text(f, style: TextStyle(fontSize: 12, color: isSelected ? Colors.black : Colors.white)),
                    selected: isSelected,
                    selectedColor: const Color(0xFF8BE0C0),
                    backgroundColor: const Color(0xFF1E293B),
                    onSelected: (val) {
                      if (val) setState(() => _feeling = f);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF162032),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Gasto Calórico Estimado:', style: TextStyle(fontSize: 11, color: Colors.white60)),
                          Text(
                            '$estimatedKcal kcal quemadas',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.orangeAccent),
                          ),
                          const Text('Cálculo verificable por METs × Peso × Duración (~45m)', style: TextStyle(fontSize: 10, color: Colors.white38)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_didComplete == false) ...[
              const SizedBox(height: 20),
              const Divider(color: Colors.white12),
              const SizedBox(height: 12),
              const Text(
                'Motivo principal (para que la IA adapte tu descanso):',
                style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _skipReasons.map((r) {
                  final isSelected = _notCompletedReason == r;
                  return ChoiceChip(
                    label: Text(r, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.white70)),
                    selected: isSelected,
                    selectedColor: const Color(0xFF882233),
                    backgroundColor: const Color(0xFF1E293B),
                    onSelected: (val) {
                      if (val) setState(() => _notCompletedReason = r);
                    },
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8BE0C0),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: (_didComplete == null || _isSaving)
                  ? null
                  : () async {
                      setState(() => _isSaving = true);
                      await DailyNotificationService.instance.submitCheckinSurvey(
                        completed: _didComplete == true,
                        rpe: _rpe,
                        feeling: _feeling,
                        caloriesBurned: estimatedKcal,
                        notes: _didComplete == true
                            ? 'Encuesta completada satisfactoriamente'
                            : 'No completado: $_notCompletedReason',
                      );
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _didComplete == true
                                  ? '✅ ¡Excelente! Tu sesión y fatiga fueron registradas con $estimatedKcal kcal estimadas.'
                                  : 'ℹ️ Sesión registrada como descanso. El Coach IA adaptará la sobrecarga.',
                            ),
                            backgroundColor: const Color(0xFF1B4D3E),
                          ),
                        );
                        widget.onCompleted?.call();
                      }
                    },
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('Guardar y Registrar en Mi Perfil', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

  String _getRpeLabel(int rpe) {
    if (rpe <= 3) return 'Suave / Ligero';
    if (rpe <= 6) return 'Moderado';
    if (rpe <= 8) return 'Exigente / Óptimo';
    return 'Máximo Esfuerzo';
  }
}
