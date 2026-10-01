import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koralis_app/features/auth/domain/entities/user.dart';
import 'package:koralis_app/features/clients/domain/entities/client.dart';
import 'package:koralis_app/features/clients/domain/repositories/client_repository.dart';
import 'package:koralis_app/features/clients/domain/usecases/get_clients_usecase.dart';
import 'package:koralis_app/features/profile/domain/entities/profile.dart';
import 'package:koralis_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:koralis_app/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:koralis_app/features/transactions/domain/entities/transaction.dart';
import 'package:koralis_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:koralis_app/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:koralis_app/features/transactions/presentation/transactions_screen.dart';

class MockProfileRepo implements ProfileRepository {
  @override
  Future<Profile> getProfile(String userId) async {
    return Profile(
      id: 'p1',
      userId: userId,
      avatarPath: '',
      nombre: 'Edwin Londoño',
      correo: 'edwin@koralis.com',
    );
  }
}

class MockClientRepo implements ClientRepository {
  final List<Client> clients;
  MockClientRepo([this.clients = const []]);

  @override
  Future<List<Client>> getClients() async => clients;

  @override
  Future<void> addClient(Client client) async {}
}

class MockTransactionRepo implements TransactionRepository {
  final List<Transaction> items;
  MockTransactionRepo(this.items);

  @override
  Future<List<Transaction>> getTransactions({String? clienteId}) async {
    if (clienteId != null && clienteId.isNotEmpty) {
      return items.where((t) => t.clienteId == clienteId).toList();
    }
    return List<Transaction>.from(items);
  }

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    final idx = items.indexWhere((t) => t.id == transaction.id);
    if (idx >= 0) {
      items[idx] = transaction;
    } else {
      items.add(transaction);
    }
  }

  @override
  Future<void> deleteTransaction(String id, {String? clienteId}) async {
    items.removeWhere((t) => t.id == id);
  }
}

void main() {
  final testTheme = ThemeData.dark().copyWith(
    splashFactory: InkRipple.splashFactory,
  );

  final testUser = User(
    id: 'user-001',
    nombre: 'Edwin Londoño',
    correo: 'edwin@koralis.com',
  );

  final ahora = DateTime.now();

  final testClients = [
    Client(
      id: 'c1',
      nombre: 'Carlos Gómez',
      documento: '12345678',
      correo: 'carlos@test.com',
      telefono: '3001234567',
    ),
    Client(
      id: 'c2',
      nombre: 'Mariana Duarte',
      documento: '87654321',
      correo: 'mariana@test.com',
      telefono: '3109876543',
    ),
  ];

  group('TransactionsScreen - Visualización y filtros combinados', () {
    testWidgets('Debe mostrar estado vacío cuando no existen transacciones', (tester) async {
      tester.view.physicalSize = const Size(420, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final txRepo = MockTransactionRepo([]);
      final clientRepo = MockClientRepo(testClients);
      final getTransactions = GetTransactionsUseCase(txRepo);
      final getProfile = GetProfileUseCase(MockProfileRepo());
      final getClients = GetClientsUseCase(clientRepo);

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: TransactionsScreen(
            user: testUser,
            getTransactionsUseCase: getTransactions,
            getProfileUseCase: getProfile,
            getClientsUseCase: getClients,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No hay transacciones registradas'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('Debe renderizar la lista y los controles de filtro (Cliente, Tipo, Fechas)', (tester) async {
      tester.view.physicalSize = const Size(420, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tx1 = Transaction(
        id: 'tx-1',
        clienteId: 'c1',
        clienteNombre: 'Carlos Gómez',
        tipo: TransactionType.recarga,
        valor: 2000000.0,
        fecha: DateTime(ahora.year, ahora.month, 5),
        observacion: 'Depósito por transferencia',
      );

      final tx2 = Transaction(
        id: 'tx-2',
        clienteId: 'c2',
        clienteNombre: 'Mariana Duarte',
        tipo: TransactionType.retiro,
        valor: 500000.0,
        fecha: DateTime(ahora.year, ahora.month, 8),
        observacion: 'Retiro bancario',
      );

      final txRepo = MockTransactionRepo([tx1, tx2]);
      final clientRepo = MockClientRepo(testClients);
      final getTransactions = GetTransactionsUseCase(txRepo);
      final getProfile = GetProfileUseCase(MockProfileRepo());
      final getClients = GetClientsUseCase(clientRepo);

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: TransactionsScreen(
            user: testUser,
            getTransactionsUseCase: getTransactions,
            getProfileUseCase: getProfile,
            getClientsUseCase: getClients,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verificar controles de filtro
      expect(find.text('Cliente'), findsOneWidget);
      expect(find.text('Tipo'), findsOneWidget);
      expect(find.text('Desde'), findsOneWidget);
      expect(find.text('Hasta'), findsOneWidget);

      // Verificar que se listan los nombres de los clientes
      expect(find.textContaining('Carlos Gómez'), findsWidgets);
      expect(find.textContaining('Mariana Duarte'), findsWidgets);

      // Verificar valores con signo formateado
      expect(find.textContaining('+ \$ 2.000.000,00'), findsOneWidget);
      expect(find.textContaining('- \$ 500.000,00'), findsOneWidget);
    });

    testWidgets('Debe filtrar la lista por tipo de transacción usando el dropdown', (tester) async {
      tester.view.physicalSize = const Size(420, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tx1 = Transaction(
        id: 'tx-1',
        clienteId: 'c1',
        clienteNombre: 'Carlos Gómez',
        tipo: TransactionType.recarga,
        valor: 2000000.0,
        fecha: DateTime(ahora.year, ahora.month, 2),
      );

      final tx2 = Transaction(
        id: 'tx-2',
        clienteId: 'c2',
        clienteNombre: 'Mariana Duarte',
        tipo: TransactionType.retiro,
        valor: 500000.0,
        fecha: DateTime(ahora.year, ahora.month, 4),
      );

      final txRepo = MockTransactionRepo([tx1, tx2]);
      final clientRepo = MockClientRepo(testClients);
      final getTransactions = GetTransactionsUseCase(txRepo);
      final getProfile = GetProfileUseCase(MockProfileRepo());
      final getClients = GetClientsUseCase(clientRepo);

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: TransactionsScreen(
            user: testUser,
            getTransactionsUseCase: getTransactions,
            getProfileUseCase: getProfile,
            getClientsUseCase: getClients,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Ambas transacciones visibles
      expect(find.textContaining('Carlos Gómez'), findsWidgets);
      expect(find.textContaining('Mariana Duarte'), findsWidgets);

      // Abrir dropdown de Tipo
      final tipoDropdown = find.widgetWithText(DropdownButtonFormField<TransactionType?>, 'Tipo');
      expect(tipoDropdown, findsOneWidget);
      await tester.tap(tipoDropdown);
      await tester.pumpAndSettle();

      // Seleccionar opción 'Recarga' en el popup
      final opcionRecarga = find.widgetWithText(DropdownMenuItem<TransactionType?>, 'Recarga').last;
      await tester.tap(opcionRecarga);
      await tester.pumpAndSettle();

      // Solo Carlos Gómez debe estar en la lista de resultados
      expect(find.textContaining('+ \$ 2.000.000,00'), findsOneWidget);
      expect(find.textContaining('- \$ 500.000,00'), findsNothing);
    });

    testWidgets('Tocar una tarjeta debe abrir el modal de detalle inferior', (tester) async {
      tester.view.physicalSize = const Size(420, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tx = Transaction(
        id: 'tx-1',
        clienteId: 'c1',
        clienteNombre: 'Carlos Gómez',
        tipo: TransactionType.recarga,
        valor: 2000000.0,
        fecha: DateTime(ahora.year, ahora.month, 1),
        observacion: 'Depósito en efectivo',
      );

      final txRepo = MockTransactionRepo([tx]);
      final clientRepo = MockClientRepo(testClients);
      final getTransactions = GetTransactionsUseCase(txRepo);
      final getProfile = GetProfileUseCase(MockProfileRepo());
      final getClients = GetClientsUseCase(clientRepo);

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: TransactionsScreen(
            user: testUser,
            getTransactionsUseCase: getTransactions,
            getProfileUseCase: getProfile,
            getClientsUseCase: getClients,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tocar la tarjeta
      await tester.tap(find.textContaining('+ \$ 2.000.000,00'));
      await tester.pumpAndSettle();

      // Verificar modal inferior
      expect(find.text('Valor de la Transacción'), findsOneWidget);
      expect(find.text('Depósito en efectivo'), findsWidgets);
      expect(find.text('Editar Transacción'), findsOneWidget);
    });
  });
}
