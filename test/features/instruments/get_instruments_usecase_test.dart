import 'package:flutter_test/flutter_test.dart';
import 'package:koralis_app/features/instruments/domain/entities/instrument.dart';
import 'package:koralis_app/features/instruments/domain/repositories/instrument_repository.dart';
import 'package:koralis_app/features/instruments/domain/usecases/get_instruments_usecase.dart';

class MockInstrumentRepo implements InstrumentRepository {
  final List<Instrument> items;
  MockInstrumentRepo(this.items);

  @override
  Future<List<Instrument>> getInstruments() async => items;

  @override
  Future<void> saveInstrument(Instrument instrument) async => items.add(instrument);

  @override
  Future<void> deleteInstrument(String id) async => items.removeWhere((i) => i.id == id);
}

void main() {
  group('GetInstrumentsUseCase Tests', () {
    test('Debe retornar la lista de instrumentos financieros registrados', () async {
      final repo = MockInstrumentRepo([
        Instrument(
          id: '1',
          numero: 'CDT-001',
          entidad: 'Bancolombia',
          fechaApertura: DateTime(2026, 1, 1),
          dias: 90,
          tasaIea: 11.5,
          valorInvertido: 1000000,
          rendimientoTProyec: 25000,
        ),
        Instrument(
          id: '2',
          numero: 'CDT-002',
          entidad: 'Davivienda',
          fechaApertura: DateTime(2026, 2, 1),
          dias: 180,
          tasaIea: 12.0,
          valorInvertido: 2000000,
          rendimientoTProyec: 80000,
        ),
      ]);

      final useCase = GetInstrumentsUseCase(repo);
      final result = await useCase.execute();

      expect(result.length, equals(2));
      expect(result[0].numero, equals('CDT-001'));
      expect(result[1].entidad, equals('Davivienda'));
    });

    test('Debe retornar lista vacía si no hay registros', () async {
      final repo = MockInstrumentRepo([]);
      final useCase = GetInstrumentsUseCase(repo);
      final result = await useCase.execute();

      expect(result, isEmpty);
    });
  });
}
