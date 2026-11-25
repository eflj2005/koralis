import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart' hide Transaction;
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
import 'package:koralis_app/features/transactions/domain/usecases/delete_transaction_usecase.dart';
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

  @override
  Future<void> deleteClient(String id) async {}
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

  Widget buildTestApp(Widget home) {
    return MaterialApp(
      theme: testTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'CO'),
        Locale('es', ''),
        Locale('en', ''),
      ],
      locale: const Locale('es', 'CO'),
      home: home,
    );
  }

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
        buildTestApp(
          TransactionsScreen(
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
        buildTestApp(
          TransactionsScreen(
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
        buildTestApp(
          TransactionsScreen(
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
        buildTestApp(
          TransactionsScreen(
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

      // Verificar modal inferior sin botón Editar Transacción
      expect(find.text('Valor de la Transacción'), findsOneWidget);
      expect(find.text('Depósito en efectivo'), findsWidgets);
      expect(find.text('Editar Transacción'), findsNothing);
    });

    testWidgets('El swipe muestra Editar y Eliminar solo en transacciones manuales y no en automáticas', (tester) async {
      tester.view.physicalSize = const Size(420, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final txManual = Transaction(
        id: 'tx-manual',
        clienteId: 'c1',
        clienteNombre: 'Carlos Gómez',
        tipo: TransactionType.recarga,
        valor: 2000000.0,
        fecha: DateTime(ahora.year, ahora.month, 10),
      );
      final txAuto = Transaction(
        id: 'tx-auto',
        clienteId: 'c2',
        clienteNombre: 'Mariana Duarte',
        tipo: TransactionType.inversion,
        valor: 1000000.0,
        fecha: DateTime(ahora.year, ahora.month, 5),
        instrumentoId: 'inst-1',
      );

      final txRepo = MockTransactionRepo([txManual, txAuto]);
      final clientRepo = MockClientRepo(testClients);
      final getTransactions = GetTransactionsUseCase(txRepo);
      final deleteTransaction = DeleteTransactionUseCase(txRepo);
      final getProfile = GetProfileUseCase(MockProfileRepo());
      final getClients = GetClientsUseCase(clientRepo);

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es', 'CO'),
            Locale('es', ''),
            Locale('en', ''),
          ],
          locale: const Locale('es', 'CO'),
          routes: {
            '/transaction_form': (context) => const Scaffold(
                  body: Text('Pantalla Formulario Transacción'),
                ),
          },
          home: TransactionsScreen(
            user: testUser,
            getTransactionsUseCase: getTransactions,
            deleteTransactionUseCase: deleteTransaction,
            getProfileUseCase: getProfile,
            getClientsUseCase: getClients,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Intentar swipe en transacción automática (Mariana Duarte) -> NO debe mostrar acciones
      await tester.drag(find.byType(AppListCard).at(1), const Offset(-180, 0));
      await tester.pumpAndSettle();
      expect(find.text('Editar'), findsNothing);
      expect(find.text('Eliminar'), findsNothing);

      // Swipe en transacción manual (Carlos Gómez) -> Sí muestra Editar y Eliminar
      await tester.drag(find.byType(AppListCard).first, const Offset(-180, 0));
      await tester.pumpAndSettle();
      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Eliminar'), findsOneWidget);

      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
      expect(find.text('Pantalla Formulario Transacción'), findsOneWidget);
    });

    testWidgets('Al eliminar una recarga manual debe notificar el nuevo saldo incluso si resulta negativo', (tester) async {
      tester.view.physicalSize = const Size(420, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final txRecarga = Transaction(
        id: 'tx-rec',
        clienteId: 'c1',
        clienteNombre: 'Carlos Gómez',
        tipo: TransactionType.recarga,
        valor: 2000000.0,
        fecha: DateTime(ahora.year, ahora.month, 10),
      );
      final txRetiro = Transaction(
        id: 'tx-ret',
        clienteId: 'c1',
        clienteNombre: 'Carlos Gómez',
        tipo: TransactionType.retiro,
        valor: 1500000.0,
        fecha: DateTime(ahora.year, ahora.month, 5),
      );

      final txRepo = MockTransactionRepo([txRecarga, txRetiro]);
      final clientRepo = MockClientRepo(testClients);

      await tester.pumpWidget(
        buildTestApp(
          TransactionsScreen(
            user: testUser,
            getTransactionsUseCase: GetTransactionsUseCase(txRepo),
            deleteTransactionUseCase: DeleteTransactionUseCase(txRepo),
            getProfileUseCase: GetProfileUseCase(MockProfileRepo()),
            getClientsUseCase: GetClientsUseCase(clientRepo),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Eliminar la recarga de $2.000.000 -> queda únicamente el retiro de $1.500.000 => saldo -$1.500.000
      await tester.drag(find.byType(AppListCard).first, const Offset(-180, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(find.text('Eliminar Transacción'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();

      expect(txRepo.items.length, equals(1));
      expect(txRepo.items.single.id, equals('tx-ret'));
      expect(
        find.textContaining('Nuevo saldo de Carlos Gómez: - \$ 1.500.000,00 (saldo negativo)'),
        findsOneWidget,
      );
    });

    testWidgets('Tocar el filtro "Desde" debe abrir el DatePickerDialog correctamente sin error de localizaciones', (tester) async {
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
        buildTestApp(
          TransactionsScreen(
            user: testUser,
            getTransactionsUseCase: getTransactions,
            getProfileUseCase: getProfile,
            getClientsUseCase: getClients,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tocar el campo "Desde"
      await tester.tap(find.widgetWithText(InputDecorator, 'Desde'));
      await tester.pumpAndSettle();

      // Debe abrir el DatePickerDialog sin lanzar excepciones de localización
      expect(find.byType(DatePickerDialog), findsOneWidget);

      // Cerrar el diálogo tocando Cancelar
      final botonCancelar = find.text('Cancelar');
      expect(botonCancelar, findsOneWidget);
      await tester.tap(botonCancelar);
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsNothing);
    });
  });
}
