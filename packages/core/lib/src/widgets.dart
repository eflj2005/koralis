import 'package:flutter/material.dart';
import 'theme.dart';
export 'widgets/app_messenger.dart';


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
// AppTextField
// ---------------------------------------------------------------------------

/// Widget reutilizable de campo de texto de la aplicación.
/// Encapsula un [TextField] con soporte para ícono, label, hint, validator
/// y modo contraseña (con toggle de visibilidad integrado).
///
/// Ejemplo de uso:
/// ```dart
/// AppTextField(
///   label: 'Correo electrónico',
///   hint: 'ejemplo@correo.com',
///   icono: Icons.email_outlined,
///   controller: _emailController,
/// )
///
/// AppTextField(
///   label: 'Contraseña',
///   icono: Icons.lock_outlined,
///   controller: _passwordController,
///   esOscuro: true,
/// )
/// ```
class AppTextField extends StatefulWidget {
  /// Texto flotante que describe el campo (label superior).
  final String? label;

  /// Texto de sugerencia que aparece cuando el campo está vacío.
  final String? hint;

  /// Función de validación. Retorna un mensaje de error o null si es válido.
  final String? Function(String?)? validator;

  /// Controlador externo del campo de texto.
  final TextEditingController? controller;

  /// Ícono que aparece al inicio (izquierda) del campo.
  final IconData? icono;

  /// Activa el modo contraseña: oculta el texto y muestra un toggle de visibilidad.
  final bool esOscuro;

  /// Tipo de teclado a mostrar (por defecto: texto).
  final TextInputType tipoTeclado;

  /// Relleno interno del campo. Si es null, usa un padding compacto por defecto.
  final EdgeInsetsGeometry? contentPadding;

  /// Control de mayúsculas automáticas del texto.
  final TextCapitalization textCapitalization;

  /// Color de fondo del campo de texto (por defecto blanco para asegurar contraste).
  final Color fillColor;

  /// Radio de curvatura para redondear ligeramente las esquinas del campo de texto (por defecto 12 px).
  final BorderRadius borderRadius;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.validator,
    this.controller,
    this.icono,
    this.esOscuro = false,
    this.tipoTeclado = TextInputType.text,
    this.contentPadding,
    this.textCapitalization = TextCapitalization.none,
    this.fillColor = Colors.white,
    this.borderRadius = const BorderRadius.all(Radius.circular(12.0)),
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  /// Estado interno: controla si el texto está oculto (solo aplica en modo esOscuro)
  late bool _textoOculto;

  @override
  void initState() {
    super.initState();
    // Inicialmente oculto si el campo es de tipo contraseña
    _textoOculto = widget.esOscuro;
  }

  /// Alterna la visibilidad del texto en campos de contraseña
  void _toggleVisibilidad() {
    setState(() {
      _textoOculto = !_textoOculto;
    });
  }

  @override
  Widget build(BuildContext context) {
    const List<String> fuentesRespaldo = [
      'Roboto',
      'Noto Sans',
      'Segoe UI',
      'Arial',
      'sans-serif',
    ];

    final theme = Theme.of(context);

    return TextFormField(
      controller: widget.controller,
      obscureText: _textoOculto,
      keyboardType: widget.tipoTeclado,
      textCapitalization: widget.textCapitalization,
      validator: widget.validator,
      style: TextStyle(
        color: theme.colorScheme.onSurface,
        fontFamilyFallback: fuentesRespaldo,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: widget.fillColor,
        contentPadding: widget.contentPadding ??
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        labelText: widget.label,
        labelStyle: const TextStyle(
          fontFamilyFallback: fuentesRespaldo,
        ),
        hintText: widget.hint,
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          fontFamilyFallback: fuentesRespaldo,
        ),
        border: OutlineInputBorder(
          borderRadius: widget.borderRadius,
        ),
        // Ícono prefijo compacto si fue proporcionado
        prefixIcon: widget.icono != null
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(widget.icono, size: 22),
              )
            : null,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 42,
          minHeight: 40,
        ),
        // Botón de toggle de visibilidad compacto solo en modo contraseña
        suffixIcon: widget.esOscuro
            ? IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                icon: Icon(
                  _textoOculto
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 22,
                ),
                onPressed: _toggleVisibilidad,
              )
            : null,
        suffixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// LoadingWidget
// ---------------------------------------------------------------------------

/// Widget de carga que muestra un overlay semitransparente con un
/// [CircularProgressIndicator] y la imagen del spinner configurada en el centro.
/// El color de fondo y la opacidad pueden configurarse globalmente en el tema
/// o pasarse como parámetros en el constructor.
///
/// Ejemplo de uso:
/// ```dart
/// if (_cargando) const LoadingWidget(),
/// ```
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
