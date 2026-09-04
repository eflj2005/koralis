import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';

void main() {
  group('CoreTheme - Configuración de Cuadros de Texto', () {
    test('CoreTheme.buildTheme debe configurar el fondo de los campos de texto en blanco por defecto', () {
      // Construir el tema base
      final tema = CoreTheme.buildTheme();

      // Verificar que inputDecorationTheme tenga relleno activo y color blanco
      expect(tema.inputDecorationTheme.filled, isTrue);
      expect(tema.inputDecorationTheme.fillColor, equals(Colors.white));
    });
  });

  group('AppTextField - Fondo y Contraste', () {
    testWidgets('AppTextField debe renderizarse con fondo blanco y relleno activo por defecto', (WidgetTester tester) async {
      // Renderizar el widget dentro de un MaterialApp básico
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppTextField(
              label: 'Correo de prueba',
              hint: 'correo@ejemplo.com',
            ),
          ),
        ),
      );

      // Encontrar el TextField subyacente
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      final textField = tester.widget<TextField>(textFieldFinder);
      final decoracion = textField.decoration;

      // Verificar que la decoración tenga relleno blanco para contraste
      expect(decoracion?.filled, isTrue);
      expect(decoracion?.fillColor, equals(Colors.white));
    });

    testWidgets('AppTextField permite personalizar fillColor si es necesario', (WidgetTester tester) async {
      const colorPersonalizado = Color(0xFFF0F0F0);

      // Renderizar con color de fondo personalizado
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppTextField(
              label: 'Campo personalizado',
              fillColor: colorPersonalizado,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.filled, isTrue);
      expect(textField.decoration?.fillColor, equals(colorPersonalizado));
    });
  });
}
