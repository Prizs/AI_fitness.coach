import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/anatomy_exercise.dart';
import 'package:mobile_app/screens/anatomy_workout_screen.dart';

void main() {
  // El visor 3D real usa un WebView que no existe en el entorno de test, asi
  // que se sustituye por un marcador para poder probar el resto de la pantalla.
  Widget stubViewer(
    BuildContext context,
    AnatomyExercise exercise,
    bool autoRotate,
  ) {
    return const ColoredBox(color: Color(0xFF000000));
  }

  test('los cuatro ejercicios de demostracion estan completos', () {
    expect(kAnatomyExercises.length, 4);
    for (final exercise in kAnatomyExercises) {
      expect(exercise.agonist, isNotEmpty);
      expect(exercise.synergists, isNotEmpty);
      expect(exercise.biomechanics, isNotEmpty);
      expect(exercise.tempo, isNotEmpty);
      expect(exercise.posture, isNotEmpty);
      expect(exercise.warning, isNotEmpty);
    }
  });

  test('cada ejercicio tiene un agonista distinto', () {
    final agonistas = kAnatomyExercises.map((e) => e.agonist).toSet();
    expect(agonistas.length, kAnatomyExercises.length);
  });

  testWidgets('la pantalla muestra el titulo y el agonista', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AnatomyWorkoutScreen(initialExerciseId: 'squat', viewerBuilder: stubViewer),
    ));
    await tester.pump();

    expect(find.text('Sentadilla Profunda con Barra'), findsOneWidget);
    // El agonista de la sentadilla se ve en el chip rojo.
    expect(find.text('Cuadriceps'), findsOneWidget);
  });

  testWidgets('cambiar de ejercicio actualiza el foco muscular', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AnatomyWorkoutScreen(initialExerciseId: 'squat', viewerBuilder: stubViewer),
    ));
    await tester.pump();

    await tester.tap(find.text('Peso Muerto'));
    await tester.pumpAndSettle();

    // Ahora manda el isquiotibial, no el cuadriceps.
    expect(find.text('Peso Muerto con Barra'), findsOneWidget);
    expect(find.text('Isquiotibiales'), findsOneWidget);
  });

  testWidgets('el panel muestra los indicadores biomecanicos', (tester) async {
    // Se agranda la superficie para que la hoja desplegada quepa entera.
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: AnatomyWorkoutScreen(viewerBuilder: stubViewer),
    ));
    await tester.pump();

    expect(find.text('Indicadores biomecanicos'), findsOneWidget);
    expect(find.text('Tempo recomendado'), findsOneWidget);
    expect(find.text('Nota postural'), findsOneWidget);
    expect(find.text('Prevencion de lesiones'), findsOneWidget);
  });

  testWidgets('el boton alterna la autorrotacion', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AnatomyWorkoutScreen(viewerBuilder: stubViewer),
    ));
    await tester.pump();

    expect(find.byIcon(Icons.threesixty_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.threesixty_rounded));
    await tester.pump();
    expect(find.byIcon(Icons.rotate_right_rounded), findsOneWidget);
  });
}
