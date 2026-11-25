import 'package:flutter/foundation.dart';
import 'package:koralis_app/features/clients/data/repositories/client_repository_impl.dart';
import 'package:koralis_app/features/clients/domain/entities/client.dart';
import 'package:koralis_app/features/clients/domain/usecases/get_clients_usecase.dart';
import 'package:koralis_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:koralis_app/features/transactions/domain/entities/transaction.dart';
import 'package:koralis_app/features/transactions/domain/usecases/save_transaction_usecase.dart';

/// ViewModel para la creación, edición y visualización de transacciones en [TransactionFormScreen].
class TransactionFormViewModel extends ChangeNotifier {
  final String _userId;
  final Transaction? transactionInicial;
  SaveTransactionUseCase? _saveTransactionUseCase;
  GetClientsUseCase? _getClientsUseCase;

  String? _clienteIdSeleccionado;
  String? _clienteNombreSeleccionado;
  late TransactionType _tipoSeleccionado;
  late DateTime _fecha;
  bool _guardando = false;
  bool _cargandoClientes = true;
  List<Client> _clientesDisponibles = const [];
  String? _errorMessage;
  bool _disposed = false;

  TransactionFormViewModel({
    required String userId,
    this.transactionInicial,
    String? clienteIdPreseleccionado,
    SaveTransactionUseCase? saveTransactionUseCase,
    GetClientsUseCase? getClientsUseCase,
  })  : _userId = userId,
        _saveTransactionUseCase = saveTransactionUseCase,
        _getClientsUseCase = getClientsUseCase {
    _tipoSeleccionado = transactionInicial?.tipo ?? TransactionType.recarga;
    _fecha = transactionInicial?.fecha ?? DateTime.now();
    _clienteIdSeleccionado =
        transactionInicial?.clienteId ?? clienteIdPreseleccionado;
    _clienteNombreSeleccionado = transactionInicial?.clienteNombre;
  }

  bool get esEdicion => transactionInicial != null;
  bool get esAutomatica =>
      esEdicion &&
      (transactionInicial!.tipo == TransactionType.inversion ||
          transactionInicial!.tipo == TransactionType.retorno);

  String? get clienteIdSeleccionado => _clienteIdSeleccionado;
  String? get clienteNombreSeleccionado => _clienteNombreSeleccionado;
  TransactionType get tipoSeleccionado => _tipoSeleccionado;
  DateTime get fecha => _fecha;
  bool get guardando => _guardando;
  bool get cargandoClientes => _cargandoClientes;
  List<Client> get clientesDisponibles =>
      List.unmodifiable(_clientesDisponibles);
  String? get errorMessage => _errorMessage;

  SaveTransactionUseCase _obtenerSaveTransactionUseCase() =>
      _saveTransactionUseCase ??= SaveTransactionUseCase(
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

  /// Carga los clientes disponibles y completa el nombre si había preselección.
  Future<void> cargarClientes() async {
    _cargandoClientes = true;
    _notificar();

    try {
      final clientes = await _obtenerGetClientsUseCase().execute();
      _clientesDisponibles = clientes;
      if (_clienteIdSeleccionado != null &&
          (_clienteNombreSeleccionado == null ||
              _clienteNombreSeleccionado!.isEmpty)) {
        final encontrado =
            clientes.where((c) => c.id == _clienteIdSeleccionado);
        if (encontrado.isNotEmpty) {
          _clienteNombreSeleccionado = encontrado.first.nombre;
        }
      }
    } catch (_) {
      // Mantener lista vacía segura si falla la carga
    } finally {
      _cargandoClientes = false;
      _notificar();
    }
  }

  void seleccionarCliente(String? clienteId) {
    _clienteIdSeleccionado = clienteId;
    final sel = _clientesDisponibles.cast<Client?>().firstWhere(
          (c) => c?.id == clienteId,
          orElse: () => null,
        );
    _clienteNombreSeleccionado = sel?.nombre;
    _notificar();
  }

  void seleccionarTipo(TransactionType tipo) {
    if (esAutomatica || _tipoSeleccionado == tipo) return;
    _tipoSeleccionado = tipo;
    _notificar();
  }

  void seleccionarFecha(DateTime nuevaFecha) {
    if (esAutomatica || _fecha == nuevaFecha) return;
    _fecha = nuevaFecha;
    _notificar();
  }

  /// Construye y persiste la transacción mediante [SaveTransactionUseCase].
  Future<Transaction> guardarTransaccion({
    required double valor,
    required String observacion,
  }) async {
    _guardando = true;
    _errorMessage = null;
    _notificar();

    final nuevaTx = Transaction(
      id: transactionInicial?.id ?? '',
      clienteId: _clienteIdSeleccionado ?? '',
      clienteNombre: _clienteNombreSeleccionado ?? '',
      tipo: _tipoSeleccionado,
      valor: valor,
      fecha: _fecha,
      instrumentoId: transactionInicial?.instrumentoId,
      observacion: observacion.trim(),
      fechaCreacion: transactionInicial?.fechaCreacion,
    );

    try {
      await _obtenerSaveTransactionUseCase().execute(nuevaTx);
      return nuevaTx;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
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
