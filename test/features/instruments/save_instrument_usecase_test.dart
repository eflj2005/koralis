import 'package:flutter_test/flutter_test.dart';
import 'package:koralis_app/features/instruments/domain/entities/instrument.dart';
import 'package:koralis_app/features/instruments/domain/repositories/instrument_repository.dart';
import 'package:koralis_app/features/instruments/domain/usecases/save_instrument_usecase.dart';

class MockInstrumentRepo implements InstrumentRepository {
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
  Future<void> deleteInstrument(String id) async => items.removeWhere((i) => i.id == id);
}

void main() {
  group('SaveInstrumentUseCase Tests', () {
    test('Debe registrar un nuevo instrumento cuando no existe previamente', () async {
      final repo = MockInstrumentRepo();
      final useCase = SaveInstrumentUseCase(repo);

      final nuevo = Instrument(
        id: 'inst-1',
        numero: 'CDT-100',
        entidad: 'BBVA',
        fechaApertura: DateTime(2026, 1, 1),
        dias: 90,
        tasaIea: 12.0,
        valorInvertido: 3000000,
        rendimientoTProyec: 75000,
      );

      await useCase.execute(nuevo);

      expect(repo.items.length, equals(1));
      expect(repo.items.first.numero, equals('CDT-100'));
      expect(repo.items.first.entidad, equals('BBVA'));
    });

    test('Debe actualizar un instrumento existente cuando su ID ya está registrado', () async {
      final repo = MockInstrumentRepo();
      final useCase = SaveInstrumentUseCase(repo);

      final inicial = Instrument(
        id: 'inst-1',
        numero: 'CDT-100',
        entidad: 'BBVA',
        fechaApertura: DateTime(2026, 1, 1),
        dias: 90,
        tasaIea: 12.0,
        valorInvertido: 3000000,
        rendimientoTProyec: 75000,
      );
      repo.items.add(inicial);

      final modificado = inicial.copyWith(
        dias: 180,
        rendimientoTProyec: 150000,
      );

      await useCase.execute(modificado);

      expect(repo.items.length, equals(1));
      expect(repo.items.first.dias, equals(180));
      expect(repo.items.first.rendimientoTProyec, equals(150000));
    });
  });
}
