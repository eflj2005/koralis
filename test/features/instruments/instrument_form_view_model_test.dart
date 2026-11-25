import 'package:flutter_test/flutter_test.dart';
import 'package:koralis_app/features/clients/domain/entities/client.dart';
import 'package:koralis_app/features/clients/domain/repositories/client_repository.dart';
import 'package:koralis_app/features/clients/domain/usecases/get_clients_usecase.dart';
import 'package:koralis_app/features/instruments/domain/entities/bank.dart';
import 'package:koralis_app/features/instruments/domain/entities/instrument.dart';
import 'package:koralis_app/features/instruments/domain/repositories/bank_repository.dart';
import 'package:koralis_app/features/instruments/domain/repositories/instrument_repository.dart';
import 'package:koralis_app/features/instruments/domain/usecases/get_banks_usecase.dart';
import 'package:koralis_app/features/instruments/domain/usecases/process_instrument_save_usecase.dart';
import 'package:koralis_app/features/instruments/domain/usecases/save_instrument_usecase.dart';
import 'package:koralis_app/features/instruments/presentation/viewmodels/instrument_form_view_model.dart';
import 'package:koralis_app/features/transactions/domain/entities/transaction.dart';
import 'package:koralis_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:koralis_app/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:koralis_app/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:koralis_app/features/transactions/domain/usecases/save_transaction_usecase.dart';

class _FakeBankRepo implements BankRepository {
  @override
  Future<List<Bank>> getBanks() async =>
      const [Bank(id: 'b1', nombre: 'Bancolombia')];
}

class _FakeInstRepo implements InstrumentRepository {
  final List<Instrument> items = [];

  @override
  Future<List<Instrument>> getInstruments() async => items;

  @override
  Future<void> saveInstrument(Instrument instrument) async {
    final idx = items.indexWhere((i) => i.id == instrument.id);
    if (idx >= 0) {
      items[idx] = instrument;
    } else {
      items.add(instrument);
    }
  }

  @override
  Future<void> deleteInstrument(String id) async {}
}

class _FakeTxRepo implements TransactionRepository {
  final List<Transaction> txs;
  _FakeTxRepo(this.txs);

  @override
  Future<List<Transaction>> getTransactions({String? clienteId}) async =>
      clienteId == null
          ? txs
          : txs.where((t) => t.clienteId == clienteId).toList();

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    final idx = txs.indexWhere((t) => t.id == transaction.id);
    if (idx >= 0) {
      txs[idx] = transaction;
    } else {
      txs.add(transaction);
    }
  }

  @override
  Future<void> deleteTransaction(String id, {String? clienteId}) async {
    txs.removeWhere((t) => t.id == id);
  }
}

class _FakeClientRepo implements ClientRepository {
  final List<Client> clientes;
  final _FakeTxRepo txRepo;

  _FakeClientRepo(this.clientes, this.txRepo);

  @override
  Future<List<Client>> getClients() async {
    return clientes.map((c) {
      final txsC = txRepo.txs.where((t) => t.clienteId == c.id).toList();
      return c.copyWith(transacciones: txsC);
    }).toList();
  }

  @override
  Future<void> addClient(Client client) async {}

  @override
  Future<void> deleteClient(String id) async {}
}

void main() {
  group('InstrumentFormViewModel', () {
    test('Cálculos financieros reactivos e inicialización de bancos', () async {
      final instRepo = _FakeInstRepo();
      final txRepo = _FakeTxRepo([]);
      final vm = InstrumentFormViewModel(
        userId: 'u1',
        saveInstrumentUseCase: SaveInstrumentUseCase(instRepo),
        getBanksUseCase: GetBanksUseCase(_FakeBankRepo()),
        getTransactionsUseCase: GetTransactionsUseCase(txRepo),
        getClientsUseCase: GetClientsUseCase(_FakeClientRepo([], txRepo)),
        saveTransactionUseCase: SaveTransactionUseCase(txRepo),
        deleteTransactionUseCase: DeleteTransactionUseCase(txRepo),
      );

      await vm.inicializar();
      expect(vm.cargandoBancos, isFalse);
      expect(vm.bancos.single.nombre, equals('Bancolombia'));

      final apertura = DateTime(2026, 5, 1);
      vm.seleccionarFechaApertura(apertura);
      vm.actualizarCalculos(
        dias: 90,
        valorInvertido: 10000000,
        rendimientoTProyec: 300000,
        retencionPorcentaje: 4.0,
      );

      expect(vm.fechaCierre, equals(apertura.add(const Duration(days: 90))));
      expect(vm.valorRecibido, equals(10300000));
      expect(vm.rendimientos, equals(300000));
      expect(vm.retencionValor, equals(12000));
      expect(vm.valorFinalRend, equals(288000));
    });

    test('Aportes diferidos en Borrador, activación y reversión a Borrador', () async {
      final cliente = Client(
        id: 'c1',
        nombre: 'Carlos Santana',
        documento: '1010',
        correo: 'c@test.com',
        telefono: '300',
      );
      final txRepo = _FakeTxRepo([
        Transaction(
          id: 'rec-1',
          clienteId: 'c1',
          clienteNombre: 'Carlos Santana',
          tipo: TransactionType.recarga,
          valor: 15000000,
          fecha: DateTime(2026, 4, 1),
        ),
      ]);
      final instRepo = _FakeInstRepo();
      final inicial = Instrument(
        id: 'inst-1',
        numero: 'CDT-01',
        entidad: 'Bancolombia',
        fechaApertura: DateTime(2026, 4, 10),
        dias: 90,
        tasaIea: 12.0,
        valorInvertido: 10000000,
        rendimientoTProyec: 300000,
        estado: 'Borrador',
      );
      await instRepo.saveInstrument(inicial);

      final vm = InstrumentFormViewModel(
        userId: 'u1',
        instrumentInicial: inicial,
        saveInstrumentUseCase: SaveInstrumentUseCase(instRepo),
        getBanksUseCase: GetBanksUseCase(_FakeBankRepo()),
        getTransactionsUseCase: GetTransactionsUseCase(txRepo),
        getClientsUseCase: GetClientsUseCase(_FakeClientRepo([cliente], txRepo)),
        saveTransactionUseCase: SaveTransactionUseCase(txRepo),
        deleteTransactionUseCase: DeleteTransactionUseCase(txRepo),
      );

      expect(vm.puedeGestionarAportes, isTrue);

      // Registrar aporte en borrador sin crear transacción
      await vm.guardarAporteEnBorrador(cliente: cliente, monto: 8000000);
      expect(vm.aportes.length, equals(1));
      expect(vm.huboCambiosPersistidos, isTrue);
      expect(txRepo.txs.where((t) => t.tipo == TransactionType.inversion), isEmpty);

      // Activar instrumento -> genera transacción automática
      vm.seleccionarEstado('Activo');
      final resAct = await vm.guardarInstrumento(
        numero: 'CDT-01',
        entidad: 'Bancolombia',
        tasaIea: 12.0,
        observacion: '',
      );
      expect(resAct.transaccionesGeneradas, equals(1));
      expect(vm.huboCambiosPersistidos, isFalse);
      expect(vm.estadoPersistido, equals('Activo'));
      expect(txRepo.txs.where((t) => t.tipo == TransactionType.inversion).length, equals(1));

      // Revertir a Borrador -> elimina transacción y conserva aporte
      vm.seleccionarEstado('Borrador');
      expect(vm.requiereConfirmacionReversion, isTrue);
      final resRev = await vm.guardarInstrumento(
        numero: 'CDT-01',
        entidad: 'Bancolombia',
        tasaIea: 12.0,
        observacion: '',
      );
      expect(resRev.transaccionesReversadas, equals(1));
      expect(txRepo.txs.where((t) => t.tipo == TransactionType.inversion), isEmpty);
      expect(vm.aportes.length, equals(1));
      expect(vm.aportes.single.transaccionId, isNull);
    });

    test('Carga aportes legacy cuando el instrumento ya está Activo sin campo aportes', () async {
      final txRepo = _FakeTxRepo([
        Transaction(
          id: 'tx-leg-1',
          clienteId: 'c1',
          clienteNombre: 'Carlos Santana',
          tipo: TransactionType.inversion,
          valor: 5000000,
          fecha: DateTime(2026, 3, 2),
          instrumentoId: 'inst-leg',
        ),
      ]);
      final legacy = Instrument(
        id: 'inst-leg',
        numero: 'CDT-LEG',
        entidad: 'Davivienda',
        fechaApertura: DateTime(2026, 3, 1),
        dias: 90,
        tasaIea: 10.0,
        valorInvertido: 5000000,
        rendimientoTProyec: 120000,
        estado: 'Activo',
      );

      final vm = InstrumentFormViewModel(
        userId: 'u1',
        instrumentInicial: legacy,
        saveInstrumentUseCase: SaveInstrumentUseCase(_FakeInstRepo()),
        getBanksUseCase: GetBanksUseCase(_FakeBankRepo()),
        getTransactionsUseCase: GetTransactionsUseCase(txRepo),
        getClientsUseCase: GetClientsUseCase(_FakeClientRepo([], txRepo)),
        saveTransactionUseCase: SaveTransactionUseCase(txRepo),
        deleteTransactionUseCase: DeleteTransactionUseCase(txRepo),
      );

      await vm.inicializar();
      expect(vm.cargandoAportesLegacy, isFalse);
      expect(vm.aportesMostrados.length, equals(1));
      expect(vm.aportesMostrados.single.clienteNombre, equals('Carlos Santana'));
    });

    test('Propaga InsufficientBalanceException al intentar activar sin saldo', () async {
      final cliente = Client(
        id: 'c1',
        nombre: 'Carlos Santana',
        documento: '1010',
        correo: 'c@test.com',
        telefono: '300',
      );
      final txRepo = _FakeTxRepo([]);
      final inst = Instrument(
        id: 'inst-nf',
        numero: 'CDT-NF',
        entidad: 'Bancolombia',
        fechaApertura: DateTime(2026, 4, 1),
        dias: 90,
        tasaIea: 11.0,
        valorInvertido: 5000000,
        rendimientoTProyec: 150000,
        estado: 'Borrador',
        aportes: [
          InstrumentContribution(
            clienteId: 'c1',
            clienteNombre: 'Carlos Santana',
            valor: 5000000,
          ),
        ],
      );

      final vm = InstrumentFormViewModel(
        userId: 'u1',
        instrumentInicial: inst,
        saveInstrumentUseCase: SaveInstrumentUseCase(_FakeInstRepo()),
        getBanksUseCase: GetBanksUseCase(_FakeBankRepo()),
        getTransactionsUseCase: GetTransactionsUseCase(txRepo),
        getClientsUseCase: GetClientsUseCase(_FakeClientRepo([cliente], txRepo)),
        saveTransactionUseCase: SaveTransactionUseCase(txRepo),
        deleteTransactionUseCase: DeleteTransactionUseCase(txRepo),
      );

      vm.seleccionarEstado('Activo');
      await expectLater(
        () => vm.guardarInstrumento(
          numero: 'CDT-NF',
          entidad: 'Bancolombia',
          tasaIea: 11.0,
          observacion: '',
        ),
        throwsA(isA<InsufficientBalanceException>()),
      );
      expect(vm.guardando, isFalse);
    });

    test('guardarInstrumento exige numero obligatorio y no persiste si está vacío', () async {
      final instRepo = _FakeInstRepo();
      final txRepo = _FakeTxRepo([]);
      final vm = InstrumentFormViewModel(
        userId: 'u1',
        saveInstrumentUseCase: SaveInstrumentUseCase(instRepo),
        getBanksUseCase: GetBanksUseCase(_FakeBankRepo()),
        getTransactionsUseCase: GetTransactionsUseCase(txRepo),
        getClientsUseCase: GetClientsUseCase(_FakeClientRepo([], txRepo)),
        saveTransactionUseCase: SaveTransactionUseCase(txRepo),
        deleteTransactionUseCase: DeleteTransactionUseCase(txRepo),
      );

      await expectLater(
        () => vm.guardarInstrumento(
          numero: '   ',
          entidad: 'Bancolombia',
          tasaIea: 11.0,
          observacion: '',
        ),
        throwsException,
      );
      expect(instRepo.items, isEmpty);
      expect(vm.guardando, isFalse);
    });
  });
}
