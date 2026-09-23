import '../entities/client.dart';
import '../repositories/client_repository.dart';

/// Caso de uso para registrar un nuevo cliente o persistir modificaciones de uno existente.
///
/// Aplica validaciones de reglas de negocio para asegurar integridad en los datos
/// requeridos antes de delegar la persistencia al repositorio.
class SaveClientUseCase {
  /// Repositorio de clientes abstracto inyectado.
  final ClientRepository repository;

  SaveClientUseCase(this.repository);

  /// Valida y persiste el cliente provisto.
  ///
  /// Lanza [ArgumentError] si el nombre o la identificación se encuentran vacíos.
  Future<void> execute(Client client) async {
    if (client.nombre.trim().isEmpty) {
      throw ArgumentError('El nombre del cliente no puede estar vacío');
    }

    if (client.documento.trim().isEmpty) {
      throw ArgumentError('El documento o identificación del cliente no puede estar vacío');
    }

    await repository.addClient(client);
  }
}
