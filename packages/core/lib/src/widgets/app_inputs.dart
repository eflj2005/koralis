import 'package:flutter/material.dart';

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
