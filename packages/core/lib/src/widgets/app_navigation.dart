import 'package:flutter/material.dart';

/// Metadatos inmutables que configuran una pestaña de carpeta (Folder Tab) en la barra de navegación.
class AppFolderTabItem {
  /// Identificador numérico secuencial de la pestaña.
  final int indice;

  /// Texto descriptivo de la solapa.
  final String titulo;

  /// Ícono representativo de la solapa.
  final IconData icono;

  /// Color cromático distintivo asignado a esta opción.
  final Color colorAcento;

  /// Acción a disparar al interactuar con la pestaña.
  final VoidCallback? onTap;

  const AppFolderTabItem({
    required this.indice,
    required this.titulo,
    required this.icono,
    required this.colorAcento,
    this.onTap,
  });
}

/// Widget individual tipo solapa de archivador físico (Folder Tab).
///
/// Características:
/// - Silueta asimétrica de archivador con esquinas redondeadas en el extremo derecho.
/// - Texto e ícono rotados 90° a la izquierda ([RotatedBox] con quarterTurns: 3) para lectura vertical.
/// - Anclaje a la base izquierda ([Alignment.bottomLeft]) para que todas las opciones compartan la misma línea base.
/// - Fondo opaco mediante [Color.alphaBlend] para evitar transparencias al sobreponerse con otras pestañas.
class AppFolderTab extends StatelessWidget {
  final int indice;
  final IconData icono;
  final String titulo;
  final Color colorAcento;
  final bool esActiva;
  final VoidCallback? onTap;
  final double ancho;
  final double alto;
  final double paddingInferior;
  final double paddingSuperior;
  final double paddingIzquierdo;
  final double separacionIconoTexto;

  const AppFolderTab({
    super.key,
    required this.indice,
    required this.icono,
    required this.titulo,
    required this.colorAcento,
    required this.esActiva,
    this.onTap,
    this.ancho = 44.0,
    this.alto = 168.0,
    this.paddingInferior = 28.0,
    this.paddingSuperior = 12.0,
    this.paddingIzquierdo = 4.0,
    this.separacionIconoTexto = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Fondo opaco para evitar transparencias al sobreponerse con solapas contiguas
    final Color colorFondo = esActiva
        ? Color.alphaBlend(
            colorAcento.withValues(alpha: 0.16),
            colorScheme.surface,
          )
        : colorScheme.surface;

    final Color colorIcono =
        esActiva ? colorAcento : colorScheme.onSurfaceVariant;

    final Color colorTexto =
        esActiva ? colorAcento : colorScheme.onSurfaceVariant;

    final Color colorBorde = esActiva
        ? colorAcento
        : colorScheme.outline.withValues(alpha: 0.28);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
          topLeft: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: ancho,
          height: alto,
          padding: EdgeInsets.only(
            top: paddingSuperior,
            bottom: paddingInferior,
            left: paddingIzquierdo,
            right: 2.0,
          ),
          decoration: BoxDecoration(
            color: colorFondo,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(
              color: colorBorde,
              width: esActiva ? 1.8 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: esActiva
                    ? colorAcento.withValues(alpha: 0.26)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: esActiva ? 8 : 4,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.only(left: paddingIzquierdo),
              child: RotatedBox(
                quarterTurns: 3,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Ícono con la misma rotación de 90° (ubicado en la base inferior)
                    Icon(
                      icono,
                      size: 20,
                      color: colorIcono,
                    ),
                    SizedBox(width: separacionIconoTexto),

                    // Texto en lectura natural de abajo hacia arriba protegido con Flexible
                    Flexible(
                      child: Text(
                        titulo,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorTexto,
                          fontWeight: esActiva ? FontWeight.bold : FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Contenedor apilado que gestiona una lista de [AppFolderTabItem] con sobreposición escalonada continua
/// y elevación dinámica en el eje Z para situar al frente la solapa activa.
class AppFolderTabBar extends StatelessWidget {
  final List<AppFolderTabItem> items;
  final int? indiceSeleccionado;
  final ValueChanged<int>? onTabSelected;
  final double anchoBarra;
  final double altoPestana;
  final double traslape;
  final double anchoPestana;

  const AppFolderTabBar({
    super.key,
    required this.items,
    this.indiceSeleccionado,
    this.onTabSelected,
    this.anchoBarra = 58.0,
    this.altoPestana = 168.0,
    this.traslape = 22.0,
    this.anchoPestana = 44.0,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final double pasoVertical = altoPestana - traslape;
    final double alturaTotal = altoPestana + (items.length - 1) * pasoVertical;

    // Para lograr el efecto de archivador donde la solapa activa resalta sobre las demás,
    // ordenamos el renderizado del Stack para que la seleccionada se dibuje de última (z-index superior).
    final List<AppFolderTabItem> listaOrdenada;
    if (indiceSeleccionado != null &&
        indiceSeleccionado! >= 0 &&
        indiceSeleccionado! < items.length) {
      final int activo = indiceSeleccionado!;
      listaOrdenada = [
        ...items.where((it) => it.indice != activo),
        items.firstWhere((it) => it.indice == activo),
      ];
    } else {
      listaOrdenada = items;
    }

    // Posición horizontal centrada fija dentro de la barra
    final double posicionHorizontalFija = (anchoBarra - anchoPestana) / 2;

    return SizedBox(
      height: alturaTotal,
      width: anchoBarra,
      child: Stack(
        clipBehavior: Clip.none,
        children: listaOrdenada.map((item) {
          final bool esActiva = item.indice == indiceSeleccionado;
          final double topOffset = item.indice * pasoVertical;

          return Positioned(
            key: ValueKey(item.indice),
            top: topOffset,
            left: posicionHorizontalFija,
            child: AppFolderTab(
              indice: item.indice,
              icono: item.icono,
              titulo: item.titulo,
              colorAcento: item.colorAcento,
              esActiva: esActiva,
              ancho: anchoPestana,
              alto: altoPestana,
              onTap: () {
                onTabSelected?.call(item.indice);
                item.onTap?.call();
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Esfera de perfil flotante diseñada para sobresalir horizontalmente a la derecha del menú lateral.
class AppFloatingProfileBadge extends StatelessWidget {
  /// Proveedor de imagen del avatar (AssetImage, NetworkImage, etc.).
  final ImageProvider? proveedorImagen;

  /// Acción a ejecutar al presionar la esfera de perfil.
  final VoidCallback? onTap;

  /// Radio del avatar circular.
  final double radio;

  /// Ancho del borde cromático perimetral.
  final double anchoBorde;

  /// Color perimetral del borde. Por defecto usa [ColorScheme.primary].
  final Color? colorBorde;

  const AppFloatingProfileBadge({
    super.key,
    this.proveedorImagen,
    this.onTap,
    this.radio = 25.0,
    this.anchoBorde = 3.0,
    this.colorBorde,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colorBordeFinal = colorBorde ?? colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: colorBordeFinal,
            width: anchoBorde,
          ),
          boxShadow: [
            BoxShadow(
              color: colorBordeFinal.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: radio,
          backgroundImage: proveedorImagen,
          backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
          child: proveedorImagen == null
              ? Icon(
                  Icons.person,
                  size: radio * 1.1,
                  color: colorBordeFinal,
                )
              : null,
        ),
      ),
    );
  }
}

/// Botón compacto de acción para la barra lateral (e.g. cierre de sesión, ajustes).
class AppSidebarIconButton extends StatelessWidget {
  /// Ícono a renderizar dentro del botón.
  final IconData icono;

  /// Acción ejecutada al presionar el botón.
  final VoidCallback? onTap;

  /// Mensaje explicativo mostrado al mantener presionado o pasar el cursor.
  final String? mensajeTooltip;

  /// Indica si la acción es destructiva o de riesgo (e.g. cerrar sesión).
  final bool esDestructivo;

  /// Dimensión cuadrada exterior del botón interactivo.
  final double tamanio;

  /// Dimensión del glifo del ícono.
  final double tamanioIcono;

  const AppSidebarIconButton({
    super.key,
    required this.icono,
    this.onTap,
    this.mensajeTooltip,
    this.esDestructivo = false,
    this.tamanio = 40.0,
    this.tamanioIcono = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color colorBase =
        esDestructivo ? colorScheme.error : colorScheme.onSurfaceVariant;

    final boton = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: tamanio,
        height: tamanio,
        decoration: BoxDecoration(
          color: colorBase.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icono,
          size: tamanioIcono,
          color: colorBase,
        ),
      ),
    );

    if (mensajeTooltip != null && mensajeTooltip!.isNotEmpty) {
      return Tooltip(
        message: mensajeTooltip!,
        child: boton,
      );
    }

    return boton;
  }
}

/// Barra lateral de navegación completa para aplicaciones con menú tipo archivador o solapas de carpeta.
///
/// Permite renderizar de forma modular:
/// - Un cuerpo lateral con ancho constante (e.g. 58 px).
/// - Un espacio superior para insignias flotantes ([insigniaFlotante]).
/// - Una sección intermedia scrollable para pestañas ([seccionPestanas]).
/// - Separadores configurables.
/// - Un pie de acciones inferiores ([pieAcciones]).
class AppSidebarNavigation extends StatelessWidget {
  /// Ancho base de la columna de la barra lateral.
  final double anchoBarra;

  /// Widget flotante posicionado en la cabecera (e.g. [AppFloatingProfileBadge]).
  final Widget? insigniaFlotante;

  /// Desplazamiento horizontal para la insignia flotante.
  final double posicionInsigniaIzquierda;

  /// Desplazamiento vertical para la insignia flotante.
  final double posicionInsigniaSuperior;

  /// Altura reservada en el flujo interno de la barra para no solapar la insignia.
  final double alturaCabeceraReservada;

  /// Sección central con las solapas o botones de navegación.
  final Widget? seccionPestanas;

  /// Pie inferior con botones de acción (e.g. cerrar sesión).
  final Widget? pieAcciones;

  const AppSidebarNavigation({
    super.key,
    this.anchoBarra = 58.0,
    this.insigniaFlotante,
    this.posicionInsigniaIzquierda = 8.0,
    this.posicionInsigniaSuperior = 14.0,
    this.alturaCabeceraReservada = 72.0,
    this.seccionPestanas,
    this.pieAcciones,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cuerpo principal de la barra lateral
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: anchoBarra,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Espacio reservado para la insignia flotante superior
                SizedBox(height: alturaCabeceraReservada),

                // Separador superior
                Divider(
                  height: 16,
                  indent: 8,
                  endIndent: 8,
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),

                // Sección scrollable de solapas de carpeta
                if (seccionPestanas != null)
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: seccionPestanas!,
                    ),
                  )
                else
                  const Spacer(),

                // Separador inferior
                Divider(
                  height: 16,
                  indent: 8,
                  endIndent: 8,
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),

                const SizedBox(height: 10),

                // Pie de barra lateral (e.g. botón de cerrar sesión)
                if (pieAcciones != null) pieAcciones!,
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),

        // Insignia o esfera flotante superior que sobresale hacia la derecha
        if (insigniaFlotante != null)
          Positioned(
            left: posicionInsigniaIzquierda,
            top: posicionInsigniaSuperior,
            child: insigniaFlotante!,
          ),
      ],
    );
  }
}
