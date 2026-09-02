import '../repositories/auth_repository.dart';

/// Caso de uso para solicitar la recuperación de contraseña mediante correo electrónico.
class SendPasswordResetEmailUseCase {
  final AuthRepository repository;

  SendPasswordResetEmailUseCase(this.repository);

  /// Ejecuta el proceso de recuperación de contraseña utilizando las credenciales del usuario.
  Future<void> execute(String correo) {
    return repository.sendPasswordResetEmail(correo);
  }
}