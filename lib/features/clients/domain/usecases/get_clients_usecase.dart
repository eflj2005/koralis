import '../entities/client.dart';
import '../repositories/client_repository.dart';

/// Caso de uso para obtener el listado de clientes registrados en el sistema.
///
/// Garantiza la regla de negocio de ordenar la colección de forma alfabética estricta (A - Z)
/// sin importar el orden físico en que provengan de la fuente de datos.
class GetClientsUseCase {
  final ClientRepository repository;

  GetClientsUseCase(this.repository);

  /// Ejecuta la consulta y retorna la lista ordenada alfabéticamente por nombre.
  Future<List<Client>> execute() async {
    final clientes = await repository.getClients();

    // Ordenamiento alfabético ascendente insensible a mayúsculas/minúsculas y tildes
    clientes.sort((a, b) {
      return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
    });

    return clientes;
  }
}
