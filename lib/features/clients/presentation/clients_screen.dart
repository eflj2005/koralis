import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:provider/provider.dart';
import 'package:koralis_app/features/auth/domain/entities/user.dart';
import 'package:koralis_app/features/auth/presentation/widgets/forgot_password_form_sheet.dart';
import 'package:koralis_app/features/profile/domain/entities/profile.dart';
import 'package:koralis_app/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:koralis_app/features/profile/presentation/viewmodels/profile_view_model.dart';
import 'client_form_screen.dart';
import '../domain/entities/client.dart';
import '../domain/usecases/get_clients_usecase.dart';
import '../domain/usecases/add_client_usecase.dart';
import '../domain/usecases/delete_client_usecase.dart';
import 'viewmodels/clients_view_model.dart';

/// Pantalla principal del Módulo de Clientes (arquitectura MVVM con `provider`).
///
/// Integra:
/// - Barra lateral continua compacta de 58 px con esfera de perfil superior.
/// - Pestaña "Clientes" seleccionada como activa en el menú de carpetas.
/// - Encabezado tipográfico ("Clientes").
/// - Listado de tarjetas [AppListCard] ordenadas alfabéticamente de la A a la Z con swipe.
/// - Botón flotante inferior (+) para crear y registrar nuevos clientes.
class ClientsScreen extends StatelessWidget {
  final User user;
  final GetClientsUseCase? getClientsUseCase;
  final AddClientUseCase? addClientUseCase;
  final DeleteClientUseCase? deleteClientUseCase;
  final GetProfileUseCase? getProfileUseCase;

  const ClientsScreen({
    super.key,
    required this.user,
    this.getClientsUseCase,
    this.addClientUseCase,
    this.deleteClientUseCase,
    this.getProfileUseCase,
  });

  bool _tieneProvider<T>(BuildContext context) {
    try {
      Provider.of<T>(context, listen: false);
      return true;
    } on ProviderNotFoundException {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tieneClientsVm = _tieneProvider<ClientsViewModel>(context);
    final tieneProfileVm = _tieneProvider<ProfileViewModel>(context);

    if (tieneClientsVm && tieneProfileVm) {
      return _ClientsView(user: user);
    }

    return MultiProvider(
      providers: [
        if (!tieneClientsVm)
          ChangeNotifierProvider<ClientsViewModel>(
            create: (_) => ClientsViewModel(
              userId: user.id,
              getClientsUseCase: getClientsUseCase,
              deleteClientUseCase: deleteClientUseCase,
            ),
          ),
        if (!tieneProfileVm)
          ChangeNotifierProvider<ProfileViewModel>(
            create: (_) => ProfileViewModel(
              getProfileUseCase: getProfileUseCase,
            ),
          ),
      ],
      child: _ClientsView(user: user),
    );
  }
}

class _ClientsView extends StatefulWidget {
  final User user;

  const _ClientsView({required this.user});

  @override
  State<_ClientsView> createState() => _ClientsViewState();
}

class _ClientsViewState extends State<_ClientsView> {
  static const double _anchoBarraBase = 58.0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ClientsViewModel>().cargarClientes();
      context.read<ProfileViewModel>().cargarPerfil(widget.user.id);
    });
  }

  /// Despliega el menú contextual de perfil
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
                showAppModalBottomSheet(
                  context,
                  child: ForgotPasswordFormSheet(initialEmail: widget.user.correo),
                );
              },
            ),
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
                context.read<ProfileViewModel>().limpiar();
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
              child: const Text('Salir'),
            ),
          ],
        );
      },
    );
  }

  /// Navega a la pantalla independiente para registrar un nuevo cliente
  Future<void> _navegarCrearCliente(BuildContext context) async {
    final recargar = await Navigator.pushNamed(
      context,
      '/client_form',
      arguments: ClientFormArgs(user: widget.user),
    );
    if (recargar == true && context.mounted) {
      context.read<ClientsViewModel>().cargarClientes();
    }
  }

  /// Navega a la pantalla independiente para editar un cliente existente
  Future<void> _navegarEditarCliente(BuildContext context, Client cliente) async {
    final recargar = await Navigator.pushNamed(
      context,
      '/client_form',
      arguments: ClientFormArgs(
        user: widget.user,
        client: cliente,
      ),
    );
    if (recargar == true && context.mounted) {
      context.read<ClientsViewModel>().cargarClientes();
    }
  }

  /// Solicita confirmación y elimina el cliente validando que no tenga registros asociados.
  Future<void> _confirmarEliminarCliente(
    BuildContext context,
    Client cliente,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Eliminar Cliente', overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de eliminar a "${cliente.nombre}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      await this.context.read<ClientsViewModel>().eliminarCliente(cliente);
      if (!mounted) return;
      AppMessenger.showSuccessSnackBar(
        this.context,
        'Cliente "${cliente.nombre}" eliminado correctamente',
      );
    } on ClientDeletionBlockedException catch (e) {
      if (!mounted) return;
      AppMessenger.showInfoSnackBar(this.context, e.message);
    } catch (e) {
      if (!mounted) return;
      AppMessenger.showErrorSnackBar(
        this.context,
        'No fue posible eliminar el cliente: $e',
      );
    }
  }

  /// Construye los ítems de navegación lateral con "Clientes" activa
  List<AppFolderTabItem> _obtenerItemsPestanas(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return [
      AppFolderTabItem(
        indice: 0,
        titulo: 'Clientes',
        icono: Icons.people_alt_outlined,
        colorAcento: colorScheme.secondary,
        onTap: () {},
      ),
      AppFolderTabItem(
        indice: 1,
        titulo: 'Instrumentos',
        icono: Icons.paid_outlined,
        colorAcento: colorScheme.primary,
        onTap: () {
          Navigator.pushReplacementNamed(
            context,
            '/instruments',
            arguments: widget.user,
          );
        },
      ),
      AppFolderTabItem(
        indice: 2,
        titulo: 'Transacciones',
        icono: Icons.receipt_long_outlined,
        colorAcento: colorScheme.tertiary,
        onTap: () {
          Navigator.pushReplacementNamed(
            context,
            '/transactions',
            arguments: widget.user,
          );
        },
      ),
      AppFolderTabItem(
        indice: 3,
        titulo: 'Seguimiento',
        icono: Icons.insights_rounded,
        colorAcento: Colors.indigo,
        onTap: () {
          showUnderConstructionDialog(context, accion: 'Módulo de Seguimiento');
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final vm = context.watch<ClientsViewModel>();
    final profileVm = context.watch<ProfileViewModel>();
    final profile = profileVm.profile;
    final imageProvider = profile?.avatarPath != null
        ? AssetImage(profile!.avatarPath) as ImageProvider
        : const AssetImage('images/avatar.png');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(width: _anchoBarraBase),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppHeaderTitle(
                          titulo: 'Clientes',
                          onBack: () => Navigator.pop(context),
                          accion: IconButton(
                            icon: const Icon(Icons.refresh_rounded),
                            tooltip: 'Actualizar lista',
                            onPressed: () =>
                                context.read<ClientsViewModel>().cargarClientes(),
                          ),
                        ),
                        Expanded(
                          child: _buildContenidoLista(
                            context,
                            vm: vm,
                            theme: theme,
                            colorScheme: colorScheme,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            AppSidebarNavigation(
              anchoBarra: _anchoBarraBase,
              insigniaFlotante: AppFloatingProfileBadge(
                proveedorImagen: imageProvider,
                onTap: () => _mostrarMenuPerfil(context, profile),
              ),
              seccionPestanas: AppFolderTabBar(
                items: _obtenerItemsPestanas(context),
                indiceSeleccionado: 0,
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
      floatingActionButton: AppFloatingActionButton(
        icono: Icons.add_rounded,
        mensajeTooltip: 'Crear nuevo cliente',
        onPressed: () => _navegarCrearCliente(context),
      ),
    );
  }

  Widget _buildContenidoLista(
    BuildContext context, {
    required ClientsViewModel vm,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    if (vm.isLoading && vm.clientes.isEmpty) {
      return const Center(child: LoadingWidget());
    }

    if (vm.errorMessage != null && vm.clientes.isEmpty) {
      return Center(
        child: EmptyWidget(
          icono: Icons.error_outline_rounded,
          titulo: 'Error al consultar clientes',
          descripcion: vm.errorMessage!,
        ),
      );
    }

    final clientes = vm.clientes;
    if (clientes.isEmpty) {
      return const Center(
        child: EmptyWidget(
          icono: Icons.people_outline_rounded,
          titulo: 'Aún no tienes clientes registrados',
          descripcion:
              'Presiona el botón (+) en la esquina inferior para registrar tu primer cliente.',
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80.0),
      itemCount: clientes.length,
      itemBuilder: (context, index) {
        final cliente = clientes[index];
        final bool esActivo = cliente.estado.toLowerCase() == 'activo';

        return AppListCard(
          titulo: cliente.nombre,
          subtitulo: cliente.documento,
          detalle: cliente.correo.isNotEmpty
              ? '${cliente.correo} • ${cliente.telefono}'
              : cliente.telefono,
          colorAcento: colorScheme.secondary,
          fusionarSubtituloSiMultilinea: true,
          pie: Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Disponible: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '\$0',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          badge: AppBadge(
            texto: cliente.estado,
            color: esActivo ? Colors.green : colorScheme.outline,
          ),
          accionesSwipe: [
            AppSwipeAction(
              etiqueta: 'Editar',
              icono: Icons.edit_outlined,
              colorFondo: colorScheme.primary,
              onTap: () => _navegarEditarCliente(context, cliente),
            ),
            AppSwipeAction(
              etiqueta: 'Eliminar',
              icono: Icons.delete_outline_rounded,
              colorFondo: colorScheme.error,
              onTap: () => _confirmarEliminarCliente(context, cliente),
            ),
          ],
          onTap: () {
            showAppModalBottomSheet(
              context,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cliente.nombre,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                cliente.documento,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppBadge(
                          texto: cliente.estado,
                          color: esActivo ? Colors.green : Colors.grey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.badge_outlined),
                      title: const Text('Identificación'),
                      subtitle: Text(cliente.documento),
                    ),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('Correo Electrónico'),
                      subtitle: Text(
                        cliente.correo.isNotEmpty
                            ? cliente.correo
                            : 'No registrado',
                      ),
                    ),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.phone_outlined),
                      title: const Text('Teléfono'),
                      subtitle: Text(
                        cliente.telefono.isNotEmpty
                            ? cliente.telefono
                            : 'No registrado',
                      ),
                    ),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.account_balance_wallet_outlined),
                      title: const Text('Disponible'),
                      subtitle: Text(
                        '\$0',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (cliente.observacion.isNotEmpty)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.notes_rounded),
                        title: const Text('Observación'),
                        subtitle: Text(cliente.observacion),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
