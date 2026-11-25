import 'package:flutter/material.dart';

// =============================================================================
// Widgets de Tarjetas, Bloques de Lista y Banners Estructurados del Core
// =============================================================================

/// Indicador de estado compacto tipo píldora (Badge) para resaltar estados como "Activo", "Pendiente", etc.
class AppBadge extends StatelessWidget {
  /// Texto que describe el estado.
  final String texto;

  /// Color cromático principal de la insignia (usado para texto y borde o fondo).
  final Color color;

  /// Indica si la insignia debe tener fondo suave con texto de color pleno (por defecto true).
  final bool fondoSuave;

  const AppBadge({
    super.key,
    required this.texto,
    required this.color,
    this.fondoSuave = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fondoSuave ? color.withValues(alpha: 0.12) : color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: fondoSuave ? 0.35 : 1.0),
          width: 1.0,
        ),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: fondoSuave ? color : Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Encabezado tipográfico elegante y profesional para pantallas y módulos.
///
/// A diferencia de [AppHeaderBanner], este widget no utiliza tarjetas ni sombras,
/// proporcionando una jerarquía visual limpia que se integra orgánicamente sobre el fondo.
class AppHeaderTitle extends StatelessWidget {
  /// Título principal de la sección (ej. "Clientes").
  final String titulo;

  /// Subtítulo descriptivo o conteo informativo opcional (ej. "Cartera y perfiles registrados").
  final String? subtitulo;

  /// Callback ejecutado al presionar el botón de regreso. Si es nulo, no se muestra el botón.
  final VoidCallback? onBack;

  /// Widget de acción auxiliar a la derecha (ej. botón de recarga o filtro).
  final Widget? accion;

  /// Espaciado interno inferior para separar naturalmente del contenido (por defecto 16 px).
  final double espaciadoInferior;

  const AppHeaderTitle({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.onBack,
    this.accion,
    this.espaciadoInferior = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: espaciadoInferior),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (onBack != null) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              iconSize: 20,
              tooltip: 'Regresar',
              color: colorScheme.onSurface,
              onPressed: onBack,
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                if (subtitulo != null && subtitulo!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitulo!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (accion != null) accion!,
        ],
      ),
    );
  }
}

/// Bloque rectangular superior de encabezado de sección que respeta el esquema de diseño superior.
/// Presenta el título de la pantalla, un subtítulo o conteo informativo y acciones auxiliares.
class AppHeaderBanner extends StatelessWidget {
  /// Título principal de la sección (ej. "Clientes").
  final String titulo;

  /// Subtítulo o conteo auxiliar descriptivo (ej. "12 clientes registrados").
  final String? subtitulo;

  /// Ícono temático decorativo opcional a la izquierda del título.
  final IconData? icono;

  /// Widget de acción auxiliar a la derecha (ej. botón de búsqueda o filtro).
  final Widget? accion;

  const AppHeaderBanner({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.icono,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (icono != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icono,
                color: colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (subtitulo != null && subtitulo!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitulo!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (accion != null) accion!,
        ],
      ),
    );
  }
}

/// Modelo de acción revelada al deslizar horizontalmente una tarjeta [AppListCard].
class AppSwipeAction {
  /// Texto corto mostrado debajo del ícono (ej. "Editar", "Eliminar").
  final String etiqueta;

  /// Ícono representativo de la acción.
  final IconData icono;

  /// Color de fondo del botón de acción.
  final Color colorFondo;

  /// Color del ícono y de la etiqueta (por defecto blanco).
  final Color colorContenido;

  /// Callback ejecutado al presionar la acción.
  final VoidCallback? onTap;

  const AppSwipeAction({
    required this.etiqueta,
    required this.icono,
    required this.colorFondo,
    this.colorContenido = Colors.white,
    this.onTap,
  });
}

/// Tarjeta de bloque rectangular apilable diseñada específicamente para listados densos o estructurados.
///
/// Conserva el diseño geométrico de bloques horizontales limpios con soporte para:
/// - Avatar o iniciales a la izquierda.
/// - Nombre principal y subtítulo descriptivo.
/// - Línea de contacto o detalle secundario.
/// - Insignia o badge de estado a la derecha.
/// - Indicador visual y evento `onTap`.
/// - Acciones opcionales reveladas mediante desplazamiento horizontal (`accionesSwipe`).
class AppListCard extends StatelessWidget {
  /// Título principal del elemento (ej. Nombre del cliente).
  final String titulo;

  /// Subtítulo o categoría (ej. "DNI: 12345678 • Persona Natural").
  final String? subtitulo;

  /// Información complementaria o contacto (ej. "carlos@ejemplo.com").
  final String? detalle;

  /// Letra o texto de iniciales para el avatar circular si no se provee icono.
  final String? textoAvatar;

  /// Ícono representativo opcional a mostrar en el avatar.
  final IconData? iconoAvatar;

  /// Color cromático distintivo asignado al avatar y acentos.
  final Color? colorAcento;

  /// Etiqueta o badge de estado a mostrar a la derecha.
  final Widget? badge;

  /// Acción a ejecutar al presionar la tarjeta.
  final VoidCallback? onTap;

  /// Margen exterior inferior entre bloques (por defecto 10 px).
  final double margenInferior;

  /// Indica si se debe mostrar el contenedor del avatar a la izquierda.
  /// Si es null, se determina automáticamente según la presencia de [iconoAvatar] o [textoAvatar].
  final bool? mostrarAvatar;

  /// Número máximo de líneas permitidas para el título.
  /// Si es null, el texto continuará en los renglones necesarios sin cortarse.
  final int? tituloMaxLines;

  /// Si es true, cuando el título excede una sola línea, el subtítulo se anexa al final
  /// del título en el segundo renglón en lugar de ocupar una línea separada.
  final bool fusionarSubtituloSiMultilinea;

  /// Widget complementario opcional que se muestra al pie de la columna textual (ej. Saldo Disponible).
  final Widget? pie;

  /// Acciones opcionales que se revelan al deslizar la tarjeta de derecha a izquierda.
  final List<AppSwipeAction>? accionesSwipe;

  const AppListCard({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.detalle,
    this.textoAvatar,
    this.iconoAvatar,
    this.colorAcento,
    this.badge,
    this.onTap,
    this.margenInferior = 10.0,
    this.mostrarAvatar,
    this.tituloMaxLines,
    this.fusionarSubtituloSiMultilinea = false,
    this.pie,
    this.accionesSwipe,
  });

  @override
  Widget build(BuildContext context) {
    final tieneSwipe = accionesSwipe != null && accionesSwipe!.isNotEmpty;
    if (!tieneSwipe) {
      return _buildTarjeta(
        context,
        margin: EdgeInsets.only(bottom: margenInferior),
        onTapEfectivo: onTap,
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: margenInferior),
      child: _SwipeableListCard(
        acciones: accionesSwipe!,
        onTapTarjeta: onTap,
        builder: (onTapInterno) => _buildTarjeta(
          context,
          margin: EdgeInsets.zero,
          onTapEfectivo: onTapInterno,
        ),
      ),
    );
  }

  Widget _buildTarjeta(
    BuildContext context, {
    required EdgeInsetsGeometry margin,
    required VoidCallback? onTapEfectivo,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colorBase = colorAcento ?? colorScheme.primary;
    final bool renderizarAvatar = mostrarAvatar ??
        (iconoAvatar != null || (textoAvatar != null && textoAvatar!.isNotEmpty));

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.16),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTapEfectivo,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: [
                // Avatar circular con iniciales o ícono (opcional)
                if (renderizarAvatar) ...[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorBase.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorBase.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: iconoAvatar != null
                          ? Icon(
                              iconoAvatar,
                              color: colorBase,
                              size: 22,
                            )
                          : Text(
                              textoAvatar != null && textoAvatar!.isNotEmpty
                                  ? textoAvatar!.substring(0, 1).toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: colorBase,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],

                // Contenido textual central
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final titleStyle = theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      );

                      bool saltaLinea = false;
                      if (fusionarSubtituloSiMultilinea &&
                          subtitulo != null &&
                          subtitulo!.isNotEmpty &&
                          constraints.maxWidth.isFinite) {
                        double espacioBadge = 0.0;
                        if (badge != null) {
                          espacioBadge = 8.0;
                          if (badge is AppBadge) {
                            final badgePainter = TextPainter(
                              text: TextSpan(
                                text: (badge as AppBadge).texto,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
                              textScaler: MediaQuery.textScalerOf(context),
                              maxLines: 1,
                            )..layout();
                            espacioBadge += badgePainter.width + 22.0;
                          } else {
                            espacioBadge += 70.0;
                          }
                        }

                        final double anchoTituloDisponible =
                            (constraints.maxWidth - espacioBadge).clamp(0.0, double.infinity);

                        final textPainter = TextPainter(
                          text: TextSpan(text: titulo, style: titleStyle),
                          textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
                          textScaler: MediaQuery.textScalerOf(context),
                          maxLines: 1,
                        )..layout(maxWidth: anchoTituloDisponible);

                        saltaLinea = textPainter.didExceedMaxLines;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: saltaLinea
                                    ? Text.rich(
                                        TextSpan(
                                          text: titulo,
                                          style: titleStyle,
                                          children: [
                                            TextSpan(
                                              text: ' • ',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            TextSpan(
                                              text: subtitulo,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        maxLines: tituloMaxLines,
                                        overflow: tituloMaxLines != null
                                            ? TextOverflow.ellipsis
                                            : null,
                                      )
                                    : Text(
                                        titulo,
                                        style: titleStyle,
                                        maxLines: tituloMaxLines,
                                        overflow: tituloMaxLines != null
                                            ? TextOverflow.ellipsis
                                            : null,
                                      ),
                              ),
                              if (badge != null) ...[
                                const SizedBox(width: 8),
                                badge!,
                              ],
                            ],
                          ),
                          if (!saltaLinea && subtitulo != null && subtitulo!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitulo!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (detalle != null && detalle!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              detalle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (pie != null) ...[
                            const SizedBox(height: 5),
                            pie!,
                          ],
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // Indicador de navegación derecho
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Contenedor interno con gesto horizontal para revelar botones de acción detrás de [AppListCard].
class _SwipeableListCard extends StatefulWidget {
  final List<AppSwipeAction> acciones;
  final VoidCallback? onTapTarjeta;
  final Widget Function(VoidCallback? onTapInterno) builder;

  const _SwipeableListCard({
    required this.acciones,
    required this.onTapTarjeta,
    required this.builder,
  });

  @override
  State<_SwipeableListCard> createState() => _SwipeableListCardState();
}

class _SwipeableListCardState extends State<_SwipeableListCard>
    with SingleTickerProviderStateMixin {
  static const double _anchoAccion = 72.0;

  late final AnimationController _controller;
  Animation<double>? _animacion;
  double _offset = 0.0;

  double get _anchoTotal => widget.acciones.length * _anchoAccion;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        if (_animacion != null) {
          setState(() {
            _offset = _animacion!.value;
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animarHacia(double destino) {
    _animacion = Tween<double>(begin: _offset, end: destino).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller
      ..reset()
      ..forward();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_controller.isAnimating) {
      _controller.stop();
    }
    setState(() {
      _offset = (_offset + details.delta.dx).clamp(-_anchoTotal, 0.0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;
    if (velocity < -250 || _offset.abs() > _anchoTotal * 0.35) {
      _animarHacia(-_anchoTotal);
    } else {
      _animarHacia(0.0);
    }
  }

  void _manejarTapTarjeta() {
    if (_offset < -1.0) {
      _animarHacia(0.0);
      return;
    }
    widget.onTapTarjeta?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            if (_offset < 0)
              Positioned.fill(
                child: Container(
                  color: widget.acciones.last.colorFondo,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: widget.acciones.map((accion) {
                      return SizedBox(
                        width: _anchoAccion,
                        child: Material(
                          color: accion.colorFondo,
                          child: InkWell(
                            onTap: () {
                              _animarHacia(0.0);
                              accion.onTap?.call();
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  accion.icono,
                                  color: accion.colorContenido,
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  accion.etiqueta,
                                  style: TextStyle(
                                    color: accion.colorContenido,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            Transform.translate(
              offset: Offset(_offset, 0),
              child: widget.builder(
                widget.onTapTarjeta != null || _offset < -1.0
                    ? _manejarTapTarjeta
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
