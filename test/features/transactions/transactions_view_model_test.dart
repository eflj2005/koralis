import 'package:flutter_test/flutter_test.dart';
import 'package:koralis_app/features/clients/domain/entities/client.dart';
import 'package:koralis_app/features/clients/domain/repositories/client_repository.dart';
import 'package:koralis_app/features/clients/domain/usecases/get_clients_usecase.dart';
import 'package:koralis_app/features/transactions/domain/entities/transaction.dart';
import 'package:koralis_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:koralis_app/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:koralis_app/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:koralis_app/features/transactions/presentation/viewmodels/transactions_view_model.dart';

class _FakeTxRepo implements TransactionRepository {
  final List<Transaction> items;
  bool shouldFail = false;

  _FakeTxRepo(this.items);

  @override
  Future<List<Transaction>> getTransactions({String? clienteId}) async {
    if (shouldFail) throw Exception('Error de red');
    if (clienteId != null && clienteId.isNotEmpty) {
      return items.where((t) => t.clienteId == clienteId).toList();
    }
    return List.from(items);
  }

  @override
  Future<void> saveTransaction(Transaction transaction) async {}

  @override
  Future<void> deleteTransaction(String id, {String? clienteId}) async {
    items.removeWhere((t) => t.id == id);
  }
}

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

void main() {
  final ahora = DateTime.now();

  final cli1 = Client(
    id: 'c1',
    nombre: 'Carlos',
    documento: '1',
    correo: 'c@test.com',
    telefono: '300',
  );
  final cli2 = Client(
    id: 'c2',
    nombre: 'Mariana',
    documento: '2',
    correo: 'm@test.com',
    telefono: '301',
  );

  group('TransactionsViewModel', () {
    test('cargarDatos y filtros combinados (cliente, tipo y fechas) funcionan correctamente', () async {
      final tx1 = Transaction(
        id: 't1',
        clienteId: 'c1',
        clienteNombre: 'Carlos',
        tipo: TransactionType.recarga,
        valor: 2000000,
        fecha: DateTime(ahora.year, ahora.month, 5),
      );
      final tx2 = Transaction(
        id: 't2',
        clienteId: 'c2',
        clienteNombre: 'Mariana',
        tipo: TransactionType.retiro,
        valor: 500000,
        fecha: DateTime(ahora.year, ahora.month, 8),
      );
      final txMesPasado = Transaction(
        id: 't3',
        clienteId: 'c1',
        clienteNombre: 'Carlos',
        tipo: TransactionType.recarga,
        valor: 1000000,
        fecha: DateTime(ahora.year, ahora.month - 1, 15),
      );

      final txRepo = _FakeTxRepo([tx1, tx2, txMesPasado]);
      final vm = TransactionsViewModel(
        userId: 'u1',
        getTransactionsUseCase: GetTransactionsUseCase(txRepo),
        deleteTransactionUseCase: DeleteTransactionUseCase(txRepo),
        getClientsUseCase: GetClientsUseCase(_FakeClientRepo([cli1, cli2])),
      );

      await vm.cargarDatos();
      expect(vm.isLoading, isFalse);
      expect(vm.esMesActual, isTrue);
      // Por defecto filtra al mes actual (2 transacciones)
      expect(vm.transaccionesFiltradas.length, equals(2));

      // Filtrar por cliente
      vm.setFiltroCliente('c2');
      expect(vm.transaccionesFiltradas.single.id, equals('t2'));

      // Limpiar cliente y filtrar por tipo
      vm.setFiltroCliente(null);
      vm.setFiltroTipo(TransactionType.recarga);
      expect(vm.transaccionesFiltradas.single.id, equals('t1'));
      expect(vm.hayFiltrosActivos, isTrue);

      // Validación de rango de fechas inválido
      final fechaFutura = vm.fechaFinal.add(const Duration(days: 5));
      expect(vm.actualizarFechaInicial(fechaFutura), isFalse);

      final fechaPasada = vm.fechaInicial.subtract(const Duration(days: 5));
      expect(vm.actualizarFechaFinal(fechaPasada), isFalse);

      // Ampliar fecha inicial al mes pasado incluye t3
      vm.setFiltroTipo(null);
      expect(
        vm.actualizarFechaInicial(DateTime(ahora.year, ahora.month - 1, 1)),
        isTrue,
      );
      expect(vm.transaccionesFiltradas.length, equals(3));

      // Restablecer al mes actual
      vm.restablecerMesActual();
      expect(vm.esMesActual, isTrue);
      expect(vm.transaccionesFiltradas.length, equals(2));
    });

    test('eliminarTransaccion recalcula el saldo resultante incluso si queda negativo', () async {
      final txRecarga = Transaction(
        id: 't1',
        clienteId: 'c1',
        clienteNombre: 'Carlos',
        tipo: TransactionType.recarga,
        valor: 2000000,
        fecha: DateTime(ahora.year, ahora.month, 5),
      );
      final txRetiro = Transaction(
        id: 't2',
        clienteId: 'c1',
        clienteNombre: 'Carlos',
        tipo: TransactionType.retiro,
        valor: 1500000,
        fecha: DateTime(ahora.year, ahora.month, 6),
      );

      final txRepo = _FakeTxRepo([txRecarga, txRetiro]);
      final vm = TransactionsViewModel(
        userId: 'u1',
        getTransactionsUseCase: GetTransactionsUseCase(txRepo),
        deleteTransactionUseCase: DeleteTransactionUseCase(txRepo),
        getClientsUseCase: GetClientsUseCase(_FakeClientRepo([cli1])),
      );

      await vm.cargarDatos();
      final nuevoSaldo = await vm.eliminarTransaccion(txRecarga);

      expect(nuevoSaldo, equals(-1500000.0));
      expect(vm.transacciones.length, equals(1));
      expect(vm.transacciones.single.id, equals('t2'));
    });
  });
}
