// Smoke test: verifica que la pantalla de login se construye correctamente.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aries_mobile/core/di/injection.dart';
import 'package:aries_mobile/features/auth/presentation/pages/login_page.dart';

void main() {
  testWidgets('LoginPage muestra el formulario de inicio de sesión', (WidgetTester tester) async {
    await configureDependencies();

    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    // La carga de empresas intenta una llamada de red real que no está
    // disponible en el entorno de test; se avanza el reloj simulado hasta
    // que expire su connectTimeout (15s) para que quede resuelta.
    await tester.pump(const Duration(seconds: 16));

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });
}
