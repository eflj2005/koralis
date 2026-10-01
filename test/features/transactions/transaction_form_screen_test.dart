import 'package:flutter/material.dart';
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
import 'package:koralis_app/features/transactions/domain/usecases/save_transaction_usecase.dart';
import 'package:koralis_app/features/transactions/presentation/transaction_form_screen.dart';

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
  MockClientRepo(this.clients);

  @override
  Future<List<Client>> getClients() async => List<Client>.from(clients);

  @override
  Future<void> addClient(Client client) async {
    clients.add(client);
  }
}

class MockTransactionRepo implements TransactionRepository {
  final List<Transaction> items = [];

  @override
  Future<List<Transaction>> getTransactions({String? clienteId}) async => items;

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

  final testClients = [
    Client(
      id: 'c1',
      nombre: 'Juan Camilo',
      documento: '12345678',
      correo: 'juan@koralis.com',
      telefono: '3001234567',
    ),
    Client(
      id: 'c2',
      nombre: 'Laura Restrepo',
      documento: '87654321',
      correo: 'laura@koralis.com',
      telefono: '3109876543',
    ),
  ];

  group('TransactionFormScreen - Formulario de registro y detalle', () {
    testWidgets('Debe renderizar los campos principales en creación de transacción', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final txRepo = MockTransactionRepo();
      final clientRepo = MockClientRepo(testClients);
      final saveTxUseCase = SaveTransactionUseCase(txRepo);
      final getClientsUseCase = GetClientsUseCase(clientRepo);
      final getProfileUseCase = GetProfileUseCase(MockProfileRepo());

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: TransactionFormScreen(
            user: testUser,
            saveTransactionUseCase: saveTxUseCase,
            getClientsUseCase: getClientsUseCase,
            getProfileUseCase: getProfileUseCase,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Nueva Transacción'), findsOneWidget);
      expect(find.text('Cliente *'), findsOneWidget);
      expect(find.text('Tipo de Transacción *'), findsOneWidget);
      expect(find.text('Recarga (+)'), findsOneWidget);
      expect(find.text('Retiro (-)'), findsOneWidget);
      expect(find.text('Fecha *'), findsOneWidget);
      expect(find.text('Valor de la Transacción (\$) *'), findsOneWidget);
      expect(find.text('Observación'), findsOneWidget);
      expect(find.text('Registrar Transacción'), findsOneWidget);
    });

    testWidgets('Debe permitir seleccionar el tipo entre Recarga y Retiro', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final txRepo = MockTransactionRepo();
      final clientRepo = MockClientRepo(testClients);
      final saveTxUseCase = SaveTransactionUseCase(txRepo);
      final getClientsUseCase = GetClientsUseCase(clientRepo);
      final getProfileUseCase = GetProfileUseCase(MockProfileRepo());

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: TransactionFormScreen(
            user: testUser,
            saveTransactionUseCase: saveTxUseCase,
            getClientsUseCase: getClientsUseCase,
            getProfileUseCase: getProfileUseCase,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tocar en Retiro (-)
      await tester.tap(find.text('Retiro (-)'));
      await tester.pump();

      // Tocar nuevamente en Recarga (+)
      await tester.tap(find.text('Recarga (+)'));
      await tester.pump();

      expect(find.text('Recarga (+)'), findsOneWidget);
      expect(find.text('Retiro (-)'), findsOneWidget);
    });

    testWidgets('Debe registrar exitosamente una transacción cuando los campos son válidos', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final txRepo = MockTransactionRepo();
      final clientRepo = MockClientRepo(testClients);
      final saveTxUseCase = SaveTransactionUseCase(txRepo);
      final getClientsUseCase = GetClientsUseCase(clientRepo);
      final getProfileUseCase = GetProfileUseCase(MockProfileRepo());

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: TransactionFormScreen(
            user: testUser,
            clienteIdPreseleccionado: 'c1',
            saveTransactionUseCase: saveTxUseCase,
            getClientsUseCase: getClientsUseCase,
            getProfileUseCase: getProfileUseCase,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Ingresar valor
      await tester.enterText(
        find.widgetWithText(AppTextField, 'Valor de la Transacción (\$) *'),
        '1500000',
      );

      // Ingresar observación
      await tester.enterText(
        find.widgetWithText(AppTextField, 'Observación'),
        'Abono inicial en efectivo',
      );

      await tester.pump();

      // Guardar transacción
      await tester.tap(find.text('Registrar Transacción'));
      await tester.pumpAndSettle();

      expect(txRepo.items.length, 1);
      expect(txRepo.items.first.clienteId, 'c1');
      expect(txRepo.items.first.tipo, TransactionType.recarga);
      expect(txRepo.items.first.valor, 1500000.0);
      expect(txRepo.items.first.observacion, 'Abono inicial en efectivo');
    });

    testWidgets('Debe mostrar en solo lectura las transacciones automáticas creadas por instrumentos', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final autoTx = Transaction(
        id: 'tx-auto-1',
        clienteId: 'c1',
        clienteNombre: 'Juan Camilo',
        tipo: TransactionType.inversion,
        valor: 5000000.0,
        fecha: DateTime(2026, 3, 1),
        instrumentoId: 'inst-999',
        observacion: 'Participación en CDT Davivienda',
      );

      final txRepo = MockTransactionRepo();
      final clientRepo = MockClientRepo(testClients);
      final saveTxUseCase = SaveTransactionUseCase(txRepo);
      final getClientsUseCase = GetClientsUseCase(clientRepo);
      final getProfileUseCase = GetProfileUseCase(MockProfileRepo());

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: TransactionFormScreen(
            user: testUser,
            transaction: autoTx,
            saveTransactionUseCase: saveTxUseCase,
            getClientsUseCase: getClientsUseCase,
            getProfileUseCase: getProfileUseCase,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verificación de solo lectura
      expect(find.text('Detalle Transacción'), findsOneWidget);
      expect(
        find.textContaining('Esta transacción fue creada automáticamente por un instrumento financiero'),
        findsOneWidget,
      );
      expect(find.text('Instrumento Referenciado'), findsOneWidget);
      expect(find.text('inst-999'), findsOneWidget);

      // No debe mostrar botón de registrar o guardar cambios
      expect(find.text('Registrar Transacción'), findsNothing);
      expect(find.text('Guardar Cambios'), findsNothing);
    });
  });
}
