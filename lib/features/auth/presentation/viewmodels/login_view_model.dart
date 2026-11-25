import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:koralis_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:koralis_app/features/auth/domain/entities/user.dart';
import 'package:koralis_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:koralis_app/features/auth/domain/usecases/resend_email_verification_usecase.dart';

/// ViewModel de la pantalla de inicio de sesión.
///
/// Gestiona la autenticación del usuario, el estado de carga, los errores
/// y el reenvío de correos de verificación sin acoplar la vista a Firebase.
class LoginViewModel extends ChangeNotifier {
  LoginUseCase? _loginUseCase;
  ResendEmailVerificationUseCase? _resendEmailVerificationUseCase;

  bool _cargando = false;
  String? _errorMensaje;
  bool _disposed = false;

  LoginViewModel({
    LoginUseCase? loginUseCase,
    ResendEmailVerificationUseCase? resendEmailVerificationUseCase,
  })  : _loginUseCase = loginUseCase,
        _resendEmailVerificationUseCase = resendEmailVerificationUseCase;

  bool get cargando => _cargando;
  String? get errorMensaje => _errorMensaje;

  LoginUseCase _obtenerLoginUseCase() =>
      _loginUseCase ??= LoginUseCase(AuthRepositoryImpl());

  ResendEmailVerificationUseCase _obtenerResendUseCase() =>
      _resendEmailVerificationUseCase ??=
          ResendEmailVerificationUseCase(AuthRepositoryImpl());

  void _notificar() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// Determina si un mensaje de error corresponde a un correo pendiente de verificación.
  bool esErrorCorreoNoVerificado(String mensaje) {
    final lower = mensaje.toLowerCase();
    return lower.contains('no ha sido verificado') ||
        lower.contains('verificación') ||
        lower.contains('confirmación');
  }

  /// Limpia el último mensaje de error registrado.
  void limpiarError() {
    if (_errorMensaje == null) return;
    _errorMensaje = null;
    _notificar();
  }

  /// Autentica al usuario con correo y contraseña.
  Future<User> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    _errorMensaje = null;
    _cargando = true;
    _notificar();

    try {
      return await _obtenerLoginUseCase().execute(correo.trim(), contrasena);
    } catch (e) {
      _errorMensaje = AppErrorHandler.parseMessage(e);
      rethrow;
    } finally {
      _cargando = false;
      _notificar();
    }
  }

  /// Reenvía el enlace de verificación al correo del usuario.
  Future<void> reenviarConfirmacion({
    required String correo,
    required String contrasena,
  }) async {
    _errorMensaje = null;
    _cargando = true;
    _notificar();

    try {
      await _obtenerResendUseCase().execute(
        correo: correo.trim(),
        contrasena: contrasena,
      );
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
