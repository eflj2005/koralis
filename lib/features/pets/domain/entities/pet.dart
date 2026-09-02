// =============================================================================
// ⚠️ [DEPRECATED / BORRAR] - CÓDIGO DE REFERENCIA TEMPORAL HEREDADO (TRANSICIÓN A KORALIS)
// =============================================================================

/// Entidad de dominio que representa una mascota registrada en la aplicación.
/// 
/// ⚠️ **OBSOLETO**: Mantenido temporalmente como referencia arquitectónica. Pendiente de borrar.
@Deprecated('Código de referencia temporal heredado. Será eliminado al construir los módulos financieros de Koralis.')
class Pet {
  /// Identificador único del documento en Firestore.
  final String id;

  /// Nombre de la mascota.
  final String nombre;

  /// Edad de la mascota en años.
  final int edad;

  /// Raza de la mascota.
  final String raza;

  /// Peso de la mascota en kilogramos.
  final double peso;

  /// Código de punto del icono representativo (codePoint de IconData).
  final int iconoCodigo;

  Pet({
    required this.id,
    required this.nombre,
    required this.edad,
    required this.raza,
    required this.peso,
    required this.iconoCodigo,
  });
}
