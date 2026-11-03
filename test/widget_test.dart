import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:xabal_gestiona/config/theme.dart';
import 'package:xabal_gestiona/providers/auth_provider.dart';
import 'package:xabal_gestiona/screens/login/login_screen.dart';

Widget _appLogin() {
  return ChangeNotifierProvider<AuthProvider>(
    create: (_) => AuthProvider(),
    child: MaterialApp(
      theme: AppTheme.light,
      home: const LoginScreen(),
    ),
  );
}

void main() {
  testWidgets('HU01: el login muestra los campos requeridos',
      (WidgetTester tester) async {
    await tester.pumpWidget(_appLogin());
    await tester.pump();

    expect(find.text('Usuario'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Dominio UCi'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
    // El dominio viene predefinido y no es editable.
    expect(find.text('gestiona.uci.cu'), findsOneWidget);
  });

  testWidgets('HU01: el botón se habilita al completar usuario y contraseña',
      (WidgetTester tester) async {
    await tester.pumpWidget(_appLogin());
    await tester.pump();

    ElevatedButton boton() =>
        tester.widget<ElevatedButton>(find.byType(ElevatedButton));

    expect(boton().onPressed, isNull);

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'usuario');
    await tester.pump();
    expect(boton().onPressed, isNull, reason: 'Falta la contraseña');

    await tester.enterText(campos.at(1), 'secreto');
    await tester.pump();
    expect(boton().onPressed, isNotNull);

    await tester.enterText(campos.at(1), '');
    await tester.pump();
    expect(boton().onPressed, isNull);
  });
}
