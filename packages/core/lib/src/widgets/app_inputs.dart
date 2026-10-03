import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  /// Número máximo de líneas que puede ocupar el campo (por defecto 1).
  final int? maxLines;

  /// Número mínimo de líneas visibles que ocupa el campo.
  final int? minLines;

  /// Lista opcional de formateadores de entrada de texto (filtros numéricos, límite de caracteres, etc.).
  final List<TextInputFormatter>? inputFormatters;

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
    this.maxLines = 1,
    this.minLines,
    this.inputFormatters,
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
      inputFormatters: widget.inputFormatters,
      maxLines: widget.esOscuro ? 1 : widget.maxLines,
      minLines: widget.esOscuro ? 1 : widget.minLines,
      style: TextStyle(
        color: theme.colorScheme.onSurface,
        fontFamilyFallback: fuentesRespaldo,
      ),
      decoration: InputDecoration(
        alignLabelWithHint: (widget.maxLines != null && widget.maxLines! > 1) ||
            (widget.minLines != null && widget.minLines! > 1),
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
        // Ícono prefijo compacto con separación reducida hacia el texto
        prefixIcon: widget.icono != null
            ? Padding(
                padding: const EdgeInsets.only(left: 10, right: 4),
                child: Icon(widget.icono, size: 22),
              )
            : null,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 36,
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
// AppDropdownField
// ---------------------------------------------------------------------------

/// Widget reutilizable de lista desplegable de la aplicación.
/// Mantiene la misma línea gráfica, bordes, colores, padding e íconos que [AppTextField].
class AppDropdownField<T> extends StatelessWidget {
  /// Etiqueta superior flotante del campo.
  final String? label;

  /// Texto orientativo cuando no se ha seleccionado ninguna opción.
  final String? hint;

  /// Valor actualmente seleccionado en la lista desplegable.
  final T? value;

  /// Lista de opciones disponibles para selección.
  final List<DropdownMenuItem<T>> items;

  /// Callback invocado cuando el usuario selecciona una opción diferente.
  final ValueChanged<T?>? onChanged;

  /// Función validadora del formulario. Retorna un mensaje de error o null si es válido.
  final String? Function(T?)? validator;

  /// Ícono prefijo representativo al inicio del campo.
  final IconData? icono;

  /// Color de fondo del campo (blanco por defecto para contraste).
  final Color fillColor;

  /// Radio de curvatura de los bordes del campo (12 px por defecto).
  final BorderRadius borderRadius;

  /// Indica si los datos de la lista se encuentran en proceso de carga asíncrona.
  final bool isLoading;

  const AppDropdownField({
    super.key,
    this.label,
    this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.icono,
    this.fillColor = Colors.white,
    this.borderRadius = const BorderRadius.all(Radius.circular(12.0)),
    this.isLoading = false,
  });

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

    // Se omite 'key: ValueKey(value)' para preservar la identidad del widget y su FocusNode
    // durante el cierre de la ruta del menú desplegable, previniendo bloqueos (ANR) en Android.
    // En Flutter moderno, didUpdateWidget sincroniza 'initialValue' automáticamente sin destruir el estado.
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: isLoading ? null : onChanged,
      validator: validator,
      isExpanded: true,
      dropdownColor: Colors.white,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.arrow_drop_down_rounded, size: 24),
      style: TextStyle(
        color: theme.colorScheme.onSurface,
        fontFamilyFallback: fuentesRespaldo,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: fillColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        labelText: label,
        labelStyle: const TextStyle(
          fontFamilyFallback: fuentesRespaldo,
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          fontFamilyFallback: fuentesRespaldo,
        ),
        border: OutlineInputBorder(
          borderRadius: borderRadius,
        ),
        prefixIcon: icono != null
            ? Padding(
                padding: const EdgeInsets.only(left: 10, right: 4),
                child: Icon(icono, size: 22),
              )
            : null,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 40,
        ),
      ),
    );
  }
}

