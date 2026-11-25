import 'package:flutter_test/flutter_test.dart';
import 'package:koralis_app/features/instruments/domain/entities/instrument.dart';
import 'package:koralis_app/features/instruments/domain/repositories/instrument_repository.dart';
import 'package:koralis_app/features/instruments/domain/usecases/delete_instrument_usecase.dart';
import 'package:koralis_app/features/transactions/domain/entities/transaction.dart';
import 'package:koralis_app/features/transactions/domain/repositories/transaction_repository.dart';

class _FakeInstrumentRepo implements InstrumentRepository {
  final List<Instrument> items;
  _FakeInstrumentRepo(this.items);

  @override
  Future<List<Instrument>> getInstruments() async => items;

  @override
  Future<void> saveInstrument(Instrument instrument) async {}

  @override
  Future<void> deleteInstrument(String id) async =>
      items.removeWhere((i) => i.id == id);
}

class _FakeTransactionRepo implements TransactionRepository {
  final List<Transaction> items;
  _FakeTransactionRepo(this.items);

  @override
  Future<List<Transaction>> getTransactions({String? clienteId}) async => items;

  @override
  Future<void> saveTransaction(Transaction transaction) async {}

  @override
  Future<void> deleteTransaction(String id, {String? clienteId}) async {}
}

void main() {
  Instrument crearInstrumento({
    String estado = 'Borrador',
    List<InstrumentContribution> aportes = const [],
  }) {
    return Instrument(
      id: 'inst-1',
      numero: 'CDT-001',
      entidad: 'Bancolombia',
      fechaApertura: DateTime(2026, 4, 1),
      dias: 90,
      tasaIea: 11.0,
      valorInvertido: 5000000,
      rendimientoTProyec: 150000,
      estado: estado,
      aportes: aportes,
    );
  }

  group('DeleteInstrumentUseCase', () {
    test('Elimina instrumento en Borrador sin aportes ni transacciones asociadas', () async {
      final inst = crearInstrumento(estado: 'Borrador');
      final instRepo = _FakeInstrumentRepo([inst]);
      final useCase = DeleteInstrumentUseCase(
        instrumentRepository: instRepo,
        transactionRepository: _FakeTransactionRepo([]),
      );

      await useCase.execute(inst);

      expect(instRepo.items, isEmpty);
    });

    test('Bloquea eliminación si el instrumento está Activo o Cerrado', () async {
      for (final estado in ['Activo', 'Cerrado']) {
        final inst = crearInstrumento(estado: estado);
        final instRepo = _FakeInstrumentRepo([inst]);
        final useCase = DeleteInstrumentUseCase(
          instrumentRepository: instRepo,
          transactionRepository: _FakeTransactionRepo([]),
        );

        await expectLater(
          () => useCase.execute(inst),
          throwsA(isA<InstrumentDeletionBlockedException>()),
        );
        expect(instRepo.items.length, equals(1));
      }
    });

    test('Bloquea eliminación si el instrumento tiene aportes registrados en borrador', () async {
      final inst = crearInstrumento(
        estado: 'Borrador',
        aportes: [
          InstrumentContribution(
            clienteId: 'cli-1',
            clienteNombre: 'Carlos',
            valor: 2000000,
          ),
        ],
      );
      final instRepo = _FakeInstrumentRepo([inst]);
      final useCase = DeleteInstrumentUseCase(
        instrumentRepository: instRepo,
        transactionRepository: _FakeTransactionRepo([]),
      );

      await expectLater(
        () => useCase.execute(inst),
        throwsA(isA<InstrumentDeletionBlockedException>()),
      );
      expect(instRepo.items.length, equals(1));
    });

    test('Bloquea eliminación si el instrumento tiene transacciones asociadas', () async {
      final inst = crearInstrumento(estado: 'Borrador');
      final instRepo = _FakeInstrumentRepo([inst]);
      final tx = Transaction(
        id: 'tx-1',
        clienteId: 'cli-1',
        clienteNombre: 'Carlos',
        tipo: TransactionType.inversion,
        valor: 2000000,
        fecha: DateTime(2026, 4, 2),
        instrumentoId: 'inst-1',
      );
      final useCase = DeleteInstrumentUseCase(
        instrumentRepository: instRepo,
        transactionRepository: _FakeTransactionRepo([tx]),
      );

      await expectLater(
        () => useCase.execute(inst),
        throwsA(isA<InstrumentDeletionBlockedException>()),
      );
      expect(instRepo.items.length, equals(1));
    });
  });
}
