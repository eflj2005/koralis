/// Entidad de dominio que representa un banco o entidad financiera en Koralis.
/// Proviene de los documentos registrados en la colección 'banks' de Firestore.
class Bank {
  /// Identificador único del documento en Firestore.
  final String id;

  /// Nombre de la entidad financiera (ej. "Bancolombia", "Davivienda").
  final String nombre;

  const Bank({
    required this.id,
    required this.nombre,
  });

  /// Construye una entidad [Bank] a partir de los datos obtenidos de Firestore.
  /// Mapea de forma resiliente distintas variantes de nombre ('nombre', 'name', 'entidad', 'banco').
  factory Bank.fromMap(Map<String, dynamic> map, {String? id}) {
    final nombreExtraido = (map['nombre'] ??
            map['name'] ??
            map['entidad'] ??
            map['banco'] ??
            id ??
            '')
        .toString()
        .trim();

    return Bank(
      id: id ?? (map['id'] as String? ?? ''),
      nombre: nombreExtraido.isNotEmpty ? nombreExtraido : (id ?? ''),
    );
  }

  /// Serializa la entidad a un mapa de datos compatible con Firestore.
  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
      };
}
