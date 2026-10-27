import 'package:flutter/material.dart';
import 'package:mobile_app/models/anatomy_exercise.dart';
import 'package:mobile_app/widgets/muscle_map_view.dart';

/// Pantalla de demostración didáctica del modelo anatómico y técnica.
///
/// Ofrece 3 modos de visualización avanzados y certificados:
/// 0: Atlas Anatómico de Músculos (resaltado interactivo frontal/dorsal de agonistas y sinergistas).
/// 1: Técnica Real (GIF) animado en bucle adaptado.
/// 2: Reclutamiento Muscular y Biomecánica (telemetría porcentual de activación).
class AnatomyWorkoutScreen extends StatefulWidget {
  const AnatomyWorkoutScreen({
    super.key,
    this.initialExerciseId = 'squat',
    this.dynamicExercises,
    this.viewerBuilder,
  });

  final String initialExerciseId;
  final List<AnatomyExercise>? dynamicExercises;
  final Widget Function(BuildContext, AnatomyExercise, bool)? viewerBuilder;

  @override
  State<AnatomyWorkoutScreen> createState() => _AnatomyWorkoutScreenState();
}

class _AnatomyWorkoutScreenState extends State<AnatomyWorkoutScreen> {
  late AnatomyExercise _exercise;
  bool _autoRotate = true;
  int _viewMode = 0; // 0: GIF, 1: Atlas Muscular, 2: 3D Muscular con Marcadores

  /// Altura de la zona visual: la mitad superior de la pantalla.
  static const double _viewerHeight = 330;

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

  String _appBarTitle() {
    switch (_viewMode) {
      case 0:
        return 'Atlas Anatómico de Músculos';
      case 1:
        return 'Guía de Ejecución y Técnica';
      case 2:
        return 'Reclutamiento y Biomecánica';
      default:
        return 'Anatomía y Técnica';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAnatomyBackground,
      appBar: AppBar(
        backgroundColor: kAnatomySurface,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _appBarTitle(),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5),
        ),
        actions: [
          IconButton(
            tooltip: 'Info Anatómica',
            icon: const Icon(Icons.info_outline_rounded, color: Colors.white70),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔴 Rojo: Músculo Agonista (100%) · 🟡 Ámbar: Sinergista (70%)'),
                  duration: Duration(seconds: 3),
                  backgroundColor: Color(0xFF16253B),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Selector dinámico con 3 modos de visualización de alta fidelidad
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: kAnatomySurface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildModeChip(
                    mode: 0,
                    icon: Icons.accessibility_new_rounded,
                    label: 'Atlas Muscular',
                    color: const Color(0xFFFFB340),
                  ),
                  const SizedBox(width: 10),
                  _buildModeChip(
                    mode: 1,
                    icon: Icons.play_circle_fill_rounded,
                    label: 'Técnica Real (GIF)',
                    color: const Color(0xFF1FAE87),
                  ),
                  const SizedBox(width: 10),
                  _buildModeChip(
                    mode: 2,
                    icon: Icons.analytics_rounded,
                    label: 'Reclutamiento Muscular',
                    color: const Color(0xFF8BE0C0),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: _viewerHeight,
            width: double.infinity,
            child: widget.viewerBuilder?.call(
                  context,
                  _exercise,
                  _autoRotate,
                ) ??
                _Viewer(
                  exercise: _exercise,
                  autoRotate: _autoRotate,
                  viewMode: _viewMode,
                  onSelectMode: (m) => setState(() => _viewMode = m),
                ),
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

  Widget _buildModeChip({
    required int mode,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = _viewMode == mode;
    return ChoiceChip(
      avatar: Icon(icon, size: 15, color: isSelected ? const Color(0xFF0B1220) : color),
      label: Text(label),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: const Color(0xFF16253B),
      side: BorderSide(color: isSelected ? color : Colors.white12),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF0B1220) : Colors.white,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        fontSize: 11.5,
      ),
      onSelected: (val) {
        if (val) setState(() => _viewMode = mode);
      },
    );
  }
}

/// Visor polivalente interactivo con 3 modos de alta fidelidad.
class _Viewer extends StatelessWidget {
  const _Viewer({
    required this.exercise,
    required this.autoRotate,
    required this.viewMode,
    required this.onSelectMode,
  });

  final AnatomyExercise exercise;
  final bool autoRotate;
  final int viewMode;
  final ValueChanged<int> onSelectMode;

  Color _intensityColor(String level) {
    final l = level.toLowerCase();
    if (l.contains('baja') || l.contains('basico') || l.contains('básico')) {
      return const Color(0xFF8BE0C0);
    }
    if (l.contains('alta') || l.contains('avanzado')) {
      return const Color(0xFFFF5252);
    }
    return const Color(0xFFFFB74D);
  }

  @override
  Widget build(BuildContext context) {
    // Modo 0: Atlas Anatómico de Músculos (resaltado con precisión en rojo y ámbar)
    if (viewMode == 0) {
      return Container(
        color: const Color(0xFF070C16),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: MuscleMapView(
          primaryMuscle: exercise.agonist,
          secondaryMuscle: exercise.synergists.isNotEmpty ? exercise.synergists.first : null,
          height: 250,
        ),
      );
    }

    // Modo 2: Reclutamiento Muscular y Telemetría Biomecánica
    if (viewMode == 2) {
      return _MuscleRecruitmentView(
        exercise: exercise,
      );
    }

    // Modo 1: Técnica Real (GIF garantizado y adaptado)
    final effectiveGifUrl = resolveGuaranteedGifUrl(
      name: exercise.name,
      agonist: exercise.agonist,
      intensityLevel: exercise.intensityLevel,
      existingUrl: exercise.gifUrl,
    );
    final badgeColor = _intensityColor(exercise.intensityLevel);

    return Container(
      color: kAnatomyBackground,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            effectiveGifUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: kAgonistColor),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Image.network(
                'https://cdn.jsdelivr.net/gh/JahelCuadrado/ExerciseGymGifsDB@v1.1.0/pectorals/lever-seated-fly.gif',
                fit: BoxFit.contain,
              );
            },
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xDD101B2D),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: badgeColor, width: 1.4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_rounded, size: 14, color: badgeColor),
                  const SizedBox(width: 4),
                  Text(
                    exercise.intensityLevel,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Visor de Reclutamiento Muscular y Telemetría Biomecánica.
/// Muestra desglosado con exactitud porcentual la activación de agonista,
/// sinergistas, estabilizadores, articulaciones y tempo seguro.
class _MuscleRecruitmentView extends StatelessWidget {
  final AnatomyExercise exercise;

  const _MuscleRecruitmentView({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final agonist = exercise.agonist;
    final synergists = exercise.synergists.isNotEmpty ? exercise.synergists.join(', ') : 'Estabilizadores generales';
    final intensity = exercise.intensityLevel;

    return Container(
      color: const Color(0xFF070C16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Agonista Primario (100% Reclutamiento)
            _buildCard(
              title: 'Músculo Motor Primario (Agonista)',
              muscle: agonist,
              percentage: 100,
              color: const Color(0xFFFF3B30),
              icon: Icons.flash_on_rounded,
              description: 'Genera la fuerza principal y máxima tensión durante la fase concéntrica.',
            ),
            const SizedBox(height: 8),

            // Sinergistas (70% Reclutamiento)
            _buildCard(
              title: 'Músculos Asistentes (Sinergistas)',
              muscle: synergists,
              percentage: 70,
              color: const Color(0xFFFFC24B),
              icon: Icons.group_work_rounded,
              description: 'Colaboran en la trayectoria motora y estabilizan la articulación clave.',
            ),
            const SizedBox(height: 8),

            // Estabilizadores (45% Reclutamiento)
            _buildCard(
              title: 'Estabilizadores Articulares & Core',
              muscle: 'Core, Erectores y Fijadores articulares',
              percentage: 45,
              color: const Color(0xFF8BE0C0),
              icon: Icons.shield_rounded,
              description: 'Mantienen la columna neutra y absorben fuerzas disipativas para prevenir lesiones.',
            ),
            const SizedBox(height: 8),

            // Fila de Métricas Biomecánicas
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F192B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E2D42)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      label: 'Tempo de Ejecución',
                      value: exercise.tempo.isNotEmpty ? exercise.tempo : '3-1-1',
                      icon: Icons.timer_outlined,
                      color: const Color(0xFF8BE0C0),
                    ),
                  ),
                  Container(width: 1, height: 32, color: Colors.white12),
                  Expanded(
                    child: _buildMetricItem(
                      label: 'Nivel / Carga',
                      value: intensity,
                      icon: Icons.speed_rounded,
                      color: const Color(0xFFFFB340),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String muscle,
    required int percentage,
    required Color color,
    required IconData icon,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F192B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$percentage%',
                  style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            muscle,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100.0,
              backgroundColor: const Color(0xFF16253B),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(color: Colors.white60, fontSize: 9.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 9.5)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w800),
          overflow: TextOverflow.ellipsis,
        ),
      ],
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
    final l = ex.intensityLevel.toLowerCase();
    final Color intColor = (l.contains('baja') || l.contains('basico') || l.contains('básico'))
        ? const Color(0xFF8BE0C0)
        : (l.contains('alta') || l.contains('avanzado')
            ? const Color(0xFFFF5252)
            : const Color(0xFFFFB74D));
    return [
      Text(
        ex.name,
        style: const TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 10),
      Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: intColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: intColor, width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, size: 15, color: intColor),
              const SizedBox(width: 6),
              Text(
                'Categoría: ${ex.intensityLevel}',
                style: TextStyle(
                  color: intColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
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
