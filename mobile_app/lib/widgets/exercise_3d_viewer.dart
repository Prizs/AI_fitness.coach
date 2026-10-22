import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mobile_app/models/anatomy_exercise.dart';
import 'package:mobile_app/widgets/biomechanical_kinematics_view.dart';

/// Punto 3D con operaciones vectoriales.
class _V3 {
  const _V3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  _V3 operator +(_V3 other) => _V3(x + other.x, y + other.y, z + other.z);
  _V3 operator -(_V3 other) => _V3(x - other.x, y - other.y, z - other.z);
  _V3 operator *(double k) => _V3(x * k, y * k, z * k);
}

/// Punto 3D proyectado a 2D en pantalla.
class _Projected {
  const _Projected(this.offset, this.depth);

  final Offset offset;
  final double depth;
}

/// Segmento muscular o hueso conectando dos articulaciones.
class _Bone {
  const _Bone(this.a, this.b, this.thickness, {this.isTorso = false});

  final String a;
  final String b;
  final double thickness;
  final bool isTorso;
}

/// Estructura base del maniquí anatómico 3D.
const List<_Bone> _skeleton = [
  _Bone('neck', 'head', 1.25),
  _Bone('spineTop', 'neck', 1.1, isTorso: true),
  _Bone('spineMid', 'spineTop', 1.35, isTorso: true),
  _Bone('hipCenter', 'spineMid', 1.3, isTorso: true),
  _Bone('shoulderL', 'neck', 0.85, isTorso: true),
  _Bone('shoulderR', 'neck', 0.85, isTorso: true),
  _Bone('elbowL', 'shoulderL', 0.75),
  _Bone('elbowR', 'shoulderR', 0.75),
  _Bone('wristL', 'elbowL', 0.65),
  _Bone('wristR', 'elbowR', 0.65),
  _Bone('hipL', 'hipCenter', 0.9, isTorso: true),
  _Bone('hipR', 'hipCenter', 0.9, isTorso: true),
  _Bone('kneeL', 'hipL', 0.95),
  _Bone('kneeR', 'hipR', 0.95),
  _Bone('ankleL', 'kneeL', 0.75),
  _Bone('ankleR', 'kneeR', 0.75),
];

/// Rol del grupo muscular dentro del ejercicio.
enum MuscleGroup { primary, secondary, neutral }

/// Deduce los segmentos a iluminar según el músculo del ejercicio.
Set<String> _highlightedBones(String? muscleText, MuscleGroup role) {
  if (muscleText == null || muscleText.trim().isEmpty) return const {};
  final text = muscleText.toLowerCase();
  final bones = <String>{};

  if (text.contains('cuadriceps') ||
      text.contains('cuádriceps') ||
      text.contains('quad') ||
      text.contains('isquio') ||
      text.contains('femoral') ||
      text.contains('pierna')) {
    bones.addAll(['kneeL', 'kneeR', 'hipL', 'hipR']);
  }
  if (text.contains('glute') || text.contains('glúte') || text.contains('cadera')) {
    bones.addAll(['hipL', 'hipR', 'hipCenter']);
  }
  if (text.contains('pectoral') ||
      text.contains('pecho') ||
      text.contains('apertura') ||
      text.contains('fly') ||
      text.contains('empuje')) {
    bones.addAll(['shoulderL', 'shoulderR', 'spineTop', 'neck']);
  }
  if (text.contains('tricep') ||
      text.contains('trícep') ||
      text.contains('bicep') ||
      text.contains('bícep') ||
      text.contains('brazo')) {
    bones.addAll(['elbowL', 'elbowR', 'wristL', 'wristR']);
  }
  if (text.contains('hombro') ||
      text.contains('deltoid') ||
      text.contains('militar') ||
      text.contains('lateral')) {
    bones.addAll(['shoulderL', 'shoulderR', 'neck', 'elbowL', 'elbowR']);
  }
  if (text.contains('core') ||
      text.contains('abdom') ||
      text.contains('lumbar') ||
      text.contains('espalda') ||
      text.contains('dorsal') ||
      text.contains('remo') ||
      text.contains('jalon') ||
      text.contains('jalón') ||
      text.contains('tiron') ||
      text.contains('tirón')) {
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

/// Genera la pose cinemática y articular en 3D para la animación en fase [t] (0.0 a 1.0).
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
  double wristZ = 0;

  // 1. SENTADILLAS / PIERNAS
  if (key.contains('squat') || key.contains('sentadilla')) {
    final drop = 0.44 * phase;
    hipY -= drop;
    kneeY -= drop * 0.35;
    kneeZ += 0.30 * phase;
    hipZ -= 0.08 * phase;
    torsoLean = 0.38 * phase;
    shoulderY -= drop;
    elbowY -= drop;
    wristY -= drop;
    armZ = -0.15 * phase;
    armSpread = 0.22;
  }
  // 2. FLEXIONES / PUSH-UPS
  else if (key.contains('push-up') ||
      key.contains('pushup') ||
      key.contains('flexion') ||
      key.contains('flexión')) {
    return _horizontalBody(
      armAngle: 1.35 - 0.85 * phase,
      legAngle: 1.45,
      headLift: 0.35,
    );
  }
  // 3. PLANCHAS / ISOMETRÍAS
  else if (key.contains('plank') || key.contains('plancha')) {
    return _horizontalBody(
      armAngle: 1.5,
      legAngle: 1.5,
      headLift: 0.2,
      forearmDown: true,
    );
  }
  // 4. PRESS DE PECHO / PRESS DE BANCA / APERTURAS
  else if (key.contains('bench') ||
      key.contains('press_pecho') ||
      key.contains('apertura') ||
      key.contains('pec') ||
      key.contains('fly')) {
    // Maniquí sentado empujando hacia adelante con flexión/aducción horizontal
    final push = phase;
    armSpread = 0.42 - 0.24 * push;
    armZ = -0.05 + 0.38 * push;
    elbowY = 1.28 + 0.05 * push;
    wristY = 1.26 + 0.06 * push;
  }
  // 5. BÍCEPS / CURL
  else if (key.contains('bicep') || key.contains('bícep') || key.contains('curl')) {
    final curl = phase;
    elbowY = 1.18;
    wristY = 0.95 + 0.42 * curl;
    wristZ = 0.08 + 0.28 * curl;
    armSpread = 0.22;
  }
  // 6. TRÍCEPS / FONDOS / EXTENSIÓN
  else if (key.contains('tricep') || key.contains('trícep') || key.contains('fondo') || key.contains('dip')) {
    final ext = phase;
    elbowY = 1.25 + 0.10 * ext;
    wristY = 1.30 - 0.40 * ext;
    wristZ = 0.12 - 0.24 * ext;
    armSpread = 0.25;
  }
  // 7. HOMBROS / PRESS MILITAR / ELEVACIONES
  else if (key.contains('shoulder') ||
      key.contains('hombro') ||
      key.contains('military') ||
      key.contains('militar') ||
      key.contains('lateral') ||
      key.contains('pajaro') ||
      key.contains('pájaro')) {
    final push = phase;
    shoulderY += 0.03 * push;
    elbowY = 1.25 + 0.26 * push;
    wristY = 1.18 + 0.52 * push;
    armSpread = 0.22 + 0.14 * push;
  }
  // 8. ESPALDA / REMO / JALÓN / PULLDOWN
  else if (key.contains('row') ||
      key.contains('remo') ||
      key.contains('jalon') ||
      key.contains('jalón') ||
      key.contains('pulldown') ||
      key.contains('espalda') ||
      key.contains('dorsal')) {
    final pull = phase;
    torsoLean = 0.25 * pull;
    elbowY = 1.45 - 0.32 * pull;
    wristY = 1.60 - 0.45 * pull;
    armSpread = 0.36 - 0.12 * pull;
    armZ = 0.25 - 0.35 * pull;
  }
  // 9. ZANCADAS / LUNGES
  else if (key.contains('lunge') || key.contains('zancada')) {
    final step = phase;
    hipY -= 0.22 * step;
    kneeY -= 0.12 * step;
    kneeZ += 0.35 * step;
    ankleZ += 0.50 * step;
    shoulderY -= 0.20 * step;
    elbowY -= 0.18 * step;
    wristY -= 0.15 * step;
    armZ = -0.18 * step;
    armSpread = 0.14;
    torsoLean = 0.14 * step;
  }
  // 10. JUMPING JACKS
  else if (key.contains('jump') || key.contains('jack')) {
    final open = phase;
    shoulderY += 0.05 * open;
    elbowY = 1.34 + 0.32 * open;
    wristY = 1.28 + 0.48 * open;
    armSpread = 0.24 + 0.22 * open;
    kneeZ += 0.26 * open;
    ankleZ += 0.30 * open;
  }
  // 11. CAMINATA / RUN
  else if (key.contains('walk') ||
      key.contains('caminata') ||
      key.contains('jog') ||
      key.contains('trot') ||
      key.contains('run')) {
    final swing = math.sin(t * 2 * math.pi);
    kneeZ += 0.24 * swing;
    ankleZ += 0.32 * swing;
    armZ = -0.20 * swing;
    elbowY += 0.06 * swing;
  }
  // DEFAULT: RESPIRACIÓN Y CONTRACCIÓN BASE
  else {
    final breathing = math.sin(t * 2 * math.pi);
    shoulderY += 0.015 * breathing;
    armZ = 0.06 * breathing;
    kneeZ += 0.03 * phase;
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
      -0.22,
      leaned(shoulderY, shoulderY) + 0.04,
      hipZ + torsoLean * 0.12,
    ),
    'shoulderR': _V3(
      0.22,
      leaned(shoulderY, shoulderY) + 0.04,
      hipZ + torsoLean * 0.12,
    ),
    'elbowL': _V3(-armSpread, leaned(elbowY, elbowY) + 0.02, armZ),
    'elbowR': _V3(armSpread, leaned(elbowY, elbowY) + 0.02, armZ),
    'wristL': _V3(-armSpread - 0.04, leaned(wristY, wristY), wristZ != 0 ? wristZ : armZ * 1.3),
    'wristR': _V3(armSpread + 0.04, leaned(wristY, wristY), wristZ != 0 ? wristZ : armZ * 1.3),
    'hipL': _V3(-0.13, hipY, hipZ),
    'hipR': _V3(0.13, hipY, hipZ),
    'kneeL': _V3(-0.14, kneeY, kneeZ),
    'kneeR': _V3(0.14, kneeY, kneeZ),
    'ankleL': _V3(-0.14, ankleY, ankleZ),
    'ankleR': _V3(0.14, ankleY, ankleZ),
  };
}

/// Cuerpo horizontal usado en flexiones y planchas.
Map<String, _V3> _horizontalBody({
  required double armAngle,
  required double legAngle,
  required double headLift,
  bool forearmDown = false,
  double legDrive = 0,
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
    (shoulder.y + wrist.y) / 2 + (forearmDown ? -0.05 : 0.08),
    (shoulder.z + wrist.z) / 2 - 0.12,
  );

  final feet = _V3(
    0,
    hip.y - math.cos(legAngle) * 0.95,
    hip.z - math.sin(legAngle) * 0.95,
  );
  final knee = _V3(
    0,
    (hip.y + feet.y) / 2 + 0.05 * legDrive,
    (hip.z + feet.z) / 2 + 0.12 * legDrive,
  );

  return {
    'head': head,
    'neck': _V3(0, shoulder.y + 0.04, shoulder.z + 0.06),
    'spineTop': shoulder,
    'spineMid': _V3(0, (shoulder.y + hip.y) / 2, (shoulder.z + hip.z) / 2),
    'hipCenter': hip,
    'shoulderL': _V3(-0.22, shoulder.y, shoulder.z),
    'shoulderR': _V3(0.22, shoulder.y, shoulder.z),
    'elbowL': _V3(-0.34, elbow.y, elbow.z),
    'elbowR': _V3(0.34, elbow.y, elbow.z),
    'wristL': _V3(-0.30, wrist.y, wrist.z),
    'wristR': _V3(0.30, wrist.y, wrist.z),
    'hipL': _V3(-0.13, hip.y, hip.z),
    'hipR': _V3(0.13, hip.y, hip.z),
    'kneeL': _V3(-0.14, knee.y, knee.z),
    'kneeR': _V3(0.14, knee.y, knee.z),
    'ankleL': _V3(-0.14, feet.y, feet.z),
    'ankleR': _V3(0.14, feet.y, feet.z),
  };
}

/// Rotación 3D alrededor de los ejes Y (yaw) y X (pitch).
_V3 _rotate(_V3 p, double yaw, double pitch) {
  final cosY = math.cos(yaw);
  final sinY = math.sin(yaw);
  final x1 = p.x * cosY + p.z * sinY;
  final z1 = -p.x * sinY + p.z * cosY;

  final cosP = math.cos(pitch);
  final sinP = math.sin(pitch);
  final y2 = p.y * cosP - z1 * sinP;
  final z2 = p.y * sinP + z1 * cosP;

  return _V3(x1, y2, z2);
}

/// Proyección en perspectiva hacia la pantalla.
_Projected _project(_V3 p, Size size, double zoom) {
  const cameraDistance = 3.4;
  final depth = cameraDistance + p.z;
  final perspective = cameraDistance / math.max(depth, 0.4);

  final scale = size.height * 0.46 * zoom * perspective;
  final centerX = size.width / 2;
  final centerY = size.height * 0.58;

  final screenX = centerX + p.x * scale;
  final screenY = centerY - (p.y - 0.75) * scale;

  return _Projected(Offset(screenX, screenY), depth);
}

/// Pintor 3D de alta fidelidad: dibuja el maniquí anatómico con volúmenes sombreados,
/// cápsulas musculares, destellos luminiscentes y goniómetro articular en vivo.
class _VolumetricSkeletonPainter extends CustomPainter {
  const _VolumetricSkeletonPainter({
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
    final rawPose = _poseFor(animationKey, phase);

    final rotated = <String, _V3>{};
    final projected = <String, _Projected>{};
    rawPose.forEach((k, v) {
      final r = _rotate(v, yaw, pitch);
      rotated[k] = r;
      projected[k] = _project(r, size, zoom);
    });

    // 1. Piso 3D Sci-Fi con cuadrícula en perspectiva
    _paintPerspectiveFloor(canvas, size);

    // 2. Sombra de contacto
    _paintContactShadow(canvas, size, projected);

    // 3. Volúmenes del torso anatómico (Pectorales y Abdomen)
    _paintAnatomicalTorso(canvas, size, projected);

    // 4. Extremidades musculares cilíndricas volumétricas
    _paintVolumetricLimbs(canvas, size, projected);

    // 5. Cabeza y Articulaciones con sombreado esférico
    _paintAnatomicalJoints(canvas, size, projected);

    // 6. Goniómetro Biomecánico proyectado en 3D sobre la articulación clave
    _paintLive3dGoniometer(canvas, size, projected);
  }

  void _paintPerspectiveFloor(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF16253B).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final centerY = size.height * 0.88;
    final centerX = size.width / 2;

    for (int r = 1; r <= 3; r++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX, centerY),
          width: r * (size.width * 0.28) * zoom,
          height: r * (size.height * 0.08) * zoom,
        ),
        gridPaint,
      );
    }
  }

  void _paintContactShadow(Canvas canvas, Size size, Map<String, _Projected> projected) {
    final hip = projected['hipCenter'];
    if (hip == null) return;

    final centerY = size.height * 0.88;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(hip.offset.dx, centerY),
        width: 110 * zoom,
        height: 22 * zoom,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );
  }

  void _paintAnatomicalTorso(Canvas canvas, Size size, Map<String, _Projected> projected) {
    final neck = projected['neck'];
    final sL = projected['shoulderL'];
    final sR = projected['shoulderR'];
    final sMid = projected['spineMid'];
    final hipL = projected['hipL'];
    final hipR = projected['hipR'];

    if (neck == null || sL == null || sR == null || sMid == null || hipL == null || hipR == null) return;

    final isChestActive = primaryBones.contains('spineTop') || primaryBones.contains('shoulderL');

    // Polígono de la caja torácica (Pectorales / Pecho)
    final chestPath = Path()
      ..moveTo(neck.offset.dx, neck.offset.dy)
      ..lineTo(sL.offset.dx, sL.offset.dy)
      ..lineTo(sMid.offset.dx, sMid.offset.dy)
      ..lineTo(sR.offset.dx, sR.offset.dy)
      ..close();

    final chestPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isChestActive
            ? [const Color(0xFFFF5252), const Color(0xFFB3241C)]
            : [const Color(0xFF2C5665), const Color(0xFF132B34)],
      ).createShader(chestPath.getBounds())
      ..style = PaintingStyle.fill;

    canvas.drawPath(chestPath, chestPaint);

    // Resplandor si está activo
    if (isChestActive) {
      canvas.drawPath(
        chestPath,
        Paint()
          ..color = const Color(0xFFFF3B30).withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
      );
    }

    // Polígono del Core / Abdomen
    final corePath = Path()
      ..moveTo(sL.offset.dx, sL.offset.dy)
      ..lineTo(hipL.offset.dx, hipL.offset.dy)
      ..lineTo(hipR.offset.dx, hipR.offset.dy)
      ..lineTo(sR.offset.dx, sR.offset.dy)
      ..lineTo(sMid.offset.dx, sMid.offset.dy)
      ..close();

    canvas.drawPath(
      corePath,
      Paint()
        ..color = const Color(0xFF0F222B).withValues(alpha: 0.85)
        ..style = PaintingStyle.fill,
    );
  }

  void _paintVolumetricLimbs(Canvas canvas, Size size, Map<String, _Projected> projected) {
    // Ordenar de atrás hacia adelante por profundidad
    final sortedBones = List<_Bone>.from(_skeleton)
      ..sort((a, b) {
        final dA = (projected[a.a]?.depth ?? 3) + (projected[a.b]?.depth ?? 3);
        final dB = (projected[b.a]?.depth ?? 3) + (projected[b.b]?.depth ?? 3);
        return dB.compareTo(dA);
      });

    for (final bone in sortedBones) {
      final from = projected[bone.a];
      final to = projected[bone.b];
      if (from == null || to == null) continue;

      final isPrimary = primaryBones.contains(bone.a) || primaryBones.contains(bone.b);
      final isSecondary = secondaryBones.contains(bone.a) || secondaryBones.contains(bone.b);

      final avgDepth = (from.depth + to.depth) / 2;
      final limbWidth = bone.thickness * (size.height * 0.046) * zoom * (3.4 / avgDepth);

      final dir = to.offset - from.offset;
      final len = dir.distance;
      if (len < 1) continue;

      final normal = Offset(-dir.dy / len, dir.dx / len);

      // Trazo volumétrico fusiforme (más grueso en el vientre muscular)
      final mid = Offset((from.offset.dx + to.offset.dx) / 2, (from.offset.dy + to.offset.dy) / 2);
      final rEnd = limbWidth * 0.45;
      final rBelly = limbWidth * 0.70;

      final musclePath = Path()
        ..moveTo(from.offset.dx - normal.dx * rEnd, from.offset.dy - normal.dy * rEnd)
        ..lineTo(mid.dx - normal.dx * rBelly, mid.dy - normal.dy * rBelly)
        ..lineTo(to.offset.dx - normal.dx * rEnd, to.offset.dy - normal.dy * rEnd)
        ..lineTo(to.offset.dx + normal.dx * rEnd, to.offset.dy + normal.dy * rEnd)
        ..lineTo(mid.dx + normal.dx * rBelly, mid.dy + normal.dy * rBelly)
        ..lineTo(from.offset.dx + normal.dx * rEnd, from.offset.dy + normal.dy * rEnd)
        ..close();

      final Color lightColor;
      final Color darkColor;

      if (isPrimary) {
        lightColor = const Color(0xFFFF6B6B);
        darkColor = const Color(0xFFC91A1A);
      } else if (isSecondary) {
        lightColor = const Color(0xFFFFD166);
        darkColor = const Color(0xFFB37400);
      } else {
        lightColor = const Color(0xFF8BE0C0);
        darkColor = const Color(0xFF123C42);
      }

      final limbPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [lightColor, darkColor],
        ).createShader(musclePath.getBounds())
        ..style = PaintingStyle.fill;

      canvas.drawPath(musclePath, limbPaint);

      // Resplandor muscular para el agonista
      if (isPrimary) {
        canvas.drawPath(
          musclePath,
          Paint()
            ..color = const Color(0xFFFF3B30).withValues(alpha: 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
        );
      }
    }
  }

  void _paintAnatomicalJoints(Canvas canvas, Size size, Map<String, _Projected> projected) {
    void drawSphere(String name, double factor, Color color) {
      final p = projected[name];
      if (p == null) return;
      final r = factor * (size.height * 0.045) * zoom * (3.4 / p.depth);

      // Sombreado radial 3D (highlight especular)
      final paint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          radius: 0.85,
          colors: [Colors.white.withValues(alpha: 0.9), color, color.withValues(alpha: 0.7)],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: p.offset, radius: r));

      canvas.drawCircle(p.offset, math.max(r, 4.0), paint);
    }

    drawSphere('head', 1.85, const Color(0xFF8BE0C0));
    drawSphere('shoulderL', 0.85, const Color(0xFF64B5F6));
    drawSphere('shoulderR', 0.85, const Color(0xFF64B5F6));
    drawSphere('elbowL', 0.70, const Color(0xFF8BE0C0));
    drawSphere('elbowR', 0.70, const Color(0xFF8BE0C0));
    drawSphere('wristL', 0.65, const Color(0xFF8BE0C0));
    drawSphere('wristR', 0.65, const Color(0xFF8BE0C0));
    drawSphere('hipL', 0.85, const Color(0xFF64B5F6));
    drawSphere('hipR', 0.85, const Color(0xFF64B5F6));
    drawSphere('kneeL', 0.85, const Color(0xFF8BE0C0));
    drawSphere('kneeR', 0.85, const Color(0xFF8BE0C0));
    drawSphere('ankleL', 0.70, const Color(0xFF8BE0C0));
    drawSphere('ankleR', 0.70, const Color(0xFF8BE0C0));
  }

  void _paintLive3dGoniometer(Canvas canvas, Size size, Map<String, _Projected> projected) {
    // Localiza la articulación activa
    String targetJoint = 'elbowR';
    if (animationKey.contains('squat') || animationKey.contains('lunge')) {
      targetJoint = 'kneeR';
    } else if (animationKey.contains('shoulder')) {
      targetJoint = 'shoulderR';
    }

    final joint = projected[targetJoint];
    if (joint == null) return;

    final angleDegrees = 50 + (phase * 40).round();
    final center = joint.offset;

    // Arco de goniómetro holográfico en 3D
    final arcRect = Rect.fromCircle(center: center, radius: 24 * zoom);
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      math.pi * phase,
      false,
      Paint()
        ..color = const Color(0xFF64B5F6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );

    // Texto de grados digitales
    final textSpan = TextSpan(
      text: '$angleDegrees°',
      style: const TextStyle(
        color: Color(0xFF8BE0C0),
        fontSize: 11,
        fontWeight: FontWeight.w900,
        backgroundColor: Color(0xCC070C16),
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(center.dx + 16, center.dy - 12));
  }

  @override
  bool shouldRepaint(covariant _VolumetricSkeletonPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.yaw != yaw ||
        oldDelegate.pitch != pitch ||
        oldDelegate.zoom != zoom ||
        oldDelegate.animationKey != animationKey;
  }
}

/// Visor 3D interactivo con el muñeco animado en tiempo real haciendo el ejercicio.
/// Incluye telemetría HUD biomecánica, control táctil 360° y botón para ver la curva de torque.
class Exercise3DViewer extends StatefulWidget {
  const Exercise3DViewer({
    super.key,
    required this.animationKey,
    this.primaryMuscle,
    this.secondaryMuscle,
    this.height = 320,
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

class _Exercise3DViewerState extends State<Exercise3DViewer> with TickerProviderStateMixin {
  late final AnimationController _cycle;
  late final AnimationController _spin;

  double _yawOffset = 0;
  double _pitch = -0.08;
  double _zoom = 1.05;
  double _startZoom = 1.0;
  bool _autoSpin = true;

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
    setState(() => _autoSpin = false);
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

  void _showBiomechanicalDialog(BuildContext context) {
    // Genera ejercicio dummy para resolver datos cinemáticos
    final dummyEx = AnatomyExercise(
      id: widget.animationKey,
      name: widget.animationKey,
      shortName: widget.animationKey,
      agonist: widget.primaryMuscle ?? 'Músculo Principal',
      synergists: widget.secondaryMuscle != null ? [widget.secondaryMuscle!] : [],
      biomechanics: 'Análisis cinemático del patrón motor.',
      tempo: '2s concéntrico · 2s excéntrico',
      posture: 'Espalda neutra y alineación articular óptima.',
      warning: 'Controlar el rango de movimiento seguro.',
      gifUrl: '',
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF070C16),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SizedBox(
          height: 380,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.insights_rounded, color: Color(0xFF64B5F6), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Análisis Físico & Curva de Torque',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: BiomechanicalKinematicsView(
                  exercise: dummyEx,
                  height: 320,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryBones = _highlightedBones(widget.primaryMuscle, MuscleGroup.primary);
    final secondaryBones = _highlightedBones(widget.secondaryMuscle, MuscleGroup.secondary);

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFF070C16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF173B45), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: GestureDetector(
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Canvas 3D con el muñeco haciendo el ejercicio
              AnimatedBuilder(
                animation: Listenable.merge([_cycle, _spin]),
                builder: (context, _) {
                  final yaw = _yawOffset + (_autoSpin ? _spin.value * 2 * math.pi : 0.0);
                  return CustomPaint(
                    size: Size.infinite,
                    painter: _VolumetricSkeletonPainter(
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

              // HUD Superior: 3D interactivo y fase concéntrica/excéntrica
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xDD0F192B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF64B5F6).withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.view_in_ar_rounded, size: 13, color: Color(0xFF64B5F6)),
                          SizedBox(width: 4),
                          Text(
                            '3D interactivo',
                            style: TextStyle(
                              color: Color(0xFF64B5F6),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Indicador de fase dinámico
                    AnimatedBuilder(
                      animation: _cycle,
                      builder: (context, _) {
                        final isConcentric = _cycle.status == AnimationStatus.forward;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isConcentric ? const Color(0xDD10281F) : const Color(0xDD281910),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isConcentric ? const Color(0xFF8BE0C0) : const Color(0xFFFFB340),
                            ),
                          ),
                          child: Text(
                            isConcentric ? 'FASE CONCÉNTRICA' : 'FASE EXCÉNTRICA',
                            style: TextStyle(
                              color: isConcentric ? const Color(0xFF8BE0C0) : const Color(0xFFFFB340),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    // Botón para ver diagnóstico físico y torque
                    IconButton(
                      tooltip: 'Ver Curva de Torque & Kinesiología',
                      icon: const Icon(Icons.analytics_rounded, color: Color(0xFFFFB340), size: 20),
                      onPressed: () => _showBiomechanicalDialog(context),
                    ),
                  ],
                ),
              ),

              // Leyenda Inferior de Músculos Activos (Requerida para tests y didáctica)
              if (widget.showMuscleLegend)
                Positioned(
                  bottom: 8,
                  left: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xDD0B1220),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF1E2D42)),
                    ),
                    child: Row(
                      children: [
                        if (widget.primaryMuscle != null) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF3B30),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Agonista: ${widget.primaryMuscle}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (widget.secondaryMuscle != null) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFC24B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Sinergista: ${widget.secondaryMuscle}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                        ],
                        const Text(
                          'Giro 360°',
                          style: TextStyle(color: Colors.white38, fontSize: 9.5),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
