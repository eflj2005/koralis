import 'package:flutter/material.dart';
import 'app_buttons.dart';

// ---------------------------------------------------------------------------
// AppModalBottomSheet (Widget genérico para emergentes / modales)
// ---------------------------------------------------------------------------

/// Contenedor base reutilizable para cualquier ventana emergente (modal / bottom sheet).
///
/// Ofrece:
/// - Bordes redondeados y sombra estilizada.
/// - Indicador de arrastre superior (drag handle).
/// - Ajuste automático de margen y padding para teclado virtual ([MediaQueryData.viewInsets]).
/// - Límite de altura máxima responsivo con soporte para desplazamiento.
class AppModalBottomSheet extends StatelessWidget {
  /// Widget con el contenido a mostrar dentro del emergente.
  final Widget child;

  /// Indica si se debe mostrar el indicador de arrastre superior.
  final bool mostrarIndicador;

  /// Margen exterior del contenedor flotante.
  final EdgeInsetsGeometry? margin;

  /// Relleno interno del contenedor.
  final EdgeInsetsGeometry? padding;

  /// Altura máxima relativa respecto a la pantalla (por defecto: 90%).
  final double maxHeightFactor;

  /// Color de fondo personalizado del modal (opcional; por defecto usa el fondo del tema).
  final Color? backgroundColor;

  const AppModalBottomSheet({
    super.key,
    required this.child,
    this.mostrarIndicador = true,
    this.margin,
    this.padding,
    this.maxHeightFactor = 0.90,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final insetsBottom = mediaQuery.viewInsets.bottom;
    final maxHeight = mediaQuery.size.height * maxHeightFactor;

    return Padding(
      // Evita superponerse con el teclado virtual
      padding: EdgeInsets.only(bottom: insetsBottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        margin: margin ?? const EdgeInsets.all(16),
        padding: padding ?? const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (mostrarIndicador) ...[
                Center(
                  child: Container(
                    width: 48,
                    height: 6,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Función helper genérica para desplegar cualquier emergente estilizado en la aplicación.
Future<T?> showAppModalBottomSheet<T>(
  BuildContext context, {
  required Widget child,
  bool isDismissible = true,
  bool enableDrag = true,
  bool mostrarIndicador = true,
  EdgeInsetsGeometry? margin,
  EdgeInsetsGeometry? padding,
  double maxHeightFactor = 0.90,
  Color? backgroundColor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    builder: (context) => AppModalBottomSheet(
      mostrarIndicador: mostrarIndicador,
      margin: margin,
      padding: padding,
      maxHeightFactor: maxHeightFactor,
      backgroundColor: backgroundColor,
      child: child,
    ),
  );
}

// ---------------------------------------------------------------------------
// showUnderConstructionDialog (Refactorizado con base en AppModalBottomSheet)
// ---------------------------------------------------------------------------

/// Muestra un modal estilizado indicando que la función se encuentra en construcción.
/// Implementado sobre el componente genérico [showAppModalBottomSheet].
void showUnderConstructionDialog(
  BuildContext context, {
  required String accion,
}) {
  final theme = Theme.of(context);

  showAppModalBottomSheet(
    context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.construction_rounded,
          size: 64,
          color: theme.colorScheme.secondary,
        ),
        const SizedBox(height: 16),
        Text(
          'En construcción',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Próximamente -> $accion',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 24),
        AppButton(
          texto: 'Entendido',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}
