import 'package:flutter_test/flutter_test.dart';
import 'package:koralis_app/features/clients/domain/entities/client.dart';
import 'package:koralis_app/features/clients/domain/repositories/client_repository.dart';
import 'package:koralis_app/features/clients/domain/usecases/get_clients_usecase.dart';
import 'package:koralis_app/features/instruments/domain/entities/instrument.dart';
import 'package:koralis_app/features/instruments/domain/repositories/instrument_repository.dart';
import 'package:koralis_app/features/instruments/domain/usecases/process_instrument_save_usecase.dart';
import 'package:koralis_app/features/instruments/domain/usecases/save_instrument_usecase.dart';
import 'package:koralis_app/features/transactions/domain/entities/transaction.dart';
import 'package:koralis_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:koralis_app/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:koralis_app/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:koralis_app/features/transactions/domain/usecases/save_transaction_usecase.dart';

class _FakeInstrumentRepo implements InstrumentRepository {
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
  Future<void> deleteInstrument(String id) async {
    items.removeWhere((i) => i.id == id);
  }
}

class _FakeClientRepo implements ClientRepository {
  final List<Client> clientes;
  final _FakeTransactionRepo txRepo;

  _FakeClientRepo({required this.clientes, required this.txRepo});

  @override
  Future<List<Client>> getClients() async {
    // Calcula transacciones embebidas reflejando el estado actual de txRepo
    return clientes.map((c) {
      final txsCliente =
          txRepo.transacciones.where((t) => t.clienteId == c.id).toList();
      return c.copyWith(transacciones: txsCliente);
    }).toList();
  }

  @override
  Future<void> addClient(Client client) async => clientes.add(client);

  @override
  Future<void> deleteClient(String id) async =>
      clientes.removeWhere((c) => c.id == id);
}

class _FakeTransactionRepo implements TransactionRepository {
  final List<Transaction> transacciones;
  String? failOnClienteId;

  _FakeTransactionRepo({List<Transaction>? transacciones})
      : transacciones = transacciones != null ? List.from(transacciones) : [];

  @override
  Future<List<Transaction>> getTransactions({String? clienteId}) async {
    if (clienteId != null) {
      return transacciones.where((t) => t.clienteId == clienteId).toList();
    }
    return List.from(transacciones);
  }

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    if (failOnClienteId != null && transaction.clienteId == failOnClienteId) {
      throw Exception('Falla simulada de red al guardar transacción');
    }
    final txConId = transaction.id.trim().isNotEmpty
        ? transaction
        : transaction.copyWith(id: 'tx_${transacciones.length + 1}');
    final idx = transacciones.indexWhere((t) => t.id == txConId.id);
    if (idx >= 0) {
      transacciones[idx] = txConId;
    } else {
      transacciones.add(txConId);
    }
  }

  @override
  Future<void> deleteTransaction(String id, {String? clienteId}) async {
    transacciones.removeWhere((t) => t.id == id);
  }
}

void main() {
  late _FakeInstrumentRepo instRepo;
  late _FakeTransactionRepo txRepo;
  late _FakeClientRepo clientRepo;
  late ProcessInstrumentSaveUseCase useCase;

  final client1 = Client(
    id: 'cli-1',
    nombre: 'Carlos Santana',
    documento: '1001',
    correo: 'carlos@test.com',
    telefono: '3001112233',
  );
  final client2 = Client(
    id: 'cli-2',
    nombre: 'Mariana Pajón',
    documento: '1002',
    correo: 'mariana@test.com',
    telefono: '3004445566',
  );

  Instrument crearInstrumentoBase({
    String estado = 'Borrador',
    List<InstrumentContribution> aportes = const [],
  }) {
    return Instrument(
      id: 'inst-1',
      numero: 'CDT-001',
      entidad: 'Bancolombia',
      fechaApertura: DateTime(2026, 4, 1),
      dias: 90,
      tasaIea: 11.5,
      valorInvertido: 15000000,
      rendimientoTProyec: 400000,
      estado: estado,
      aportes: aportes,
    );
  }

  setUp(() {
    txRepo = _FakeTransactionRepo(
      transacciones: [
        Transaction(
          id: 'rec-1',
          clienteId: 'cli-1',
          clienteNombre: 'Carlos Santana',
          tipo: TransactionType.recarga,
          valor: 10000000,
          fecha: DateTime(2026, 3, 1),
        ),
        Transaction(
          id: 'rec-2',
          clienteId: 'cli-2',
          clienteNombre: 'Mariana Pajón',
          tipo: TransactionType.recarga,
          valor: 8000000,
          fecha: DateTime(2026, 3, 1),
        ),
      ],
    );
    instRepo = _FakeInstrumentRepo();
    clientRepo = _FakeClientRepo(clientes: [client1, client2], txRepo: txRepo);
    useCase = ProcessInstrumentSaveUseCase(
      saveInstrumentUseCase: SaveInstrumentUseCase(instRepo),
      getClientsUseCase: GetClientsUseCase(clientRepo),
      getTransactionsUseCase: GetTransactionsUseCase(txRepo),
      saveTransactionUseCase: SaveTransactionUseCase(txRepo),
      deleteTransactionUseCase: DeleteTransactionUseCase(txRepo),
    );
  });

  group('ProcessInstrumentSaveUseCase', () {
    test('Borrador -> Borrador guarda aportes sin generar transacciones de inversión', () async {
      final previo = crearInstrumentoBase(estado: 'Borrador');
      final nuevo = previo.copyWith(
        aportes: [
          InstrumentContribution(
            clienteId: 'cli-1',
            clienteNombre: 'Carlos Santana',
            valor: 6000000,
          ),
        ],
      );

      final res = await useCase.execute(
        instrumentoNuevo: nuevo,
        instrumentoPrevio: previo,
      );

      expect(res.transaccionesGeneradas, equals(0));
      expect(res.transaccionesReversadas, equals(0));
      expect(txRepo.transacciones.where((t) => t.tipo == TransactionType.inversion), isEmpty);
      expect(instRepo.items.single.aportes.single.transaccionId, isNull);
    });

    test('Borrador -> Activo con saldo suficiente genera transacciones y vincula transaccionId', () async {
      final aportes = [
        InstrumentContribution(
          clienteId: 'cli-1',
          clienteNombre: 'Carlos Santana',
          valor: 7000000,
        ),
        InstrumentContribution(
          clienteId: 'cli-2',
          clienteNombre: 'Mariana Pajón',
          valor: 5000000,
        ),
      ];
      final previo = crearInstrumentoBase(estado: 'Borrador', aportes: aportes);
      final nuevo = previo.copyWith(estado: 'Activo');

      final res = await useCase.execute(
        instrumentoNuevo: nuevo,
        instrumentoPrevio: previo,
      );

      expect(res.transaccionesGeneradas, equals(2));
      expect(res.transaccionesReversadas, equals(0));

      final inversiones = txRepo.transacciones
          .where((t) => t.tipo == TransactionType.inversion)
          .toList();
      expect(inversiones.length, equals(2));
      expect(inversiones.map((t) => t.id), containsAll(['inv_inst-1_cli-1', 'inv_inst-1_cli-2']));
      expect(instRepo.items.single.estado, equals('Activo'));
      expect(instRepo.items.single.aportes[0].transaccionId, equals('inv_inst-1_cli-1'));
      expect(instRepo.items.single.aportes[1].transaccionId, equals('inv_inst-1_cli-2'));

      // Verificar saldo disponible actualizado en los clientes
      final clientesActualizados = await clientRepo.getClients();
      expect(clientesActualizados.firstWhere((c) => c.id == 'cli-1').saldoDisponible, equals(3000000));
      expect(clientesActualizados.firstWhere((c) => c.id == 'cli-2').saldoDisponible, equals(3000000));
    });

    test('Borrador -> Activo con saldo insuficiente bloquea activación sin mutar estado ni crear transacciones', () async {
      // Carlos retira 6M antes de activar -> le quedan 4M, pero su aporte era de 7M
      await txRepo.saveTransaction(
        Transaction(
          id: 'ret-1',
          clienteId: 'cli-1',
          clienteNombre: 'Carlos Santana',
          tipo: TransactionType.retiro,
          valor: 6000000,
          fecha: DateTime(2026, 3, 15),
        ),
      );

      final aportes = [
        InstrumentContribution(
          clienteId: 'cli-1',
          clienteNombre: 'Carlos Santana',
          valor: 7000000,
        ),
        InstrumentContribution(
          clienteId: 'cli-2',
          clienteNombre: 'Mariana Pajón',
          valor: 5000000,
        ),
      ];
      final previo = crearInstrumentoBase(estado: 'Borrador', aportes: aportes);
      await instRepo.saveInstrument(previo);
      final nuevo = previo.copyWith(estado: 'Activo');

      await expectLater(
        () => useCase.execute(instrumentoNuevo: nuevo, instrumentoPrevio: previo),
        throwsA(
          isA<InsufficientBalanceException>().having(
            (e) => e.faltantes.single.clienteId,
            'clienteId',
            'cli-1',
          ),
        ),
      );

      // Ni siquiera se creó la inversión de Mariana (cli-2) ni cambió a Activo
      expect(txRepo.transacciones.where((t) => t.tipo == TransactionType.inversion), isEmpty);
      expect(instRepo.items.single.estado, equals('Borrador'));
    });

    test('Activo -> Activo es idempotente y no duplica transacciones', () async {
      final aportes = [
        InstrumentContribution(
          clienteId: 'cli-1',
          clienteNombre: 'Carlos Santana',
          valor: 5000000,
        ),
      ];
      final borrador = crearInstrumentoBase(estado: 'Borrador', aportes: aportes);
      final activacion = await useCase.execute(
        instrumentoNuevo: borrador.copyWith(estado: 'Activo'),
        instrumentoPrevio: borrador,
      );

      final editado = activacion.instrumentoGuardado.copyWith(observacion: 'Editado en activo');
      final res2 = await useCase.execute(
        instrumentoNuevo: editado,
        instrumentoPrevio: activacion.instrumentoGuardado,
      );

      expect(res2.transaccionesGeneradas, equals(0));
      expect(txRepo.transacciones.where((t) => t.tipo == TransactionType.inversion).length, equals(1));
    });

    test('Activo -> Borrador elimina transacciones generadas, devuelve saldo y conserva aportes', () async {
      final aportes = [
        InstrumentContribution(
          clienteId: 'cli-1',
          clienteNombre: 'Carlos Santana',
          valor: 6000000,
        ),
      ];
      final borrador = crearInstrumentoBase(estado: 'Borrador', aportes: aportes);
      final activacion = await useCase.execute(
        instrumentoNuevo: borrador.copyWith(estado: 'Activo'),
        instrumentoPrevio: borrador,
      );

      expect(txRepo.transacciones.where((t) => t.tipo == TransactionType.inversion).length, equals(1));

      final reversion = await useCase.execute(
        instrumentoNuevo: activacion.instrumentoGuardado.copyWith(estado: 'Borrador'),
        instrumentoPrevio: activacion.instrumentoGuardado,
      );

      expect(reversion.transaccionesReversadas, equals(1));
      expect(txRepo.transacciones.where((t) => t.tipo == TransactionType.inversion), isEmpty);
      expect(instRepo.items.single.estado, equals('Borrador'));
      expect(instRepo.items.single.aportes.length, equals(1));
      expect(instRepo.items.single.aportes.single.valor, equals(6000000));
      expect(instRepo.items.single.aportes.single.transaccionId, isNull);

      final clientesActualizados = await clientRepo.getClients();
      expect(clientesActualizados.firstWhere((c) => c.id == 'cli-1').saldoDisponible, equals(10000000));
    });

    test('Rollback defensivo revierte transacciones parciales si falla el guardado de una transacción', () async {
      txRepo.failOnClienteId = 'cli-2';
      final aportes = [
        InstrumentContribution(
          clienteId: 'cli-1',
          clienteNombre: 'Carlos Santana',
          valor: 4000000,
        ),
        InstrumentContribution(
          clienteId: 'cli-2',
          clienteNombre: 'Mariana Pajón',
          valor: 3000000,
        ),
      ];
      final previo = crearInstrumentoBase(estado: 'Borrador', aportes: aportes);
      await instRepo.saveInstrument(previo);

      await expectLater(
        () => useCase.execute(
          instrumentoNuevo: previo.copyWith(estado: 'Activo'),
          instrumentoPrevio: previo,
        ),
        throwsException,
      );

      // La transacción de cli-1 debe haberse eliminado por el rollback
      expect(txRepo.transacciones.where((t) => t.tipo == TransactionType.inversion), isEmpty);
      expect(instRepo.items.single.estado, equals('Borrador'));
    });

    test('Transiciones inválidas lanzan InvalidInstrumentStateTransitionException', () async {
      final cerrado = crearInstrumentoBase(estado: 'Cerrado');
      await expectLater(
        () => useCase.execute(
          instrumentoNuevo: cerrado.copyWith(estado: 'Borrador'),
          instrumentoPrevio: cerrado,
        ),
        throwsA(isA<InvalidInstrumentStateTransitionException>()),
      );

      final borradorConAportes = crearInstrumentoBase(
        estado: 'Borrador',
        aportes: [
          InstrumentContribution(
            clienteId: 'cli-1',
            clienteNombre: 'Carlos Santana',
            valor: 2000000,
          ),
        ],
      );
      await expectLater(
        () => useCase.execute(
          instrumentoNuevo: borradorConAportes.copyWith(estado: 'Cerrado'),
          instrumentoPrevio: borradorConAportes,
        ),
        throwsA(isA<InvalidInstrumentStateTransitionException>()),
      );
    });
  });
}
