import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Visor 3D real para ejercicios, escrito en Dart puro.
///
/// No depende de WebView, OpenGL ni assets externos, por lo que funciona en
/// cualquier telefono Android sin licencias de modelos 3D. El cuerpo humanoide
/// se define con puntos 3D, se rota con matrices, se proyecta en perspectiva y
/// se dibuja ordenando los segmentos por profundidad.
class _V3 {
  const _V3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  _V3 operator +(_V3 other) => _V3(x + other.x, y + other.y, z + other.z);
  _V3 operator -(_V3 other) => _V3(x - other.x, y - other.y, z - other.z);
  _V3 operator *(double k) => _V3(x * k, y * k, z * k);
}

/// Punto 3D ya proyectado a la pantalla.
class _Projected {
  const _Projected(this.offset, this.depth);

  final Offset offset;
  final double depth;
}

class _Bone {
  const _Bone(this.a, this.b, this.thickness);

  final String a;
  final String b;
  final double thickness;
}

/// Esqueleto base; los nombres de las articulaciones son estables para que las
/// poses y el resaltado de musculos puedan referenciarlos.
const List<_Bone> _skeleton = [
  _Bone('neck', 'head', 1.15),
  _Bone('spineTop', 'neck', 1.0),
  _Bone('spineMid', 'spineTop', 1.0),
  _Bone('hipCenter', 'spineMid', 1.05),
  _Bone('shoulderL', 'neck', 0.62),
  _Bone('shoulderR', 'neck', 0.62),
  _Bone('elbowL', 'shoulderL', 0.5),
  _Bone('elbowR', 'shoulderR', 0.5),
  _Bone('wristL', 'elbowL', 0.42),
  _Bone('wristR', 'elbowR', 0.42),
  _Bone('hipL', 'hipCenter', 0.6),
  _Bone('hipR', 'hipCenter', 0.6),
  _Bone('kneeL', 'hipL', 0.56),
  _Bone('kneeR', 'hipR', 0.56),
  _Bone('ankleL', 'kneeL', 0.46),
  _Bone('ankleR', 'kneeR', 0.46),
];

/// Rol de un musculo dentro del ejercicio.
enum MuscleGroup { primary, secondary, neutral }

/// Deduce que huesos resaltar a partir del texto de musculo del plan de la IA.
Set<String> _highlightedBones(String? muscleText, MuscleGroup role) {
  if (muscleText == null || muscleText.trim().isEmpty) return const {};
  final text = muscleText.toLowerCase();
  final bones = <String>{};

  if (text.contains('cuadriceps') ||
      text.contains('quad') ||
      text.contains('isquio') ||
      text.contains('femoral') ||
      text.contains('pierna')) {
    bones.addAll(['kneeL', 'kneeR', 'hipL', 'hipR']);
  }
  if (text.contains('glute') || text.contains('cadera')) {
    bones.addAll(['hipL', 'hipR', 'hipCenter']);
  }
  if (text.contains('pectoral') ||
      text.contains('pecho') ||
      text.contains('empuje')) {
    bones.addAll(['shoulderL', 'shoulderR', 'spineTop']);
  }
  if (text.contains('triceps') ||
      text.contains('biceps') ||
      text.contains('brazo') ||
      text.contains('hombro') ||
      text.contains('deltoid')) {
    bones.addAll(['elbowL', 'elbowR', 'shoulderL', 'shoulderR']);
  }
  if (text.contains('core') ||
      text.contains('abdom') ||
      text.contains('lumbar') ||
      text.contains('espalda') ||
      text.contains('dorsal') ||
      text.contains('tiron')) {
    bones.addAll(['spineMid', 'spineTop', 'hipCenter']);
  }
  if (text.contains('cardio') ||
      text.contains('pulmonar') ||
      text.contains('resistencia') ||
      text.contains('oxigen')) {
    bones.addAll(['kneeL', 'kneeR', 'spineMid', 'shoulderL', 'shoulderR']);
  }
  if (bones.isEmpty && role == MuscleGroup.primary) {
    bones.addAll(['spineMid', 'spineTop']);
  }
  return bones;
}

/// Devuelve la pose del esqueleto para un ejercicio y una fase [t] en [0, 1].
Map<String, _V3> _poseFor(String animationKey, double t) {
  final key = animationKey.toLowerCase();
  final phase = math.sin(t * math.pi); // 0 -> 1 -> 0

  double shoulderY = 1.5;
  double elbowY = 1.24;
  double wristY = 1.0;
  double hipY = 0.98;
  double kneeY = 0.52;
  double ankleY = 0.06;
  double hipZ = 0;
  double kneeZ = 0;
  double ankleZ = 0;
  double torsoLean = 0;
  double armSpread = 0.26;
  double armZ = 0;

  if (key.contains('squat')) {
    final drop = 0.42 * phase;
    hipY -= drop;
    kneeY -= drop * 0.35;
    kneeZ += 0.28 * phase;
    hipZ -= 0.05 * phase;
    torsoLean = 0.35 * phase;
    shoulderY -= drop;
    elbowY -= drop;
    wristY -= drop;
    armZ = -0.12 * phase;
  } else if (key.contains('push-up') ||
      key.contains('pushup') ||
      key.contains('flexion')) {
    return _horizontalBody(
      armAngle: 1.35 - 0.85 * phase,
      legAngle: 1.45,
      headLift: 0.35,
    );
  } else if (key.contains('plank') || key.contains('plancha')) {
    return _horizontalBody(
      armAngle: 1.5,
      legAngle: 1.5,
      headLift: 0.2,
      forearmDown: true,
    );
  } else if (key.contains('bench') || key.contains('press')) {
    return _lyingBody(armExtension: 0.35 + 0.5 * phase);
  } else if (key.contains('row') ||
      key.contains('remo') ||
      key.contains('swing')) {
    final pull = 0.35 * phase;
    torsoLean = 0.9;
    armSpread = 0.2;
    armZ = -0.1;
    elbowY = 1.1 + pull * 0.25;
    wristY = 0.95 + pull * 0.3;
  } else if (key.contains('walk') ||
      key.contains('caminata') ||
      key.contains('trote') ||
      key.contains('run')) {
    final swing = math.sin(t * 2 * math.pi);
    kneeZ += 0.22 * swing;
    ankleZ += 0.3 * swing;
    armZ = -0.18 * swing;
    elbowY += 0.05 * swing;
  } else {
    final breathing = math.sin(t * 2 * math.pi);
    shoulderY += 0.012 * breathing;
    armZ = 0.05 * breathing;
    kneeZ += 0.02 * phase;
  }

  double leaned(double y, double base) {
    final factor = (y - hipY) / 1.0;
    return base + torsoLean * factor * 0.55;
  }

  return {
    'head': _V3(
      leaned(shoulderY + 0.22, 0),
      shoulderY + 0.28,
      hipZ + torsoLean * 0.35 - 0.02,
    ),
    'neck': _V3(0, shoulderY + 0.05, hipZ + torsoLean * 0.2),
    'spineTop': _V3(0, leaned(shoulderY, shoulderY), hipZ + torsoLean * 0.12),
    'spineMid': _V3(
      0,
      (leaned(shoulderY, shoulderY) + hipY) / 2,
      hipZ + torsoLean * 0.04,
    ),
    'hipCenter': _V3(0, hipY, hipZ),
    'shoulderL': _V3(
      -0.2,
      leaned(shoulderY, shoulderY) + 0.04,
      hipZ + torsoLean * 0.12,
    ),
    'shoulderR': _V3(
      0.2,
      leaned(shoulderY, shoulderY) + 0.04,
      hipZ + torsoLean * 0.12,
    ),
    'elbowL': _V3(-armSpread, leaned(elbowY, elbowY) + 0.02, armZ),
    'elbowR': _V3(armSpread, leaned(elbowY, elbowY) + 0.02, armZ),
    'wristL': _V3(-armSpread - 0.03, leaned(wristY, wristY), armZ * 1.4),
    'wristR': _V3(armSpread + 0.03, leaned(wristY, wristY), armZ * 1.4),
    'hipL': _V3(-0.11, hipY, hipZ),
    'hipR': _V3(0.11, hipY, hipZ),
    'kneeL': _V3(-0.12, kneeY, kneeZ),
    'kneeR': _V3(0.12, kneeY, kneeZ),
    'ankleL': _V3(-0.12, ankleY, ankleZ),
    'ankleR': _V3(0.12, ankleY, ankleZ),
  };
}

/// Cuerpo horizontal usado en flexiones y planchas.
Map<String, _V3> _horizontalBody({
  required double armAngle,
  required double legAngle,
  required double headLift,
  bool forearmDown = false,
}) {
  const bodyLength = 1.0;
  const hip = _V3(0, 0.55, 0);
  final shoulder = _V3(
    0,
    hip.y + math.cos(armAngle) * bodyLength,
    math.sin(armAngle) * bodyLength,
  );
  final head = _V3(
    0,
    shoulder.y + 0.2 * math.cos(headLift),
    shoulder.z + 0.2 * math.sin(headLift),
  );

  final handDrop = forearmDown ? 0.26 : 0.62;
  final wrist = _V3(
    0,
    shoulder.y - handDrop,
    shoulder.z + (forearmDown ? 0.18 : 0.34),
  );
  final elbow = _V3(
    0,
    (shoulder.y + wrist.y) / 2 + (forearmDown ? 0.08 : 0.02),
    (shoulder.z + wrist.z) / 2 - 0.1,
  );

  final knee = _V3(0, hip.y - 0.45 * math.sin(legAngle), -0.45 * math.cos(legAngle));
  final ankle = _V3(0, knee.y - 0.42, knee.z);

  return {
    'head': head,
    'neck': _V3(0, shoulder.y + 0.06, shoulder.z - 0.02),
    'spineTop': shoulder,
    'spineMid': _V3(0, (shoulder.y + hip.y) / 2, (shoulder.z + hip.z) / 2),
    'hipCenter': hip,
    'shoulderL': _V3(-0.22, shoulder.y, shoulder.z),
    'shoulderR': _V3(0.22, shoulder.y, shoulder.z),
    'elbowL': _V3(-0.24, elbow.y, elbow.z),
    'elbowR': _V3(0.24, elbow.y, elbow.z),
    'wristL': _V3(-0.24, wrist.y, wrist.z),
    'wristR': _V3(0.24, wrist.y, wrist.z),
    'hipL': _V3(-0.12, hip.y, hip.z),
    'hipR': _V3(0.12, hip.y, hip.z),
    'kneeL': _V3(-0.13, knee.y, knee.z),
    'kneeR': _V3(0.13, knee.y, knee.z),
    'ankleL': _V3(-0.13, ankle.y, ankle.z),
    'ankleR': _V3(0.13, ankle.y, ankle.z),
  };
}

/// Cuerpo tumbado usado en press de banca.
Map<String, _V3> _lyingBody({required double armExtension}) {
  const hip = _V3(0, 0.5, 0);
  const shoulder = _V3(0, 0.62, 0.05);
  final handY = shoulder.y + 0.35 + armExtension * 0.35;
  final elbow = _V3(0, (shoulder.y + handY) / 2, shoulder.z + 0.22);
  final wrist = _V3(0, handY, shoulder.z - 0.05);
  final knee = _V3(0, 0.6, -0.45);
  final ankle = _V3(0, 0.16, -0.85);

  return {
    'head': _V3(0, 0.62, -0.24),
    'neck': _V3(0, 0.62, -0.08),
    'spineTop': shoulder,
    'spineMid': _V3(0, (shoulder.y + hip.y) / 2, (shoulder.z + hip.z) / 2),
    'hipCenter': hip,
    'shoulderL': _V3(-0.22, shoulder.y, shoulder.z),
    'shoulderR': _V3(0.22, shoulder.y, shoulder.z),
    'elbowL': _V3(-0.26, elbow.y, elbow.z),
    'elbowR': _V3(0.26, elbow.y, elbow.z),
    'wristL': _V3(-0.22, wrist.y, wrist.z),
    'wristR': _V3(0.22, wrist.y, wrist.z),
    'hipL': _V3(-0.12, hip.y, hip.z),
    'hipR': _V3(0.12, hip.y, hip.z),
    'kneeL': _V3(-0.14, knee.y, knee.z),
    'kneeR': _V3(0.14, knee.y, knee.z),
    'ankleL': _V3(-0.14, ankle.y, ankle.z),
    'ankleR': _V3(0.14, ankle.y, ankle.z),
  };
}

/// Rotacion 3D (yaw sobre Y, pitch sobre X) con pivote en el centro del torso.
_V3 _rotate(_V3 p, double yaw, double pitch) {
  const pivotY = 0.95;
  final x = p.x;
  final y = p.y - pivotY;
  final z = p.z;

  final cosY = math.cos(yaw);
  final sinY = math.sin(yaw);
  final x1 = x * cosY + z * sinY;
  final z1 = -x * sinY + z * cosY;

  final cosP = math.cos(pitch);
  final sinP = math.sin(pitch);
  final y2 = y * cosP - z1 * sinP;
  final z2 = y * sinP + z1 * cosP;

  return _V3(x1, y2, z2);
}

/// Proyeccion en perspectiva.
_Projected _project(_V3 p, Size size, double zoom) {
  const cameraDistance = 3.4;
  final depth = math.max(cameraDistance + p.z, 0.35);
  final scale = (size.height * 1.15 * zoom) / depth;
  final center = Offset(size.width / 2, size.height / 2);
  return _Projected(
    Offset(center.dx + p.x * scale, center.dy - p.y * scale),
    depth,
  );
}

/// Pintor que dibuja el esqueleto con orden por profundidad y sombreado.
class _SkeletonPainter extends CustomPainter {
  _SkeletonPainter({
    required this.animationKey,
    required this.phase,
    required this.yaw,
    required this.pitch,
    required this.zoom,
    required this.primaryBones,
    required this.secondaryBones,
  });

  final String animationKey;
  final double phase;
  final double yaw;
  final double pitch;
  final double zoom;
  final Set<String> primaryBones;
  final Set<String> secondaryBones;

  @override
  void paint(Canvas canvas, Size size) {
    final joints = _poseFor(animationKey, phase);

    final rotated = <String, _V3>{};
    joints.forEach((name, point) {
      rotated[name] = _rotate(point, yaw, pitch);
    });

    final projected = <String, _Projected>{};
    rotated.forEach((name, point) {
      projected[name] = _project(point, size, zoom);
    });

    _paintShadow(canvas, size, rotated);

    final bones = List<_Bone>.from(_skeleton)
      ..sort((a, b) {
        final depthA = (projected[a.a]!.depth + projected[a.b]!.depth) / 2;
        final depthB = (projected[b.a]!.depth + projected[b.b]!.depth) / 2;
        return depthB.compareTo(depthA);
      });

    for (final bone in bones) {
      final from = projected[bone.a];
      final to = projected[bone.b];
      if (from == null || to == null) continue;
      final averageDepth = (from.depth + to.depth) / 2;
      final shade = ((averageDepth - 2.5) / 1.8).clamp(0.0, 1.0);

      final isPrimary =
          primaryBones.contains(bone.a) || primaryBones.contains(bone.b);
      final isSecondary =
          secondaryBones.contains(bone.a) || secondaryBones.contains(bone.b);

      final Color color;
      if (isPrimary) {
        color = Color.lerp(
          const Color(0xFFB3241C),
          const Color(0xFFFF6B5B),
          1 - shade,
        )!;
      } else if (isSecondary) {
        color = Color.lerp(
          const Color(0xFF8A5A00),
          const Color(0xFFFFC24B),
          1 - shade,
        )!;
      } else {
        color = Color.lerp(
          const Color(0xFF14424A),
          const Color(0xFF8BE0C0),
          1 - shade,
        )!;
      }

      final width = bone.thickness *
          (size.height * 0.05) *
          zoom *
          (3.4 / averageDepth);

      canvas.drawLine(
        from.offset,
        to.offset,
        Paint()
          ..color = color
          ..strokeWidth = math.max(width, 3)
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }

    _paintJoints(canvas, size, projected, rotated);
  }

  void _paintShadow(Canvas canvas, Size size, Map<String, _V3> rotated) {
    final groundA = _project(_V3(-0.3, -0.98, 0), size, zoom);
    final groundB = _project(_V3(0.3, -0.98, 0), size, zoom);
    final radius = (groundB.offset.dx - groundA.offset.dx).abs() / 2;
    canvas.drawOval(
      Rect.fromCenter(
        center: groundA.offset,
        width: math.max(radius * 3.2, 24),
        height: math.max(radius * 0.95, 8),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
  }

  void _paintJoints(
    Canvas canvas,
    Size size,
    Map<String, _Projected> projected,
    Map<String, _V3> rotated,
  ) {
    void drawSphere(String name, double radiusFactor, Color base) {
      final point = projected[name];
      if (point == null) return;
      final shade = ((point.depth - 2.5) / 1.8).clamp(0.0, 1.0);
      final radius = radiusFactor * (size.height * 0.05) * zoom * (3.4 / point.depth);
      canvas.drawCircle(
        point.offset,
        math.max(radius, 3),
        Paint()..color = Color.lerp(base.withValues(alpha: 0.75), base, 1 - shade)!,
      );
    }

    drawSphere('head', 1.75, const Color(0xFF9BEBD2));
    drawSphere('wristL', 0.7, const Color(0xFF63C7AC));
    drawSphere('wristR', 0.7, const Color(0xFF63C7AC));
    drawSphere('ankleL', 0.75, const Color(0xFF63C7AC));
    drawSphere('ankleR', 0.75, const Color(0xFF63C7AC));
    drawSphere('hipCenter', 0.85, const Color(0xFF3E9E87));
  }

  @override
  bool shouldRepaint(covariant _SkeletonPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.yaw != yaw ||
        oldDelegate.pitch != pitch ||
        oldDelegate.zoom != zoom ||
        oldDelegate.animationKey != animationKey ||
        oldDelegate.primaryBones != primaryBones ||
        oldDelegate.secondaryBones != secondaryBones;
  }
}

/// Visor 3D interactivo de un ejercicio.
///
/// - Rotacion automatica continua.
/// - Arrastrar con un dedo para girar el modelo.
/// - Pellizcar con dos dedos para acercar o alejar.
class Exercise3DViewer extends StatefulWidget {
  const Exercise3DViewer({
    super.key,
    required this.animationKey,
    this.primaryMuscle,
    this.secondaryMuscle,
    this.height = 260,
    this.showMuscleLegend = true,
  });

  final String animationKey;
  final String? primaryMuscle;
  final String? secondaryMuscle;
  final double height;
  final bool showMuscleLegend;

  @override
  State<Exercise3DViewer> createState() => _Exercise3DViewerState();
}

class _Exercise3DViewerState extends State<Exercise3DViewer>
    with TickerProviderStateMixin {
  late final AnimationController _cycle;
  late final AnimationController _spin;

  double _yawOffset = 0;
  double _pitch = -0.12;
  double _zoom = 1;
  double _startZoom = 1;

  @override
  void initState() {
    super.initState();
    _cycle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _cycle.dispose();
    _spin.dispose();
    super.dispose();
  }

  void _onScaleStart(ScaleStartDetails details) {
    _startZoom = _zoom;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _yawOffset += details.focalPointDelta.dx * 0.012;
      _pitch = (_pitch + details.focalPointDelta.dy * 0.008).clamp(-0.7, 0.7);
      if (details.scale != 1.0) {
        _zoom = (_startZoom * details.scale).clamp(0.6, 2.2);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryBones =
        _highlightedBones(widget.primaryMuscle, MuscleGroup.primary);
    final secondaryBones =
        _highlightedBones(widget.secondaryMuscle, MuscleGroup.secondary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            gradient: const RadialGradient(
              colors: [Color(0xFF12303A), Color(0xFF070C16)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF173B45), width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: GestureDetector(
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              child: Stack(
                children: [
                  AnimatedBuilder(
                    animation: Listenable.merge([_cycle, _spin]),
                    builder: (context, _) {
                      final yaw = _yawOffset + _spin.value * 2 * math.pi;
                      return CustomPaint(
                        size: Size.infinite,
                        painter: _SkeletonPainter(
                          animationKey: widget.animationKey,
                          phase: _cycle.value,
                          yaw: yaw,
                          pitch: _pitch,
                          zoom: _zoom,
                          primaryBones: primaryBones,
                          secondaryBones: secondaryBones,
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF173B45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.threed_rotation_rounded,
                              size: 14, color: Color(0xFF8BE0C0)),
                          SizedBox(width: 4),
                          Text('3D interactivo',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Text(
                      'Arrastra para girar · Pellizca para zoom',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.showMuscleLegend) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if ((widget.primaryMuscle ?? '').isNotEmpty)
                Expanded(
                  child: Chip(
                    backgroundColor: const Color(0xFFFF3B30),
                    label: Text(
                      'Agonista: ${widget.primaryMuscle}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              if ((widget.secondaryMuscle ?? '').isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Chip(
                    backgroundColor: const Color(0xFFFF9500),
                    label: Text(
                      'Sinergista: ${widget.secondaryMuscle}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
