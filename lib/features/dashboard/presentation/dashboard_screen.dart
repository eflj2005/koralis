import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:koralis_app/features/auth/domain/entities/user.dart';
import 'package:koralis_app/features/auth/presentation/widgets/forgot_password_form_sheet.dart';
// ignore: deprecated_member_use_from_same_package
import 'package:koralis_app/features/pets/domain/entities/pet.dart';
// ignore: deprecated_member_use_from_same_package
import 'package:koralis_app/features/pets/domain/usecases/get_pets_usecase.dart';
import 'package:koralis_app/features/pets/data/repositories/pet_repository_impl.dart';
import 'package:koralis_app/features/profile/domain/entities/profile.dart';
import 'package:koralis_app/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:koralis_app/features/profile/data/repositories/profile_repository_impl.dart';

/// Pantalla principal (Dashboard) de Koralis estructurada con barra lateral de menú,
/// esfera de acceso al perfil con menú emergente y columna de información en tarjetas.
class DashboardScreen extends StatefulWidget {
  final User user;

  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final GetProfileUseCase _getProfileUseCase;
  // ignore: deprecated_member_use_from_same_package
  late final GetPetsUseCase _getPetsUseCase;

  Future<Profile>? _profileFuture;
  // ignore: deprecated_member_use_from_same_package
  Future<List<Pet>>? _petsFuture;

  @override
  void initState() {
    super.initState();
    _getProfileUseCase = GetProfileUseCase(ProfileRepositoryImpl());
    // ignore: deprecated_member_use_from_same_package
    _getPetsUseCase = GetPetsUseCase(PetRepositoryImpl());

    // Iniciar carga del perfil usando el id del usuario autenticado
    _profileFuture = _getProfileUseCase.execute(widget.user.id);
    _petsFuture = _getPetsUseCase.execute();
  }

  /// Muestra el menú contextual de perfil con opciones para ir al perfil,
  /// cambiar clave o cerrar sesión.
  void _mostrarMenuPerfil(BuildContext context, Profile? profile) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showAppModalBottomSheet(
      context,
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
              final perfilNavegar = profile ??
                  Profile(
                    id: widget.user.id,
                    userId: widget.user.id,
                    nombre: widget.user.nombre,
                    correo: widget.user.correo,
                    avatarPath: 'images/avatar.png',
                  );
              Navigator.pushNamed(context, '/profile', arguments: perfilNavegar);
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
              const Text('Cerrar sesión'),
            ],
          ),
          content: const Text('¿Estás seguro de que deseas salir de tu cuenta?'),
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
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
              child: const Text('Salir'),
            ),
          ],
        );
      },
    );
  }

  /// Botón individual para el menú de navegación de la barra lateral
  Widget _buildBotonBarraLateral({
    required BuildContext context,
    required IconData icono,
    required String tooltip,
    required VoidCallback onTap,
    bool activo = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: activo
                ? colorScheme.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: activo
                ? Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.4),
                    width: 1.5,
                  )
                : null,
          ),
          child: Icon(
            icono,
            size: 26,
            color: activo ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===============================================================
            // 1. BARRA LATERAL IZQUIERDA (Menú + Esfera de Perfil)
            // ===============================================================
            Container(
              width: 86,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(3, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // --- Esfera interactiva de perfil (Acceso al menú de perfil) ---
                  FutureBuilder<Profile>(
                    future: _profileFuture,
                    builder: (context, snapshot) {
                      final profile = snapshot.data;
                      final imageProvider = profile?.avatarPath != null
                          ? AssetImage(profile!.avatarPath) as ImageProvider
                          : const AssetImage('images/avatar.png');

                      return GestureDetector(
                        onTap: () => _mostrarMenuPerfil(context, profile),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.primary,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundImage: imageProvider,
                            backgroundColor:
                                colorScheme.primary.withValues(alpha: 0.1),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                  Divider(
                    indent: 14,
                    endIndent: 14,
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),

                  // --- Ítems de navegación vertical ---
                  _buildBotonBarraLateral(
                    context: context,
                    icono: Icons.dashboard_rounded,
                    tooltip: 'Dashboard',
                    activo: true,
                    onTap: () {},
                  ),
                  const SizedBox(height: 14),

                  _buildBotonBarraLateral(
                    context: context,
                    icono: Icons.pets_rounded,
                    tooltip: 'Mascotas',
                    activo: false,
                    onTap: () {
                      Navigator.pushNamed(context, '/pets');
                    },
                  ),
                  const SizedBox(height: 14),

                  _buildBotonBarraLateral(
                    context: context,
                    icono: Icons.analytics_outlined,
                    tooltip: 'Actividad',
                    activo: false,
                    onTap: () {
                      showUnderConstructionDialog(
                        context,
                        accion: 'Analítica y Movimientos',
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  _buildBotonBarraLateral(
                    context: context,
                    icono: Icons.notifications_outlined,
                    tooltip: 'Notificaciones',
                    activo: false,
                    onTap: () {
                      showUnderConstructionDialog(
                        context,
                        accion: 'Bandeja de Notificaciones',
                      );
                    },
                  ),

                  const Spacer(),

                  // --- Botón inferior para cerrar sesión ---
                  _buildBotonBarraLateral(
                    context: context,
                    icono: Icons.logout_rounded,
                    tooltip: 'Cerrar sesión',
                    activo: false,
                    onTap: () => _confirmarCerrarSesion(context),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // ===============================================================
            // 2. COLUMNA DERECHA (Información del Dashboard en Tarjetas)
            // ===============================================================
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
                              color: colorScheme.primary.withValues(alpha: 0.12),
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
                                  '¡Hola de nuevo!',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  widget.user.nombre,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- Tarjeta 2: Métrica Principal (Cantidad de Mascotas) ---
                    _buildTarjetaDashboard(
                      context: context,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.secondary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.pets_rounded,
                              color: colorScheme.secondary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mascotas registradas',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Activas en tu cuenta',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Contador reactivo
                          // ignore: deprecated_member_use_from_same_package
                          FutureBuilder<List<Pet>>(
                            future: _petsFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                );
                              }
                              final count =
                                  snapshot.hasData ? snapshot.data!.length : 0;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // --- Tarjeta 3: Acceso Directo a Mascotas ---
                    _buildTarjetaDashboard(
                      context: context,
                      onTap: () {
                        Navigator.pushNamed(context, '/pets');
                      },
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.tertiary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.list_alt_rounded,
                              color: colorScheme.tertiary,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gestionar Mascotas',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Ver listado y detalles completos',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
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

                    // --- Tarjeta 4: Estado de la Cuenta ---
                    _buildTarjetaDashboard(
                      context: context,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.verified_user_rounded,
                              color: Colors.green,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Cuenta Verificada',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.user.correo,
                                  style: theme.textTheme.bodySmall?.copyWith(
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

                    // --- Tarjeta 5: Resumen de Cartera / Instrumentos ---
                    _buildTarjetaDashboard(
                      context: context,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet_outlined,
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
                                  'Portafolio Koralis',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Servicios y datos sincronizados',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- Tarjeta 6: Soporte y Asistencia ---
                    _buildTarjetaDashboard(
                      context: context,
                      onTap: () {
                        showUnderConstructionDialog(
                          context,
                          accion: 'Mesa de Ayuda y Soporte',
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.secondary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.help_outline_rounded,
                              color: colorScheme.secondary,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Centro de Ayuda',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '¿Dudas o requerimientos? Contáctanos',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
