import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:koralis_app/features/auth/domain/entities/user.dart';
import 'package:koralis_app/features/auth/presentation/widgets/forgot_password_form_sheet.dart';
import 'package:koralis_app/features/profile/domain/entities/profile.dart';
import 'package:koralis_app/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:koralis_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'client_form_screen.dart';
import '../domain/entities/client.dart';
import '../domain/usecases/get_clients_usecase.dart';
import '../domain/usecases/add_client_usecase.dart';
import '../domain/repositories/client_repository.dart';
import '../data/repositories/client_repository_impl.dart';

/// Pantalla principal del Módulo de Clientes.
///
/// Integra:
/// - Barra lateral continua compacta de 58 px con esfera de perfil superior.
/// - Pestaña "Clientes" seleccionada como activa en el menú de carpetas.
/// - Banner rectangular superior de encabezado ("Clientes").
/// - Listado de bloques rectangulares apilados ordenados alfabéticamente de la A a la Z.
/// - Botón flotante inferior (+) para crear y registrar nuevos clientes en Cloud Firestore.
class ClientsScreen extends StatefulWidget {
  final User user;
  final GetClientsUseCase? getClientsUseCase;
  final AddClientUseCase? addClientUseCase;
  final GetProfileUseCase? getProfileUseCase;

  const ClientsScreen({
    super.key,
    required this.user,
    this.getClientsUseCase,
    this.addClientUseCase,
    this.getProfileUseCase,
  });

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  static const double _anchoBarraBase = 58.0;

  late final GetClientsUseCase _getClientsUseCase;
  late final GetProfileUseCase _getProfileUseCase;

  Future<List<Client>>? _clientesFuture;
  Future<Profile>? _profileFuture;

  @override
  void initState() {
    super.initState();
    ClientRepository? repositorio;
    ClientRepository obtenerRepositorio() => repositorio ??= ClientRepositoryImpl();

    _getClientsUseCase =
        widget.getClientsUseCase ?? GetClientsUseCase(obtenerRepositorio());
    _getProfileUseCase =
        widget.getProfileUseCase ?? GetProfileUseCase(ProfileRepositoryImpl());

    _cargarClientes();
    _profileFuture = _getProfileUseCase.execute(widget.user.id);
  }

  /// Recarga la lista de clientes desde la fuente de datos
  void _cargarClientes() {
    setState(() {
      _clientesFuture = _getClientsUseCase.execute();
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
    if (recargar == true) {
      _cargarClientes();
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
    if (recargar == true) {
      _cargarClientes();
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
        onTap: () {
          // Ya nos encontramos en la pantalla de Clientes
        },
      ),
      AppFolderTabItem(
        indice: 1,
        titulo: 'Instrumentos',
        icono: Icons.paid_outlined,
        colorAcento: colorScheme.primary,
        onTap: () {
          showUnderConstructionDialog(context, accion: 'Módulo de Instrumentos');
        },
      ),
      AppFolderTabItem(
        indice: 2,
        titulo: 'Transacciones',
        icono: Icons.receipt_long_outlined,
        colorAcento: colorScheme.tertiary,
        onTap: () {
          showUnderConstructionDialog(context, accion: 'Módulo de Transacciones');
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // ===============================================================
            // 1. CAPA DE CONTENIDO: LISTA DE CLIENTES Y ENCABEZADO
            // Separado por 58 px de la izquierda para respetar la barra lateral
            // ===============================================================
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
                        // --- Encabezado Superior Tipográfico Limpio y Elegante ---
                        AppHeaderTitle(
                          titulo: 'Clientes',
                          onBack: () => Navigator.pop(context),
                          accion: IconButton(
                            icon: const Icon(Icons.refresh_rounded),
                            tooltip: 'Actualizar lista',
                            onPressed: _cargarClientes,
                          ),
                        ),

                        // --- Listado Asíncrono de Clientes ---
                        Expanded(
                          child: FutureBuilder<List<Client>>(
                            future: _clientesFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: LoadingWidget());
                              }

                              if (snapshot.hasError) {
                                return Center(
                                  child: EmptyWidget(
                                    icono: Icons.error_outline_rounded,
                                    titulo: 'Error al consultar clientes',
                                    descripcion: '${snapshot.error}',
                                  ),
                                );
                              }

                              final clientes = snapshot.data ?? [];

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
                                    onTap: () {
                                      // Al pulsar en un cliente, mostrar ficha rápida
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
                                                          style: theme.textTheme.titleMedium
                                                              ?.copyWith(
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
                                                subtitle: Text(cliente.correo.isNotEmpty
                                                    ? cliente.correo
                                                    : 'No registrado'),
                                              ),
                                              ListTile(
                                                dense: true,
                                                leading: const Icon(Icons.phone_outlined),
                                                title: const Text('Teléfono'),
                                                subtitle: Text(cliente.telefono.isNotEmpty
                                                    ? cliente.telefono
                                                    : 'No registrado'),
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
                                              const SizedBox(height: 14),
                                              AppButton(
                                                texto: 'Editar Cliente',
                                                icono: Icons.edit_outlined,
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _navegarEditarCliente(context, cliente);
                                                },
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
                            },
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
            // Barra continua con solapa activa en "Clientes" e insignia flotante
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
}
