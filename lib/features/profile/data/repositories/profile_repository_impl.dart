import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import 'package:koralis_app/app/database.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final AppDatabase _db = AppDatabase();

  @override
  Future<Profile> getProfile(int userId) async {
    final data = await _db.getProfile(userId);

    if (data != null) {
      return Profile(
        id: data['id'] as int,
        userId: data['user_id'] as int,
        avatarPath: data['avatar_path'] as String,
        nombre: data['nombre'] as String,
        correo: data['correo'] as String,
      );
    } else {
      throw Exception('Perfil no encontrado para el usuario $userId');
    }
  }
}
