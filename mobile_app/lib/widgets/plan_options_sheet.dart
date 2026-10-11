import 'package:flutter/material.dart';
import 'package:mobile_app/services/weekly_plan_service.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void showPlanOptionsSheet(
  BuildContext context, {
  String initialPrompt = '',
  void Function(String summaryText)? onSendState,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF101B2D),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) => _PlanOptionsForm(initialPrompt: initialPrompt, onSendState: onSendState),
  );
}

class _PlanOptionsForm extends StatefulWidget {
  final String initialPrompt;
  final void Function(String summaryText)? onSendState;

  const _PlanOptionsForm({
    this.initialPrompt = '',
    this.onSendState,
  });

  @override
  State<_PlanOptionsForm> createState() => _PlanOptionsFormState();
}

class _PlanOptionsFormState extends State<_PlanOptionsForm> {
  late final TextEditingController _promptController;
  final TextEditingController _molestiaController = TextEditingController();
  
  late stt.SpeechToText _speech;
  bool _isListening = false;
  
  String _estado = 'Bien';
  String _equipo = 'Gym Completo';
  String _intensity = 'Medio';
  String _experience = 'Intermedio';

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(text: widget.initialPrompt);
    _speech = stt.SpeechToText();
  }
  
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
           if (val == 'done') setState(() => _isListening = false);
        },
        onError: (val) => setState(() => _isListening = false),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            if (_estado == 'Molestia') {
              _molestiaController.text = val.recognizedWords;
            } else {
              _promptController.text = val.recognizedWords;
            }
          }),
          localeId: 'es_ES',
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    _molestiaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Configuración Rápida', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                  color: _isListening ? Colors.redAccent : const Color(0xFF8BE0C0),
                  onPressed: _listen,
                  tooltip: 'Dictar por voz',
                ),
              ],
            ),
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
              const SizedBox(height: 12),
              TextField(
                controller: _molestiaController,
                maxLines: 2,
                minLines: 1,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '¿Dónde te duele? (Ej: Rodilla derecha, evita saltos)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF4A1A1A).withValues(alpha: 0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
                ),
              ),
            ],

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

            // 3. Intensidad
            const Text('Nivel de Intensidad', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Bajo', label: Text('Bajo')),
                ButtonSegment(value: 'Medio', label: Text('Medio')),
                ButtonSegment(value: 'Alto', label: Text('Intenso')),
              ],
              selected: {_intensity},
              onSelectionChanged: (set) => setState(() => _intensity = set.first),
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
              onSelectionChanged: (set) => setState(() => _experience = set.first),
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
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8BE0C0),
                  foregroundColor: const Color(0xFF0B1220),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  
                  final buffer = StringBuffer();
                  buffer.writeln('📋 Mi Estado Actual para la sesión:');
                  if (_estado == 'Molestia' && _molestiaController.text.trim().isNotEmpty) {
                    buffer.writeln('• Estado Físico: Tengo una molestia/dolor en . Por favor toma la decisión pertinente de descanso o sugerir ejercicios que no afecten esa área.');
                  } else {
                    buffer.writeln('• Estado Físico: Me siento al 100% (Bien)');
                  }
                  buffer.writeln('• Equipo disponible: ');
                  buffer.writeln('• Intensidad deseada: ');
                  buffer.writeln('• Nivel de experiencia: ');
                  
                  final prompt = _promptController.text.trim();
                  if (prompt.isNotEmpty) {
                    buffer.writeln('• Detalles / Objetivo: ');
                  }
                  
                  final summary = buffer.toString().trim();

                  if (widget.onSendState != null) {
                    widget.onSendState!(summary);
                  } else {
                    WeeklyPlanService.instance.refresh(
                      AuthService.instance.loggedInUser,
                      goal: summary.isNotEmpty ? summary : 'Mejorar condición física general',
                      experienceLevel: _experience,
                      intensityPreference: _intensity,
                      equipmentAvailable: _equipo != 'Sin Herramientas',
                    );
                  }
                },
                icon: const Icon(Icons.send_rounded),
                label: const Text('Enviar Estado Actual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
