import 'package:firebase_core/firebase_core.dart';

/// Clase de utilidad para traducir y formatear errores de Firebase a mensajes legibles en español.
class FirebaseErrors {
  /// Traduce un código de error de Firebase Authentication o FirebaseException a un mensaje descriptivo en español.
  /// 
  /// Recibe como argumento [code] que representa la clave de error entregada por la excepción.
  static String mapMessage(String code) {
    switch (code) {
      // Errores de Autenticación
      case 'invalid-email':
        return 'El formato del correo electrónico es inválido.';
      case 'user-not-found':
        return 'No existe ningún usuario registrado con este correo electrónico.';
      case 'wrong-password':
        return 'La contraseña ingresada es incorrecta.';
      case 'weak-password':
        return 'La contraseña es muy débil. Debe tener al menos 6 caracteres.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta registrada con este correo electrónico.';
      case 'user-disabled':
        return 'Esta cuenta de usuario ha sido inhabilitada por el administrador.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Por favor, inténtelo de nuevo más tarde.';
      case 'operation-not-allowed':
        return 'El servicio de autenticación seleccionado no está habilitado.';
      case 'invalid-credential':
        return 'Las credenciales provistas son inválidas o han caducado.';
      case 'account-exists-with-different-credential':
        return 'Ya existe una cuenta asociada a este correo con un método de inicio de sesión distinto.';

      // Errores de Red y Conexión
      case 'network-request-failed':
        return 'Error de conexión a la red. Verifica tu señal de internet e intentalo nuevamente.';
      case 'unavailable':
        return 'El servicio de Firebase no se encuentra disponible momentáneamente.';
      
      // Errores de Permisos e Inexistencia en Firestore/Storage
      case 'permission-denied':
        return 'No tienes permisos suficientes para realizar esta operación.';
      case 'not-found':
        return 'El recurso solicitado no fue encontrado.';
      case 'already-exists':
        return 'El recurso que intentas crear ya existe.';
      case 'canceled':
        return 'La operación fue cancelada por el usuario o el sistema.';

      // Caso por defecto cuando no hay traducción específica
      default:
        return 'Ocurrió un error inesperado de Firebase ($code). Inténtalo de nuevo.';
    }
  }

  /// Extrae el mensaje de error adecuado a partir de un objeto de excepción genérico.
  static String getErrorMessage(Object exception) {
    if (exception is FirebaseException) {
      return mapMessage(exception.code);
    } else if (exception is String) {
      return mapMessage(exception);
    }
    return exception.toString();
  }
}
