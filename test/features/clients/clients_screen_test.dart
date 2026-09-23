import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';
import 'package:koralis_app/app/styles.dart';
import 'package:koralis_app/features/auth/domain/entities/user.dart';
import 'package:koralis_app/features/clients/domain/entities/client.dart';
import 'package:koralis_app/features/clients/domain/repositories/client_repository.dart';
import 'package:koralis_app/features/clients/domain/usecases/get_clients_usecase.dart';
import 'package:koralis_app/features/clients/domain/usecases/add_client_usecase.dart';
import 'package:koralis_app/features/clients/presentation/clients_screen.dart';
import 'package:koralis_app/features/profile/domain/entities/profile.dart';
import 'package:koralis_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:koralis_app/features/profile/domain/usecases/get_profile_usecase.dart';

class MockProfileRepo implements ProfileRepository {
  @override
  Future<Profile> getProfile(String userId) async {
    return Profile(
      id: 'p1',
      userId: userId,
      avatarPath: 'images/avatar.png',
      nombre: 'Carlos Mendoza',
      correo: 'carlos@koralis.com',
    );
  }
}

class MockClientRepo implements ClientRepository {
  final List<Client> items;
  MockClientRepo(this.items);

  @override
  Future<List<Client>> getClients() async {
    return List<Client>.from(items);
  }

  @override
  Future<void> addClient(Client client) async {
    items.add(client);
  }
}

void main() {
  final testUser = User(
    id: 'user-1',
    nombre: 'Carlos Mendoza',
    correo: 'carlos@koralis.com',
  );

  group('ClientsScreen - Interfaz y Funcionalidad de Clientes', () {
    testWidgets('Debe mostrar estado vacío (EmptyWidget) cuando la colección no tiene clientes', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = MockClientRepo([]);
      final getClients = GetClientsUseCase(repo);
      final addClient = AddClientUseCase(repo);
      final getProfile = GetProfileUseCase(MockProfileRepo());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppStyles.theme,
          home: ClientsScreen(
            user: testUser,
            getClientsUseCase: getClients,
            addClientUseCase: addClient,
            getProfileUseCase: getProfile,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar encabezado superior tipográfico limpio
      expect(find.text('Clientes'), findsWidgets);
      expect(find.byType(AppHeaderTitle), findsOneWidget);

      // Verificar que se muestre el EmptyWidget
      expect(find.byType(EmptyWidget), findsOneWidget);
      expect(find.text('Aún no tienes clientes registrados'), findsOneWidget);

      // Verificar la presencia del botón flotante (+)
      expect(find.byType(AppFloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('Debe listar clientes en bloques rectangulares (AppListCard) ordenados alfabéticamente A-Z', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final listaClientes = [
        Client(
          id: '1',
          nombre: 'Zulma Quintero',
          documento: 'CC 1001',
          correo: 'zulma@koralis.com',
          telefono: '300111',
          observacion: 'Persona Natural',
        ),
        Client(
          id: '2',
          nombre: 'Bernardo Silva',
          documento: 'NIT 2002',
          correo: 'bernardo@koralis.com',
          telefono: '300222',
          observacion: 'Empresa',
        ),
        Client(
          id: '3',
          nombre: 'Alberto Gómez',
          documento: 'CC 3003',
          correo: 'alberto@koralis.com',
          telefono: '300333',
          observacion: 'Inversionista',
        ),
      ];

      final repo = MockClientRepo(listaClientes);
      final getClients = GetClientsUseCase(repo);
      final addClient = AddClientUseCase(repo);
      final getProfile = GetProfileUseCase(MockProfileRepo());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppStyles.theme,
          home: ClientsScreen(
            user: testUser,
            getClientsUseCase: getClients,
            addClientUseCase: addClient,
            getProfileUseCase: getProfile,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Debe haber 3 tarjetas AppListCard en pantalla
      expect(find.byType(AppListCard), findsNWidgets(3));

      // Verificar el orden visual de arriba a abajo: Alberto -> Bernardo -> Zulma
      final posAlberto = tester.getTopLeft(find.text('Alberto Gómez')).dy;
      final posBernardo = tester.getTopLeft(find.text('Bernardo Silva')).dy;
      final posZulma = tester.getTopLeft(find.text('Zulma Quintero')).dy;

      expect(posAlberto, lessThan(posBernardo), reason: 'Alberto debe mostrarse antes que Bernardo');
      expect(posBernardo, lessThan(posZulma), reason: 'Bernardo debe mostrarse antes que Zulma');
    });

    testWidgets('Al presionar el botón flotante (+) debe navegar a la pantalla de nuevo cliente (/client_form)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = MockClientRepo([]);
      final getClients = GetClientsUseCase(repo);
      final addClient = AddClientUseCase(repo);
      final getProfile = GetProfileUseCase(MockProfileRepo());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppStyles.theme,
          routes: {
            '/client_form': (context) => const Scaffold(
                  body: Text('Pantalla Formulario Cliente'),
                ),
          },
          home: ClientsScreen(
            user: testUser,
            getClientsUseCase: getClients,
            addClientUseCase: addClient,
            getProfileUseCase: getProfile,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tocar el botón flotante (+)
      await tester.tap(find.byType(AppFloatingActionButton));
      await tester.pumpAndSettle();

      // Debe haber navegado a la ruta de formulario independiente
      expect(find.text('Pantalla Formulario Cliente'), findsOneWidget);
    });

    testWidgets('Al presionar una tarjeta de cliente debe abrir la ficha con la opción Editar Cliente', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final clientePrueba = Client(
        id: '10',
        nombre: 'Mateo Sandoval',
        documento: 'CC 554433',
        correo: 'mateo@test.com',
        telefono: '3150009988',
        observacion: 'Cliente preferencial',
      );

      final repo = MockClientRepo([clientePrueba]);
      final getClients = GetClientsUseCase(repo);
      final addClient = AddClientUseCase(repo);
      final getProfile = GetProfileUseCase(MockProfileRepo());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppStyles.theme,
          routes: {
            '/client_form': (context) => const Scaffold(
                  body: Text('Pantalla Formulario Cliente'),
                ),
          },
          home: ClientsScreen(
            user: testUser,
            getClientsUseCase: getClients,
            addClientUseCase: addClient,
            getProfileUseCase: getProfile,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tocar la tarjeta de Mateo
      await tester.tap(find.text('Mateo Sandoval'));
      await tester.pumpAndSettle();

      // Debe desplegar la ficha rápida con el botón 'Editar Cliente'
      expect(find.text('Editar Cliente'), findsOneWidget);
      expect(find.text('Cliente preferencial'), findsOneWidget);

      // Al tocar 'Editar Cliente', debe navegar a /client_form
      await tester.tap(find.text('Editar Cliente'));
      await tester.pumpAndSettle();

      expect(find.text('Pantalla Formulario Cliente'), findsOneWidget);
    });
  });
}
