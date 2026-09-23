import '../entities/client.dart';

/// Contrato abstracto del repositorio para la gestión y persistencia de clientes.
abstract class ClientRepository {
  /// Obtiene la lista completa de clientes registrados.
  Future<List<Client>> getClients();

  /// Registra y persiste un nuevo cliente en el repositorio.
  Future<void> addClient(Client client);
}
