import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import '../firebase/firebase_errors.dart';

/// Procesador centralizado genérico para analizar y convertir excepciones en mensajes legibles en español.
class AppErrorHandler {
  /// Analiza cualquier objeto de excepción [error] y retorna un mensaje descriptivo para el usuario final.
  static String parseMessage(Object? error) {
    if (error == null) {
      return 'Ocurrió un error desconocido.';
    }

    // 1. Excepciones de Firebase
    if (error is FirebaseException) {
      return FirebaseErrors.mapMessage(error.code);
    }

    // 2. Excepciones de conexión y red
    if (error is SocketException) {
      return 'No hay conexión a internet. Verifica tu red e inténtalo de nuevo.';
    }
    if (error is TimeoutException) {
      return 'La solicitud ha superado el tiempo de espera. Inténtalo más tarde.';
    }

    // 3. Excepciones de formato o conversión de datos
    if (error is FormatException) {
      return 'Error en la estructura de los datos procesados.';
    }

    // 4. Si el error ya es una cadena de texto
    if (error is String) {
      if (error.trim().isEmpty) {
        return 'Ocurrió un error inesperado.';
      }
      return FirebaseErrors.mapMessage(error);
    }

    // 5. Excepciones genéricas que implementan toString
    final errorString = error.toString();
    if (errorString.contains('Exception:')) {
      return errorString.replaceAll('Exception:', '').trim();
    }

    return 'Ocurrió un error durante la operación: $errorString';
  }
}
