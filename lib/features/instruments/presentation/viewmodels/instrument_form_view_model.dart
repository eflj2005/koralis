import 'package:flutter/foundation.dart';
import 'package:koralis_app/features/clients/data/repositories/client_repository_impl.dart';
import 'package:koralis_app/features/clients/domain/entities/client.dart';
import 'package:koralis_app/features/clients/domain/usecases/get_clients_usecase.dart';
import 'package:koralis_app/features/instruments/data/repositories/bank_repository_impl.dart';
import 'package:koralis_app/features/instruments/data/repositories/instrument_repository_impl.dart';
import 'package:koralis_app/features/instruments/domain/entities/bank.dart';
import 'package:koralis_app/features/instruments/domain/entities/instrument.dart';
import 'package:koralis_app/features/instruments/domain/usecases/get_banks_usecase.dart';
import 'package:koralis_app/features/instruments/domain/usecases/process_instrument_save_usecase.dart';
import 'package:koralis_app/features/instruments/domain/usecases/save_instrument_usecase.dart';
import 'package:koralis_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:koralis_app/features/transactions/domain/entities/transaction.dart';
import 'package:koralis_app/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:koralis_app/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:koralis_app/features/transactions/domain/usecases/save_transaction_usecase.dart';

/// ViewModel para la creación, edición, cálculos financieros y aportes diferidos en [InstrumentFormScreen].
class InstrumentFormViewModel extends ChangeNotifier {
  final String _userId;
  final Instrument? instrumentInicial;

  SaveInstrumentUseCase? _saveInstrumentUseCase;
  GetBanksUseCase? _getBanksUseCase;
  GetTransactionsUseCase? _getTransactionsUseCase;
  GetClientsUseCase? _getClientsUseCase;
  SaveTransactionUseCase? _saveTransactionUseCase;
  DeleteTransactionUseCase? _deleteTransactionUseCase;

  Instrument? _instrumentoPersistido;
  late List<InstrumentContribution> _aportes;
  List<InstrumentContribution> _aportesLegacy = const [];
  bool _cargandoAportesLegacy = false;
  String? _errorAportesLegacy;

  late String _estado;
  late String _estadoPersistido;
  bool _huboCambiosPersistidos = false;
  bool _guardando = false;

  List<Bank> _bancos = const [];
  bool _cargandoBancos = true;

  late DateTime _fechaApertura;
  late int _dias;
  late double _valorInvertido;
  late double _rendimientoTProyec;
  late double _retencionPorcentaje;
  bool _disposed = false;

  InstrumentFormViewModel({
    required String userId,
    this.instrumentInicial,
    SaveInstrumentUseCase? saveInstrumentUseCase,
    GetBanksUseCase? getBanksUseCase,
    GetTransactionsUseCase? getTransactionsUseCase,
    GetClientsUseCase? getClientsUseCase,
    SaveTransactionUseCase? saveTransactionUseCase,
    DeleteTransactionUseCase? deleteTransactionUseCase,
  })  : _userId = userId,
        _saveInstrumentUseCase = saveInstrumentUseCase,
        _getBanksUseCase = getBanksUseCase,
        _getTransactionsUseCase = getTransactionsUseCase,
        _getClientsUseCase = getClientsUseCase,
        _saveTransactionUseCase = saveTransactionUseCase,
        _deleteTransactionUseCase = deleteTransactionUseCase {
    _instrumentoPersistido = instrumentInicial;
    _aportes =
        List<InstrumentContribution>.from(instrumentInicial?.aportes ?? const []);
    _estado = instrumentInicial?.estado ?? 'Borrador';
    _estadoPersistido = instrumentInicial?.estado ?? 'Borrador';
    _fechaApertura = instrumentInicial?.fechaApertura ?? DateTime.now();
    _dias = instrumentInicial?.dias ?? 0;
    _valorInvertido = instrumentInicial?.valorInvertido ?? 0.0;
    _rendimientoTProyec = instrumentInicial?.rendimientoTProyec ?? 0.0;
    _retencionPorcentaje = instrumentInicial?.retencionPorcentaje ?? 4.0;
  }

  bool get esEdicion => instrumentInicial != null;
  String get estado => _estado;
  String get estadoPersistido => _estadoPersistido;
  bool get huboCambiosPersistidos => _huboCambiosPersistidos;
  bool get guardando => _guardando;
  List<Bank> get bancos => List.unmodifiable(_bancos);
  bool get cargandoBancos => _cargandoBancos;
  bool get cargandoAportesLegacy => _cargandoAportesLegacy;
  String? get errorAportesLegacy => _errorAportesLegacy;

  bool get puedeGestionarAportes =>
      esEdicion && _estado == 'Borrador' && _estadoPersistido == 'Borrador';

  bool get requiereConfirmacionReversion =>
      esEdicion && _estadoPersistido == 'Activo' && _estado == 'Borrador';

  List<InstrumentContribution> get aportes => List.unmodifiable(_aportes);
  List<InstrumentContribution> get aportesMostrados => _aportes.isNotEmpty
      ? List.unmodifiable(_aportes)
      : List.unmodifiable(_aportesLegacy);

  DateTime get fechaApertura => _fechaApertura;
  int get dias => _dias;
  DateTime get fechaCierre => _fechaApertura.add(Duration(days: _dias));
  double get valorInvertido => _valorInvertido;
  double get rendimientoTProyec => _rendimientoTProyec;
  double get valorRecibido => _valorInvertido + _rendimientoTProyec;
  double get rendimientos => valorRecibido - _valorInvertido;
  double get retencionPorcentaje => _retencionPorcentaje;
  double get retencionValor => rendimientos * (_retencionPorcentaje / 100.0);
  double get valorFinalRend => rendimientos - retencionValor;

  SaveInstrumentUseCase _obtenerSaveInstrumentUseCase() =>
      _saveInstrumentUseCase ??= SaveInstrumentUseCase(
        InstrumentRepositoryImpl(userId: _userId),
      );

  GetBanksUseCase _obtenerGetBanksUseCase() =>
      _getBanksUseCase ??= GetBanksUseCase(BankRepositoryImpl());

  GetTransactionsUseCase _obtenerGetTransactionsUseCase() =>
      _getTransactionsUseCase ??= GetTransactionsUseCase(
        TransactionRepositoryImpl(userId: _userId),
      );

  GetClientsUseCase _obtenerGetClientsUseCase() =>
      _getClientsUseCase ??= GetClientsUseCase(
        ClientRepositoryImpl(userId: _userId),
      );

  SaveTransactionUseCase _obtenerSaveTransactionUseCase() =>
      _saveTransactionUseCase ??= SaveTransactionUseCase(
        TransactionRepositoryImpl(userId: _userId),
      );

  DeleteTransactionUseCase _obtenerDeleteTransactionUseCase() =>
      _deleteTransactionUseCase ??= DeleteTransactionUseCase(
        TransactionRepositoryImpl(userId: _userId),
      );

  void _notificar() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// Carga bancos y, si aplica, aportes legacy para instrumentos ya activos/cerrados.
  Future<void> inicializar() async {
    await Future.wait([
      _cargarBancos(),
      if (esEdicion && _aportes.isEmpty && _estadoPersistido != 'Borrador')
        _cargarAportesLegacy(),
    ]);
  }

  Future<void> _cargarBancos() async {
    try {
      _bancos = await _obtenerGetBanksUseCase().execute();
    } catch (_) {
      // En pruebas unitarias sin Firebase o sin mock, se mantiene lista vacía segura
    } finally {
      _cargandoBancos = false;
      _notificar();
    }
  }

  Future<void> _cargarAportesLegacy() async {
    _cargandoAportesLegacy = true;
    _errorAportesLegacy = null;
    _notificar();

    try {
      final todas = await _obtenerGetTransactionsUseCase().execute();
      final instId = instrumentInicial!.id;
      final instNum = instrumentInicial!.numero;

      _aportesLegacy = todas
          .where((t) {
            final esInversion = t.tipo == TransactionType.inversion;
            final ref = t.instrumentoId ?? '';
            final coincide =
                ref.isNotEmpty && (ref == instId || ref == instNum);
            return esInversion && coincide;
          })
          .map(
            (tx) => InstrumentContribution(
              clienteId: tx.clienteId,
              clienteNombre: tx.clienteNombre,
              valor: tx.valor,
              fecha: tx.fecha,
              transaccionId: tx.id,
            ),
          )
          .toList();
    } catch (e) {
      _errorAportesLegacy = e.toString();
    } finally {
      _cargandoAportesLegacy = false;
      _notificar();
    }
  }

  void seleccionarFechaApertura(DateTime fecha) {
    if (_fechaApertura == fecha) return;
    _fechaApertura = fecha;
    _notificar();
  }

  void seleccionarEstado(String nuevoEstado) {
    if (_estado == nuevoEstado) return;
    _estado = nuevoEstado;
    _notificar();
  }

  /// Actualiza los valores numéricos usados en los cálculos financieros reactivos.
  void actualizarCalculos({
    required int dias,
    required double valorInvertido,
    required double rendimientoTProyec,
    required double retencionPorcentaje,
  }) {
    if (_dias == dias &&
        _valorInvertido == valorInvertido &&
        _rendimientoTProyec == rendimientoTProyec &&
        _retencionPorcentaje == retencionPorcentaje) {
      return;
    }
    _dias = dias;
    _valorInvertido = valorInvertido;
    _rendimientoTProyec = rendimientoTProyec;
    _retencionPorcentaje = retencionPorcentaje;
    _notificar();
  }

  /// Consulta los clientes disponibles para el selector de aportes.
  Future<List<Client>> cargarClientesDisponibles() async {
    return _obtenerGetClientsUseCase().execute();
  }

  /// Registra o actualiza un aporte en estado Borrador directamente en el instrumento sin afectar saldos.
  Future<void> guardarAporteEnBorrador({
    required Client cliente,
    required double monto,
    InstrumentContribution? aporteAEditar,
  }) async {
    final List<InstrumentContribution> nuevosAportes;
    if (aporteAEditar != null) {
      final actualizado = aporteAEditar.copyWith(
        valor: monto,
        fecha: DateTime.now(),
      );
      nuevosAportes = _aportes
          .map((a) => a.clienteId == aporteAEditar.clienteId ? actualizado : a)
          .toList();
    } else {
      final nuevo = InstrumentContribution(
        clienteId: cliente.id,
        clienteNombre: cliente.nombre,
        valor: monto,
        fecha: DateTime.now(),
      );
      nuevosAportes = [nuevo, ..._aportes];
    }

    await _persistirAportesEnBorrador(nuevosAportes);
  }

  /// Elimina un aporte en estado Borrador del documento del instrumento.
  Future<void> eliminarAporteEnBorrador(String clienteId) async {
    final nuevosAportes =
        _aportes.where((a) => a.clienteId != clienteId).toList();
    await _persistirAportesEnBorrador(nuevosAportes);
  }

  Future<void> _persistirAportesEnBorrador(
    List<InstrumentContribution> nuevosAportes,
  ) async {
    final base = _instrumentoPersistido ?? instrumentInicial!;
    final actualizado = base.copyWith(
      estado: 'Borrador',
      aportes: nuevosAportes,
    );
    await _obtenerSaveInstrumentUseCase().execute(actualizado);
    _aportes = List<InstrumentContribution>.from(nuevosAportes);
    _instrumentoPersistido = actualizado;
    _huboCambiosPersistidos = true;
    _notificar();
  }

  /// Persiste el instrumento y procesa las transacciones automáticas según la transición de estado.
  Future<InstrumentSaveResult> guardarInstrumento({
    required String numero,
    required String entidad,
    required double tasaIea,
    required String observacion,
  }) async {
    _guardando = true;
    _notificar();

    final previo = _instrumentoPersistido ?? instrumentInicial;
    final id = instrumentInicial?.id ?? '';
    final fechaCreacion = instrumentInicial?.fechaCreacion ?? DateTime.now();

    final instrumento = Instrument(
      id: id,
      numero: numero.trim(),
      entidad: entidad.trim(),
      fechaApertura: _fechaApertura,
      dias: _dias,
      tasaIea: tasaIea,
      valorInvertido: _valorInvertido,
      rendimientoTProyec: _rendimientoTProyec,
      retencionPorcentaje: _retencionPorcentaje,
      observacion: observacion.trim(),
      estado: _estado,
      fechaCreacion: fechaCreacion,
      participaciones: instrumentInicial?.participaciones ?? const [],
      aportes: _aportes,
      userId: _userId,
    );

    final processUseCase = ProcessInstrumentSaveUseCase(
      saveInstrumentUseCase: _obtenerSaveInstrumentUseCase(),
      getClientsUseCase: _obtenerGetClientsUseCase(),
      getTransactionsUseCase: _obtenerGetTransactionsUseCase(),
      saveTransactionUseCase: _obtenerSaveTransactionUseCase(),
      deleteTransactionUseCase: _obtenerDeleteTransactionUseCase(),
    );

    try {
      final resultado = await processUseCase.execute(
        instrumentoNuevo: instrumento,
        instrumentoPrevio: previo,
      );
      _instrumentoPersistido = resultado.instrumentoGuardado;
      _estadoPersistido = resultado.instrumentoGuardado.estado;
      _aportes = List<InstrumentContribution>.from(
        resultado.instrumentoGuardado.aportes,
      );
      _huboCambiosPersistidos = false;
      return resultado;
    } finally {
      _guardando = false;
      _notificar();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
