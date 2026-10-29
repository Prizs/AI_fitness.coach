import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/screens/auth/register_screen.dart';

void main() {
  testWidgets('validadores y formatters de registro funcionan correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterScreen(
          onRegisterSuccess: () {},
          onBackToLogin: () {},
        ),
      ),
    );

    // 1. Cedula: escribir letras y numeros, solo deben quedar los numeros
    final cedulaField = find.widgetWithText(TextFormField, 'Cédula venezolana');
    expect(cedulaField, findsOneWidget);
    await tester.enterText(cedulaField, 'V123abc456!@#');
    await tester.pump();
    final cedulaWidget = tester.widget<TextFormField>(cedulaField);
    expect(cedulaWidget.controller!.text, '123456');

    // 2. Nombre: escribir numeros y simbolos, solo deben quedar letras y espacios
    final nombreField = find.widgetWithText(TextFormField, 'Nombre');
    expect(nombreField, findsOneWidget);
    await tester.enterText(nombreField, 'Juan123 Carlos!@#');
    await tester.pump();
    final nombreWidget = tester.widget<TextFormField>(nombreField);
    expect(nombreWidget.controller!.text, 'Juan Carlos');

    // 3. Apellido: escribir numeros y simbolos, solo deben quedar letras y espacios
    final apellidoField = find.widgetWithText(TextFormField, 'Apellido');
    expect(apellidoField, findsOneWidget);
    await tester.enterText(apellidoField, 'Pérez99 ##Gómez');
    await tester.pump();
    final apellidoWidget = tester.widget<TextFormField>(apellidoField);
    expect(apellidoWidget.controller!.text, 'Pérez Gómez');

    // 4. Edad: escribir letras y numeros, solo deben quedar numeros
    final edadField = find.widgetWithText(TextFormField, 'Edad');
    expect(edadField, findsOneWidget);
    await tester.enterText(edadField, 'abc25xyz');
    await tester.pump();
    final edadWidget = tester.widget<TextFormField>(edadField);
    expect(edadWidget.controller!.text, '25');

    // 5. Contraseña: debe permitir letras, números y caracteres especiales
    final passField = find.widgetWithText(TextFormField, 'Contraseña');
    expect(passField, findsOneWidget);
    await tester.enterText(passField, 'MiClave#2026_Segura!');
    await tester.pump();
    final passWidget = tester.widget<TextFormField>(passField);
    expect(passWidget.controller!.text, 'MiClave#2026_Segura!');
  });
}
