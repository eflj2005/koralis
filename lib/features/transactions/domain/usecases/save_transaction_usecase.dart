import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

/// Caso de uso para validar y registrar o actualizar una transacción financiera.
class SaveTransactionUseCase {
  final TransactionRepository _repository;

  SaveTransactionUseCase(this._repository);

  Future<void> execute(Transaction transaction) async {
    if (transaction.clienteId.trim().isEmpty) {
      throw ArgumentError('La transacción debe estar asociada a un cliente válido');
    }
    if (transaction.valor <= 0) {
      throw ArgumentError('El valor de la transacción debe ser mayor a cero');
    }
    return _repository.saveTransaction(transaction);
  }
}
