import 'package:flutter_test/flutter_test.dart';
import 'package:koralis_app/features/clients/domain/entities/client.dart';
import 'package:koralis_app/features/clients/domain/repositories/client_repository.dart';
import 'package:koralis_app/features/clients/domain/usecases/save_client_usecase.dart';

/// Implementación simulada del repositorio de clientes para pruebas unitarias
class MockClientRepository implements ClientRepository {
  final List<Client> _clientes;

  MockClientRepository([List<Client>? clientesIniciales])
      : _clientes = clientesIniciales != null ? List.from(clientesIniciales) : [];

  @override
  Future<List<Client>> getClients() async {
    return List.unmodifiable(_clientes);
  }

  @override
  Future<void> addClient(Client client) async {
    final indice = _clientes.indexWhere((c) => c.id == client.id);
    if (indice >= 0) {
      _clientes[indice] = client;
    } else {
      _clientes.add(client);
    }
  }
}

void main() {
  group('SaveClientUseCase Tests', () {
    late MockClientRepository mockRepo;
    late SaveClientUseCase useCase;

    setUp(() {
      mockRepo = MockClientRepository();
      useCase = SaveClientUseCase(mockRepo);
    });

    test('Debe registrar un nuevo cliente cuando los datos son válidos', () async {
      final nuevoCliente = Client(
        id: '1',
        nombre: 'Carolina Herrera',
        documento: 'CC 987654321',
        correo: 'carolina@test.com',
        telefono: '+57 311 000 1122',
        observacion: 'Cliente VIP',
        estado: 'Activo',
      );

      await useCase.execute(nuevoCliente);

      final clientes = await mockRepo.getClients();
      expect(clientes.length, equals(1));
      expect(clientes.first.nombre, equals('Carolina Herrera'));
      expect(clientes.first.documento, equals('CC 987654321'));
    });

    test('Debe actualizar un cliente existente cuando su ID ya existe', () async {
      final clienteInicial = Client(
        id: '1',
        nombre: 'Carolina Herrera',
        documento: 'CC 987654321',
        correo: 'carolina@test.com',
        telefono: '+57 311 000 1122',
        observacion: 'Cliente VIP',
        estado: 'Activo',
      );
      await useCase.execute(clienteInicial);

      final clienteModificado = clienteInicial.copyWith(
        observacion: 'Cliente VIP Actualizado',
        estado: 'Inactivo',
      );
      await useCase.execute(clienteModificado);

      final clientes = await mockRepo.getClients();
      expect(clientes.length, equals(1));
      expect(clientes.first.observacion, equals('Cliente VIP Actualizado'));
      expect(clientes.first.estado, equals('Inactivo'));
    });

    test('Debe lanzar ArgumentError si el nombre está vacío', () async {
      final clienteInvalido = Client(
        id: '2',
        nombre: '   ',
        documento: 'CC 12345',
        correo: 'invalido@test.com',
        telefono: '3000000000',
      );

      expect(
        () => useCase.execute(clienteInvalido),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Debe lanzar ArgumentError si el documento está vacío', () async {
      final clienteInvalido = Client(
        id: '3',
        nombre: 'Carlos Ruiz',
        documento: '   ',
        correo: 'carlos@test.com',
        telefono: '3000000000',
      );

      expect(
        () => useCase.execute(clienteInvalido),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
