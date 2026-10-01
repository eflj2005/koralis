import 'package:flutter_test/flutter_test.dart';
import 'package:koralis_app/features/transactions/domain/entities/transaction.dart';
import 'package:koralis_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:koralis_app/features/transactions/domain/usecases/get_transactions_usecase.dart';

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
  Future<void> saveTransaction(Transaction transaction) async => items.add(transaction);

  @override
  Future<void> deleteTransaction(String id, {String? clienteId}) async =>
      items.removeWhere((t) => t.id == id);
}

void main() {
  group('GetTransactionsUseCase Tests', () {
    test('Debe retornar las transacciones ordenadas de la más reciente a la más antigua', () async {
      final t1 = Transaction(
        id: '1',
        clienteId: 'c1',
        clienteNombre: 'Cliente 1',
        tipo: TransactionType.recarga,
        valor: 1000,
        fecha: DateTime(2026, 1, 10),
      );
      final t2 = Transaction(
        id: '2',
        clienteId: 'c1',
        clienteNombre: 'Cliente 1',
        tipo: TransactionType.inversion,
        valor: 500,
        fecha: DateTime(2026, 3, 20),
      );
      final t3 = Transaction(
        id: '3',
        clienteId: 'c1',
        clienteNombre: 'Cliente 1',
        tipo: TransactionType.recarga,
        valor: 2000,
        fecha: DateTime(2026, 2, 15),
      );

      final repo = MockTransactionRepo([t1, t2, t3]);
      final useCase = GetTransactionsUseCase(repo);

      final resultado = await useCase.execute();

      expect(resultado.length, equals(3));
      expect(resultado[0].id, equals('2')); // Más reciente (20 de marzo)
      expect(resultado[1].id, equals('3')); // 15 de febrero
      expect(resultado[2].id, equals('1')); // 10 de enero
    });

    test('Debe permitir filtrar por cliente específico', () async {
      final t1 = Transaction(
        id: '1',
        clienteId: 'c1',
        clienteNombre: 'Cliente 1',
        tipo: TransactionType.recarga,
        valor: 1000,
        fecha: DateTime(2026, 1, 10),
      );
      final t2 = Transaction(
        id: '2',
        clienteId: 'c2',
        clienteNombre: 'Cliente 2',
        tipo: TransactionType.recarga,
        valor: 500,
        fecha: DateTime(2026, 1, 11),
      );

      final repo = MockTransactionRepo([t1, t2]);
      final useCase = GetTransactionsUseCase(repo);

      final resultado = await useCase.execute(clienteId: 'c2');

      expect(resultado.length, equals(1));
      expect(resultado.first.clienteNombre, equals('Cliente 2'));
    });
  });
}
