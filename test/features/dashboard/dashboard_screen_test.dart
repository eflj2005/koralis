import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';
import 'package:koralis_app/features/auth/domain/entities/user.dart';
import 'package:koralis_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:koralis_app/features/profile/domain/entities/profile.dart';
import 'package:koralis_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:koralis_app/features/profile/domain/usecases/get_profile_usecase.dart';

const _transparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
];

class TestAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      final ByteData data = const StandardMessageCodec().encodeMessage(<String, Object?>{})!;
      return data;
    }
    if (key == 'AssetManifest.json') {
      final bytes = Uint8List.fromList('{}'.codeUnits);
      return ByteData.view(bytes.buffer);
    }
    return ByteData.view(Uint8List.fromList(_transparentImage).buffer);
  }
}

/// Implementación mock del repositorio de perfil para pruebas independientes
class MockProfileRepository implements ProfileRepository {
  @override
  Future<Profile> getProfile(String userId) async {
    return Profile(
      id: 'profile-test-1',
      userId: 'test-user-1',
      avatarPath: 'images/avatar.png',
      nombre: 'Carlos Mendoza',
      correo: 'carlos@koralis.com',
    );
  }
}

Widget _crearWidgetPrueba({
  required Widget child,
  Map<String, WidgetBuilder>? routes,
}) {
  return DefaultAssetBundle(
    bundle: TestAssetBundle(),
    child: MaterialApp(
      theme: ThemeData.light().copyWith(splashFactory: InkRipple.splashFactory),
      routes: routes ?? const <String, WidgetBuilder>{},
      home: child,
    ),
  );
}

void main() {
  group('DashboardScreen - Menú con Pestañas de Carpetas Verticales', () {
    final testUser = User(
      id: 'test-user-1',
      nombre: 'Carlos Mendoza',
      correo: 'carlos@koralis.com',
    );

    late GetProfileUseCase mockUseCase;

    setUp(() {
      mockUseCase = GetProfileUseCase(MockProfileRepository());
    });

    testWidgets(
      'Debe renderizar las 4 pestañas de carpetas con textos y orientación vertical sin desbordamiento',
      (tester) async {
        // Simular pantalla estándar de smartphone
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _crearWidgetPrueba(
            routes: {
              '/instruments': (context) => Scaffold(
                    appBar: AppBar(title: const Text('Pantalla Instrumentos')),
                    body: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Volver'),
                    ),
                  ),
            },
            child: DashboardScreen(
              user: testUser,
              getProfileUseCase: mockUseCase,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verificar que existan las 4 opciones en el árbol de widgets
        expect(find.text('Clientes'), findsOneWidget);
        expect(find.text('Instrumentos'), findsOneWidget);
        expect(find.text('Transacciones'), findsOneWidget);
        expect(find.text('Seguimiento'), findsOneWidget);

        // Verificar que cada texto esté envuelto en un RotatedBox con quarterTurns: 3
        final rotatedBoxes = find.byType(RotatedBox);
        expect(rotatedBoxes, findsNWidgets(4));

        final rotBoxWidgets = tester.widgetList<RotatedBox>(rotatedBoxes);
        for (final rot in rotBoxWidgets) {
          expect(rot.quarterTurns, equals(3));
        }

        // Verificar que el ícono esté ubicado por debajo del texto rotado en la pestaña
        final textoClientesOffset = tester.getCenter(find.text('Clientes'));
        final pestanaClientes = find.ancestor(
          of: find.text('Clientes'),
          matching: find.byType(InkWell),
        );
        final iconoClientesOffset = tester.getCenter(
          find.descendant(
            of: pestanaClientes,
            matching: find.byIcon(Icons.people_alt_outlined),
          ),
        );
        expect(
          iconoClientesOffset.dy,
          greaterThan(textoClientesOffset.dy),
          reason: 'El ícono debe ubicarse en la parte inferior del texto de la pestaña',
        );

        // Verificar el ícono de bolsa de dinero (Icons.paid_outlined) en la pestaña de Instrumentos
        final pestanaInstrumentos = find.ancestor(
          of: find.text('Instrumentos'),
          matching: find.byType(InkWell),
        );
        expect(
          find.descendant(
            of: pestanaInstrumentos,
            matching: find.byIcon(Icons.paid_outlined),
          ),
          findsOneWidget,
          reason: 'La pestaña de Instrumentos debe usar el ícono de bolsa de dinero (Icons.paid_outlined)',
        );

        // Verificar que el contenido de las pestañas esté anclado a la base izquierda (Alignment.bottomLeft)
        final alignsPestanas = find.descendant(
          of: pestanaClientes,
          matching: find.byType(Align),
        );
        expect(alignsPestanas, findsWidgets);
        final alignWidget = tester.widget<Align>(alignsPestanas.first);
        expect(
          alignWidget.alignment,
          equals(Alignment.bottomLeft),
          reason: 'Los textos e íconos deben estar anclados a la base izquierda dentro de la pestaña',
        );

        // Verificar que NO exista ningún botón toggle de expandir/contraer
        expect(find.text('Contraer'), findsNothing);
        expect(find.byIcon(Icons.menu_rounded), findsNothing);
        expect(find.byIcon(Icons.menu_open_rounded), findsNothing);

        // Guardar la coordenada horizontal X antes de la interacción
        final dxAntesDeSeleccionar = tester.getTopLeft(pestanaInstrumentos).dx;

        // Probar interacción con la pestaña 'Instrumentos'
        await tester.tap(find.text('Instrumentos'));
        await tester.pumpAndSettle();

        // Debe haber navegado al módulo de instrumentos
        expect(find.text('Pantalla Instrumentos'), findsOneWidget);

        // Volver al Dashboard
        await tester.tap(find.text('Volver'));
        await tester.pumpAndSettle();

        // Verificar que la pestaña mantenga su posición horizontal fija
        final dxDespuesDeRetornar = tester.getTopLeft(pestanaInstrumentos).dx;
        expect(
          dxDespuesDeRetornar,
          equals(dxAntesDeSeleccionar),
          reason: 'La pestaña debe mantener su posición horizontal fija al seleccionarse',
        );
      },
    );

    testWidgets(
      'Debe ser responsivo en diferentes resoluciones compactas sin producir sobreflujos',
      (tester) async {
        final widths = [320.0, 360.0, 412.0];
        for (final w in widths) {
          tester.view.physicalSize = Size(w, 700);
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            _crearWidgetPrueba(
              child: DashboardScreen(
                user: testUser,
                getProfileUseCase: mockUseCase,
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Verificar que no se hayan lanzado excepciones de layout
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'La esfera de perfil debe sobresalir a la derecha de la barra lateral (58 px) y responder a la interacción',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _crearWidgetPrueba(
            child: DashboardScreen(
              user: testUser,
              getProfileUseCase: mockUseCase,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Localizar el avatar de la esfera de perfil
        final avatarPerfil = find.byType(CircleAvatar).first;
        final avatarRect = tester.getRect(avatarPerfil);

        // El extremo derecho del avatar debe ser estrictamente mayor a 58.0 px (ancho de la barra lateral)
        expect(
          avatarRect.right,
          greaterThan(58.0),
          reason: 'La esfera de perfil debe sobresalir a la derecha de la barra lateral de 58 px',
        );

        // Al pulsar la esfera de perfil debe desplegarse el menú contextual de perfil
        await tester.tap(avatarPerfil);
        await tester.pumpAndSettle();

        expect(find.text('Carlos Mendoza'), findsWidgets);
        expect(find.text('carlos@koralis.com'), findsWidgets);
        expect(find.text('Mi Perfil'), findsOneWidget);
        expect(find.text('Cambiar clave'), findsOneWidget);
      },
    );

    testWidgets(
      'Al presionar la pestaña Clientes y retornar, la pestaña activa debe desactivarse',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _crearWidgetPrueba(
            routes: {
              '/clients': (context) => Scaffold(
                    appBar: AppBar(title: const Text('Pantalla Clientes')),
                    body: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Volver'),
                    ),
                  ),
            },
            child: DashboardScreen(
              user: testUser,
              getProfileUseCase: mockUseCase,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Pulsar en la pestaña 'Clientes'
        await tester.tap(find.text('Clientes'));
        await tester.pumpAndSettle();

        // Debe haber navegado a la pantalla del módulo de clientes
        expect(find.text('Pantalla Clientes'), findsOneWidget);

        // Presionar volver para regresar al Dashboard
        await tester.tap(find.text('Volver'));
        await tester.pumpAndSettle();

        // Debe haber regresado al Dashboard y mostrar la tarjeta de bienvenida
        expect(find.text('¡Bienvenido!'), findsOneWidget);

        // Verificar que el índice seleccionado en AppFolderTabBar sea null (desactivada)
        final folderTabBarFinder = find.byType(AppFolderTabBar);
        expect(folderTabBarFinder, findsOneWidget);
        final folderTabBar = tester.widget<AppFolderTabBar>(folderTabBarFinder);
        expect(
          folderTabBar.indiceSeleccionado,
          isNull,
          reason: 'Al retornar del módulo de clientes, la pestaña debe estar desactivada',
        );
      },
    );
  });
}
