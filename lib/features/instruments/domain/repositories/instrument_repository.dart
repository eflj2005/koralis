import '../entities/instrument.dart';

/// Contrato abstracto del repositorio para la gestión y persistencia de instrumentos financieros.
abstract class InstrumentRepository {
  /// Obtiene la lista completa de instrumentos financieros registrados.
  Future<List<Instrument>> getInstruments();

  /// Registra o actualiza un instrumento financiero en el repositorio.
  Future<void> saveInstrument(Instrument instrument);

  /// Elimina un instrumento financiero por su identificador único.
  Future<void> deleteInstrument(String id);
}
