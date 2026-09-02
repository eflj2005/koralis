import '../repositories/auth_repository.dart';

/// Caso de uso para reenviar el correo de confirmación de registro a un usuario.
class ResendEmailVerificationUseCase {
  final AuthRepository repository;

  ResendEmailVerificationUseCase(this.repository);

  /// Ejecuta el proceso de reenvío del correo de confirmación utilizando las credenciales del usuario.
  Future<void> execute({
    required String correo,
    required String contrasena,
  }) {
    return repository.resendVerificationEmail(correo, contrasena);
  }
}
