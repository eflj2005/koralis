import 'package:flutter_test/flutter_test.dart';
import 'package:koralis_app/features/clients/domain/entities/client.dart';
import 'package:koralis_app/features/clients/domain/repositories/client_repository.dart';
import 'package:koralis_app/features/clients/domain/usecases/delete_client_usecase.dart';
import 'package:koralis_app/features/instruments/domain/entities/instrument.dart';
import 'package:koralis_app/features/instruments/domain/repositories/instrument_repository.dart';
import 'package:koralis_app/features/transactions/domain/entities/transaction.dart';
import 'package:koralis_app/features/transactions/domain/repositories/transaction_repository.dart';

class _FakeClientRepo implements ClientRepository {
  final List<Client> items;
  _FakeClientRepo(this.items);

  @override
  Future<List<Client>> getClients() async => items;

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
  Future<List<Transaction>> getTransactions({String? clienteId}) async {
    if (clienteId != null) {
      return items.where((t) => t.clienteId == clienteId).toList();
    }
    return items;
  }

  @override
  Future<void> saveTransaction(Transaction transaction) async {}

  @override
  Future<void> deleteTransaction(String id, {String? clienteId}) async {}
}

void main() {
  final cliente = Client(
    id: 'cli-1',
    nombre: 'Carlos Santana',
    documento: '102030',
    correo: 'carlos@test.com',
    telefono: '3001112233',
  );

  group('DeleteClientUseCase', () {
    test('Elimina el cliente cuando no tiene instrumentos ni transacciones asociadas', () async {
      final clientRepo = _FakeClientRepo([cliente]);
      final useCase = DeleteClientUseCase(
        clientRepository: clientRepo,
        instrumentRepository: _FakeInstrumentRepo([]),
        transactionRepository: _FakeTransactionRepo([]),
      );

      await useCase.execute(cliente);

      expect(clientRepo.items, isEmpty);
    });

    test('Bloquea eliminación si el cliente está asociado en aportes de un instrumento', () async {
      final clientRepo = _FakeClientRepo([cliente]);
      final inst = Instrument(
        id: 'inst-1',
        numero: 'CDT-01',
        entidad: 'Bancolombia',
        fechaApertura: DateTime(2026, 4, 1),
        dias: 90,
        tasaIea: 11.0,
        valorInvertido: 5000000,
        rendimientoTProyec: 150000,
        aportes: [
          InstrumentContribution(
            clienteId: 'cli-1',
            clienteNombre: 'Carlos Santana',
            valor: 5000000,
          ),
        ],
      );
      final useCase = DeleteClientUseCase(
        clientRepository: clientRepo,
        instrumentRepository: _FakeInstrumentRepo([inst]),
        transactionRepository: _FakeTransactionRepo([]),
      );

      await expectLater(
        () => useCase.execute(cliente),
        throwsA(isA<ClientDeletionBlockedException>()),
      );
      expect(clientRepo.items.length, equals(1));
    });

    test('Bloquea eliminación si el cliente está asociado en participaciones de un instrumento', () async {
      final clientRepo = _FakeClientRepo([cliente]);
      final inst = Instrument(
        id: 'inst-2',
        numero: 'CDT-02',
        entidad: 'Davivienda',
        fechaApertura: DateTime(2026, 4, 1),
        dias: 90,
        tasaIea: 11.0,
        valorInvertido: 5000000,
        rendimientoTProyec: 150000,
        participaciones: const [
          InstrumentClientShare(
            clienteId: 'cli-1',
            clienteNombre: 'Carlos Santana',
            porcentajeParticipacion: 100.0,
          ),
        ],
      );
      final useCase = DeleteClientUseCase(
        clientRepository: clientRepo,
        instrumentRepository: _FakeInstrumentRepo([inst]),
        transactionRepository: _FakeTransactionRepo([]),
      );

      await expectLater(
        () => useCase.execute(cliente),
        throwsA(isA<ClientDeletionBlockedException>()),
      );
      expect(clientRepo.items.length, equals(1));
    });

    test('Bloquea eliminación si el cliente tiene transacciones registradas', () async {
      final clientRepo = _FakeClientRepo([cliente]);
      final tx = Transaction(
        id: 'tx-1',
        clienteId: 'cli-1',
        clienteNombre: 'Carlos Santana',
        tipo: TransactionType.recarga,
        valor: 2000000,
        fecha: DateTime(2026, 4, 1),
      );
      final useCase = DeleteClientUseCase(
        clientRepository: clientRepo,
        instrumentRepository: _FakeInstrumentRepo([]),
        transactionRepository: _FakeTransactionRepo([tx]),
      );

      await expectLater(
        () => useCase.execute(cliente),
        throwsA(isA<ClientDeletionBlockedException>()),
      );
      expect(clientRepo.items.length, equals(1));
    });
  });
}
