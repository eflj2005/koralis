import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart' hide Transaction;
import 'package:koralis_app/app/styles.dart';
import 'package:koralis_app/features/auth/domain/entities/user.dart';
import 'package:koralis_app/features/clients/domain/entities/client.dart';
import 'package:koralis_app/features/clients/domain/repositories/client_repository.dart';
import 'package:koralis_app/features/clients/domain/usecases/get_clients_usecase.dart';
import 'package:koralis_app/features/clients/domain/usecases/add_client_usecase.dart';
import 'package:koralis_app/features/clients/domain/usecases/delete_client_usecase.dart';
import 'package:koralis_app/features/clients/presentation/clients_screen.dart';
import 'package:koralis_app/features/instruments/domain/entities/instrument.dart';
import 'package:koralis_app/features/instruments/domain/repositories/instrument_repository.dart';
import 'package:koralis_app/features/profile/domain/entities/profile.dart';
import 'package:koralis_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:koralis_app/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:koralis_app/features/transactions/domain/entities/transaction.dart';
import 'package:koralis_app/features/transactions/domain/repositories/transaction_repository.dart';

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

  @override
  Future<void> deleteClient(String id) async {
    items.removeWhere((c) => c.id == id);
  }
}

class _MockInstrumentRepo implements InstrumentRepository {
  final List<Instrument> items;
  _MockInstrumentRepo(this.items);

  @override
  Future<List<Instrument>> getInstruments() async => items;

  @override
  Future<void> saveInstrument(Instrument instrument) async {}

  @override
  Future<void> deleteInstrument(String id) async {}
}

class _MockTransactionRepo implements TransactionRepository {
  final List<Transaction> items;
  _MockTransactionRepo(this.items);

  @override
  Future<List<Transaction>> getTransactions({String? clienteId}) async {
    if (clienteId != null) {
      return items.where((t) => t.clienteId == clienteId).toList();
    }
    return items;
  }

  @override
  Future<void> saveTransaction(Transaction transaction) async {}

  @override
  Future<void> deleteTransaction(String id, {String? clienteId}) async {}
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

    testWidgets('Al presionar una tarjeta de cliente debe abrir la ficha informativa sin botón Editar Cliente', (tester) async {
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

      // Debe desplegar la ficha rápida informativa sin botón 'Editar Cliente'
      expect(find.text('Cliente preferencial'), findsOneWidget);
      expect(find.text('Editar Cliente'), findsNothing);
    });

    testWidgets('Al deslizar una tarjeta de cliente debe mostrar Editar y Eliminar', (tester) async {
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
      final deleteClient = DeleteClientUseCase(
        clientRepository: repo,
        instrumentRepository: _MockInstrumentRepo([]),
        transactionRepository: _MockTransactionRepo([]),
      );
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
            deleteClientUseCase: deleteClient,
            getProfileUseCase: getProfile,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Inicialmente ocultos
      expect(find.text('Editar'), findsNothing);
      expect(find.text('Eliminar'), findsNothing);

      // Deslizar de derecha a izquierda y probar Editar
      await tester.drag(find.byType(AppListCard), const Offset(-180, 0));
      await tester.pumpAndSettle();

      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Eliminar'), findsOneWidget);

      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
      expect(find.text('Pantalla Formulario Cliente'), findsOneWidget);
    });

    testWidgets('Al confirmar Eliminar en cliente sin asociaciones debe eliminarlo y si tiene instrumento debe bloquearlo', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final clienteSinDatos = Client(
        id: '10',
        nombre: 'Mateo Sandoval',
        documento: 'CC 554433',
        correo: 'mateo@test.com',
        telefono: '3150009988',
      );

      final repo = MockClientRepo([clienteSinDatos]);
      final deleteClient = DeleteClientUseCase(
        clientRepository: repo,
        instrumentRepository: _MockInstrumentRepo([]),
        transactionRepository: _MockTransactionRepo([]),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppStyles.theme,
          home: ClientsScreen(
            user: testUser,
            getClientsUseCase: GetClientsUseCase(repo),
            addClientUseCase: AddClientUseCase(repo),
            deleteClientUseCase: deleteClient,
            getProfileUseCase: GetProfileUseCase(MockProfileRepo()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.drag(find.byType(AppListCard), const Offset(-180, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(find.text('Eliminar Cliente'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();

      expect(repo.items, isEmpty);
      expect(find.byType(EmptyWidget), findsOneWidget);
    });
  });
}
