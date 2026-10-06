import 'package:flutter/material.dart';
import 'package:mobile_app/models/anatomy_exercise.dart';


/// Pantalla de demostracion didactica del modelo anatomico 3D.
///
/// La mitad superior muestra el cuerpo en 3D: se rota con un dedo, se hace zoom
/// con dos y la autorrotacion se alterna desde el boton de la AppBar. La mitad
/// inferior es un panel deslizable con los datos del ejercicio: agonista,
/// sinergistas, biomecanica, tempo, postura y advertencia de lesion.
///
/// La tira inferior cambia de ejercicio y actualiza el foco muscular y los
/// textos biomecanicos, que es lo que demuestra como la IA orquestaria la
/// visualizacion.
class AnatomyWorkoutScreen extends StatefulWidget {

  const AnatomyWorkoutScreen({
    super.key,
    this.initialExerciseId = 'squat',
    this.dynamicExercises,
    this.viewerBuilder,
  });

  final String initialExerciseId;
  final List<AnatomyExercise>? dynamicExercises;


  /// Permite sustituir el visor 3D. En las pruebas se usa un marcador de
  /// posicion, porque el WebView que necesita `ModelViewer` no existe en el
  /// entorno de test. En la app real se deja en null y se dibuja el modelo.
  final Widget Function(BuildContext, AnatomyExercise, bool)? viewerBuilder;

  @override
  State<AnatomyWorkoutScreen> createState() => _AnatomyWorkoutScreenState();
}

class _AnatomyWorkoutScreenState extends State<AnatomyWorkoutScreen> {
  late AnatomyExercise _exercise;
  bool _autoRotate = true;

  /// Altura de la zona 3D: la mitad superior de la pantalla.
  static const double _viewerHeight = 300;

  @override
  void initState() {
    super.initState();
    _exercise = _byId(widget.initialExerciseId);
  }

  AnatomyExercise _byId(String id) {
    for (final exercise in _exercisesList) {
      if (exercise.id == id || exercise.name.toLowerCase() == id.toLowerCase()) return exercise;
    }
    return _exercisesList.isNotEmpty ? _exercisesList.first : kAnatomyExercises.first;
  }


  List<AnatomyExercise> get _exercisesList => widget.dynamicExercises ?? kAnatomyExercises;

  void _select(AnatomyExercise exercise) {
    setState(() => _exercise = exercise);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAnatomyBackground,
      appBar: AppBar(
        backgroundColor: kAnatomySurface,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Anatomia 3D',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: _autoRotate
                ? 'Pausar autorrotacion'
                : 'Activar autorrotacion',
            onPressed: () => setState(() => _autoRotate = !_autoRotate),
            icon: Icon(
              _autoRotate
                  ? Icons.threesixty_rounded
                  : Icons.rotate_right_rounded,
              color: _autoRotate ? kAgonistColor : Colors.white38,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: _viewerHeight,
            width: double.infinity,
            child: widget.viewerBuilder?.call(
                  context,
                  _exercise,
                  _autoRotate,
                ) ??
                _Viewer(exercise: _exercise, autoRotate: _autoRotate),
          ),
          Expanded(
            child: _DidacticPanel(
              exercise: _exercise,
              onSelect: _select,
              exercises: _exercisesList,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cuerpo 3D interactivo.
///
/// En Android `model_viewer_plus` renderiza dentro de un WebView, por eso
/// necesita la permision de INTERNET para descargar el modelo. La aceleracion
/// por hardware ya esta activa en el manifiesto de Android.
class _Viewer extends StatelessWidget {
  const _Viewer({required this.exercise, required this.autoRotate});
  final AnatomyExercise exercise;
  final bool autoRotate;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: kAnatomyBackground,
      child: Stack(
        fit: StackFit.expand,
        children: [

            exercise.gifUrl.isNotEmpty 
              ? Image.network(
                  exercise.gifUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: kAgonistColor));
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.fitness_center_rounded, size: 64, color: Colors.white24));
                  },
                )
                              : Center(
                    child: SingleChildScrollView(
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF101B2D),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF8BE0C0), width: 1.5),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.psychology_rounded, size: 56, color: Color(0xFF8BE0C0)),
                            const SizedBox(height: 16),
                            Text('Guía Textual Interactiva', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Text('Visualización 3D en desarrollo para este ejercicio.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: const Color(0xFF173B45), borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                children: [
                                  Text('1. Agonista: ' + exercise.agonist, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF8BE0C0), fontSize: 14, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 8),
                                  Text('2. Sinergistas: ' + exercise.synergists.join(', '), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                  const SizedBox(height: 8),
                                  Text('3. Postura: ' + exercise.posture, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                  const SizedBox(height: 8),
                                  Text('4. Tempo: ' + exercise.tempo, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text('Guía Animada', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Capa superpuesta que marca la zona estimulada.
///
/// El modelo 3D disponible no tiene mallas musculares separadas, asi que el
/// resaltado se dibuja como una marca sobre el cuerpo, alineada con la zona que
/// trabaja el ejercicio. Cuando exista un modelo anatomico real, esta capa se
/// sustituye por el resaltado de material del propio archivo .glb.
class _MuscleOverlay extends StatelessWidget {
  const _MuscleOverlay({required this.exercise});

  final AnatomyExercise exercise;

  @override
  Widget build(BuildContext context) {
    final upper = _isUpperBody(exercise.agonist);
    return Align(
      alignment: upper
          ? const Alignment(0.12, -0.22)
          : const Alignment(0.12, 0.32),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kAgonistColor.withValues(alpha: 0.32),
          border: Border.all(color: kAgonistColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: kAgonistColor.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 3,
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.bolt_rounded, color: Colors.white, size: 26),
        ),
      ),
    );
  }

  /// Decide si el musculo principal pertenece al tren superior.
  bool _isUpperBody(String muscle) {
    const lower = [
      'cuadriceps', 'gluteos', 'isquiotibiales', 'gemelos', 'aductores',
    ];
    return !lower.contains(muscle.toLowerCase());
  }
}

/// Aviso de gestos, para saber como interactuar con el modelo.
class _Hint extends StatelessWidget {
  const _Hint({required this.autoRotate});
  final bool autoRotate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.swipe_rounded, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            autoRotate
                ? 'Un dedo rota · dos dedos acercan'
                : 'Arrastra para rotar',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// Panel inferior deslizable con los datos del ejercicio.
///
/// Se divide en dos partes: la hoja con la informacion didactica (titulo,
/// agonista, sinergistas, biomecanica, tempo, postura y advertencia) y la tira
/// de ejercicios, que queda fija al final para saltar entre demonstrations.
class _DidacticPanel extends StatelessWidget {
  const _DidacticPanel({required this.exercise, required this.onSelect, required this.exercises});
  final List<AnatomyExercise> exercises;

  final AnatomyExercise exercise;
  final ValueChanged<AnatomyExercise> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kAnatomySurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Expanded(
            child: _SlidableSheet(exercise: exercise),
          ),
          _ExerciseSelector(selected: exercise, onSelect: onSelect, exercises: exercises),
        ],
      ),
    );
  }
}

/// Hoja deslizable: se puede arrastrar hacia abajo para plegarla y quedarse solo
/// con la tira de ejercicios.
class _SlidableSheet extends StatefulWidget {
  const _SlidableSheet({required this.exercise});
  final AnatomyExercise exercise;

  @override
  State<_SlidableSheet> createState() => _SlidableSheetState();
}

class _SlidableSheetState extends State<_SlidableSheet> {
  /// Altura de la hoja cuando esta desplegada.
  static const double _expandedHeight = 460.0;
  /// Altura cuando esta plegada: solo se ve el titulo y los chips.
  static const double _collapsedHeight = 190.0;

  bool _isOpen = true;

  @override
  Widget build(BuildContext context) {
    final height = _isOpen ? _expandedHeight : _collapsedHeight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      height: height,
      child: Column(
        children: [
          // Asa de arrastre.
          GestureDetector(
            onTap: () => setState(() => _isOpen = !_isOpen),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
              children: _sections(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Bloques del panel, en orden de lectura.
  List<Widget> _sections(BuildContext context) {
    final ex = widget.exercise;
    return [
      Text(
        ex.name,
        style: const TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 16),
      _MuscleChips(agonist: ex.agonist, synergists: ex.synergists),
      const SizedBox(height: 18),
      _InfoRow(
        icon: Icons.straighten_rounded,
        title: 'Indicadores biomecanicos',
        body: ex.biomechanics,
        color: const Color(0xFF64B5F6),
      ),
      const SizedBox(height: 12),
      _InfoRow(
        icon: Icons.timer_outlined,
        title: 'Tempo recomendado',
        body: ex.tempo,
        color: const Color(0xFF9CCC65),
      ),
      const SizedBox(height: 12),
      _InfoRow(
        icon: Icons.accessibility_new_rounded,
        title: 'Nota postural',
        body: ex.posture,
        color: const Color(0xFF4DD0E1),
      ),
      const SizedBox(height: 12),
      _InfoRow(
        icon: Icons.warning_amber_rounded,
        title: 'Prevencion de lesiones',
        body: ex.warning,
        color: kAgonistColor,
      ),
    ];
  }
}

/// Chips de zonas estimuladas: agonista en rojo con glow y sinergistas en ambar.
class _MuscleChips extends StatelessWidget {
  const _MuscleChips({required this.agonist, required this.synergists});

  final String agonist;
  final List<String> synergists;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ChipLabel('Musculo agonista (principal)'),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: _GlowChip(label: agonist, color: kAgonistColor),
        ),
        const SizedBox(height: 16),
        const _ChipLabel('Musculos sinergistas / estabilizadores'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: synergists
              .map((name) => _GlowChip(label: name, color: kSynergistColor))
              .toList(),
        ),
      ],
    );
  }
}

class _ChipLabel extends StatelessWidget {
  const _ChipLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
        color: Colors.white54,
      ),
    );
  }
}

/// Chip con borde de color y resplandor, para que destaque sobre el fondo oscuro.
class _GlowChip extends StatelessWidget {
  const _GlowChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color, width: 1.4),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
/// Fila de informacion con icono, titulo y texto.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tira horizontal de los cuatro ejercicios de demostracion.
///
/// Al pulsar uno cambia el foco muscular, los textos biomecanicos y el modelo
/// que se muestra arriba, que es lo que demuestra como la IA orquestaria la
/// visualizacion anatomica.
class _ExerciseSelector extends StatelessWidget {
  const _ExerciseSelector({required this.selected, required this.onSelect, required this.exercises});
  final List<AnatomyExercise> exercises;

  final AnatomyExercise selected;
  final ValueChanged<AnatomyExercise> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: const BoxDecoration(
        color: Color(0xFF151515),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8, left: 2),
            child: Text(
              'CAMBIAR EJERCICIO',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: Colors.white54,
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: exercises.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                final isSelected = exercise.id == selected.id;
                return ChoiceChip(
                  label: Text(exercise.shortName),
                  selected: isSelected,
                  onSelected: (_) => onSelect(exercise),
                  backgroundColor: const Color(0xFF242424),
                  selectedColor: kAgonistColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                  side: BorderSide(
                    color: isSelected ? kAgonistColor : Colors.white12,
                  ),
                  showCheckmark: false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
