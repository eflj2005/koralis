import 'package:core/core.dart';

/// Configuración específica del servicio de almacenamiento Firebase Storage para Koralis.
///
/// Centraliza las rutas base de almacenamiento, tipos de contenido permitidos
/// y límites de tamaño de archivos. Modificar este archivo es suficiente para
/// ajustar la organización del Storage sin tocar la lógica de negocio.
class FirebaseStorageConfig {
  FirebaseStorageConfig._();

  // ---------------------------------------------------------------------------
  // Rutas Base en Firebase Storage
  // ---------------------------------------------------------------------------

  /// Ruta base donde se almacenan los archivos asociados a usuarios.
  static const String rutaUsuarios = 'users';

  /// Subcarpeta donde se guardan las fotos de perfil de los usuarios.
  static const String carpetaFotosPerfil = 'profile_pictures';

  // ---------------------------------------------------------------------------
  // Tipos de Contenido (MIME Types)
  // ---------------------------------------------------------------------------

  /// Tipo de contenido para imágenes JPEG.
  static const String mimeJpeg = 'image/jpeg';

  /// Tipo de contenido para imágenes PNG.
  static const String mimePng = 'image/png';

  // ---------------------------------------------------------------------------
  // Límites y Restricciones
  // ---------------------------------------------------------------------------

  /// Tamaño máximo permitido para archivos de imagen en bytes (5 MB).
  static const int tamanoMaximoImagenBytes = 5 * 1024 * 1024;

  // ---------------------------------------------------------------------------
  // Helpers de Rutas
  // ---------------------------------------------------------------------------

  /// Construye la ruta completa de una foto de perfil de un usuario en Storage.
  ///
  /// Ejemplo resultado: `users/uid123/profile_pictures/photo.jpg`
  static String rutaFotoPerfil(String uid, String nombreArchivo) {
    return '$rutaUsuarios/$uid/$carpetaFotosPerfil/$nombreArchivo';
  }

  // ---------------------------------------------------------------------------
  // Instancia configurada del servicio de Storage
  // ---------------------------------------------------------------------------

  /// Retorna una instancia de [FirebaseStorageService] pre-configurada.
  static FirebaseStorageService buildService() {
    return FirebaseStorageService();
  }
}
