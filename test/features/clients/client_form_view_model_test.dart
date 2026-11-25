import 'package:flutter_test/flutter_test.dart';
import 'package:koralis_app/features/clients/domain/entities/client.dart';
import 'package:koralis_app/features/clients/domain/repositories/client_repository.dart';
import 'package:koralis_app/features/clients/domain/usecases/save_client_usecase.dart';
import 'package:koralis_app/features/clients/presentation/viewmodels/client_form_view_model.dart';

class _FakeClientRepo implements ClientRepository {
  final List<Client> items = [];
  bool shouldFail = false;

  @override
  Future<List<Client>> getClients() async => items;

  @override
  Future<void> addClient(Client client) async {
    if (shouldFail) throw Exception('Error de escritura');
    final idx = items.indexWhere((c) => c.id == client.id && c.id.isNotEmpty);
    if (idx >= 0) {
      items[idx] = client;
    } else {
      items.add(client);
    }
  }

  @override
  Future<void> deleteClient(String id) async {}
}

void main() {
  group('ClientFormViewModel', () {
    test('Modo creación guarda nuevo cliente y actualiza estado', () async {
      final repo = _FakeClientRepo();
      final vm = ClientFormViewModel(
        userId: 'user-1',
        saveClientUseCase: SaveClientUseCase(repo),
      );

      expect(vm.esEdicion, isFalse);
      expect(vm.estadoSeleccionado, equals('Activo'));

      vm.seleccionarEstado('Inactivo');
      expect(vm.estadoSeleccionado, equals('Inactivo'));

      final guardado = await vm.guardarCliente(
        nombre: ' Laura Pérez ',
        documento: ' 12345 ',
        correo: 'laura@test.com',
        telefono: '3001234567',
        observacion: 'Nota',
      );

      expect(vm.guardando, isFalse);
      expect(guardado.nombre, equals('Laura Pérez'));
      expect(guardado.estado, equals('Inactivo'));
      expect(repo.items.length, equals(1));
    });

    test('Modo edición preserva id y fechaCreacion, y captura errores al guardar', () async {
      final repo = _FakeClientRepo();
      final fechaOriginal = DateTime(2026, 1, 15);
      final existente = Client(
        id: 'cli-99',
        nombre: 'Mauricio',
        documento: '900111',
        correo: 'm@test.com',
        telefono: '310',
        estado: 'Activo',
        fechaCreacion: fechaOriginal,
      );
      repo.items.add(existente);

      final vm = ClientFormViewModel(
        userId: 'user-1',
        clientInicial: existente,
        saveClientUseCase: SaveClientUseCase(repo),
      );

      expect(vm.esEdicion, isTrue);

      final actualizado = await vm.guardarCliente(
        nombre: 'Mauricio Editado',
        documento: '900111',
        correo: 'm@test.com',
        telefono: '310',
        observacion: 'Actualizado',
      );

      expect(actualizado.id, equals('cli-99'));
      expect(actualizado.fechaCreacion, equals(fechaOriginal));
      expect(repo.items.single.nombre, equals('Mauricio Editado'));

      repo.shouldFail = true;
      await expectLater(
        () => vm.guardarCliente(
          nombre: 'Mauricio Editado',
          documento: '900111',
          correo: 'm@test.com',
          telefono: '310',
          observacion: '',
        ),
        throwsException,
      );
      expect(vm.guardando, isFalse);
      expect(vm.errorMessage, contains('Error de escritura'));
    });
  });
}
