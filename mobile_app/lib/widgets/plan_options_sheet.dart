import 'package:flutter/material.dart';
import 'package:mobile_app/screens/coach_screen.dart';
import 'package:mobile_app/services/weekly_plan_service.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/voice_service.dart';

void showPlanOptionsSheet(
  BuildContext context, {
  String initialPrompt = '',
  String? initialIntensity,
  String? initialLevel,
  void Function(String summaryText)? onSendState,
  void Function(String level, String intensity)? onPreferenceChanged,
}) {
  if (onSendState == null) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CoachScreen()),
    );
    return;
  }
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF101B2D),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) => _PlanOptionsForm(
      initialPrompt: initialPrompt,
      initialIntensity: initialIntensity,
      initialLevel: initialLevel,
      onSendState: onSendState,
      onPreferenceChanged: onPreferenceChanged,
    ),
  );
}

class _PlanOptionsForm extends StatefulWidget {
  final String initialPrompt;
  final String? initialIntensity;
  final String? initialLevel;
  final void Function(String summaryText)? onSendState;
  final void Function(String level, String intensity)? onPreferenceChanged;

  const _PlanOptionsForm({
    this.initialPrompt = '',
    this.initialIntensity,
    this.initialLevel,
    this.onSendState,
    this.onPreferenceChanged,
  });

  @override
  State<_PlanOptionsForm> createState() => _PlanOptionsFormState();
}

class _PlanOptionsFormState extends State<_PlanOptionsForm> {
  late final TextEditingController _promptController;
  final TextEditingController _molestiaController = TextEditingController();
  
  String _estado = 'Bien';
  String _molestiaAction = 'Adaptar';
  String _equipo = 'Gym Completo';
  String _intensity = 'Medio';
  String _experience = 'Intermedio';
  String? _activeVoiceField;

  @override
  void dispose() {
    if (_activeVoiceField != null) {
      VoiceService.instance.stopListening();
    }
    _promptController.dispose();
    _molestiaController.dispose();
    super.dispose();
  }

  Future<void> _toggleVoice(String field) async {
    if (_activeVoiceField == field) {
      // Segundo toque: Detener grabación
      setState(() => _activeVoiceField = null);
      final text = await VoiceService.instance.stopListening();
      if (text.isNotEmpty && !text.startsWith('Transcribiendo')) {
        setState(() {
          if (field == 'molestia') {
            _molestiaController.text = text;
          } else {
            _promptController.text = text;
          }
        });
      }
      return;
    }

    if (_activeVoiceField != null) {
      await VoiceService.instance.stopListening();
    }

    setState(() => _activeVoiceField = field);

    await VoiceService.instance.startListening(
      onResult: (text) {
        if (mounted && _activeVoiceField == field) {
          setState(() {
            if (field == 'molestia') {
              _molestiaController.text = text;
            } else {
              _promptController.text = text;
            }
          });
        }
      },
      onListeningChanged: (listening) {
        if (!listening && mounted && _activeVoiceField == field) {
          setState(() => _activeVoiceField = null);
        }
      },
      onError: (_) {
        if (mounted && _activeVoiceField == field) {
          setState(() => _activeVoiceField = null);
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(text: widget.initialPrompt);

    // Inicializar nivel e intensidad de forma 100% independiente
    final currentPrefLevel = widget.initialLevel ?? WeeklyPlanService.instance.userLevel;
    final currentPrefIntensity = widget.initialIntensity ?? WeeklyPlanService.instance.userIntensity;

    if (currentPrefLevel.toLowerCase().contains('principiante') ||
        currentPrefLevel.toLowerCase().contains('básico') ||
        currentPrefLevel.toLowerCase().contains('basico')) {
      _experience = 'Principiante';
    } else if (currentPrefLevel.toLowerCase().contains('avanzado')) {
      _experience = 'Avanzado';
    } else {
      _experience = 'Intermedio';
    }

    if (currentPrefIntensity.toLowerCase() == 'baja' || currentPrefIntensity.toLowerCase() == 'bajo') {
      _intensity = 'Bajo';
    } else if (currentPrefIntensity.toLowerCase() == 'alta' ||
        currentPrefIntensity.toLowerCase() == 'alto' ||
        currentPrefIntensity.toLowerCase() == 'intenso') {
      _intensity = 'Alto';
    } else {
      _intensity = 'Medio';
    }
  }

  void _onIntensityChanged(String newIntensity) {
    setState(() {
      _intensity = newIntensity;
      // Desacoplado: No altera el nivel de experiencia
    });
    _syncPreferences();
  }

  void _onExperienceChanged(String newExperience) {
    setState(() {
      _experience = newExperience;
      // Desacoplado: No altera el nivel de intensidad
    });
    _syncPreferences();
  }

  void _syncPreferences() {
    final intensityCode = _intensity == 'Bajo' ? 'Baja' : (_intensity == 'Alto' ? 'Alta' : 'Media');
    WeeklyPlanService.instance.updateUserPreferences(
      level: _experience,
      intensity: intensityCode,
    );
    if (widget.onPreferenceChanged != null) {
      widget.onPreferenceChanged!(_experience, intensityCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRest = _estado == 'Molestia' && _molestiaAction == 'Descanso';

    return Padding(
      padding: EdgeInsets.only(
        left: 24.0, right: 24.0, top: 24.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Configuración Rápida', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // 1. Estado Fisico
            const Text('¿Cómo te sientes físicamente?', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Bien', label: Text('Bien (100%)', style: TextStyle(fontSize: 12))),
                ButtonSegment(value: 'Molestia', label: Text('Tengo una molestia', style: TextStyle(fontSize: 12))),
              ],
              selected: {_estado},
              onSelectionChanged: (set) => setState(() => _estado = set.first),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFF8BE0C0) : Colors.transparent),
                foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFF0B1220) : Colors.white),
              ),
            ),
            
            if (_estado == 'Molestia') ...[
              const SizedBox(height: 16),
              const Text('¿La molestia te permite entrenar hoy?', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'Descanso',
                    icon: Icon(Icons.hotel_rounded, size: 16),
                    label: Text('Pausa / Descanso', style: TextStyle(fontSize: 11)),
                  ),
                  ButtonSegment(
                    value: 'Adaptar',
                    icon: Icon(Icons.fitness_center_rounded, size: 16),
                    label: Text('Entrenar con cuidado', style: TextStyle(fontSize: 11)),
                  ),
                ],
                selected: {_molestiaAction},
                onSelectionChanged: (set) => setState(() => _molestiaAction = set.first),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected)
                      ? (_molestiaAction == 'Descanso' ? const Color(0xFFE57373) : const Color(0xFF8BE0C0))
                      : Colors.transparent),
                  foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected)
                      ? const Color(0xFF0B1220)
                      : Colors.white),
                ),
              ),

              const SizedBox(height: 14),
              Text(
                isRest
                    ? 'Describe el dolor o motivo que te impide entrenar:'
                    : '¿Dónde sientes la molestia y qué movimientos evitar?',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _molestiaController,
                maxLines: isRest ? 3 : 2,
                minLines: 1,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: isRest
                      ? 'Ej: Dolor punzante lumbar al flexionar, siento pinchazos, inflamación o fatiga extrema...'
                      : 'Ej: Molestia en hombro izquierdo, evitar press banca y fondos...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF4A1A1A).withValues(alpha: 0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _activeVoiceField == 'molestia' ? Icons.mic : Icons.mic_none_rounded,
                      color: _activeVoiceField == 'molestia' ? Colors.redAccent : const Color(0xFF8BE0C0),
                    ),
                    tooltip: _activeVoiceField == 'molestia' ? 'Detener dictado' : 'Dictar molestia por voz',
                    onPressed: () => _toggleVoice('molestia'),
                  ),
                ),
              ),

              if (isRest) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF261D1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.healing_rounded, color: Colors.amber, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Se pausará el entrenamiento de hoy. Tu Coach IA analizará tus síntomas para recomendarte tiempo prudencial de reposo, pautas de alivio y si amerita acudir a un traumatólogo o fisioterapeuta.',
                          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            // Solo mostrar opciones de entrenamiento si está Bien o si desea Adaptar el entreno
            if (!isRest) ...[
              const SizedBox(height: 20),
              
              // 2. Equipo
              const Text('¿Dónde entrenarás / Equipo?', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Gym Completo', label: Text('Gym Completo', style: TextStyle(fontSize: 11))),
                  ButtonSegment(value: 'Herramientas en Casa', label: Text('Herramientas\nen Casa', textAlign: TextAlign.center, style: TextStyle(fontSize: 10))),
                  ButtonSegment(value: 'Sin Herramientas', label: Text('Sin\nHerramientas', textAlign: TextAlign.center, style: TextStyle(fontSize: 10))),
                ],
                selected: {_equipo},
                onSelectionChanged: (set) => setState(() => _equipo = set.first),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFF8BE0C0) : Colors.transparent),
                  foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFF0B1220) : Colors.white),
                ),
              ),

              const SizedBox(height: 20),

              // 3. Intensidad (Totalmente independiente)
              const Text('Nivel de Intensidad', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Bajo', label: Text('Bajo')),
                  ButtonSegment(value: 'Medio', label: Text('Medio')),
                  ButtonSegment(value: 'Alto', label: Text('Intenso')),
                ],
                selected: {_intensity},
                onSelectionChanged: (set) => _onIntensityChanged(set.first),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFF8BE0C0) : Colors.transparent),
                  foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFF0B1220) : Colors.white),
                ),
              ),

              const SizedBox(height: 20),
              
              // 4. Experiencia
              const Text('Nivel de Experiencia', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Principiante', label: Text('Principiante', style: TextStyle(fontSize: 12))),
                  ButtonSegment(value: 'Intermedio', label: Text('Intermedio', style: TextStyle(fontSize: 12))),
                  ButtonSegment(value: 'Avanzado', label: Text('Avanzado', style: TextStyle(fontSize: 12))),
                ],
                selected: {_experience},
                onSelectionChanged: (set) => _onExperienceChanged(set.first),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFF8BE0C0) : Colors.transparent),
                  foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFF0B1220) : Colors.white),
                ),
              ),

              const SizedBox(height: 20),

              // Peticion libre
              const Text('Detalles adicionales (Opcional)', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _promptController,
                maxLines: 2,
                minLines: 1,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ej: Solo tengo 30 min, enfocate en piernas...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _activeVoiceField == 'prompt' ? Icons.mic : Icons.mic_none_rounded,
                      color: _activeVoiceField == 'prompt' ? Colors.redAccent : const Color(0xFF8BE0C0),
                    ),
                    tooltip: _activeVoiceField == 'prompt' ? 'Detener dictado' : 'Dictar detalles por voz',
                    onPressed: () => _toggleVoice('prompt'),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRest ? const Color(0xFFE57373) : const Color(0xFF8BE0C0),
                  foregroundColor: const Color(0xFF0B1220),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  
                  final buffer = StringBuffer();
                  buffer.writeln('📋 Mi Estado Actual para la sesión:');
                  if (_estado == 'Molestia') {
                    final rawMotivo = _molestiaController.text.trim();
                    final lowerMotivo = rawMotivo.toLowerCase();
                    // Si el usuario expresó explícitamente en el texto que desea entrenar o pide ejercicios adaptados,
                    // prevalece su deseo de entrenar y se conmuta a modo Adaptar.
                    final wantsTrainingInText = [
                      'quiero que me planifiques', 'planifiques ejercicios', 'planificar ejercicios',
                      'quiero entrenar', 'deseo entrenar', 'ejercicios que no', 'rutina que no',
                      'sin tocar', 'no afecte', 'no demanden', 'sin demandar', 'no demanden este'
                    ].any((k) => lowerMotivo.contains(k));

                    final effectiveIsRest = isRest && !wantsTrainingInText;

                    if (effectiveIsRest) {
                      buffer.writeln('• Estado Físico: Tengo una molestia/dolor que me IMPIDE ENTRENAR HOY.');
                      final motivo = _molestiaController.text.trim();
                      if (motivo.isNotEmpty) {
                        buffer.writeln('• Motivo / Descripción del dolor: $motivo');
                      } else {
                        buffer.writeln('• Motivo / Descripción del dolor: Molestia física general que requiere reposo.');
                      }
                      buffer.writeln('• Decisión del usuario: Tomar una pausa o descanso total.');
                      buffer.writeln('• Instrucción clave para la IA: NO generes ninguna rutina de ejercicios hoy. Analiza mis síntomas con criterio profesional, indícame cuánto tiempo debo esperar antes de volver a entrenar, pautas de recuperación y si amerita acudir a un traumatólogo o fisioterapeuta.');
                    } else {
                      final area = _molestiaController.text.trim();
                      if (area.isNotEmpty) {
                        buffer.writeln('• Estado Físico: Tengo una molestia en $area, pero DESEO ENTRENAR adaptando la sesión.');
                        buffer.writeln('• Instrucción para la IA: Excluir totalmente ejercicios que carguen o comprometan la zona afectada ($area), priorizando ejercicios seguros o tren opuesto.');
                      } else {
                        buffer.writeln('• Estado Físico: Tengo una molestia leve, pero DESEO ENTRENAR con rutina adaptada.');
                      }
                      buffer.writeln('• Equipo disponible: $_equipo');
                      buffer.writeln('• Intensidad deseada: $_intensity');
                      buffer.writeln('• Nivel de experiencia: $_experience');
                      final prompt = _promptController.text.trim();
                      if (prompt.isNotEmpty) {
                        buffer.writeln('• Detalles / Objetivo: $prompt');
                      }
                    }
                  } else {
                    buffer.writeln('• Estado Físico: Me siento al 100% (Bien)');
                    buffer.writeln('• Equipo disponible: $_equipo');
                    buffer.writeln('• Intensidad deseada: $_intensity');
                    buffer.writeln('• Nivel de experiencia: $_experience');
                    final prompt = _promptController.text.trim();
                    if (prompt.isNotEmpty) {
                      buffer.writeln('• Detalles / Objetivo: $prompt');
                    }
                  }
                  
                  final summary = buffer.toString().trim();

                  if (widget.onSendState != null) {
                    widget.onSendState!(summary);
                  } else {
                    WeeklyPlanService.instance.refresh(
                      AuthService.instance.loggedInUser,
                      goal: summary.isNotEmpty ? summary : 'Mejorar condición física general',
                      experienceLevel: _experience,
                      intensityPreference: isRest ? 'Bajo' : _intensity,
                      equipmentAvailable: _equipo != 'Sin Herramientas',
                    );
                  }
                },
                icon: Icon(isRest ? Icons.healing_rounded : Icons.send_rounded),
                label: Text(
                  isRest
                      ? 'Enviar Reporte de Descanso a la IA'
                      : (_estado == 'Molestia' ? 'Enviar Estado y Adaptar Rutina' : 'Enviar Estado Actual'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
