import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:koralis_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:koralis_app/features/auth/domain/usecases/sign_up_usecase.dart';

/// ViewModel del formulario modal de registro de usuarios.
///
/// Centraliza la fecha de nacimiento seleccionada, el estado de carga,
/// la gestión de errores y la ejecución del caso de uso de registro.
class SignUpViewModel extends ChangeNotifier {
  SignUpUseCase? _signUpUseCase;

  bool _cargando = false;
  String? _errorMensaje;
  DateTime? _selectedBirthDate;
  bool _disposed = false;

  SignUpViewModel({SignUpUseCase? signUpUseCase})
      : _signUpUseCase = signUpUseCase;

  bool get cargando => _cargando;
  String? get errorMensaje => _errorMensaje;
  DateTime? get selectedBirthDate => _selectedBirthDate;

  SignUpUseCase _obtenerSignUpUseCase() =>
      _signUpUseCase ??= SignUpUseCase(AuthRepositoryImpl());

  void _notificar() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// Actualiza la fecha de nacimiento seleccionada y limpia errores previos.
  void seleccionarFechaNacimiento(DateTime fecha) {
    _selectedBirthDate = fecha;
    _errorMensaje = null;
    _notificar();
  }

  /// Establece o limpia un mensaje de error visible en el formulario.
  void setError(String? mensaje) {
    _errorMensaje = mensaje;
    _notificar();
  }

  /// Registra un nuevo usuario y retorna el correo normalizado.
  Future<String> registrarUsuario({
    required String nombre,
    required String correo,
    required String contrasena,
    required String nacimiento,
  }) async {
    _errorMensaje = null;
    _cargando = true;
    _notificar();

    final correoLimpio = correo.trim();
    try {
      await _obtenerSignUpUseCase().execute(
        nombre: nombre.trim(),
        correo: correoLimpio,
        contrasena: contrasena,
        nacimiento: nacimiento.trim(),
      );
      return correoLimpio;
    } catch (e) {
      _errorMensaje = AppErrorHandler.parseMessage(e);
      rethrow;
    } finally {
      _cargando = false;
      _notificar();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
