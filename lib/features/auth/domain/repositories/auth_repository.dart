import '../entities/user.dart';

/// Contrato de repositorio para la autenticación, registro y verificación de usuarios.
abstract class AuthRepository {
  /// Inicia sesión con correo y contraseña.
  ///
  /// Valida de forma obligatoria que el correo electrónico esté verificado (`emailVerified == true`).
  /// Si el correo no ha sido verificado, bloquea el acceso, cierra la sesión y lanza una excepción.
  Future<User> login(String correo, String contrasena);

  /// Registra un nuevo usuario en Firebase Authentication, envía el correo de confirmación
  /// (`sendEmailVerification`), guarda el perfil en Firestore y cierra la sesión inmediata
  /// hasta que el usuario confirme su cuenta.
  Future<User> signUp({
    required String nombre,
    required String correo,
    required String contrasena,
    required String nacimiento,
  });

  /// Reenvía el correo de verificación al usuario correspondiente autenticando temporalmente
  /// con sus credenciales y cerrando la sesión tras el envío.
  Future<void> resendVerificationEmail(String correo, String contrasena);

  /// Envía un correo electrónico para restablecer la contraseña al correo provisto.
  Future<void> sendPasswordResetEmail(String correo);
}
