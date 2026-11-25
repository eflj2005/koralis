import 'package:koralis_app/features/clients/domain/entities/client.dart';
import 'package:koralis_app/features/clients/domain/usecases/get_clients_usecase.dart';
import 'package:koralis_app/features/transactions/domain/entities/transaction.dart';
import 'package:koralis_app/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:koralis_app/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:koralis_app/features/transactions/domain/usecases/save_transaction_usecase.dart';
import '../entities/instrument.dart';
import 'save_instrument_usecase.dart';

/// Detalle de insuficiencia de saldo de un cliente al intentar activar un instrumento.
class ClientBalanceShortfall {
  final String clienteId;
  final String clienteNombre;
  final double montoRequerido;
  final double saldoDisponible;
  final bool clienteNoEncontrado;

  const ClientBalanceShortfall({
    required this.clienteId,
    required this.clienteNombre,
    required this.montoRequerido,
    required this.saldoDisponible,
    this.clienteNoEncontrado = false,
  });
}

/// Excepción lanzada cuando uno o más clientes no cuentan con saldo disponible suficiente
/// para respaldar sus aportes al activar un instrumento.
class InsufficientBalanceException implements Exception {
  final List<ClientBalanceShortfall> faltantes;

  const InsufficientBalanceException(this.faltantes);

  @override
  String toString() {
    final detalles = faltantes
        .map((f) => f.clienteNoEncontrado
            ? '${f.clienteNombre}: cliente no encontrado'
            : '${f.clienteNombre} (requiere ${f.montoRequerido.toStringAsFixed(2)}, disponible ${f.saldoDisponible.toStringAsFixed(2)})')
        .join('; ');
    return 'Saldo insuficiente para activar el instrumento: $detalles';
  }
}

/// Excepción lanzada cuando se intenta una transición de estado no permitida en el instrumento.
class InvalidInstrumentStateTransitionException implements Exception {
  final String message;

  const InvalidInstrumentStateTransitionException(this.message);

  @override
  String toString() => message;
}

/// Resultado de ejecutar [ProcessInstrumentSaveUseCase].
class InstrumentSaveResult {
  final Instrument instrumentoGuardado;
  final int transaccionesGeneradas;
  final int transaccionesReversadas;

  const InstrumentSaveResult({
    required this.instrumentoGuardado,
    required this.transaccionesGeneradas,
    required this.transaccionesReversadas,
  });
}

/// Caso de uso orquestador para guardar instrumentos financieros gestionando el ciclo de vida
/// de las transacciones automáticas de inversión según el estado operativo del instrumento.
class ProcessInstrumentSaveUseCase {
  final SaveInstrumentUseCase _saveInstrumentUseCase;
  final GetClientsUseCase _getClientsUseCase;
  final GetTransactionsUseCase _getTransactionsUseCase;
  final SaveTransactionUseCase _saveTransactionUseCase;
  final DeleteTransactionUseCase _deleteTransactionUseCase;

  ProcessInstrumentSaveUseCase({
    required SaveInstrumentUseCase saveInstrumentUseCase,
    required GetClientsUseCase getClientsUseCase,
    required GetTransactionsUseCase getTransactionsUseCase,
    required SaveTransactionUseCase saveTransactionUseCase,
    required DeleteTransactionUseCase deleteTransactionUseCase,
  })  : _saveInstrumentUseCase = saveInstrumentUseCase,
        _getClientsUseCase = getClientsUseCase,
        _getTransactionsUseCase = getTransactionsUseCase,
        _saveTransactionUseCase = saveTransactionUseCase,
        _deleteTransactionUseCase = deleteTransactionUseCase;

  /// Persiste el instrumento y ejecuta las transacciones automáticas correspondientes a la transición de estado.
  Future<InstrumentSaveResult> execute({
    required Instrument instrumentoNuevo,
    Instrument? instrumentoPrevio,
  }) async {
    if (instrumentoNuevo.numero.trim().isEmpty) {
      throw Exception('El número del instrumento es obligatorio.');
    }

    final estadoPrevio = instrumentoPrevio?.estado;
    final estadoNuevo = instrumentoNuevo.estado;

    if (estadoPrevio == 'Cerrado' && estadoNuevo == 'Borrador') {
      throw const InvalidInstrumentStateTransitionException(
        'Un instrumento en estado "Cerrado" no puede regresar a "Borrador".',
      );
    }

    if ((estadoPrevio == null || estadoPrevio == 'Borrador') &&
        estadoNuevo == 'Cerrado' &&
        instrumentoNuevo.aportes.isNotEmpty) {
      throw const InvalidInstrumentStateTransitionException(
        'No es posible cerrar directamente un instrumento en "Borrador" con aportes pendientes. Primero actívalo para generar las transacciones de inversión.',
      );
    }

    // Caso 1: Activación (Borrador / Nuevo -> Activo)
    if ((estadoPrevio == null || estadoPrevio == 'Borrador') &&
        estadoNuevo == 'Activo') {
      return _procesarActivacion(instrumentoNuevo);
    }

    // Caso 2: Reversión (Activo -> Borrador)
    if (estadoPrevio == 'Activo' && estadoNuevo == 'Borrador') {
      return _procesarReversion(instrumentoNuevo, instrumentoPrevio);
    }

    // Caso 3: Resto de transiciones (Borrador -> Borrador, Activo -> Activo, Activo -> Cerrado)
    await _saveInstrumentUseCase.execute(instrumentoNuevo);
    return InstrumentSaveResult(
      instrumentoGuardado: instrumentoNuevo,
      transaccionesGeneradas: 0,
      transaccionesReversadas: 0,
    );
  }

  Future<InstrumentSaveResult> _procesarActivacion(
    Instrument instrumentoNuevo,
  ) async {
    if (instrumentoNuevo.aportes.isEmpty) {
      await _saveInstrumentUseCase.execute(instrumentoNuevo);
      return InstrumentSaveResult(
        instrumentoGuardado: instrumentoNuevo,
        transaccionesGeneradas: 0,
        transaccionesReversadas: 0,
      );
    }

    final clientes = await _getClientsUseCase.execute();
    final txsExistentes = await _getTransactionsUseCase.execute();

    final clientesPorId = <String, Client>{
      for (final c in clientes) c.id: c,
    };
    final idsTxExistentes = txsExistentes.map((t) => t.id).toSet();

    final refInst = instrumentoNuevo.id.trim().isNotEmpty
        ? instrumentoNuevo.id.trim()
        : instrumentoNuevo.numero.trim();

    final faltantes = <ClientBalanceShortfall>[];
    final txIdsPorAporte = <String>[];

    for (final aporte in instrumentoNuevo.aportes) {
      final txId = (aporte.transaccionId != null &&
              aporte.transaccionId!.trim().isNotEmpty)
          ? aporte.transaccionId!.trim()
          : 'inv_${refInst}_${aporte.clienteId}';
      txIdsPorAporte.add(txId);

      // Si la transacción ya fue aplicada previamente, omitimos la re-validación de saldo.
      if (idsTxExistentes.contains(txId)) continue;

      final cliente = clientesPorId[aporte.clienteId];
      if (cliente == null) {
        faltantes.add(
          ClientBalanceShortfall(
            clienteId: aporte.clienteId,
            clienteNombre: aporte.clienteNombre,
            montoRequerido: aporte.valor,
            saldoDisponible: 0.0,
            clienteNoEncontrado: true,
          ),
        );
      } else if (aporte.valor > cliente.saldoDisponible + 0.001) {
        faltantes.add(
          ClientBalanceShortfall(
            clienteId: aporte.clienteId,
            clienteNombre:
                cliente.nombre.isNotEmpty ? cliente.nombre : aporte.clienteNombre,
            montoRequerido: aporte.valor,
            saldoDisponible: cliente.saldoDisponible,
          ),
        );
      }
    }

    if (faltantes.isNotEmpty) {
      throw InsufficientBalanceException(faltantes);
    }

    final creadas = <Transaction>[];
    final aportesActualizados = <InstrumentContribution>[];

    try {
      for (var i = 0; i < instrumentoNuevo.aportes.length; i++) {
        final aporte = instrumentoNuevo.aportes[i];
        final txId = txIdsPorAporte[i];

        if (!idsTxExistentes.contains(txId)) {
          final tx = Transaction(
            id: txId,
            clienteId: aporte.clienteId,
            clienteNombre: aporte.clienteNombre,
            tipo: TransactionType.inversion,
            valor: aporte.valor,
            fecha: DateTime.now(),
            instrumentoId: refInst,
            observacion: 'Aporte a instrumento ${instrumentoNuevo.numero}',
          );
          await _saveTransactionUseCase.execute(tx);
          creadas.add(tx);
        }

        aportesActualizados.add(aporte.copyWith(transaccionId: txId));
      }

      final instFinal = instrumentoNuevo.copyWith(aportes: aportesActualizados);
      await _saveInstrumentUseCase.execute(instFinal);

      return InstrumentSaveResult(
        instrumentoGuardado: instFinal,
        transaccionesGeneradas: creadas.length,
        transaccionesReversadas: 0,
      );
    } catch (_) {
      // Rollback defensivo de las transacciones generadas en este intento fallido
      for (final tx in creadas) {
        try {
          await _deleteTransactionUseCase.execute(
            tx.id,
            clienteId: tx.clienteId,
          );
        } catch (_) {
          // Ignorar errores secundarios durante el rollback
        }
      }
      rethrow;
    }
  }

  Future<InstrumentSaveResult> _procesarReversion(
    Instrument instrumentoNuevo,
    Instrument? instrumentoPrevio,
  ) async {
    final todasTxs = await _getTransactionsUseCase.execute();

    final idsVinculados = instrumentoNuevo.aportes
        .map((a) => a.transaccionId)
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();

    final txsAReversar = todasTxs.where((t) {
      if (t.tipo != TransactionType.inversion) return false;
      if (idsVinculados.contains(t.id)) return true;
      final ref = t.instrumentoId?.trim() ?? '';
      if (ref.isEmpty) return false;
      return ref == instrumentoNuevo.id.trim() ||
          ref == instrumentoNuevo.numero.trim() ||
          (instrumentoPrevio != null &&
              ref == instrumentoPrevio.numero.trim());
    }).toList();

    final List<InstrumentContribution> aportesPreservados;
    if (instrumentoNuevo.aportes.isNotEmpty) {
      aportesPreservados = instrumentoNuevo.aportes
          .map((a) => a.copyWith(clearTransaccionId: true))
          .toList();
    } else if (txsAReversar.isNotEmpty) {
      // Soporte legacy: si el instrumento activo no tenía el campo aportes, migrarlos al revertir.
      aportesPreservados = txsAReversar
          .map(
            (tx) => InstrumentContribution(
              clienteId: tx.clienteId,
              clienteNombre: tx.clienteNombre,
              valor: tx.valor,
              fecha: tx.fecha,
              transaccionId: null,
            ),
          )
          .toList();
    } else {
      aportesPreservados = const [];
    }

    for (final tx in txsAReversar) {
      await _deleteTransactionUseCase.execute(
        tx.id,
        clienteId: tx.clienteId,
      );
    }

    final instFinal = instrumentoNuevo.copyWith(
      estado: 'Borrador',
      aportes: aportesPreservados,
    );
    await _saveInstrumentUseCase.execute(instFinal);

    return InstrumentSaveResult(
      instrumentoGuardado: instFinal,
      transaccionesGeneradas: 0,
      transaccionesReversadas: txsAReversar.length,
    );
  }
}
