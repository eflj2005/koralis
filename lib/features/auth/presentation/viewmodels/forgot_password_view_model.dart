import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:koralis_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:koralis_app/features/auth/domain/usecases/send_password_reset_email_usecase.dart';

/// ViewModel del formulario modal de recuperación de contraseña.
class ForgotPasswordViewModel extends ChangeNotifier {
  SendPasswordResetEmailUseCase? _sendPasswordResetEmailUseCase;

  bool _cargando = false;
  String? _errorMensaje;
  bool _disposed = false;

  ForgotPasswordViewModel({
    SendPasswordResetEmailUseCase? sendPasswordResetEmailUseCase,
  }) : _sendPasswordResetEmailUseCase = sendPasswordResetEmailUseCase;

  bool get cargando => _cargando;
  String? get errorMensaje => _errorMensaje;

  SendPasswordResetEmailUseCase _obtenerUseCase() =>
      _sendPasswordResetEmailUseCase ??=
          SendPasswordResetEmailUseCase(AuthRepositoryImpl());

  void _notificar() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// Limpia cualquier error mostrado en el formulario.
  void limpiarError() {
    if (_errorMensaje == null) return;
    _errorMensaje = null;
    _notificar();
  }

  /// Envía el enlace de restablecimiento al correo indicado y retorna el correo normalizado.
  Future<String> enviarEnlace(String email) async {
    _errorMensaje = null;
    _cargando = true;
    _notificar();

    final correoLimpio = email.trim();
    try {
      await _obtenerUseCase().execute(correoLimpio);
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
