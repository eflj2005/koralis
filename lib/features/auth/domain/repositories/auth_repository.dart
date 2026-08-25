import '../entities/user.dart';

/// Contrato de repositorio para la autenticación y registro de usuarios.
abstract class AuthRepository {
  /// Inicia sesión con correo y contraseña.
  Future<User> login(String correo, String contrasena);

  /// Registra un nuevo usuario en Firebase Authentication y guarda su perfil en Firestore.
  Future<User> signUp({
    required String nombre,
    required String correo,
    required String contrasena,
    required String nacimiento,
  });
}
