import 'package:flutter/foundation.dart';
import 'package:koralis_app/features/clients/data/repositories/client_repository_impl.dart';
import 'package:koralis_app/features/clients/domain/entities/client.dart';
import 'package:koralis_app/features/clients/domain/usecases/get_clients_usecase.dart';
import 'package:koralis_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:koralis_app/features/transactions/domain/entities/transaction.dart';
import 'package:koralis_app/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:koralis_app/features/transactions/domain/usecases/get_transactions_usecase.dart';

/// ViewModel de la pantalla de listado y filtrado de transacciones financieras.
class TransactionsViewModel extends ChangeNotifier {
  final String _userId;
  GetTransactionsUseCase? _getTransactionsUseCase;
  DeleteTransactionUseCase? _deleteTransactionUseCase;
  GetClientsUseCase? _getClientsUseCase;

  List<Transaction> _transacciones = const [];
  List<Client> _clientesDisponibles = const [];
  bool _isLoading = false;
  String? _errorMessage;

  String? _filtroClienteId;
  TransactionType? _filtroTipo;
  late DateTime _fechaInicial;
  late DateTime _fechaFinal;
  bool _disposed = false;

  TransactionsViewModel({
    required String userId,
    GetTransactionsUseCase? getTransactionsUseCase,
    DeleteTransactionUseCase? deleteTransactionUseCase,
    GetClientsUseCase? getClientsUseCase,
  })  : _userId = userId,
        _getTransactionsUseCase = getTransactionsUseCase,
        _deleteTransactionUseCase = deleteTransactionUseCase,
        _getClientsUseCase = getClientsUseCase {
    final ahora = DateTime.now();
    _fechaInicial = DateTime(ahora.year, ahora.month, 1);
    _fechaFinal = DateTime(ahora.year, ahora.month + 1, 0, 23, 59, 59);
  }

  List<Transaction> get transacciones => List.unmodifiable(_transacciones);
  List<Client> get clientesDisponibles =>
      List.unmodifiable(_clientesDisponibles);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get filtroClienteId => _filtroClienteId;
  TransactionType? get filtroTipo => _filtroTipo;
  DateTime get fechaInicial => _fechaInicial;
  DateTime get fechaFinal => _fechaFinal;

  GetTransactionsUseCase _obtenerGetTransactionsUseCase() =>
      _getTransactionsUseCase ??= GetTransactionsUseCase(
        TransactionRepositoryImpl(userId: _userId),
      );

  DeleteTransactionUseCase _obtenerDeleteTransactionUseCase() =>
      _deleteTransactionUseCase ??= DeleteTransactionUseCase(
        TransactionRepositoryImpl(userId: _userId),
      );

  GetClientsUseCase _obtenerGetClientsUseCase() =>
      _getClientsUseCase ??= GetClientsUseCase(
        ClientRepositoryImpl(userId: _userId),
      );

  void _notificar() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  bool get esMesActual {
    final ahora = DateTime.now();
    final primerDia = DateTime(ahora.year, ahora.month, 1);
    final ultimoDia = DateTime(ahora.year, ahora.month + 1, 0, 23, 59, 59);

    return _fechaInicial.year == primerDia.year &&
        _fechaInicial.month == primerDia.month &&
        _fechaInicial.day == primerDia.day &&
        _fechaFinal.year == ultimoDia.year &&
        _fechaFinal.month == ultimoDia.month &&
        _fechaFinal.day == ultimoDia.day;
  }

  bool get hayFiltrosActivos =>
      _filtroClienteId != null || _filtroTipo != null || !esMesActual;

  /// Lista de transacciones filtradas por cliente, tipo y rango de fechas inclusivo por día.
  List<Transaction> get transaccionesFiltradas {
    final inicio = DateTime(
      _fechaInicial.year,
      _fechaInicial.month,
      _fechaInicial.day,
    );
    final fin = DateTime(
      _fechaFinal.year,
      _fechaFinal.month,
      _fechaFinal.day,
    );

    return _transacciones.where((t) {
      final coincideCliente =
          _filtroClienteId == null || t.clienteId == _filtroClienteId;
      final coincideTipo = _filtroTipo == null || t.tipo == _filtroTipo;

      final fechaTx = DateTime(t.fecha.year, t.fecha.month, t.fecha.day);
      final coincideFecha = !fechaTx.isBefore(inicio) && !fechaTx.isAfter(fin);

      return coincideCliente && coincideTipo && coincideFecha;
    }).toList();
  }

  /// Carga transacciones y catálogo de clientes para los filtros.
  Future<void> cargarDatos() async {
    _isLoading = true;
    _errorMessage = null;
    _notificar();

    try {
      final txs = await _obtenerGetTransactionsUseCase().execute();
      _transacciones = txs;
    } catch (e) {
      _errorMessage = e.toString();
    }

    try {
      _clientesDisponibles = await _obtenerGetClientsUseCase().execute();
    } catch (_) {
      // Ignorar fallas de carga auxiliar de clientes
    } finally {
      _isLoading = false;
      _notificar();
    }
  }

  void setFiltroCliente(String? clienteId) {
    if (_filtroClienteId == clienteId) return;
    _filtroClienteId = clienteId;
    _notificar();
  }

  void setFiltroTipo(TransactionType? tipo) {
    if (_filtroTipo == tipo) return;
    _filtroTipo = tipo;
    _notificar();
  }

  /// Actualiza la fecha inicial normalizada; retorna `false` si es posterior a [_fechaFinal].
  bool actualizarFechaInicial(DateTime fecha) {
    final normalizada = DateTime(fecha.year, fecha.month, fecha.day);
    if (normalizada.isAfter(_fechaFinal)) {
      return false;
    }
    _fechaInicial = normalizada;
    _notificar();
    return true;
  }

  /// Actualiza la fecha final normalizada; retorna `false` si es anterior a [_fechaInicial].
  bool actualizarFechaFinal(DateTime fecha) {
    final normalizada = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);
    if (normalizada.isBefore(_fechaInicial)) {
      return false;
    }
    _fechaFinal = normalizada;
    _notificar();
    return true;
  }

  void restablecerMesActual() {
    final ahora = DateTime.now();
    _fechaInicial = DateTime(ahora.year, ahora.month, 1);
    _fechaFinal = DateTime(ahora.year, ahora.month + 1, 0, 23, 59, 59);
    _notificar();
  }

  /// Elimina una transacción manual, recalcula el nuevo saldo del cliente y recarga la lista.
  Future<double> eliminarTransaccion(Transaction tx) async {
    await _obtenerDeleteTransactionUseCase().execute(
      tx.id,
      clienteId: tx.clienteId,
    );
    final txsCliente = await _obtenerGetTransactionsUseCase().execute(
      clienteId: tx.clienteId,
    );
    final nuevoSaldo = txsCliente.fold<double>(
      0.0,
      (sum, t) => sum + t.valorFirmado,
    );
    await cargarDatos();
    return nuevoSaldo;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
