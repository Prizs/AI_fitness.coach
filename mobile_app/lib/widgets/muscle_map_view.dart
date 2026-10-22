import 'package:flutter/material.dart';
import 'package:flutter_body_atlas/flutter_body_atlas.dart';
import 'package:mobile_app/services/muscle_map.dart';

/// Vista anatomica del cuerpo humano con los musculos del ejercicio resaltados.
///
/// Usa el atlas SVG de `flutter_body_atlas`, que se carga de inmediato (los
/// assets van dentro de la app) y por eso no afecta la velocidad de carga.
/// El agonista se pinta de rojo y el sinergista de ambar.
class MuscleMapView extends StatefulWidget {
  const MuscleMapView({
    super.key,
    this.primaryMuscle,
    this.secondaryMuscle,
    this.height = 340,
  });

  final String? primaryMuscle;
  final String? secondaryMuscle;
  final double height;

  @override
  State<MuscleMapView> createState() => _MuscleMapViewState();
}

class _MuscleMapViewState extends State<MuscleMapView> {
  bool _showBack = false;
  String? _tapped;

  @override
  void initState() {
    super.initState();
    _determineInitialView();
  }

  @override
  void didUpdateWidget(covariant MuscleMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.primaryMuscle != widget.primaryMuscle) {
      _determineInitialView();
    }
  }

  void _determineInitialView() {
    final m = (widget.primaryMuscle ?? '').toLowerCase();
    if (m.contains('dorsal') ||
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
        m.contains('pájaro')) {
      _showBack = true;
    } else {
      _showBack = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = MuscleMap.idsFor(widget.primaryMuscle);
    final secondary = MuscleMap.idsFor(widget.secondaryMuscle)
      ..removeAll(primary);

    final colorMapping = <MuscleInfo, Color>{};
    for (final id in primary) {
      final info = MuscleCatalog.tryById(id);
      if (info != null) colorMapping[info] = const Color(0xFFFF3B30);
    }
    for (final id in secondary) {
      final info = MuscleCatalog.tryById(id);
      if (info != null) colorMapping[info] = const Color(0xFFFFC24B);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Vista frontal', style: TextStyle(fontSize: 11)),
                    icon: Icon(Icons.accessibility_new_rounded, size: 15),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Vista posterior', style: TextStyle(fontSize: 11)),
                    icon: Icon(Icons.back_hand_outlined, size: 15),
                  ),
                ],
                selected: {_showBack},
                onSelectionChanged: (selection) {
                  setState(() => _showBack = selection.first);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF0F192B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF173B45), width: 1.2),
            ),
            child: colorMapping.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Este ejercicio no tiene músculos destacados.\nToca la vista frontal o posterior para explorar la anatomía.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ),
                  )
                : BodyAtlasView<MuscleInfo>(
                    view: _showBack
                        ? AtlasAsset.musclesBack
                        : AtlasAsset.musclesFront,
                    resolver: const MuscleResolver(),
                    colorMapping: colorMapping,
                    onTapElement: (muscle) {
                      setState(() => _tapped = muscle.displayName);
                    },
                  ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 34,
          child: _tapped == null
              ? const Center(
                  child: Text(
                    'Toca un musculo para ver su nombre',
                    style: TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                )
              : Center(
                  child: Text(
                    _tapped!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8BE0C0),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ),
        if (colorMapping.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(
                color: const Color(0xFFFF3B30),
                label: 'Agonista: ${widget.primaryMuscle ?? '-'}',
              ),
              const SizedBox(width: 12),
              _LegendDot(
                color: const Color(0xFFFFC24B),
                label: 'Sinergista: ${widget.secondaryMuscle ?? '-'}',
              ),
            ],
          ),
        ],
        const SizedBox(height: 6),
        const Center(
          child: Text(
            'Atlas anatomico CC BY 4.0 - Ryan Graves',
            style: TextStyle(fontSize: 9, color: Colors.white24),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
