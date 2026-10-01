import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koralis_app/features/auth/domain/entities/user.dart';
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

  group('TransactionsScreen - Visualización y gestión de transacciones', () {
    testWidgets('Debe mostrar estado vacío cuando no existen transacciones', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = MockTransactionRepo([]);
      final getTransactions = GetTransactionsUseCase(repo);
      final getProfile = GetProfileUseCase(MockProfileRepo());

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: TransactionsScreen(
            user: testUser,
            getTransactionsUseCase: getTransactions,
            getProfileUseCase: getProfile,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No hay transacciones registradas'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('Debe renderizar la lista de transacciones con sus tarjetas y badges', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tx1 = Transaction(
        id: 'tx-1',
        clienteId: 'c1',
        clienteNombre: 'Carlos Gómez',
        tipo: TransactionType.recarga,
        valor: 2000000.0,
        fecha: DateTime(2026, 3, 1),
        observacion: 'Depósito por transferencia',
      );

      final tx2 = Transaction(
        id: 'tx-2',
        clienteId: 'c2',
        clienteNombre: 'Mariana Duarte',
        tipo: TransactionType.retiro,
        valor: 500000.0,
        fecha: DateTime(2026, 3, 2),
        observacion: 'Retiro bancario',
      );

      final repo = MockTransactionRepo([tx1, tx2]);
      final getTransactions = GetTransactionsUseCase(repo);
      final getProfile = GetProfileUseCase(MockProfileRepo());

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: TransactionsScreen(
            user: testUser,
            getTransactionsUseCase: getTransactions,
            getProfileUseCase: getProfile,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verificar que se listan los nombres de los clientes
      expect(find.textContaining('Carlos Gómez'), findsOneWidget);
      expect(find.textContaining('Mariana Duarte'), findsOneWidget);

      // Verificar badges de tipo
      expect(find.text('Recarga'), findsWidgets);
      expect(find.text('Retiro'), findsWidgets);

      // Verificar valores con signo formateado
      expect(find.textContaining('+ \$ 2.000.000,00'), findsOneWidget);
      expect(find.textContaining('- \$ 500.000,00'), findsOneWidget);
    });

    testWidgets('Debe filtrar la lista al seleccionar un chip de tipo', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tx1 = Transaction(
        id: 'tx-1',
        clienteId: 'c1',
        clienteNombre: 'Carlos Gómez',
        tipo: TransactionType.recarga,
        valor: 2000000.0,
        fecha: DateTime(2026, 3, 1),
      );

      final tx2 = Transaction(
        id: 'tx-2',
        clienteId: 'c2',
        clienteNombre: 'Mariana Duarte',
        tipo: TransactionType.retiro,
        valor: 500000.0,
        fecha: DateTime(2026, 3, 2),
      );

      final repo = MockTransactionRepo([tx1, tx2]);
      final getTransactions = GetTransactionsUseCase(repo);
      final getProfile = GetProfileUseCase(MockProfileRepo());

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: TransactionsScreen(
            user: testUser,
            getTransactionsUseCase: getTransactions,
            getProfileUseCase: getProfile,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Ambas transacciones visibles
      expect(find.textContaining('Carlos Gómez'), findsOneWidget);
      expect(find.textContaining('Mariana Duarte'), findsOneWidget);

      // Seleccionar chip 'Recargas'
      await tester.tap(find.text('Recargas'));
      await tester.pumpAndSettle();

      // Solo Carlos Gómez debe estar visible
      expect(find.textContaining('Carlos Gómez'), findsOneWidget);
      expect(find.textContaining('Mariana Duarte'), findsNothing);

      // Seleccionar chip 'Retiros' con ensureVisible para scroll horizontal
      await tester.ensureVisible(find.text('Retiros'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retiros'));
      await tester.pumpAndSettle();

      // Solo Mariana Duarte debe estar visible
      expect(find.textContaining('Carlos Gómez'), findsNothing);
      expect(find.textContaining('Mariana Duarte'), findsOneWidget);
    });

    testWidgets('Tocar una tarjeta debe abrir el modal de detalle inferior', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tx = Transaction(
        id: 'tx-1',
        clienteId: 'c1',
        clienteNombre: 'Carlos Gómez',
        tipo: TransactionType.recarga,
        valor: 2000000.0,
        fecha: DateTime(2026, 3, 1),
        observacion: 'Depósito en efectivo',
      );

      final repo = MockTransactionRepo([tx]);
      final getTransactions = GetTransactionsUseCase(repo);
      final getProfile = GetProfileUseCase(MockProfileRepo());

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: TransactionsScreen(
            user: testUser,
            getTransactionsUseCase: getTransactions,
            getProfileUseCase: getProfile,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tocar la tarjeta
      await tester.tap(find.textContaining('Carlos Gómez'));
      await tester.pumpAndSettle();

      // Verificar modal inferior
      expect(find.text('Valor de la Transacción'), findsOneWidget);
      expect(find.text('Depósito en efectivo'), findsWidgets);
      expect(find.text('Editar Transacción'), findsOneWidget);
    });
  });
}
