import '../entities/instrument.dart';
import '../repositories/instrument_repository.dart';

/// Caso de uso para obtener la colección de instrumentos financieros registrados.
class GetInstrumentsUseCase {
  final InstrumentRepository _repository;

  GetInstrumentsUseCase(this._repository);

  Future<List<Instrument>> execute() async {
    return _repository.getInstruments();
  }
}
