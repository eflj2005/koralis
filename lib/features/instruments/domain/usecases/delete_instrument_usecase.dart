import 'package:koralis_app/features/transactions/domain/repositories/transaction_repository.dart';
import '../entities/instrument.dart';
import '../repositories/instrument_repository.dart';

/// Excepción lanzada cuando un instrumento no puede eliminarse por su estado o registros asociados.
class InstrumentDeletionBlockedException implements Exception {
  final String message;

  const InstrumentDeletionBlockedException(this.message);

  @override
  String toString() => message;
}

/// Caso de uso para eliminar un instrumento financiero validando integridad referencial.
///
/// Solo permite eliminar instrumentos en estado `Borrador` que no tengan aportes
/// registrados ni transacciones asociadas.
class DeleteInstrumentUseCase {
  final InstrumentRepository _instrumentRepository;
  final TransactionRepository _transactionRepository;

  DeleteInstrumentUseCase({
    required InstrumentRepository instrumentRepository,
    required TransactionRepository transactionRepository,
  })  : _instrumentRepository = instrumentRepository,
        _transactionRepository = transactionRepository;

  Future<void> execute(Instrument instrument) async {
    final instId = instrument.id.trim();
    if (instId.isEmpty) {
      throw ArgumentError('El identificador del instrumento no puede estar vacío');
    }

    if (instrument.estado != 'Borrador') {
      throw InstrumentDeletionBlockedException(
        'No se puede eliminar el instrumento "${instrument.numero}" porque está en estado "${instrument.estado}". Solo se pueden eliminar instrumentos en estado "Borrador".',
      );
    }

    if (instrument.aportes.isNotEmpty) {
      throw InstrumentDeletionBlockedException(
        'No se puede eliminar el instrumento "${instrument.numero}" porque tiene ${instrument.aportes.length} aporte(s) registrado(s) en borrador.',
      );
    }

    final instNum = instrument.numero.trim();
    final txs = await _transactionRepository.getTransactions();
    final txsAsociadas = txs.where((t) {
      final ref = t.instrumentoId?.trim() ?? '';
      return ref.isNotEmpty && (ref == instId || (instNum.isNotEmpty && ref == instNum));
    }).toList();

    if (txsAsociadas.isNotEmpty) {
      throw InstrumentDeletionBlockedException(
        'No se puede eliminar el instrumento "${instrument.numero}" porque tiene ${txsAsociadas.length} transacción(es) asociada(s).',
      );
    }

    await _instrumentRepository.deleteInstrument(instId);
  }
}
