import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koralis_app/app/styles.dart';
import 'package:koralis_app/features/auth/domain/entities/user.dart';
import 'package:koralis_app/features/clients/domain/entities/client.dart';
import 'package:koralis_app/features/clients/domain/repositories/client_repository.dart';
import 'package:koralis_app/features/clients/domain/usecases/save_client_usecase.dart';
import 'package:koralis_app/features/clients/presentation/client_form_screen.dart';
import 'package:koralis_app/features/profile/domain/entities/profile.dart';
import 'package:koralis_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:koralis_app/features/profile/domain/usecases/get_profile_usecase.dart';

/// Repositorio de clientes para pruebas
class MockClientRepo implements ClientRepository {
  final List<Client> clientes;
  MockClientRepo([List<Client>? inicial]) : clientes = inicial != null ? List.from(inicial) : [];

  @override
  Future<List<Client>> getClients() async => List.unmodifiable(clientes);

  @override
  Future<void> addClient(Client client) async {
    final clientConId = client.id.trim().isNotEmpty
        ? client
        : client.copyWith(id: 'mock_client_${clientes.length + 1}');
    final idx = clientes.indexWhere((c) => c.id == clientConId.id);
    if (idx >= 0) {
      clientes[idx] = clientConId;
    } else {
      clientes.add(clientConId);
    }
  }
}

/// Repositorio simulado de perfil
class MockProfileRepo implements ProfileRepository {
  @override
  Future<Profile> getProfile(String userId) async {
    return Profile(
      id: 'profile-test',
      userId: userId,
      avatarPath: 'images/avatar.png',
      nombre: 'Carlos Mendoza',
      correo: 'carlos@koralis.com',
    );
  }
}

void main() {
  group('ClientFormScreen - Creación y Edición Independiente de Clientes', () {
    final testUser = User(
      id: 'user-123',
      nombre: 'Carlos Mendoza',
      correo: 'carlos@koralis.com',
    );

    late MockClientRepo mockClientRepo;
    late SaveClientUseCase saveClientUseCase;
    late GetProfileUseCase getProfileUseCase;

    setUp(() {
      mockClientRepo = MockClientRepo();
      saveClientUseCase = SaveClientUseCase(mockClientRepo);
      getProfileUseCase = GetProfileUseCase(MockProfileRepo());
    });

    Widget crearWidgetPrueba({Client? client}) {
      return MaterialApp(
        theme: AppStyles.theme,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClientFormScreen(
                      user: testUser,
                      client: client,
                      saveClientUseCase: saveClientUseCase,
                      getProfileUseCase: getProfileUseCase,
                    ),
                  ),
                );
              },
              child: const Text('Abrir Formulario'),
            ),
          ),
        ),
      );
    }

    testWidgets('Modo Creación: renderiza campos vacíos y valida campos obligatorios', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(crearWidgetPrueba());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Formulario'));
      await tester.pumpAndSettle();

      // Debe mostrar encabezado "Nuevo Cliente"
      expect(find.text('Nuevo Cliente'), findsOneWidget);
      expect(find.text('Crear Cliente'), findsOneWidget);

      // Verificar existencia de campos
      expect(find.text('Nombre completo o Razón Social'), findsOneWidget);
      expect(find.text('Documento o Identificación'), findsOneWidget);
      expect(find.text('Correo Electrónico'), findsOneWidget);
      expect(find.text('Teléfono de Contacto'), findsOneWidget);
      expect(find.text('Observación'), findsOneWidget);

      // Intentar guardar con campos vacíos
      await tester.tap(find.text('Crear Cliente'));
      await tester.pumpAndSettle();

      // Debe arrojar mensajes de validación
      expect(find.text('Ingresa el nombre del cliente'), findsOneWidget);
      expect(find.text('Ingresa la identificación'), findsOneWidget);
      expect(mockClientRepo.clientes, isEmpty);
    });

    testWidgets('Modo Creación: permite llenar datos y guardar nuevo cliente', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(crearWidgetPrueba());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Formulario'));
      await tester.pumpAndSettle();

      // Diligenciar campos
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Valeria Restrepo');
      await tester.enterText(textFields.at(1), 'CC 1098765432');
      await tester.enterText(textFields.at(2), 'valeria@koralis.com');
      await tester.enterText(textFields.at(3), '+57 320 987 6543');
      await tester.enterText(textFields.at(4), 'Cliente referida para portafolio privado');

      await tester.pumpAndSettle();

      // Guardar cliente
      await tester.tap(find.text('Crear Cliente'));
      await tester.pumpAndSettle();

      // Debe retornar a la pantalla inicial y haber guardado el cliente
      expect(find.text('Abrir Formulario'), findsOneWidget);
      expect(mockClientRepo.clientes.length, equals(1));
      final guardado = mockClientRepo.clientes.first;
      expect(guardado.nombre, equals('Valeria Restrepo'));
      expect(guardado.documento, equals('CC 1098765432'));
      expect(guardado.correo, equals('valeria@koralis.com'));
      expect(guardado.observacion, equals('Cliente referida para portafolio privado'));
      expect(guardado.estado, equals('Activo'));
    });

    testWidgets('Modo Edición: precarga cliente existente y permite actualizar estado y observación', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final clienteExistente = Client(
        id: 'cliente-999',
        nombre: 'Mauricio Bermúdez',
        documento: 'NIT 900111222-3',
        correo: 'mauricio@empresa.com',
        telefono: '3105556677',
        observacion: 'Requiere reporte mensual',
        estado: 'Activo',
      );
      mockClientRepo.clientes.add(clienteExistente);

      await tester.pumpWidget(crearWidgetPrueba(client: clienteExistente));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Formulario'));
      await tester.pumpAndSettle();

      // Debe mostrar encabezado "Editar Cliente" y botón "Guardar Cambios"
      expect(find.text('Editar Cliente'), findsOneWidget);
      expect(find.text('Guardar Cambios'), findsOneWidget);

      // Verificar que los datos estén precargados
      expect(find.text('Mauricio Bermúdez'), findsOneWidget);
      expect(find.text('NIT 900111222-3'), findsOneWidget);
      expect(find.text('mauricio@empresa.com'), findsOneWidget);
      expect(find.text('Requiere reporte mensual'), findsOneWidget);

      // Cambiar estado a "Inactivo"
      await tester.tap(find.text('Inactivo'));
      await tester.pumpAndSettle();

      // Modificar la observación
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(4), 'Cuenta en pausa por reestructuración');
      await tester.pumpAndSettle();

      // Guardar cambios
      await tester.tap(find.text('Guardar Cambios'));
      await tester.pumpAndSettle();

      // Debe regresar a la vista inicial y persistir la actualización
      expect(find.text('Abrir Formulario'), findsOneWidget);
      expect(mockClientRepo.clientes.length, equals(1));
      final actualizado = mockClientRepo.clientes.first;
      expect(actualizado.id, equals('cliente-999'));
      expect(actualizado.estado, equals('Inactivo'));
      expect(actualizado.observacion, equals('Cuenta en pausa por reestructuración'));
    });
  });
}
