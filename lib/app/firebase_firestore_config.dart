import 'package:core/core.dart';

/// Configuración específica del servicio de base de datos Cloud Firestore para Koralis.
///
/// Centraliza los nombres de colecciones, campos y comportamiento del caché.
/// Modificar este archivo es suficiente para renombrar o reestructurar
/// la base de datos sin tocar la lógica de negocio de la aplicación.
class FirebaseFirestoreConfig {
  FirebaseFirestoreConfig._();

  // ---------------------------------------------------------------------------
  // Colecciones Principales
  // ---------------------------------------------------------------------------

  /// Colección raíz de usuarios de la aplicación.
  static const String colUsuarios = 'users';

  /// Colección raíz de mascotas registradas.
  static const String colMascotas = 'pets';

  /// Colección raíz de perfiles de usuario.
  static const String colPerfiles = 'profiles';

  /// Colección raíz de clientes de la aplicación Koralis.
  static const String colClientes = 'clients';

  // ---------------------------------------------------------------------------
  // Campos Comunes
  // ---------------------------------------------------------------------------

  /// Campo de marca de tiempo de creación del documento.
  static const String campoCreatedAt = 'createdAt';

  /// Campo de marca de tiempo de última modificación del documento.
  static const String campoUpdatedAt = 'updatedAt';

  // ---------------------------------------------------------------------------
  // Configuración de Caché Offline
  // ---------------------------------------------------------------------------

  /// Tamaño máximo del caché local de Firestore en bytes.
  /// El valor -1 indica tamaño ilimitado (comportamiento por defecto de Firestore).
  static const int tamanioCacheBytes = -1;

  // ---------------------------------------------------------------------------
  // Instancia configurada del servicio de Firestore
  // ---------------------------------------------------------------------------

  /// Retorna una instancia de [FirestoreService] pre-configurada.
  static FirestoreService buildService() {
    return FirestoreService();
  }
}
