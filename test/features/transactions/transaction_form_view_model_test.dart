import 'package:flutter_test/flutter_test.dart';
import 'package:koralis_app/features/clients/domain/entities/client.dart';
import 'package:koralis_app/features/clients/domain/repositories/client_repository.dart';
import 'package:koralis_app/features/clients/domain/usecases/get_clients_usecase.dart';
import 'package:koralis_app/features/transactions/domain/entities/transaction.dart';
import 'package:koralis_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:koralis_app/features/transactions/domain/usecases/save_transaction_usecase.dart';
import 'package:koralis_app/features/transactions/presentation/viewmodels/transaction_form_view_model.dart';

class _FakeClientRepo implements ClientRepository {
  final List<Client> items;
  _FakeClientRepo(this.items);

  @override
  Future<List<Client>> getClients() async => items;

  @override
  Future<void> addClient(Client client) async {}

  @override
  Future<void> deleteClient(String id) async {}
}

class _FakeTxRepo implements TransactionRepository {
  final List<Transaction> items = [];
  bool shouldFail = false;

  @override
  Future<List<Transaction>> getTransactions({String? clienteId}) async => items;

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    if (shouldFail) throw Exception('Error al guardar');
    items.add(transaction);
  }

  @override
  Future<void> deleteTransaction(String id, {String? clienteId}) async {}
}

void main() {
  final cli1 = Client(
    id: 'c1',
    nombre: 'Carlos Gómez',
    documento: '1010',
    correo: 'c@test.com',
    telefono: '300',
  );

  group('TransactionFormViewModel', () {
    test('Carga clientes, resuelve preselección y guarda nueva transacción', () async {
      final txRepo = _FakeTxRepo();
      final vm = TransactionFormViewModel(
        userId: 'u1',
        clienteIdPreseleccionado: 'c1',
        saveTransactionUseCase: SaveTransactionUseCase(txRepo),
        getClientsUseCase: GetClientsUseCase(_FakeClientRepo([cli1])),
      );

      await vm.cargarClientes();
      expect(vm.cargandoClientes, isFalse);
      expect(vm.clienteIdSeleccionado, equals('c1'));
      expect(vm.clienteNombreSeleccionado, equals('Carlos Gómez'));

      vm.seleccionarTipo(TransactionType.retiro);
      expect(vm.tipoSeleccionado, equals(TransactionType.retiro));

      final guardada = await vm.guardarTransaccion(
        valor: 450000,
        observacion: ' Retiro de prueba ',
      );

      expect(vm.guardando, isFalse);
      expect(guardada.valor, equals(450000));
      expect(guardada.observacion, equals('Retiro de prueba'));
      expect(txRepo.items.length, equals(1));
    });

    test('En transacciones automáticas bloquea cambios de tipo y fecha', () async {
      final fechaOriginal = DateTime(2026, 3, 10);
      final txAuto = Transaction(
        id: 'tx-auto',
        clienteId: 'c1',
        clienteNombre: 'Carlos Gómez',
        tipo: TransactionType.inversion,
        valor: 5000000,
        fecha: fechaOriginal,
        instrumentoId: 'inst-1',
      );

      final vm = TransactionFormViewModel(
        userId: 'u1',
        transactionInicial: txAuto,
        saveTransactionUseCase: SaveTransactionUseCase(_FakeTxRepo()),
        getClientsUseCase: GetClientsUseCase(_FakeClientRepo([cli1])),
      );

      expect(vm.esEdicion, isTrue);
      expect(vm.esAutomatica, isTrue);

      vm.seleccionarTipo(TransactionType.recarga);
      vm.seleccionarFecha(DateTime(2026, 5, 1));

      expect(vm.tipoSeleccionado, equals(TransactionType.inversion));
      expect(vm.fecha, equals(fechaOriginal));
    });
  });
}
