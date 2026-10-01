import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

/// Caso de uso para obtener las transacciones registradas, ordenadas de la más reciente a la más antigua.
class GetTransactionsUseCase {
  final TransactionRepository _repository;

  GetTransactionsUseCase(this._repository);

  Future<List<Transaction>> execute({String? clienteId}) async {
    final transacciones = await _repository.getTransactions(clienteId: clienteId);
    transacciones.sort((a, b) => b.fecha.compareTo(a.fecha));
    return transacciones;
  }
}
