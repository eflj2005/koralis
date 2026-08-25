import 'package:core/core.dart';

/// Configuración específica del servicio de Autenticación Firebase para Koralis.
///
/// Define el comportamiento de autenticación habilitado para este proyecto.
/// El proveedor activo es exclusivamente **correo electrónico y contraseña**.
///
/// Nota: El paquete [core] mantiene soporte completo para otros proveedores
/// (Google Sign-In, etc.). Para habilitarlos basta con ajustar [buildService].
class FirebaseAuthConfig {
  FirebaseAuthConfig._();

  // ---------------------------------------------------------------------------
  // Proveedores de Autenticación
  // ---------------------------------------------------------------------------

  /// Proveedor activo en este proyecto.
  /// Valor informativo para documentar la decisión de diseño.
  static const String proveedorActivo = 'email_password';

  // ---------------------------------------------------------------------------
  // Sesión y Estado de Autenticación
  // ---------------------------------------------------------------------------

  /// Indica si la sesión del usuario debe persistir entre reinicios de la app.
  /// Por defecto Flutter/Firebase ya persiste la sesión localmente.
  static const bool persistirSesion = true;

  // ---------------------------------------------------------------------------
  // Colección de usuarios en Firestore (usada para registrar sesiones/tokens)
  // ---------------------------------------------------------------------------

  /// Nombre de la colección de Firestore donde se guardan los datos de los usuarios.
  static const String coleccionUsuarios = 'users';

  /// Campo de marca de tiempo de última actualización del registro.
  static const String campoActualizadoEn = 'updateAt';

  // ---------------------------------------------------------------------------
  // Instancia configurada del servicio de autenticación
  // ---------------------------------------------------------------------------

  /// Retorna una instancia de [FirebaseAuthService] configurada únicamente
  /// para autenticación por correo electrónico y contraseña.
  ///
  /// Para habilitar Google Sign-In en el futuro, pasar una instancia de
  /// [GoogleSignIn] al parámetro `googleSignIn` del constructor.
  static FirebaseAuthService buildService() {
    return FirebaseAuthService(
      googleSignIn: null, // Google Sign-In deshabilitado en este proyecto
    );
  }
}
