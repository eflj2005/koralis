/// Entidad de dominio que representa a un cliente en el ecosistema Koralis.
///
/// Modela los datos de contacto, identificación legal, notas u observaciones y estado operativo.
class Client {
  /// Identificador único del cliente en Cloud Firestore.
  final String id;

  /// Nombre completo de la persona o razón social de la empresa.
  final String nombre;

  /// Documento de identificación fiscal o legal (e.g. Cédula, DNI, RUT, NIT).
  final String documento;

  /// Correo electrónico de contacto principal.
  final String correo;

  /// Número telefónico de contacto.
  final String telefono;

  /// Notas u observaciones adicionales sobre el cliente o su negociación.
  final String observacion;

  /// Estado operativo del cliente (e.g. "Activo", "Inactivo", "Pendiente").
  final String estado;

  /// Fecha de registro o vinculación del cliente.
  final DateTime fechaCreacion;

  Client({
    required this.id,
    required this.nombre,
    required this.documento,
    required this.correo,
    required this.telefono,
    this.observacion = '',
    this.estado = 'Activo',
    DateTime? fechaCreacion,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  /// Crea una copia inmutable con modificaciones puntuales.
  Client copyWith({
    String? id,
    String? nombre,
    String? documento,
    String? correo,
    String? telefono,
    String? observacion,
    String? estado,
    DateTime? fechaCreacion,
  }) {
    return Client(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      documento: documento ?? this.documento,
      correo: correo ?? this.correo,
      telefono: telefono ?? this.telefono,
      observacion: observacion ?? this.observacion,
      estado: estado ?? this.estado,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}
