import '../entities/client.dart';
import '../repositories/client_repository.dart';

/// Caso de uso para registrar y persistir un nuevo cliente en el sistema.
class AddClientUseCase {
  final ClientRepository repository;

  AddClientUseCase(this.repository);

  /// Valida y registra el cliente provisto.
  Future<void> execute(Client client) async {
    if (client.nombre.trim().isEmpty) {
      throw ArgumentError('El nombre del cliente no puede estar vacío');
    }
    await repository.addClient(client);
  }
}
