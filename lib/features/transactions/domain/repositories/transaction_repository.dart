import '../entities/transaction.dart';

/// Contrato abstracto del repositorio para la persistencia y consulta de transacciones.
abstract class TransactionRepository {
  /// Obtiene la lista completa de transacciones, con opción de filtrar por un cliente específico.
  Future<List<Transaction>> getTransactions({String? clienteId});

  /// Registra o actualiza una transacción en el almacén de datos.
  Future<void> saveTransaction(Transaction transaction);

  /// Elimina una transacción por su identificador único, opcionalmente indicando el cliente al que pertenece.
  Future<void> deleteTransaction(String id, {String? clienteId});
}
