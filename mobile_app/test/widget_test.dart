// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_app/main.dart';

void main() {
  testWidgets('login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const AiFitnessCoachApp());

    expect(find.text('Tu plan empieza aquí'), findsOneWidget);
    expect(find.text('Cédula venezolana'), findsOneWidget);
    expect(find.text('Entrar a entrenar'), findsOneWidget);
  });
}
