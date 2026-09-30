import '../entities/instrument.dart';
import '../repositories/instrument_repository.dart';

/// Caso de uso para crear o actualizar un instrumento financiero.
class SaveInstrumentUseCase {
  final InstrumentRepository _repository;

  SaveInstrumentUseCase(this._repository);

  Future<void> execute(Instrument instrument) async {
    return _repository.saveInstrument(instrument);
  }
}
