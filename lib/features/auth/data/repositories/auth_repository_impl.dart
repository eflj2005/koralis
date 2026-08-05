import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'package:koralis_app/app/database.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AppDatabase _db = AppDatabase();

  @override
  Future<User> login(String correo, String contrasena) async {
    // Pequeño delay opcional para UX
    await Future.delayed(const Duration(seconds: 1));

    // Consultar SQLite desde el paquete core
    final userData = await _db.getUser(correo, contrasena);

    if (userData != null) {
      return User(
        id: userData['id'] as int,
        nombre: userData['nombre'] as String,
        correo: userData['correo'] as String,
      );
    } else {
      throw Exception('Credenciales inválidas');
    }
  }
}
