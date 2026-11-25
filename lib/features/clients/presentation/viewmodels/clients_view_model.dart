import 'package:flutter/foundation.dart';
import 'package:koralis_app/features/clients/data/repositories/client_repository_impl.dart';
import 'package:koralis_app/features/clients/domain/entities/client.dart';
import 'package:koralis_app/features/clients/domain/usecases/delete_client_usecase.dart';
import 'package:koralis_app/features/clients/domain/usecases/get_clients_usecase.dart';
import 'package:koralis_app/features/instruments/data/repositories/instrument_repository_impl.dart';
import 'package:koralis_app/features/transactions/data/repositories/transaction_repository_impl.dart';

/// ViewModel de la pantalla principal de Clientes.
class ClientsViewModel extends ChangeNotifier {
  final String _userId;
  GetClientsUseCase? _getClientsUseCase;
  DeleteClientUseCase? _deleteClientUseCase;

  List<Client> _clientes = const [];
  bool _isLoading = false;
  bool _eliminando = false;
  String? _errorMessage;
  bool _disposed = false;

  ClientsViewModel({
    required String userId,
    GetClientsUseCase? getClientsUseCase,
    DeleteClientUseCase? deleteClientUseCase,
  })  : _userId = userId,
        _getClientsUseCase = getClientsUseCase,
        _deleteClientUseCase = deleteClientUseCase;

  List<Client> get clientes => List.unmodifiable(_clientes);
  bool get isLoading => _isLoading;
  bool get eliminando => _eliminando;
  String? get errorMessage => _errorMessage;

  GetClientsUseCase _obtenerGetClientsUseCase() =>
      _getClientsUseCase ??= GetClientsUseCase(
        ClientRepositoryImpl(userId: _userId),
      );

  DeleteClientUseCase _obtenerDeleteClientUseCase() =>
      _deleteClientUseCase ??= DeleteClientUseCase(
        clientRepository: ClientRepositoryImpl(userId: _userId),
        instrumentRepository: InstrumentRepositoryImpl(userId: _userId),
        transactionRepository: TransactionRepositoryImpl(userId: _userId),
      );

  void _notificar() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// Consulta y actualiza la lista de clientes ordenada alfabéticamente.
  Future<void> cargarClientes() async {
    _isLoading = true;
    _errorMessage = null;
    _notificar();

    try {
      _clientes = await _obtenerGetClientsUseCase().execute();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _notificar();
    }
  }

  /// Elimina un cliente validando integridad referencial y recarga el listado.
  Future<void> eliminarCliente(Client cliente) async {
    _eliminando = true;
    _notificar();

    try {
      await _obtenerDeleteClientUseCase().execute(cliente);
      await cargarClientes();
    } finally {
      _eliminando = false;
      _notificar();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
