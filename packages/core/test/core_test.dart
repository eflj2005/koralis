import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';

void main() {
  group('CoreTheme - Configuración de Cuadros de Texto', () {
    test('CoreTheme.buildTheme debe configurar el fondo en blanco y esquinas redondeadas por defecto', () {
      // Construir el tema base
      final tema = CoreTheme.buildTheme();

      // Verificar que inputDecorationTheme tenga relleno activo y color blanco
      expect(tema.inputDecorationTheme.filled, isTrue);
      expect(tema.inputDecorationTheme.fillColor, equals(Colors.white));

      // Verificar que el borde sea OutlineInputBorder con esquinas redondeadas a 12 px
      final borde = tema.inputDecorationTheme.border as OutlineInputBorder?;
      expect(borde, isNotNull);
      expect(borde?.borderRadius, equals(const BorderRadius.all(Radius.circular(12.0))));
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

      // Verificar que el borde tenga las esquinas ligeramente redondeadas (12 px)
      final borde = decoracion?.border as OutlineInputBorder?;
      expect(borde, isNotNull);
      expect(borde?.borderRadius, equals(const BorderRadius.all(Radius.circular(12.0))));
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

    testWidgets('AppTextField permite personalizar borderRadius si es necesario', (WidgetTester tester) async {
      const radioPersonalizado = BorderRadius.all(Radius.circular(20.0));

      // Renderizar con radio de borde personalizado
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppTextField(
              label: 'Campo con radio custom',
              borderRadius: radioPersonalizado,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      final borde = textField.decoration?.border as OutlineInputBorder?;
      expect(borde, isNotNull);
      expect(borde?.borderRadius, equals(radioPersonalizado));
    });
  });

  group('AppMessenger - Seguridad y Ciclo de Vida', () {
    testWidgets(
      'AppMessenger debe permitir presionar la acción del SnackBar sin lanzar excepción aunque el widget originario haya sido desmontado',
      (WidgetTester tester) async {
        // Renderizar un Scaffold con un botón que dispara el SnackBar
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      AppMessenger.showErrorSnackBar(
                        context,
                        'Credenciales inválidas',
                      );
                    },
                    child: const Text('Disparar error'),
                  );
                },
              ),
            ),
          ),
        );

        // Disparar el SnackBar
        await tester.tap(find.text('Disparar error'));
        await tester.pump(); // Inicia la animación del SnackBar

        expect(find.text('Credenciales inválidas'), findsOneWidget);
        expect(find.text('Aceptar'), findsOneWidget);

        // Desmontar el Scaffold original reemplazando el widget home (simula navegar a Dashboard)
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Dashboard Screen')),
            ),
          ),
        );

        // Esperar que el SnackBar se posicione completamente
        await tester.pumpAndSettle();

        // El SnackBar sigue flotando en pantalla sobre la nueva ruta
        expect(find.text('Aceptar'), findsOneWidget);

        // Presionar la acción 'Aceptar' del SnackBar
        await tester.tap(find.text('Aceptar'));
        await tester.pumpAndSettle();

        // Verificar que no se haya lanzado la excepción de widget desactivado
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'AppMessenger.clear debe remover cualquier SnackBar activo de la pantalla',
      (WidgetTester tester) async {
        late BuildContext capturedContext;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  capturedContext = context;
                  return const Text('Pantalla activa');
                },
              ),
            ),
          ),
        );

        AppMessenger.showErrorSnackBar(capturedContext, 'Mensaje de alerta');
        await tester.pump();

        expect(find.text('Mensaje de alerta'), findsOneWidget);

        // Limpiar el SnackBar mediante AppMessenger.clear
        AppMessenger.clear(capturedContext);
        await tester.pumpAndSettle();

        expect(find.text('Mensaje de alerta'), findsNothing);
      },
    );
  });

  group('AppNavigation - Navegación Lateral y Pestañas de Carpetas', () {
    testWidgets('AppFolderTab debe rotar 90 grados a la izquierda con icono abajo y alineación bottomLeft', (WidgetTester tester) async {
      bool tapDisparado = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppFolderTab(
              indice: 0,
              icono: Icons.folder_outlined,
              titulo: 'Documentos',
              colorAcento: Colors.blue,
              esActiva: true,
              onTap: () => tapDisparado = true,
            ),
          ),
        ),
      );

      // Verificar que el texto 'Documentos' exista
      expect(find.text('Documentos'), findsOneWidget);

      // Verificar rotación de 90° a la izquierda (quarterTurns: 3)
      final rotBoxFinder = find.byType(RotatedBox);
      expect(rotBoxFinder, findsOneWidget);
      final rotBox = tester.widget<RotatedBox>(rotBoxFinder);
      expect(rotBox.quarterTurns, equals(3));

      // Verificar alineación anclada a la base izquierda
      final alignFinder = find.byType(Align);
      expect(alignFinder, findsOneWidget);
      final align = tester.widget<Align>(alignFinder);
      expect(align.alignment, equals(Alignment.bottomLeft));

      // Verificar que el ícono esté ubicado por debajo del texto en coordenadas de pantalla
      final centroTexto = tester.getCenter(find.text('Documentos'));
      final centroIcono = tester.getCenter(find.byIcon(Icons.folder_outlined));
      expect(centroIcono.dy, greaterThan(centroTexto.dy));

      // Verificar interacción onTap
      await tester.tap(find.text('Documentos'));
      expect(tapDisparado, isTrue);
    });

    testWidgets('AppFolderTabBar debe ordenar el Stack para situar al frente la pestaña activa', (WidgetTester tester) async {
      final items = [
        const AppFolderTabItem(
          indice: 0,
          titulo: 'Pestaña 0',
          icono: Icons.folder,
          colorAcento: Colors.blue,
        ),
        const AppFolderTabItem(
          indice: 1,
          titulo: 'Pestaña 1',
          icono: Icons.star,
          colorAcento: Colors.amber,
        ),
      ];

      // Renderizar con la pestaña 0 como activa
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppFolderTabBar(
              items: items,
              indiceSeleccionado: 0,
            ),
          ),
        ),
      );

      final stackFinder = find.descendant(
        of: find.byType(AppFolderTabBar),
        matching: find.byType(Stack),
      );
      final stack = tester.widget<Stack>(stackFinder);
      final keys = stack.children.map((w) => (w.key as ValueKey<int>).value).toList();

      // La pestaña seleccionada (índice 0) debe ser la última en el Stack para elevarse al frente
      expect(keys.last, equals(0));
    });

    testWidgets('AppFloatingProfileBadge y AppSidebarIconButton deben ejecutar onTap correctamente', (WidgetTester tester) async {
      bool perfilPulsado = false;
      bool botonSalidaPulsado = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppFloatingProfileBadge(
                  onTap: () => perfilPulsado = true,
                ),
                AppSidebarIconButton(
                  icono: Icons.logout,
                  esDestructivo: true,
                  mensajeTooltip: 'Salir',
                  onTap: () => botonSalidaPulsado = true,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AppFloatingProfileBadge));
      expect(perfilPulsado, isTrue);

      await tester.tap(find.byIcon(Icons.logout));
      expect(botonSalidaPulsado, isTrue);
    });

    testWidgets('AppSidebarNavigation debe renderizar estructura modular completa', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSidebarNavigation(
              anchoBarra: 58.0,
              insigniaFlotante: const Text('Insignia'),
              seccionPestanas: const Text('Pestañas'),
              pieAcciones: const Text('Pie'),
            ),
          ),
        ),
      );

      expect(find.text('Insignia'), findsOneWidget);
      expect(find.text('Pestañas'), findsOneWidget);
      expect(find.text('Pie'), findsOneWidget);
    });
  });

  group('AppCards y AppFloatingActionButton - Componentes de Listados Estructurados', () {
    testWidgets('AppBadge debe renderizar texto y estilo cromático correctamente', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppBadge(
              texto: 'Activo',
              color: Colors.green,
            ),
          ),
        ),
      );

      expect(find.text('Activo'), findsOneWidget);
    });

    testWidgets('AppHeaderTitle debe renderizar título limpio, subtítulo y ejecutar onBack', (WidgetTester tester) async {
      bool regresoPulsado = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppHeaderTitle(
              titulo: 'Clientes',
              subtitulo: 'Cartera de clientes',
              onBack: () => regresoPulsado = true,
              accion: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Clientes'), findsOneWidget);
      expect(find.text('Cartera de clientes'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      expect(regresoPulsado, isTrue);
    });

    testWidgets('AppHeaderBanner debe renderizar título, subtítulo y acción', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppHeaderBanner(
              titulo: 'Clientes',
              subtitulo: '5 registrados',
              icono: Icons.people,
              accion: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Clientes'), findsOneWidget);
      expect(find.text('5 registrados'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('AppListCard debe renderizar información completa y ejecutar onTap', (WidgetTester tester) async {
      bool pulsado = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppListCard(
              titulo: 'Carlos Mendoza',
              subtitulo: 'DNI: 12345678 • Persona Natural',
              detalle: 'carlos@ejemplo.com',
              badge: const AppBadge(texto: 'Activo', color: Colors.green),
              onTap: () => pulsado = true,
            ),
          ),
        ),
      );

      expect(find.text('Carlos Mendoza'), findsOneWidget);
      expect(find.text('DNI: 12345678 • Persona Natural'), findsOneWidget);
      expect(find.text('carlos@ejemplo.com'), findsOneWidget);
      expect(find.text('Activo'), findsOneWidget);

      await tester.tap(find.text('Carlos Mendoza'));
      expect(pulsado, isTrue);
    });

    testWidgets('AppFloatingActionButton debe renderizar ícono y responder al toque', (WidgetTester tester) async {
      bool botonPulsado = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: AppFloatingActionButton(
              icono: Icons.add,
              mensajeTooltip: 'Nuevo Cliente',
              onPressed: () => botonPulsado = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      await tester.tap(find.byType(FloatingActionButton));
      expect(botonPulsado, isTrue);
    });
  });
}
