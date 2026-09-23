import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:koralis_app/features/auth/domain/entities/user.dart';
import 'package:koralis_app/features/auth/presentation/widgets/forgot_password_form_sheet.dart';
import 'package:koralis_app/features/profile/domain/entities/profile.dart';
import 'package:koralis_app/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:koralis_app/features/profile/data/repositories/profile_repository_impl.dart';

/// Pantalla principal (Dashboard) de Koralis estructurada con:
/// - Barra lateral base compacta (86 px) con la esfera de perfil superior y el cierre de sesión inferior siempre fijos.
/// - Separador superior (bajo la esfera de perfil) y separador inferior (sobre el botón de salida).
/// - Menú con pestañas verticales estilo carpetas físicas (Folder Tabs) de separador a separador,
///   con textos girados 90° a la izquierda (lectura vertical de abajo hacia arriba) e iconos temáticos.
/// - Contenido de la derecha (tarjetas) con tamaño y posición estables e invariables.
/// - Sin barra superior de título (inmersivo a pantalla completa).
class DashboardScreen extends StatefulWidget {
  final User user;
  final GetProfileUseCase? getProfileUseCase;

  const DashboardScreen({
    super.key,
    required this.user,
    this.getProfileUseCase,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  /// Ancho estándar de la barra lateral base compacta
  static const double _anchoBarraBase = 58.0;

  /// Índice de la pestaña de carpeta actualmente seleccionada/activa (opcional)
  int? _pestanaSeleccionada;

  late final GetProfileUseCase _getProfileUseCase;
  Future<Profile>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _getProfileUseCase =
        widget.getProfileUseCase ?? GetProfileUseCase(ProfileRepositoryImpl());

    // Iniciar carga del perfil usando el id del usuario autenticado
    _profileFuture = _getProfileUseCase.execute(widget.user.id);
  }

  /// Muestra el menú contextual de perfil con opciones para ir al perfil,
  /// cambiar clave o cerrar sesión.
  void _mostrarMenuPerfil(BuildContext context, Profile? profile) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showAppModalBottomSheet(
      context,
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado del modal con avatar y datos básicos
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: profile?.avatarPath != null
                      ? AssetImage(profile!.avatarPath)
                      : const AssetImage('images/avatar.png'),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.nombre,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.user.correo,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Opción 1: Ir al Perfil
            ListTile(
              leading: Icon(
                Icons.person_outline_rounded,
                color: colorScheme.primary,
                size: 26,
              ),
              title: const Text(
                'Mi Perfil',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Ver y editar información personal'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () {
                Navigator.pop(context);
                final perfilNavegar =
                    profile ??
                    Profile(
                      id: widget.user.id,
                      userId: widget.user.id,
                      nombre: widget.user.nombre,
                      correo: widget.user.correo,
                      avatarPath: 'images/avatar.png',
                    );
                Navigator.pushNamed(
                  context,
                  '/profile',
                  arguments: perfilNavegar,
                );
              },
            ),

            // Opción 2: Cambiar Clave
            ListTile(
              leading: Icon(
                Icons.lock_reset_rounded,
                color: colorScheme.secondary,
                size: 26,
              ),
              title: const Text(
                'Cambiar clave',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Restablecer contraseña de acceso'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () {
                Navigator.pop(context);
                _mostrarModalCambioClave(context);
              },
            ),

            // Opción 3: Cerrar Sesión
            ListTile(
              leading: Icon(
                Icons.logout_rounded,
                color: colorScheme.error,
                size: 26,
              ),
              title: Text(
                'Cerrar sesión',
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text('Finalizar la sesión en este dispositivo'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmarCerrarSesion(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Despliega el modal para solicitar cambio de contraseña
  void _mostrarModalCambioClave(BuildContext context) {
    showAppModalBottomSheet(
      context,
      child: ForgotPasswordFormSheet(initialEmail: widget.user.correo),
    );
  }

  /// Diálogo de confirmación para cerrar sesión
  void _confirmarCerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.logout_rounded, color: theme.colorScheme.error),
              const SizedBox(width: 10),
              const Expanded(child: Text('Cerrar sesión')),
            ],
          ),
          content: const Text(
            '¿Estás seguro de que deseas salir de tu cuenta?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              },
              child: const Text('Salir'),
            ),
          ],
        );
      },
    );
  }

  /// Genera la colección de elementos para las pestañas de carpetas usando el modelo [AppFolderTabItem] del core
  List<AppFolderTabItem> _obtenerItemsPestanas(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return [
      AppFolderTabItem(
        indice: 0,
        titulo: 'Clientes',
        icono: Icons.people_alt_outlined,
        colorAcento: colorScheme.secondary,
        onTap: () async {
          setState(() => _pestanaSeleccionada = 0);
          await Navigator.pushNamed(context, '/clients', arguments: widget.user);
          // Al retornar del módulo de clientes, desactivar la pestaña activa
          if (mounted) {
            setState(() => _pestanaSeleccionada = null);
          }
        },
      ),
      AppFolderTabItem(
        indice: 1,
        titulo: 'Instrumentos',
        icono: Icons.paid_outlined,
        colorAcento: colorScheme.primary,
        onTap: () {
          setState(() => _pestanaSeleccionada = 1);
          showUnderConstructionDialog(
            context,
            accion: 'Módulo de Instrumentos',
          );
        },
      ),
      AppFolderTabItem(
        indice: 2,
        titulo: 'Transacciones',
        icono: Icons.receipt_long_outlined,
        colorAcento: colorScheme.tertiary,
        onTap: () {
          setState(() => _pestanaSeleccionada = 2);
          showUnderConstructionDialog(
            context,
            accion: 'Módulo de Transacciones',
          );
        },
      ),
      AppFolderTabItem(
        indice: 3,
        titulo: 'Seguimiento',
        icono: Icons.insights_rounded,
        colorAcento: Colors.indigo,
        onTap: () {
          setState(() => _pestanaSeleccionada = 3);
          showUnderConstructionDialog(context, accion: 'Módulo de Seguimiento');
        },
      ),
    ];
  }

  /// Contenedor base reutilizable para cada tarjeta de información del dashboard
  Widget _buildTarjetaDashboard({
    required BuildContext context,
    required Widget child,
    VoidCallback? onTap,
  }) {
    final tarjeta = Container(
      margin: const EdgeInsets.only(bottom: 14.0),
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: tarjeta,
      );
    }

    return tarjeta;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ===============================================================
            // 1. CAPA BASE: Contenido derecho (Tarjetas estables e invariables)
            // Separadas por un SizedBox fijo de 86 px que nunca cambia de tamaño
            // ===============================================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(width: _anchoBarraBase),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- Tarjeta 1: Saludo y Bienvenida ---
                        _buildTarjetaDashboard(
                          context: context,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.waving_hand_rounded,
                                  color: colorScheme.primary,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '¡Bienvenido!',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                    Text(
                                      widget.user.nombre,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.primary,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // --- Tarjeta 2: Resumen de Clientes ---
                        _buildTarjetaDashboard(
                          context: context,
                          onTap: () async {
                            await Navigator.pushNamed(context, '/clients', arguments: widget.user);
                            if (mounted) {
                              setState(() => _pestanaSeleccionada = null);
                            }
                          },
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondary.withValues(
                                    alpha: 0.14,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.people_alt_outlined,
                                  color: colorScheme.secondary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Gestión de Clientes',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Cartera y perfiles activos',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),

                        // --- Tarjeta 3: Instrumentos Financieros ---
                        _buildTarjetaDashboard(
                          context: context,
                          onTap: () {
                            showUnderConstructionDialog(
                              context,
                              accion: 'Módulo de Instrumentos',
                            );
                          },
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.14,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: colorScheme.primary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Instrumentos Financieros',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Catálogo y parametrización',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),

                        // --- Tarjeta 4: Transacciones ---
                        _buildTarjetaDashboard(
                          context: context,
                          onTap: () {
                            showUnderConstructionDialog(
                              context,
                              accion: 'Módulo de Transacciones',
                            );
                          },
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.tertiary.withValues(
                                    alpha: 0.14,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.receipt_long_outlined,
                                  color: colorScheme.tertiary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Transacciones y Operaciones',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Historial de movimientos y registros',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),

                        // --- Tarjeta 5: Seguimiento y Métricas ---
                        _buildTarjetaDashboard(
                          context: context,
                          onTap: () {
                            showUnderConstructionDialog(
                              context,
                              accion: 'Módulo de Seguimiento',
                            );
                          },
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.insights_rounded,
                                  color: Colors.indigo,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Seguimiento y Analítica',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Indicadores de rendimiento en tiempo real',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),

                        // --- Tarjeta 6: Estado de Cuenta y Seguridad ---
                        _buildTarjetaDashboard(
                          context: context,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.verified_user_rounded,
                                  color: Colors.green,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Cuenta Activa y Verificada',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.user.correo,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ===============================================================
            // 2. NAVEGACIÓN LATERAL MODULAR DEL CORE (AppSidebarNavigation)
            // Integra la esfera flotante de perfil, el sistema de pestañas de carpetas
            // y las acciones inferiores reutilizando exclusivamente componentes del core.
            // ===============================================================
            AppSidebarNavigation(
              anchoBarra: _anchoBarraBase,
              insigniaFlotante: FutureBuilder<Profile>(
                future: _profileFuture,
                builder: (context, snapshot) {
                  final profile = snapshot.data;
                  final imageProvider = profile?.avatarPath != null
                      ? AssetImage(profile!.avatarPath) as ImageProvider
                      : const AssetImage('images/avatar.png');

                  return AppFloatingProfileBadge(
                    proveedorImagen: imageProvider,
                    onTap: () => _mostrarMenuPerfil(context, profile),
                  );
                },
              ),
              seccionPestanas: AppFolderTabBar(
                items: _obtenerItemsPestanas(context),
                indiceSeleccionado: _pestanaSeleccionada,
                anchoBarra: _anchoBarraBase,
              ),
              pieAcciones: AppSidebarIconButton(
                icono: Icons.logout_rounded,
                esDestructivo: true,
                mensajeTooltip: 'Cerrar sesión',
                onTap: () => _confirmarCerrarSesion(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
