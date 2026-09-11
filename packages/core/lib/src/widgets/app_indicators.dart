import 'package:flutter/material.dart';
import '../theme.dart';

// ---------------------------------------------------------------------------
// AppSpinner
// ---------------------------------------------------------------------------

/// Widget de carga circular personalizado que muestra un
/// [CircularProgressIndicator] y la imagen del spinner configurada en el centro.
/// El color de fondo y la opacidad pueden configurarse globalmente en el tema
/// o pasarse como parámetros en el constructor.
class AppSpinner extends StatelessWidget {
  /// Tamaño general del spinner (ancho y alto).
  final double size;

  /// Color de fondo personalizado (opcional, sobrescribe la configuración del tema).
  final Color? backgroundColor;

  /// Opacidad de fondo personalizada de 0.0 a 1.0 (opcional, sobrescribe la configuración del tema).
  final double? backgroundOpacity;

  const AppSpinner({
    super.key,
    this.size = 120,
    this.backgroundColor,
    this.backgroundOpacity,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colorSecundario = colorScheme.secondary;
    final colorPrimario = colorScheme.primary;
    final coreTheme = Theme.of(context).extension<CoreThemeExtension>();

    // Obtener color base de fondo y nivel de opacidad (con valores de respaldo por defecto)
    final colorBaseFondo =
        backgroundColor ?? coreTheme?.spinnerBackgroundColor ?? colorSecundario;
    final opacidadFondo =
        backgroundOpacity ?? coreTheme?.spinnerBackgroundOpacity ?? 0.80;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorBaseFondo.withValues(alpha: opacidadFondo),
              ),
            ),
          ),
          SizedBox.expand(
            child: CircularProgressIndicator(
              color: colorPrimario,
              backgroundColor: colorPrimario.withValues(alpha: 0.25),
              strokeWidth: (size / 120) * 8, // Proporcional al tamaño
              strokeCap: StrokeCap.round,
            ),
          ),
          if (coreTheme?.spinnerImagePath != null)
            Image.asset(
              coreTheme!.spinnerImagePath!,
              width: size * 0.66,
              height: size * 0.66,
              fit: BoxFit.contain,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// LoadingWidget
// ---------------------------------------------------------------------------

/// Overlay de pantalla completa para indicar estado de carga general.
/// Muestra [AppSpinner] centrado sobre una capa semitransparente oscura.
///
/// Ejemplo de uso:
/// ```dart
/// if (_cargando) const LoadingWidget(),
/// ```
class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colorSecundario = colorScheme.secondary;

    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppSpinner(),
            const SizedBox(height: 16),
            Text(
              'Cargando...',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorSecundario,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EmptyWidget
// ---------------------------------------------------------------------------

/// Widget reutilizable para mostrar cuando una lista u otra colección está vacía.
/// Muestra un ícono, un título principal y una descripción opcional.
class EmptyWidget extends StatelessWidget {
  /// Ícono a mostrar en la parte superior.
  final IconData icono;

  /// Título principal que indica el estado vacío.
  final String titulo;

  /// Descripción detallada o sugerencia para el usuario.
  final String? descripcion;

  const EmptyWidget({
    super.key,
    required this.icono,
    required this.titulo,
    this.descripcion,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colorEsquema = tema.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icono,
              size: 64,
              color: colorEsquema.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: tema.textTheme.titleLarge?.copyWith(
                color: colorEsquema.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (descripcion != null) ...[
              const SizedBox(height: 8),
              Text(
                descripcion!,
                textAlign: TextAlign.center,
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: colorEsquema.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
