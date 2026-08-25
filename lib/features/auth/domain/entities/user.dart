/// Entidad de dominio que representa un usuario autenticado de la aplicación.
class User {
  /// Identificador único del usuario (UID de Firebase Authentication).
  final String id;

  /// Nombre completo del usuario.
  final String nombre;

  /// Correo electrónico del usuario.
  final String correo;

  /// Fecha de nacimiento del usuario (formato DD/MM/AAAA).
  final String? nacimiento;

  User({
    required this.id,
    required this.nombre,
    required this.correo,
    this.nacimiento,
  });
}
