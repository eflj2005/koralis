import 'package:flutter_test/flutter_test.dart';
import 'package:koralis_app/features/clients/domain/entities/client.dart';
import 'package:koralis_app/features/clients/domain/repositories/client_repository.dart';
import 'package:koralis_app/features/clients/domain/usecases/get_clients_usecase.dart';
import 'package:koralis_app/features/clients/domain/usecases/add_client_usecase.dart';

/// Repositorio mock en memoria para pruebas unitarias
class MockClientRepository implements ClientRepository {
  final List<Client> _clientes = [];

  MockClientRepository([List<Client>? iniciales]) {
    if (iniciales != null) {
      _clientes.addAll(iniciales);
    }
  }

  @override
  Future<List<Client>> getClients() async {
    return List<Client>.from(_clientes);
  }

  @override
  Future<void> addClient(Client client) async {
    _clientes.add(client);
  }
}

void main() {
  group('GetClientsUseCase - Ordenamiento Alfabético A-Z', () {
    test('Debe retornar la lista de clientes ordenada alfabéticamente de forma ascendente', () async {
      final clientesDesordenados = [
        Client(
          id: '1',
          nombre: 'Zulma Quintero',
          documento: '101',
          correo: 'zulma@test.com',
          telefono: '111',
          observacion: 'Cliente frecuente',
        ),
        Client(
          id: '2',
          nombre: 'Andrés Morales',
          documento: '102',
          correo: 'andres@test.com',
          telefono: '222',
          observacion: 'Inversionista patrimonial',
        ),
        Client(
          id: '3',
          nombre: 'Carlos Echeverry',
          documento: '103',
          correo: 'carlos@test.com',
          telefono: '333',
          observacion: 'Empresa asociada',
        ),
        Client(
          id: '4',
          nombre: 'Beatriz Salazar',
          documento: '104',
          correo: 'beatriz@test.com',
          telefono: '444',
          observacion: 'Atención personalizada',
        ),
      ];

      final mockRepo = MockClientRepository(clientesDesordenados);
      final useCase = GetClientsUseCase(mockRepo);

      final resultado = await useCase.execute();

      expect(resultado.length, equals(4));
      expect(resultado[0].nombre, equals('Andrés Morales'));
      expect(resultado[1].nombre, equals('Beatriz Salazar'));
      expect(resultado[2].nombre, equals('Carlos Echeverry'));
      expect(resultado[3].nombre, equals('Zulma Quintero'));
    });

    test('Debe retornar una lista vacía cuando no existen clientes en la base de datos', () async {
      final mockRepo = MockClientRepository([]);
      final useCase = GetClientsUseCase(mockRepo);

      final resultado = await useCase.execute();

      expect(resultado, isEmpty);
    });
  });

  group('AddClientUseCase - Registro de Clientes', () {
    test('Debe delegar en el repositorio la persistencia del cliente correctamente', () async {
      final mockRepo = MockClientRepository();
      final addUseCase = AddClientUseCase(mockRepo);

      final nuevoCliente = Client(
        id: '100',
        nombre: 'Diana Marcela Gómez',
        documento: '987654',
        correo: 'diana@test.com',
        telefono: '300123',
        observacion: 'Empresa',
      );

      await addUseCase.execute(nuevoCliente);

      final clientes = await mockRepo.getClients();
      expect(clientes.length, equals(1));
      expect(clientes.first.nombre, equals('Diana Marcela Gómez'));
    });

    test('Debe lanzar ArgumentError si el nombre está vacío', () async {
      final mockRepo = MockClientRepository();
      final addUseCase = AddClientUseCase(mockRepo);

      final clienteInvalido = Client(
        id: '101',
        nombre: '   ',
        documento: '123',
        correo: '',
        telefono: '',
        observacion: 'Persona Natural',
      );

      expect(
        () => addUseCase.execute(clienteInvalido),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
