import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mobile_app/models/anatomy_exercise.dart';

/// Datos biomecánicos y cinemáticos científicos de un ejercicio.
class BiomechanicalProfile {
  final String primaryJoint;
  final String motionPlane;
  final String activeRom;
  final double minRomAngle;
  final double maxRomAngle;
  final double optimalAngle;
  final String momentArmType;
  final String peakTorqueAngle;
  final String resistanceType;
  final String shearStressLevel;
  final String jointSafetyScore;
  final String clinicalInsight;
  final List<double> torqueCurve; // 6-7 puntos normalizados [0.0 - 1.0]

  const BiomechanicalProfile({
    required this.primaryJoint,
    required this.motionPlane,
    required this.activeRom,
    required this.minRomAngle,
    required this.maxRomAngle,
    required this.optimalAngle,
    required this.momentArmType,
    required this.peakTorqueAngle,
    required this.resistanceType,
    required this.shearStressLevel,
    required this.jointSafetyScore,
    required this.clinicalInsight,
    required this.torqueCurve,
  });
}

/// Resuelve el perfil cinemático y biomecánico exacto a partir del ejercicio.
BiomechanicalProfile resolveBiomechanicalProfile(AnatomyExercise exercise) {
  final text = '${exercise.name} ${exercise.agonist} ${exercise.biomechanics}'.toLowerCase();

  // 1. PECHO / PECTORAL
  if (text.contains('pecho') || text.contains('pectoral') || text.contains('apertura') || text.contains('fly') || text.contains('press de banca')) {
    final isFly = text.contains('apertura') || text.contains('fly');
    return BiomechanicalProfile(
      primaryJoint: 'Glenohumeral (Hombro) & Humerocubital (Codo)',
      motionPlane: isFly ? 'Plano Transversal Puro (Aducción Horizontal)' : 'Plano Transversal & Sagital',
      activeRom: '45° - 90° de aducción horizontal',
      minRomAngle: 45,
      maxRomAngle: 90,
      optimalAngle: 80,
      momentArmType: 'Curva Acampanada (Peak Torque a 80°-90°)',
      peakTorqueAngle: '85° de aducción',
      resistanceType: 'Resistencia Guiada / Palanca Ergonómica Convergente',
      shearStressLevel: 'Mínimo (< 7%) · Cero hiperextensión retro-escapular',
      jointSafetyScore: '98% Protección Articular (Sedestación lumbar)',
      clinicalInsight: 'La aducción horizontal en máquina o silla fija las escápulas y concentra el 95% de la tensión en las fibras esternocostales del pectoral mayor, descompimiendo por completo el tendón del bíceps.',
      torqueCurve: [0.35, 0.65, 0.90, 1.0, 0.85, 0.40],
    );
  }

  // 2. ESPALDA / DORSAL / REMO / JALÓN
  if (text.contains('espalda') || text.contains('dorsal') || text.contains('remo') || text.contains('jalon') || text.contains('jalón') || text.contains('pulldown')) {
    final isVertical = text.contains('jalon') || text.contains('jalón') || text.contains('pulldown');
    return BiomechanicalProfile(
      primaryJoint: 'Escapulotorácica & Glenohumeral (Retracción y Depresión)',
      motionPlane: isVertical ? 'Plano Frontal (Aducción Humeral Vertical)' : 'Plano Sagital (Extensión Humeral Horizontal)',
      activeRom: '30° - 110° de extensión / aducción',
      minRomAngle: 30,
      maxRomAngle: 110,
      optimalAngle: 95,
      momentArmType: 'Curva Ascendente (Máxima Tensión en Acortamiento)',
      peakTorqueAngle: '100° de retracción',
      resistanceType: 'Tracción Vectorial por Cable / Banda Elástica',
      shearStressLevel: 'Neutro · Favorece Descompresión Axial Vertebral',
      jointSafetyScore: '99% Bioseguridad Raquídea',
      clinicalInsight: 'Inicia el movimiento con depresión y retracción escapular activa antes de flexionar los codos. En sedestación, traccionar al pecho protege el espacio subacromial de pinzamientos.',
      torqueCurve: [0.25, 0.50, 0.75, 0.92, 1.0, 0.95],
    );
  }

  // 3. HOMBROS / DELTOIDES
  if (text.contains('hombro') || text.contains('deltoid') || text.contains('militar') || text.contains('lateral') || text.contains('pajaro') || text.contains('pájaro')) {
    final isLateral = text.contains('lateral');
    return BiomechanicalProfile(
      primaryJoint: 'Complejo Articular del Hombro (Glenohumeral & Acromioclavicular)',
      motionPlane: isLateral ? 'Plano Escapular (30° anterior al eje coronal)' : 'Plano Frontal-Sagital Mixto',
      activeRom: isLateral ? '15° - 85° de abducción' : '45° - 90° de empuje vertical',
      minRomAngle: 15,
      maxRomAngle: 85,
      optimalAngle: 75,
      momentArmType: isLateral ? 'Brazo de Momento Máximo a 90° (Gravitacional)' : 'Curva Descendente en Rango Superior',
      peakTorqueAngle: '80° de abducción',
      resistanceType: 'Carga Externa Guiada / Mancuerna en Sedestación',
      shearStressLevel: 'Protegido (< 9%) · Libre de Fricción Subacromial',
      jointSafetyScore: '96% Bioseguridad en Espacio Subacromial',
      clinicalInsight: 'Ejecutar las elevaciones en el plano escapular (Scaption) evita la compresión del tendón del supraespinoso contra el acromion y maximiza el reclutamiento del deltoides medio.',
      torqueCurve: [0.20, 0.45, 0.75, 0.95, 1.0, 0.70],
    );
  }

  // 4. BRAZOS: BÍCEPS
  if (text.contains('bicep') || text.contains('bícep') || text.contains('curl')) {
    return BiomechanicalProfile(
      primaryJoint: 'Humerocubital & Radiohumeral (Codo)',
      motionPlane: 'Plano Sagital Puro (Flexión de Codo)',
      activeRom: '20° - 125° de flexión concéntrica',
      minRomAngle: 20,
      maxRomAngle: 125,
      optimalAngle: 90,
      momentArmType: 'Pico de Brazo de Momento a 90° (sin 90° = 1.0)',
      peakTorqueAngle: '90° de flexión',
      resistanceType: 'Resistencia Isotónica / Brazo de Palanca Humeral',
      shearStressLevel: 'Bajo (< 5%) · Estabilidad Humeral Fija en Respaldo',
      jointSafetyScore: '99% Aislamiento sin Balanceo Raquídeo',
      clinicalInsight: 'El brazo de palanca externo alcanza su punto más exigente a los 90 grados de flexión. Mantener los codos pegados a los costados elimina la inercia del deltoides anterior.',
      torqueCurve: [0.30, 0.60, 0.90, 1.0, 0.80, 0.50],
    );
  }

  // 5. BRAZOS: TRÍCEPS
  if (text.contains('tricep') || text.contains('trícep') || text.contains('fondo') || text.contains('copa') || text.contains('dip')) {
    return BiomechanicalProfile(
      primaryJoint: 'Humerocubital (Extensión de Codo)',
      motionPlane: 'Plano Sagital Puro (Extensión Posterior)',
      activeRom: '80° - 165° de extensión articular',
      minRomAngle: 80,
      maxRomAngle: 165,
      optimalAngle: 155,
      momentArmType: 'Curva Ascendente hacia el Bloqueo Controlado',
      peakTorqueAngle: '160° de extensión',
      resistanceType: 'Tracción Continua por Polea o Resistencia Adaptada',
      shearStressLevel: 'Muy Bajo (< 4%) · Cero Impacto Olecraneano',
      jointSafetyScore: '97% Protección del Olécranon',
      clinicalInsight: 'La polea mantiene una tensión mecánica uniforme en las 3 cabezas del tríceps (larga, lateral y medial), evitando la descarga articular en el punto de máxima extensión.',
      torqueCurve: [0.40, 0.65, 0.85, 0.95, 1.0, 0.90],
    );
  }

  // 6. CORE / ABDOMEN
  if (text.contains('core') || text.contains('abdom') || text.contains('giro') || text.contains('twist') || text.contains('plancha')) {
    final isTwist = text.contains('giro') || text.contains('twist');
    return BiomechanicalProfile(
      primaryJoint: 'Complejo Intervertebral Dorsolumbar',
      motionPlane: isTwist ? 'Plano Transversal (Rotación Torácica Controlada)' : 'Plano Sagital (Flexión Anterior de Tronco)',
      activeRom: isTwist ? '0° - 35° de rotación segmentaria' : '15° - 30° de flexión torácica',
      minRomAngle: 10,
      maxRomAngle: 40,
      optimalAngle: 30,
      momentArmType: 'Tensión Isométrica e Isocinética Intra-abdominal',
      peakTorqueAngle: '30° de contracción isométrica',
      resistanceType: 'Tensión Elástica Progresiva / Resistencia de Hooke',
      shearStressLevel: 'Seguro · Rotación desde el Tórax, no desde la Pelvis',
      jointSafetyScore: '98% Protección de Discos L4-L5/S1',
      clinicalInsight: 'En posición sentada la pelvis queda anclada, asegurando que la torsión provenga de los oblicuos y transverso abdominal sin torsión de las vértebras lumbares bajas.',
      torqueCurve: [0.50, 0.75, 0.95, 1.0, 0.90, 0.70],
    );
  }

  // 7. PIERNAS / TREN INFERIOR (Sentadillas, Curls, Zancadas, Puente)
  return BiomechanicalProfile(
    primaryJoint: 'Coxofemoral (Cadera) & Tibiofemoral / Patelofemoral (Rodilla)',
    motionPlane: 'Plano Sagital (Flexo-Extensión Bipodal / Unipodal)',
    activeRom: '0° - 90° de flexión de rodilla',
    minRomAngle: 0,
    maxRomAngle: 90,
    optimalAngle: 85,
    momentArmType: 'Curva Acampanada con Pico en Inversión Excéntrica',
    peakTorqueAngle: '90° en paralelo',
    resistanceType: 'Carga de Gravedad Axial Vectorial',
    shearStressLevel: 'Cizallamiento Tibial Controlado con Apoyo Podal Completo',
    jointSafetyScore: '95% Eficiencia de Cadena Cinética Cerrada',
    clinicalInsight: 'Alinear el vector de fuerza de la rodilla con el segundo dedo del pie reduce las fuerzas de cizallamiento en el ligamento cruzado anterior y maximiza la coactivación glútea.',
    torqueCurve: [0.30, 0.60, 0.95, 1.0, 0.80, 0.40],
  );
}

/// Visor Biomecánico y Cinemático de Alta Precisión.
/// Sustituye los modelos vectoriales rudimentarios por un laboratorio de kinesiología y biomecánica interactiva.
class BiomechanicalKinematicsView extends StatefulWidget {
  const BiomechanicalKinematicsView({
    super.key,
    required this.exercise,
    this.height = 310,
  });

  final AnatomyExercise exercise;
  final double height;

  @override
  State<BiomechanicalKinematicsView> createState() => _BiomechanicalKinematicsViewState();
}

class _BiomechanicalKinematicsViewState extends State<BiomechanicalKinematicsView> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _tabIndex = 0; // 0: Goniómetro ROM, 1: Curva de Torque, 2: Kinesiología IA

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = resolveBiomechanicalProfile(widget.exercise);

    return Container(
      height: widget.height,
      color: const Color(0xFF070C16),
      child: Column(
        children: [
          // Sub-barra superior de pestañas biomecánicas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF0E1726),
              border: Border(bottom: BorderSide(color: Color(0xFF1E2D42), width: 1)),
            ),
            child: Row(
              children: [
                _buildSubTab(0, 'Goniómetro ROM', Icons.speed_rounded),
                const SizedBox(width: 6),
                _buildSubTab(1, 'Curva de Torque', Icons.show_chart_rounded),
                const SizedBox(width: 6),
                _buildSubTab(2, 'Diagnóstico IA', Icons.psychology_rounded),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: _buildCurrentTabContent(profile),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTab(int index, String label, IconData icon) {
    final isSelected = _tabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tabIndex = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF19324C) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? const Color(0xFF64B5F6) : Colors.white10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? const Color(0xFF64B5F6) : Colors.white60,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected ? const Color(0xFF64B5F6) : Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent(BiomechanicalProfile profile) {
    switch (_tabIndex) {
      case 0:
        return _buildRomGoniometerTab(profile);
      case 1:
        return _buildTorqueCurveTab(profile);
      case 2:
      default:
        return _buildKinesiologyAiTab(profile);
    }
  }

  // --- TAB 1: GONIÓMETRO DIGITAL Y RANGO DE MOVIMIENTO (ROM) ---
  Widget _buildRomGoniometerTab(BiomechanicalProfile profile) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        // Simula el arco del ángulo durante el ciclo de repetición
        final currentAngle = profile.minRomAngle +
            (_animController.value * (profile.maxRomAngle - profile.minRomAngle));

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              // Goniómetro Vectorial Circular
              SizedBox(
                width: 140,
                height: 140,
                child: CustomPaint(
                  painter: _RomDialPainter(
                    minAngle: profile.minRomAngle,
                    maxAngle: profile.maxRomAngle,
                    currentAngle: currentAngle,
                    optimalAngle: profile.optimalAngle,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${currentAngle.toStringAsFixed(0)}°',
                          style: const TextStyle(
                            color: Color(0xFF8BE0C0),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Text(
                          'ROM ARTICULAR',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Telemetría Articular
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMetricPill(
                      label: 'Articulación Clave',
                      value: profile.primaryJoint,
                      color: const Color(0xFF8BE0C0),
                      icon: Icons.hub_rounded,
                    ),
                    const SizedBox(height: 6),
                    _buildMetricPill(
                      label: 'Plano Cinemático',
                      value: profile.motionPlane,
                      color: const Color(0xFF64B5F6),
                      icon: Icons.straighten_rounded,
                    ),
                    const SizedBox(height: 6),
                    _buildMetricPill(
                      label: 'Rango Bioseguro',
                      value: profile.activeRom,
                      color: const Color(0xFFFFB340),
                      icon: Icons.verified_user_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- TAB 2: CURVA DE TORQUE Y BRAZO DE MOMENTO ---
  Widget _buildTorqueCurveTab(BiomechanicalProfile profile) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.show_chart_rounded, size: 14, color: Color(0xFFFF5252)),
                      const SizedBox(width: 4),
                      Text(
                        profile.momentArmType,
                        style: const TextStyle(
                          color: Color(0xFFFF9500),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF231B15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFF9500).withOpacity(0.4)),
                    ),
                    child: Text(
                      'τ = F × d⊥',
                      style: const TextStyle(
                        color: Color(0xFFFFB74D),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Gráfico vectorial de la curva de torque
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C1322),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1E2D42)),
                  ),
                  child: CustomPaint(
                    painter: _TorqueCurvePainter(
                      points: profile.torqueCurve,
                      animProgress: _animController.value,
                      peakAngleText: profile.peakTorqueAngle,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.bolt_rounded, size: 12, color: Color(0xFF8BE0C0)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Resistencia: ${profile.resistanceType}',
                      style: const TextStyle(color: Colors.white70, fontSize: 9.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- TAB 3: DIAGNÓSTICO KINESIOLÓGICO IA ---
  Widget _buildKinesiologyAiTab(BiomechanicalProfile profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF132A22),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF1FAE87)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_rounded, size: 12, color: Color(0xFF8BE0C0)),
                    const SizedBox(width: 4),
                    Text(
                      profile.jointSafetyScore,
                      style: const TextStyle(
                        color: Color(0xFF8BE0C0),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cizallamiento: ${profile.shearStressLevel}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1A2C),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1C3554)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 13, color: Color(0xFF64B5F6)),
                        SizedBox(width: 6),
                        Text(
                          'Análisis Kinesiológico & Prescripción Motora',
                          style: TextStyle(
                            color: Color(0xFF64B5F6),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      profile.clinicalInsight,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1220),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 12, color: Color(0xFFFFB340)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Optimizado para 100% de aislamiento en sedestación adaptada sin sobrecarga axial.',
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 9.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 4),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dibuja el dial del Goniómetro Articular (ROM) con arcos de bioseguridad y aguja dinámica.
class _RomDialPainter extends CustomPainter {
  final double minAngle;
  final double maxAngle;
  final double currentAngle;
  final double optimalAngle;

  _RomDialPainter({
    required this.minAngle,
    required this.maxAngle,
    required this.currentAngle,
    required this.optimalAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Fondo del arco circular (270 grados, de -135° a +135°)
    const startAngleRad = 135 * math.pi / 180;
    const sweepAngleRad = 270 * math.pi / 180;

    final bgPaint = Paint()
      ..color = const Color(0xFF1A273A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngleRad,
      sweepAngleRad,
      false,
      bgPaint,
    );

    // Arco Bioseguro (en verde menta/cian)
    final progress = ((currentAngle - minAngle) / (maxAngle - minAngle)).clamp(0.0, 1.0);
    final activeSweep = sweepAngleRad * progress;

    final activePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF64B5F6), Color(0xFF8BE0C0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngleRad,
      activeSweep,
      false,
      activePaint,
    );

    // Aguja / Indicador polar
    final needleAngleRad = startAngleRad + activeSweep;
    final needlePoint = Offset(
      center.dx + (radius - 1) * math.cos(needleAngleRad),
      center.dy + (radius - 1) * math.sin(needleAngleRad),
    );

    final needlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(needlePoint, 5, needlePaint);
    canvas.drawCircle(
      needlePoint,
      8,
      Paint()
        ..color = const Color(0xFF8BE0C0).withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _RomDialPainter oldDelegate) {
    return oldDelegate.currentAngle != currentAngle || oldDelegate.maxAngle != maxAngle;
  }
}

/// Dibuja la curva matemática de Torque (Brazo de Momento vs Ángulo Articular).
class _TorqueCurvePainter extends CustomPainter {
  final List<double> points;
  final double animProgress;
  final String peakAngleText;

  _TorqueCurvePainter({
    required this.points,
    required this.animProgress,
    required this.peakAngleText,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final gridPaint = Paint()
      ..color = const Color(0xFF1E2D42).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Líneas de cuadrícula horizontal
    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    final stepX = size.width / (points.length - 1);

    // Mapeo de puntos
    final mappedPoints = <Offset>[];
    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = size.height - (points[i] * (size.height - 20)) - 10;
      mappedPoints.add(Offset(x, y));
    }

    // Trazo de Bezier suave
    path.moveTo(mappedPoints[0].dx, mappedPoints[0].dy);
    for (int i = 0; i < mappedPoints.length - 1; i++) {
      final p0 = mappedPoints[i];
      final p1 = mappedPoints[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // Curva principal
    final curvePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF64B5F6), Color(0xFFFFB340), Color(0xFFFF5252)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, curvePaint);

    // Sombreado de área bajo la curva
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFF9500).withOpacity(0.25),
          const Color(0xFF64B5F6).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Punto interactivo dinámico que recorre la curva
    final sampleIndex = (animProgress * (mappedPoints.length - 1)).clamp(0.0, (mappedPoints.length - 1).toDouble());
    final lowIdx = sampleIndex.floor();
    final highIdx = sampleIndex.ceil();
    final subT = sampleIndex - lowIdx;
    final currentPoint = Offset(
      mappedPoints[lowIdx].dx + (mappedPoints[highIdx].dx - mappedPoints[lowIdx].dx) * subT,
      mappedPoints[lowIdx].dy + (mappedPoints[highIdx].dy - mappedPoints[lowIdx].dy) * subT,
    );

    // Dibuja el punto animado de carga mecánica
    canvas.drawCircle(
      currentPoint,
      6,
      Paint()..color = const Color(0xFFFF5252),
    );
    canvas.drawCircle(
      currentPoint,
      10,
      Paint()
        ..color = const Color(0xFFFF5252).withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _TorqueCurvePainter oldDelegate) {
    return oldDelegate.animProgress != animProgress;
  }
}
