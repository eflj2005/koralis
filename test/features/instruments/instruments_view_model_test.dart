import 'package:flutter_test/flutter_test.dart';
import 'package:koralis_app/features/instruments/domain/entities/instrument.dart';
import 'package:koralis_app/features/instruments/domain/repositories/instrument_repository.dart';
import 'package:koralis_app/features/instruments/domain/usecases/delete_instrument_usecase.dart';
import 'package:koralis_app/features/instruments/domain/usecases/get_instruments_usecase.dart';
import 'package:koralis_app/features/instruments/presentation/viewmodels/instruments_view_model.dart';
import 'package:koralis_app/features/transactions/domain/entities/transaction.dart';
import 'package:koralis_app/features/transactions/domain/repositories/transaction_repository.dart';

class _FakeInstRepo implements InstrumentRepository {
  final List<Instrument> items;
  bool shouldFail = false;

  _FakeInstRepo(this.items);

  @override
  Future<List<Instrument>> getInstruments() async {
    if (shouldFail) throw Exception('Error de red');
    return List.from(items);
  }

  @override
  Future<void> saveInstrument(Instrument instrument) async {}

  @override
  Future<void> deleteInstrument(String id) async =>
      items.removeWhere((i) => i.id == id);
}

class _FakeTxRepo implements TransactionRepository {
  @override
  Future<List<Transaction>> getTransactions({String? clienteId}) async => [];

  @override
  Future<void> saveTransaction(Transaction transaction) async {}

  @override
  Future<void> deleteTransaction(String id, {String? clienteId}) async {}
}

void main() {
  final instActivo = Instrument(
    id: 'i1',
    numero: 'CDT-01',
    entidad: 'Bancolombia',
    fechaApertura: DateTime(2026, 4, 1),
    dias: 90,
    tasaIea: 11.0,
    valorInvertido: 10000000,
    rendimientoTProyec: 300000,
    estado: 'Activo',
  );
  final instBorrador = Instrument(
    id: 'i2',
    numero: 'CDT-02',
    entidad: 'Davivienda',
    fechaApertura: DateTime(2026, 4, 2),
    dias: 60,
    tasaIea: 10.0,
    valorInvertido: 5000000,
    rendimientoTProyec: 100000,
    estado: 'Borrador',
  );

  group('InstrumentsViewModel', () {
    test('cargarInstrumentos carga lista y captura error si falla', () async {
      final repo = _FakeInstRepo([instActivo, instBorrador]);
      final vm = InstrumentsViewModel(
        userId: 'u1',
        getInstrumentsUseCase: GetInstrumentsUseCase(repo),
        deleteInstrumentUseCase: DeleteInstrumentUseCase(
          instrumentRepository: repo,
          transactionRepository: _FakeTxRepo(),
        ),
      );

      await vm.cargarInstrumentos();
      expect(vm.isLoading, isFalse);
      expect(vm.errorMessage, isNull);
      expect(vm.instrumentos.length, equals(2));

      repo.shouldFail = true;
      await vm.cargarInstrumentos();
      expect(vm.errorMessage, contains('Error de red'));
    });

    test('eliminarInstrumento elimina en Borrador y propaga bloqueo en Activo', () async {
      final repo = _FakeInstRepo([instActivo, instBorrador]);
      final vm = InstrumentsViewModel(
        userId: 'u1',
        getInstrumentsUseCase: GetInstrumentsUseCase(repo),
        deleteInstrumentUseCase: DeleteInstrumentUseCase(
          instrumentRepository: repo,
          transactionRepository: _FakeTxRepo(),
        ),
      );

      await vm.cargarInstrumentos();

      await expectLater(
        () => vm.eliminarInstrumento(instActivo),
        throwsA(isA<InstrumentDeletionBlockedException>()),
      );
      expect(vm.eliminando, isFalse);
      expect(vm.instrumentos.length, equals(2));

      await vm.eliminarInstrumento(instBorrador);
      expect(vm.eliminando, isFalse);
      expect(vm.instrumentos.length, equals(1));
      expect(vm.instrumentos.single.id, equals('i1'));
    });
  });
}
