import 'package:flutter/material.dart';

/// Tipos de notificaciones soportadas por [AppMessenger].
enum MessengerType {
  /// Notificación de error (usualmente tono rojo/destacado).
  error,

  /// Notificación de éxito (usualmente tono verde/positivo).
  success,

  /// Notificación informativa o de advertencia (usualmente tono azul/naranja).
  info,
}

/// Utilidad UI genérica centralizada para la presentación de alertas y notificaciones en pantalla.
class AppMessenger {
  /// Muestra un [SnackBar] flotante estilizado para notificar un mensaje de error.
  static void showErrorSnackBar(
    BuildContext context,
    String mensaje, {
    Duration duracion = const Duration(seconds: 4),
  }) {
    showSnackBar(
      context,
      mensaje: mensaje,
      tipo: MessengerType.error,
      duracion: duracion,
    );
  }

  /// Muestra un [SnackBar] flotante estilizado para notificar una operación exitosa.
  static void showSuccessSnackBar(
    BuildContext context,
    String mensaje, {
    Duration duracion = const Duration(seconds: 3),
  }) {
    showSnackBar(
      context,
      mensaje: mensaje,
      tipo: MessengerType.success,
      duracion: duracion,
    );
  }

  /// Muestra un [SnackBar] flotante estilizado para notificar información general o advertencias.
  static void showInfoSnackBar(
    BuildContext context,
    String mensaje, {
    Duration duracion = const Duration(seconds: 3),
  }) {
    showSnackBar(
      context,
      mensaje: mensaje,
      tipo: MessengerType.info,
      duracion: duracion,
    );
  }

  /// Oculta el [SnackBar] activo inmediatamente de forma segura.
  static void hide(BuildContext context) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  }

  /// Limpia todos los [SnackBar] en cola o activos de la pantalla de forma segura.
  static void clear(BuildContext context) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
    }
  }

  /// Muestra un [SnackBar] configurable en pantalla respetando el tema de la aplicación.
  static void showSnackBar(
    BuildContext context, {
    required String mensaje,
    MessengerType tipo = MessengerType.info,
    Duration duracion = const Duration(seconds: 3),
    String accionLabel = 'Aceptar',
    VoidCallback? onAccion,
  }) {
    if (!context.mounted) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Captura segura de la instancia ScaffoldMessengerState antes de construir el widget
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    Color backgroundColor;
    Color iconColor;
    IconData iconData;

    switch (tipo) {
      case MessengerType.error:
        backgroundColor = colorScheme.errorContainer;
        iconColor = colorScheme.onErrorContainer;
        iconData = Icons.error_outline_rounded;
        break;
      case MessengerType.success:
        backgroundColor = const Color(0xFF2E7D32); // Verde oscuro accesible
        iconColor = Colors.white;
        iconData = Icons.check_circle_outline_rounded;
        break;
      case MessengerType.info:
        backgroundColor = colorScheme.secondaryContainer;
        iconColor = colorScheme.onSecondaryContainer;
        iconData = Icons.info_outline_rounded;
        break;
    }

    // Ocultar cualquier SnackBar previo activo usando la referencia capturada
    scaffoldMessenger.hideCurrentSnackBar();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(iconData, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duracion,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: SnackBarAction(
          label: accionLabel,
          textColor: iconColor,
          onPressed: () {
            // Empleamos scaffoldMessenger directamente para evitar consultar ancestros sobre un
            // context que pudo haber sido desactivado si la pantalla cambió mientras el SnackBar seguía visible.
            scaffoldMessenger.hideCurrentSnackBar();
            onAccion?.call();
          },
        ),
      ),
    );
  }

  /// Muestra un diálogo modal de error para alertas críticas que requieran confirmación manual.
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String titulo,
    required String mensaje,
  }) async {
    final theme = Theme.of(context);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: theme.colorScheme.error,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            mensaje,
            style: theme.textTheme.bodyMedium,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Entendido'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
