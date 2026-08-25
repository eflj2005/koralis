import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

/// Caso de uso para obtener el perfil de un usuario por su UID de Firebase Authentication.
class GetProfileUseCase {
  final ProfileRepository repository;

  GetProfileUseCase(this.repository);

  /// Ejecuta la consulta del perfil para el [userId] (UID de Firebase Auth).
  Future<Profile> execute(String userId) async {
    return await repository.getProfile(userId);
  }
}
