import 'package:koralis_app/features/instruments/domain/repositories/instrument_repository.dart';
import 'package:koralis_app/features/transactions/domain/repositories/transaction_repository.dart';
import '../entities/client.dart';
import '../repositories/client_repository.dart';

/// Excepción lanzada cuando un cliente no puede eliminarse porque posee registros asociados.
class ClientDeletionBlockedException implements Exception {
  final String message;

  const ClientDeletionBlockedException(this.message);

  @override
  String toString() => message;
}

/// Caso de uso para eliminar un cliente validando previamente su integridad referencial.
///
/// Impide el borrado si el cliente tiene instrumentos financieros asociados
/// (en aportes o participaciones) o transacciones registradas.
class DeleteClientUseCase {
  final ClientRepository _clientRepository;
  final InstrumentRepository _instrumentRepository;
  final TransactionRepository _transactionRepository;

  DeleteClientUseCase({
    required ClientRepository clientRepository,
    required InstrumentRepository instrumentRepository,
    required TransactionRepository transactionRepository,
  })  : _clientRepository = clientRepository,
        _instrumentRepository = instrumentRepository,
        _transactionRepository = transactionRepository;

  Future<void> execute(Client client) async {
    final cId = client.id.trim();
    if (cId.isEmpty) {
      throw ArgumentError('El identificador del cliente no puede estar vacío');
    }

    final txs = await _transactionRepository.getTransactions(clienteId: cId);
    final totalTxs = txs.isNotEmpty ? txs.length : client.transacciones.length;

    final instrumentos = await _instrumentRepository.getInstruments();
    final instrumentosAsociados = instrumentos.where((inst) {
      final enAportes = inst.aportes.any((a) => a.clienteId.trim() == cId);
      final enParticipaciones =
          inst.participaciones.any((p) => p.clienteId.trim() == cId);
      return enAportes || enParticipaciones;
    }).length;

    if (instrumentosAsociados > 0 && totalTxs > 0) {
      throw ClientDeletionBlockedException(
        'No se puede eliminar a "${client.nombre}" porque tiene $instrumentosAsociados instrumento(s) y $totalTxs transacción(es) asociada(s).',
      );
    }

    if (instrumentosAsociados > 0) {
      throw ClientDeletionBlockedException(
        'No se puede eliminar a "${client.nombre}" porque tiene $instrumentosAsociados instrumento(s) asociado(s).',
      );
    }

    if (totalTxs > 0) {
      throw ClientDeletionBlockedException(
        'No se puede eliminar a "${client.nombre}" porque tiene $totalTxs transacción(es) registrada(s).',
      );
    }

    await _clientRepository.deleteClient(cId);
  }
}
