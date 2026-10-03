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

  /// Colección raíz de clientes de la aplicación Koralis (referencia global/legacy).
  static const String colClientes = 'clients';

  /// Colección raíz de instrumentos financieros de la aplicación Koralis (referencia global/legacy).
  static const String colInstrumentos = 'instruments';

  /// Nombre del segmento de subcolección para clientes pertenecientes a un usuario.
  static const String subcolClientes = 'clients';

  /// Nombre del segmento de subcolección para instrumentos pertenecientes a un usuario.
  static const String subcolInstrumentos = 'instruments';

  /// Colección raíz de bancos y entidades financieras (Global para todos los usuarios).
  static const String colBancos = 'banks';

  /// Clave del subobjeto/lista donde se almacenan las transacciones dentro del documento de cada cliente.
  static const String campoTransacciones = 'transacciones';

  /// Retorna la ruta canónica y aislada de la colección de clientes para un usuario específico.
  /// Formato: 'users/{userId}/clients'
  static String coleccionClientes(String userId) {
    final uidLimpio = userId.trim();
    if (uidLimpio.isEmpty) {
      return colClientes;
    }
    return '$colUsuarios/$uidLimpio/$subcolClientes';
  }

  /// Retorna la ruta canónica y aislada de la colección de instrumentos para un usuario específico.
  /// Formato: 'users/{userId}/instruments'
  static String coleccionInstrumentos(String userId) {
    final uidLimpio = userId.trim();
    if (uidLimpio.isEmpty) {
      return colInstrumentos;
    }
    return '$colUsuarios/$uidLimpio/$subcolInstrumentos';
  }

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
