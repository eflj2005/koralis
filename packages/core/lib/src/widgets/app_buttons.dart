import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// AppButton
// ---------------------------------------------------------------------------

/// Widget reutilizable de botón principal de la aplicación.
/// Encapsula un [ElevatedButton] con soporte para ícono, color personalizado y texto.
///
/// Ejemplo de uso:
/// ```dart
/// AppButton(
///   texto: 'Ingresar',
///   icono: Icons.login,
///   onPressed: () => print('presionado'),
/// )
/// ```
class AppButton extends StatelessWidget {
  /// Texto que se muestra dentro del botón.
  final String texto;

  /// Callback que se ejecuta al presionar el botón.
  /// Si es null, el botón queda deshabilitado.
  final VoidCallback? onPressed;

  /// Color de fondo del botón.
  /// Si es null, usa el color primario del tema actual.
  final Color? color;

  /// Ícono opcional que aparece a la izquierda del texto.
  /// Si es null, se renderiza un botón sin ícono.
  final IconData? icono;

  const AppButton({
    super.key,
    required this.texto,
    required this.onPressed,
    this.color,
    this.icono,
  });

  @override
  Widget build(BuildContext context) {
    // Estilo base: respeta el tema global pero permite sobrescribir el color de fondo
    final ButtonStyle estiloBase = ElevatedButton.styleFrom(
      backgroundColor: color,
    );

    // Si se recibe un ícono, usar la variante ElevatedButton.icon
    if (icono != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        style: estiloBase,
        icon: Icon(icono),
        label: Text(texto),
      );
    }

    // Sin ícono: botón estándar
    return ElevatedButton(
      onPressed: onPressed,
      style: estiloBase,
      child: Text(texto),
    );
  }
}

// ---------------------------------------------------------------------------
// AppMenuButton
// ---------------------------------------------------------------------------

/// Botón de menú para navegación principal (Dashboard).
/// Adaptado del diseño base, pero utilizando los estilos del CoreTheme.
class AppMenuButton extends StatelessWidget {
  /// Título que aparece en el botón.
  final String title;

  /// Ícono a la izquierda del título.
  final IconData icon;

  /// Acción al presionar el botón.
  final VoidCallback onTap;

  const AppMenuButton({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: theme.colorScheme.surface,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: accentColor.withValues(alpha: 0.5), width: 1.2),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: accentColor),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                height: 1.3,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right,
            size: 24,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
