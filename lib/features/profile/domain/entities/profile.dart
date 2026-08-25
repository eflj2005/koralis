/// Entidad de dominio que representa el perfil extendido de un usuario.
class Profile {
  /// Identificador único del documento de perfil en Firestore.
  final String id;

  /// UID del usuario propietario de este perfil (Firebase Authentication).
  final String userId;

  /// Ruta o URL del avatar del usuario.
  final String avatarPath;

  /// Nombre completo del usuario.
  final String nombre;

  /// Correo electrónico del usuario.
  final String correo;

  Profile({
    required this.id,
    required this.userId,
    required this.avatarPath,
    required this.nombre,
    required this.correo,
  });
}
