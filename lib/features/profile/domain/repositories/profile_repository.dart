import '../entities/profile.dart';

/// Contrato de repositorio para gestión del perfil de usuario.
abstract class ProfileRepository {
  /// Obtiene el perfil del usuario por su UID de Firebase Authentication.
  Future<Profile> getProfile(String userId);
}
