import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para registrar un nuevo usuario en el sistema.
class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  /// Ejecuta el proceso de registro validando credenciales y creando el perfil en base de datos.
  Future<User> execute({
    required String nombre,
    required String correo,
    required String contrasena,
    required String nacimiento,
  }) {
    return repository.signUp(
      nombre: nombre,
      correo: correo,
      contrasena: contrasena,
      nacimiento: nacimiento,
    );
  }
}
