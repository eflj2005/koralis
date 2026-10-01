import 'package:flutter_test/flutter_test.dart';
import 'package:koralis_app/features/transactions/domain/entities/transaction.dart';
import 'package:koralis_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:koralis_app/features/transactions/domain/usecases/save_transaction_usecase.dart';

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
  Future<void> deleteTransaction(String id, {String? clienteId}) async =>
      items.removeWhere((t) => t.id == id);
}

void main() {
  group('SaveTransactionUseCase Tests', () {
    test('Debe registrar una transacción válida en el repositorio', () async {
      final repo = MockTransactionRepo();
      final useCase = SaveTransactionUseCase(repo);

      final tx = Transaction(
        id: 'tx-1',
        clienteId: 'cli-1',
        clienteNombre: 'Carlos Mendoza',
        tipo: TransactionType.recarga,
        valor: 1000000,
        fecha: DateTime(2026, 3, 1),
      );

      await useCase.execute(tx);

      expect(repo.items.length, equals(1));
      expect(repo.items.first.valor, equals(1000000));
      expect(repo.items.first.clienteNombre, equals('Carlos Mendoza'));
    });

    test('Debe lanzar ArgumentError si el clienteId está vacío', () async {
      final repo = MockTransactionRepo();
      final useCase = SaveTransactionUseCase(repo);

      final txInvalida = Transaction(
        id: 'tx-2',
        clienteId: '  ',
        clienteNombre: '',
        tipo: TransactionType.recarga,
        valor: 500000,
        fecha: DateTime(2026, 3, 1),
      );

      expect(
        () => useCase.execute(txInvalida),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Debe lanzar ArgumentError si el valor es menor o igual a cero', () async {
      final repo = MockTransactionRepo();
      final useCase = SaveTransactionUseCase(repo);

      final txInvalida = Transaction(
        id: 'tx-3',
        clienteId: 'cli-1',
        clienteNombre: 'Carlos',
        tipo: TransactionType.retiro,
        valor: 0,
        fecha: DateTime(2026, 3, 1),
      );

      expect(
        () => useCase.execute(txInvalida),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
