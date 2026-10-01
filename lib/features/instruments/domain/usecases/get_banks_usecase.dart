import '../entities/bank.dart';
import '../repositories/bank_repository.dart';

/// Caso de uso para obtener la lista de bancos disponibles desde la base de datos.
class GetBanksUseCase {
  final BankRepository _repository;

  GetBanksUseCase(this._repository);

  /// Ejecuta la consulta de bancos y retorna la lista correspondiente.
  Future<List<Bank>> execute() => _repository.getBanks();
}
