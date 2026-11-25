import 'package:flutter/foundation.dart';
import 'package:koralis_app/features/clients/data/repositories/client_repository_impl.dart';
import 'package:koralis_app/features/clients/domain/entities/client.dart';
import 'package:koralis_app/features/clients/domain/usecases/save_client_usecase.dart';

/// ViewModel para la creación y edición de clientes en [ClientFormScreen].
class ClientFormViewModel extends ChangeNotifier {
  final String _userId;
  final Client? clientInicial;
  SaveClientUseCase? _saveClientUseCase;

  late String _estadoSeleccionado;
  bool _guardando = false;
  String? _errorMessage;
  bool _disposed = false;

  ClientFormViewModel({
    required String userId,
    this.clientInicial,
    SaveClientUseCase? saveClientUseCase,
  })  : _userId = userId,
        _saveClientUseCase = saveClientUseCase,
        _estadoSeleccionado = clientInicial?.estado ?? 'Activo';

  bool get esEdicion => clientInicial != null;
  String get estadoSeleccionado => _estadoSeleccionado;
  bool get guardando => _guardando;
  String? get errorMessage => _errorMessage;

  SaveClientUseCase _obtenerSaveClientUseCase() =>
      _saveClientUseCase ??= SaveClientUseCase(
        ClientRepositoryImpl(userId: _userId),
      );

  void _notificar() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// Actualiza el estado operativo seleccionado en el formulario.
  void seleccionarEstado(String nuevoEstado) {
    if (_estadoSeleccionado == nuevoEstado) return;
    _estadoSeleccionado = nuevoEstado;
    _notificar();
  }

  /// Construye la entidad [Client] y ejecuta su persistencia mediante [SaveClientUseCase].
  Future<Client> guardarCliente({
    required String nombre,
    required String documento,
    required String correo,
    required String telefono,
    required String observacion,
  }) async {
    _guardando = true;
    _errorMessage = null;
    _notificar();

    final cliente = Client(
      id: clientInicial?.id ?? '',
      nombre: nombre.trim(),
      documento: documento.trim(),
      correo: correo.trim(),
      telefono: telefono.trim(),
      observacion: observacion.trim(),
      estado: _estadoSeleccionado,
      transacciones: clientInicial?.transacciones ?? const [],
      fechaCreacion: clientInicial?.fechaCreacion ?? DateTime.now(),
      userId: _userId,
    );

    try {
      await _obtenerSaveClientUseCase().execute(cliente);
      return cliente;
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
