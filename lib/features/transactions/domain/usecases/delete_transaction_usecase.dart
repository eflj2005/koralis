import '../repositories/transaction_repository.dart';

/// Caso de uso para eliminar una transacción financiera del repositorio.
class DeleteTransactionUseCase {
  final TransactionRepository _repository;

  DeleteTransactionUseCase(this._repository);

  /// Ejecuta la eliminación de una transacción por su ID y opcionalmente el ID del cliente asociado.
  Future<void> execute(String id, {String? clienteId}) async {
    if (id.trim().isEmpty) {
      throw ArgumentError('El identificador de la transacción no puede estar vacío');
    }
    return _repository.deleteTransaction(id, clienteId: clienteId);
  }
}
