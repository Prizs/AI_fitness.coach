import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/widgets/exercise_3d_viewer.dart';

void main() {
  testWidgets('el visor 3D muestra los musculos y la leyenda', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Exercise3DViewer(
            animationKey: 'squat',
            primaryMuscle: 'Cuádriceps',
            secondaryMuscle: 'Glúteos',
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('3D interactivo'), findsOneWidget);
    expect(find.text('Agonista: Cuádriceps'), findsOneWidget);
    expect(find.text('Sinergista: Glúteos'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Se desmonta para detener los tickers de animacion.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('todas las animaciones se renderizan sin error', (tester) async {
    const keys = [
      'squat',
      'push-up',
      'incline-push-up',
      'front-plank',
      'bench-press',
      'row-intervals',
      'walk',
      'generic-exercise',
      'clave-desconocida',
    ];

    for (final key in keys) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Exercise3DViewer(animationKey: key)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.takeException(), isNull, reason: 'fallo con $key');
    }

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('se puede ocultar la leyenda de musculos', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Exercise3DViewer(
            animationKey: 'squat',
            primaryMuscle: 'Pectoral',
            showMuscleLegend: false,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 60));

    expect(find.text('Agonista: Pectoral'), findsNothing);
    expect(find.text('3D interactivo'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
