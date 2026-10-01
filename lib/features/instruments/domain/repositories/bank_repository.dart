import '../entities/bank.dart';

/// Contrato abstracto del repositorio para la obtención de bancos/entidades financieras.
abstract class BankRepository {
  /// Obtiene la lista completa de bancos registrados en la colección 'banks'.
  Future<List<Bank>> getBanks();
}
