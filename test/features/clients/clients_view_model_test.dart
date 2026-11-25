import 'package:flutter_test/flutter_test.dart';
import 'package:koralis_app/features/clients/domain/entities/client.dart';
import 'package:koralis_app/features/clients/domain/repositories/client_repository.dart';
import 'package:koralis_app/features/clients/domain/usecases/delete_client_usecase.dart';
import 'package:koralis_app/features/clients/domain/usecases/get_clients_usecase.dart';
import 'package:koralis_app/features/clients/presentation/viewmodels/clients_view_model.dart';
import 'package:koralis_app/features/instruments/domain/entities/instrument.dart';
import 'package:koralis_app/features/instruments/domain/repositories/instrument_repository.dart';
import 'package:koralis_app/features/transactions/domain/entities/transaction.dart';
import 'package:koralis_app/features/transactions/domain/repositories/transaction_repository.dart';

class _FakeClientRepo implements ClientRepository {
  final List<Client> items;
  bool shouldFailGet = false;

  _FakeClientRepo(this.items);

  @override
  Future<List<Client>> getClients() async {
    if (shouldFailGet) throw Exception('Falla de red');
    return List.from(items);
  }

  @override
  Future<void> addClient(Client client) async => items.add(client);

  @override
  Future<void> deleteClient(String id) async =>
      items.removeWhere((c) => c.id == id);
}

class _FakeInstrumentRepo implements InstrumentRepository {
  final List<Instrument> items;
  _FakeInstrumentRepo(this.items);

  @override
  Future<List<Instrument>> getInstruments() async => items;

  @override
  Future<void> saveInstrument(Instrument instrument) async {}

  @override
  Future<void> deleteInstrument(String id) async {}
}

class _FakeTransactionRepo implements TransactionRepository {
  final List<Transaction> items;
  _FakeTransactionRepo(this.items);

  @override
  Future<List<Transaction>> getTransactions({String? clienteId}) async =>
      clienteId == null
          ? items
          : items.where((t) => t.clienteId == clienteId).toList();

  @override
  Future<void> saveTransaction(Transaction transaction) async {}

  @override
  Future<void> deleteTransaction(String id, {String? clienteId}) async {}
}

void main() {
  final cli1 = Client(
    id: 'c1',
    nombre: 'Zulma Quintero',
    documento: '1001',
    correo: 'zulma@test.com',
    telefono: '3001',
  );
  final cli2 = Client(
    id: 'c2',
    nombre: 'Alberto Gómez',
    documento: '1002',
    correo: 'alberto@test.com',
    telefono: '3002',
  );

  group('ClientsViewModel', () {
    test('cargarClientes ordena alfabéticamente y maneja estado de carga/error', () async {
      final repo = _FakeClientRepo([cli1, cli2]);
      final vm = ClientsViewModel(
        userId: 'u1',
        getClientsUseCase: GetClientsUseCase(repo),
        deleteClientUseCase: DeleteClientUseCase(
          clientRepository: repo,
          instrumentRepository: _FakeInstrumentRepo([]),
          transactionRepository: _FakeTransactionRepo([]),
        ),
      );

      await vm.cargarClientes();
      expect(vm.isLoading, isFalse);
      expect(vm.errorMessage, isNull);
      expect(vm.clientes.map((c) => c.nombre).toList(),
          equals(['Alberto Gómez', 'Zulma Quintero']));

      repo.shouldFailGet = true;
      await vm.cargarClientes();
      expect(vm.errorMessage, contains('Falla de red'));
    });

    test('eliminarCliente borra sin asociaciones y propaga bloqueo si tiene transacciones', () async {
      final repo = _FakeClientRepo([cli1, cli2]);
      final txRepo = _FakeTransactionRepo([
        Transaction(
          id: 'tx1',
          clienteId: 'c1',
          clienteNombre: 'Zulma Quintero',
          tipo: TransactionType.recarga,
          valor: 100000,
          fecha: DateTime(2026, 5, 1),
        ),
      ]);
      final vm = ClientsViewModel(
        userId: 'u1',
        getClientsUseCase: GetClientsUseCase(repo),
        deleteClientUseCase: DeleteClientUseCase(
          clientRepository: repo,
          instrumentRepository: _FakeInstrumentRepo([]),
          transactionRepository: txRepo,
        ),
      );

      await vm.cargarClientes();
      expect(vm.clientes.length, equals(2));

      // Bloquea c1 por tener transacción
      await expectLater(
        () => vm.eliminarCliente(cli1),
        throwsA(isA<ClientDeletionBlockedException>()),
      );
      expect(vm.eliminando, isFalse);
      expect(vm.clientes.length, equals(2));

      // Elimina c2 sin asociaciones y recarga lista
      await vm.eliminarCliente(cli2);
      expect(vm.eliminando, isFalse);
      expect(vm.clientes.length, equals(1));
      expect(vm.clientes.single.id, equals('c1'));
    });

    test('cargarClientes expone saldoDisponible calculado con ingresos, egresos, negativo y cero', () async {
      final conMovimientos = Client(
        id: 'c-pos',
        nombre: 'Ana Positiva',
        documento: '2001',
        correo: 'ana@test.com',
        telefono: '3001',
        transacciones: [
          Transaction(
            id: 't1',
            clienteId: 'c-pos',
            clienteNombre: 'Ana Positiva',
            tipo: TransactionType.recarga,
            valor: 1000000,
            fecha: DateTime(2026, 5, 1),
          ),
          Transaction(
            id: 't2',
            clienteId: 'c-pos',
            clienteNombre: 'Ana Positiva',
            tipo: TransactionType.inversion,
            valor: 400000,
            fecha: DateTime(2026, 5, 2),
          ),
          Transaction(
            id: 't3',
            clienteId: 'c-pos',
            clienteNombre: 'Ana Positiva',
            tipo: TransactionType.retorno,
            valor: 150000,
            fecha: DateTime(2026, 5, 3),
          ),
          Transaction(
            id: 't4',
            clienteId: 'c-pos',
            clienteNombre: 'Ana Positiva',
            tipo: TransactionType.retiro,
            valor: 50000,
            fecha: DateTime(2026, 5, 4),
          ),
        ],
      );

      final conNegativo = Client(
        id: 'c-neg',
        nombre: 'Beto Negativo',
        documento: '2002',
        correo: 'beto@test.com',
        telefono: '3002',
        transacciones: [
          Transaction(
            id: 't5',
            clienteId: 'c-neg',
            clienteNombre: 'Beto Negativo',
            tipo: TransactionType.recarga,
            valor: 100000,
            fecha: DateTime(2026, 5, 1),
          ),
          Transaction(
            id: 't6',
            clienteId: 'c-neg',
            clienteNombre: 'Beto Negativo',
            tipo: TransactionType.retiro,
            valor: 150000,
            fecha: DateTime(2026, 5, 2),
          ),
        ],
      );

      final sinMovimientos = Client(
        id: 'c-cero',
        nombre: 'Carlos Cero',
        documento: '2003',
        correo: 'carlos@test.com',
        telefono: '3003',
      );

      final repo = _FakeClientRepo([conMovimientos, conNegativo, sinMovimientos]);
      final vm = ClientsViewModel(
        userId: 'u1',
        getClientsUseCase: GetClientsUseCase(repo),
        deleteClientUseCase: DeleteClientUseCase(
          clientRepository: repo,
          instrumentRepository: _FakeInstrumentRepo([]),
          transactionRepository: _FakeTransactionRepo([]),
        ),
      );

      await vm.cargarClientes();

      expect(vm.clientes[0].saldoDisponible, 700000.0);
      expect(vm.clientes[1].saldoDisponible, -50000.0);
      expect(vm.clientes[2].saldoDisponible, 0.0);
    });
  });
}
