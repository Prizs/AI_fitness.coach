import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:mobile_app/models/anatomy_exercise.dart';
import 'package:mobile_app/widgets/biomechanical_kinematics_view.dart';
import 'package:mobile_app/widgets/muscle_map_view.dart';

/// Pantalla de demostración didáctica del modelo anatómico y técnica.
///
/// Ofrece 4 modos de visualización avanzados:
/// 0: Técnica Real (GIF) animado en bucle adaptado.
/// 1: Atlas Anatómico de Músculos (resaltado interactivo frontal/dorsal de agonistas y sinergistas).
/// 2: Modelo Anatómico 3D Muscular (360°) con Balizas Holográficas de Activación.
/// 3: Cinemática & Biomecánica Articular (Goniómetro ROM, Curva de Torque τ = F×d⊥ y Diagnóstico IA).
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
  int _viewMode = 0; // 0: GIF, 1: Atlas Muscular, 2: 3D Muscular con Marcadores, 3: Cinemática & Biomecánica

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
      case 1:
        return 'Atlas Anatómico de Músculos';
      case 2:
        return 'Modelo 3D Muscular (360° Marcadores)';
      case 3:
        return 'Cinemática & Biomecánica Articular';
      default:
        return 'Guía de Ejecución y Técnica';
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
          if (_viewMode == 2)
            IconButton(
              tooltip: _autoRotate ? 'Pausar autorrotación' : 'Activar giro 360°',
              onPressed: () => setState(() => _autoRotate = !_autoRotate),
              icon: Icon(
                _autoRotate ? Icons.threesixty_rounded : Icons.rotate_right_rounded,
                color: _autoRotate ? const Color(0xFF8BE0C0) : Colors.white70,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Selector dinámico con 4 modos de visualización
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: kAnatomySurface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildModeChip(
                    mode: 0,
                    icon: Icons.play_circle_fill_rounded,
                    label: 'Técnica Real (GIF)',
                    color: const Color(0xFF1FAE87),
                  ),
                  const SizedBox(width: 8),
                  _buildModeChip(
                    mode: 1,
                    icon: Icons.accessibility_new_rounded,
                    label: 'Atlas Muscular',
                    color: const Color(0xFFFFB340),
                  ),
                  const SizedBox(width: 8),
                  _buildModeChip(
                    mode: 2,
                    icon: Icons.threed_rotation_rounded,
                    label: 'Modelo 3D (Marcadores)',
                    color: const Color(0xFF8BE0C0),
                  ),
                  const SizedBox(width: 8),
                  _buildModeChip(
                    mode: 3,
                    icon: Icons.speed_rounded,
                    label: 'Cinemática & Biomecánica',
                    color: const Color(0xFF64B5F6),
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

/// Visor polivalente interactivo con 4 modos de alta fidelidad.
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
    // Modo 1: Atlas Anatómico de Músculos (flutter_body_atlas con auto-orientación)
    if (viewMode == 1) {
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

    // Modo 2: Modelo 3D Muscular Real con Balizas Holográficas de Activación y Presets de Cámara
    if (viewMode == 2) {
      return _Muscular3DViewer(
        exercise: exercise,
        autoRotate: autoRotate,
      );
    }

    // Modo 3: Cinemática & Biomecánica Articular (Goniómetro ROM, Curva de Torque y Kinesiología IA)
    if (viewMode == 3) {
      return BiomechanicalKinematicsView(
        exercise: exercise,
        height: 330,
      );
    }

    // Modo 0: Técnica Real (GIF garantizado y adaptado)
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

/// Visor 3D Muscular interactivo con balizas holográficas de activación sobre el músculo agonista
/// y selector rápido de ángulo de cámara (Frente / Espalda / Perfil).
class _Muscular3DViewer extends StatefulWidget {
  final AnatomyExercise exercise;
  final bool autoRotate;

  const _Muscular3DViewer({
    required this.exercise,
    required this.autoRotate,
  });

  @override
  State<_Muscular3DViewer> createState() => _Muscular3DViewerState();
}

class _Muscular3DViewerState extends State<_Muscular3DViewer> with SingleTickerProviderStateMixin {
  late AnimationController _beaconAnim;
  String _currentOrbit = '0deg 75deg 105%';
  bool _isPosteriorTarget = false;

  @override
  void initState() {
    super.initState();
    _beaconAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _resolveTargetOrientation();
  }

  @override
  void didUpdateWidget(covariant _Muscular3DViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.id != widget.exercise.id) {
      _resolveTargetOrientation();
    }
  }

  @override
  void dispose() {
    _beaconAnim.dispose();
    super.dispose();
  }

  void _resolveTargetOrientation() {
    final m = '${widget.exercise.agonist} ${widget.exercise.name}'.toLowerCase();
    _isPosteriorTarget = m.contains('dorsal') ||
        m.contains('espalda') ||
        m.contains('glute') ||
        m.contains('glúte') ||
        m.contains('isquio') ||
        m.contains('femoral') ||
        m.contains('hamstring') ||
        m.contains('tricep') ||
        m.contains('trícep') ||
        m.contains('lumbar') ||
        m.contains('pantorrilla') ||
        m.contains('gemelo') ||
        m.contains('posterior') ||
        m.contains('trapecio') ||
        m.contains('pajaro') ||
        m.contains('pájaro');

    _currentOrbit = _isPosteriorTarget ? '180deg 75deg 105%' : '0deg 75deg 105%';
  }

  Alignment _getMuscleAlignment() {
    final m = '${widget.exercise.agonist} ${widget.exercise.name}'.toLowerCase();
    if (m.contains('pecho') || m.contains('pectoral') || m.contains('apertura')) {
      return const Alignment(0.0, -0.32);
    }
    if (m.contains('dorsal') || m.contains('espalda') || m.contains('remo') || m.contains('jalon')) {
      return const Alignment(0.0, -0.28);
    }
    if (m.contains('hombro') || m.contains('deltoid') || m.contains('militar') || m.contains('lateral')) {
      return const Alignment(-0.38, -0.42);
    }
    if (m.contains('bicep') || m.contains('bícep') || m.contains('curl')) {
      return const Alignment(-0.48, -0.15);
    }
    if (m.contains('tricep') || m.contains('trícep') || m.contains('fondo')) {
      return const Alignment(-0.48, -0.18);
    }
    if (m.contains('core') || m.contains('abdom') || m.contains('twist')) {
      return const Alignment(0.0, 0.0);
    }
    if (m.contains('isquio') || m.contains('femoral') || m.contains('glute')) {
      return const Alignment(0.0, 0.28);
    }
    if (m.contains('sentadilla') || m.contains('cuadric') || m.contains('prensa')) {
      return const Alignment(-0.20, 0.40);
    }
    return const Alignment(0.0, -0.20);
  }

  @override
  Widget build(BuildContext context) {
    final beaconAlign = _getMuscleAlignment();
    final agonist = widget.exercise.agonist;
    final synergists = widget.exercise.synergists.isNotEmpty ? widget.exercise.synergists.join(', ') : 'Estabilizadores';

    return Container(
      color: const Color(0xFF070C16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Modelo 3D con model_viewer_plus y cámara inteligente
          ModelViewer(
            key: ValueKey('mv_${widget.exercise.id}_${widget.autoRotate}_$_currentOrbit'),
            src: kMuscularAnatomyModelUrl,
            alt: 'Modelo Anatómico Muscular 3D (360°)',
            ar: false,
            autoRotate: widget.autoRotate,
            cameraControls: true,
            cameraOrbit: _currentOrbit,
            backgroundColor: const Color(0xFF070C16),
            shadowIntensity: 1.0,
          ),

          // Baliza Holográfica de Activación Muscular (Crosshair / Target Beacon)
          AnimatedBuilder(
            animation: _beaconAnim,
            builder: (context, child) {
              final pulse = _beaconAnim.value;
              return Align(
                alignment: beaconAlign,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tag flotante del músculo activo
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xEE1A0808),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFF3B30), width: 1.4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF3B30).withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.my_location_rounded, size: 12, color: Color(0xFFFF5252)),
                          const SizedBox(width: 4),
                          Text(
                            '🔥 AGONISTA: $agonist (100%)',
                            style: const TextStyle(
                              color: Color(0xFFFF8585),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Diana pulsante
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 22 + (pulse * 12),
                          height: 22 + (pulse * 12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFF3B30).withOpacity(1.0 - pulse),
                              width: 1.8,
                            ),
                          ),
                        ),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFF3B30),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFFF3B30),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // Selector de ángulo de cámara rápido en la parte superior
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Row(
              children: [
                _buildCameraAngleButton(
                  label: 'Frente',
                  icon: Icons.accessibility_new_rounded,
                  orbit: '0deg 75deg 105%',
                  isActive: _currentOrbit.startsWith('0deg'),
                ),
                const SizedBox(width: 6),
                _buildCameraAngleButton(
                  label: 'Espalda',
                  icon: Icons.back_hand_outlined,
                  orbit: '180deg 75deg 105%',
                  isActive: _currentOrbit.startsWith('180deg'),
                ),
                const SizedBox(width: 6),
                _buildCameraAngleButton(
                  label: 'Perfil',
                  icon: Icons.crop_portrait_rounded,
                  orbit: '90deg 75deg 105%',
                  isActive: _currentOrbit.startsWith('90deg'),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xDD0B1220),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF8BE0C0).withOpacity(0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_rounded, color: Color(0xFF8BE0C0), size: 12),
                      SizedBox(width: 3),
                      Text(
                        'Giro 360°',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // HUD inferior de telemetría de reclutamiento muscular
          Positioned(
            bottom: 8,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xDD0C1322),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1E2D42)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFF3B30), shape: BoxShape.circle)),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'Agonista: $agonist (100%)',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFFB340), shape: BoxShape.circle)),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'Sinergistas: $synergists',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: _isPosteriorTarget ? const Color(0xFF261D10) : const Color(0xFF10261E),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _isPosteriorTarget ? const Color(0xFFFFB340) : const Color(0xFF8BE0C0)),
                    ),
                    child: Text(
                      _isPosteriorTarget ? 'Plano Posterior' : 'Plano Anterior',
                      style: TextStyle(
                        color: _isPosteriorTarget ? const Color(0xFFFFB340) : const Color(0xFF8BE0C0),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
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

  Widget _buildCameraAngleButton({
    required String label,
    required IconData icon,
    required String orbit,
    required bool isActive,
  }) {
    return InkWell(
      onTap: () => setState(() => _currentOrbit = orbit),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1F3854) : const Color(0xCC0E1828),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? const Color(0xFF64B5F6) : Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isActive ? const Color(0xFF64B5F6) : Colors.white70),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFF64B5F6) : Colors.white70,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
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
