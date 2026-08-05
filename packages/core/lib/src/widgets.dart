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

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.validator,
    this.controller,
    this.icono,
    this.esOscuro = false,
    this.tipoTeclado = TextInputType.text,
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
    return TextFormField(
      controller: widget.controller,
      obscureText: _textoOculto,
      keyboardType: widget.tipoTeclado,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        border: const OutlineInputBorder(),
        // Ícono prefijo si fue proporcionado
        prefixIcon: widget.icono != null ? Icon(widget.icono) : null,
        // Botón de toggle de visibilidad solo en modo contraseña
        suffixIcon: widget.esOscuro
            ? IconButton(
                icon: Icon(
                  _textoOculto
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: _toggleVisibilidad,
              )
            : null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// LoadingWidget
// ---------------------------------------------------------------------------

/// Widget de carga que muestra un overlay semitransparente con un
/// [CircularProgressIndicator] y el GIF del perrito corriendo en el centro.
/// Usa los colores secundarios del tema activo.
/// Flutter anima los GIFs de forma nativa con [Image.asset], por lo que
/// no se requieren controladores de animación adicionales.
///
/// Ejemplo de uso:
/// ```dart
/// if (_cargando) const LoadingWidget(),
/// ```
class AppSpinner extends StatelessWidget {
  final double size;

  const AppSpinner({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colorSecundario = colorScheme.secondary;
    final colorPrimario = colorScheme.primary;

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
                color: colorSecundario.withValues(alpha: 0.80),
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
          if (Theme.of(context).extension<CoreThemeExtension>()?.spinnerImagePath != null)
            Image.asset(
              Theme.of(context).extension<CoreThemeExtension>()!.spinnerImagePath!,
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
// showUnderConstructionDialog
// ---------------------------------------------------------------------------

/// Muestra un modal estilizado (bottom sheet) indicando que la función está en construcción.
void showUnderConstructionDialog(BuildContext context,
    {required String accion}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      final theme = Theme.of(context);
      return Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Entendido',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    },
  );
}
