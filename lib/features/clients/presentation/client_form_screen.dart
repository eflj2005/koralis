import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:provider/provider.dart';
import 'package:koralis_app/features/auth/domain/entities/user.dart';
import 'package:koralis_app/features/auth/presentation/widgets/forgot_password_form_sheet.dart';
import 'package:koralis_app/features/profile/domain/entities/profile.dart';
import 'package:koralis_app/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:koralis_app/features/profile/presentation/viewmodels/profile_view_model.dart';
import '../domain/entities/client.dart';
import '../domain/usecases/save_client_usecase.dart';
import 'viewmodels/client_form_view_model.dart';

/// Argumentos para la navegación hacia la pantalla de formulario de cliente.
class ClientFormArgs {
  final User user;
  final Client? client;

  const ClientFormArgs({
    required this.user,
    this.client,
  });
}

/// Pantalla independiente para la creación y edición de clientes (arquitectura MVVM con `provider`).
class ClientFormScreen extends StatelessWidget {
  final User user;
  final Client? client;
  final SaveClientUseCase? saveClientUseCase;
  final GetProfileUseCase? getProfileUseCase;

  const ClientFormScreen({
    super.key,
    required this.user,
    this.client,
    this.saveClientUseCase,
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
    final tieneFormVm = _tieneProvider<ClientFormViewModel>(context);
    final tieneProfileVm = _tieneProvider<ProfileViewModel>(context);

    if (tieneFormVm && tieneProfileVm) {
      return _ClientFormView(user: user, client: client);
    }

    return MultiProvider(
      providers: [
        if (!tieneFormVm)
          ChangeNotifierProvider<ClientFormViewModel>(
            create: (_) => ClientFormViewModel(
              userId: user.id,
              clientInicial: client,
              saveClientUseCase: saveClientUseCase,
            ),
          ),
        if (!tieneProfileVm)
          ChangeNotifierProvider<ProfileViewModel>(
            create: (_) => ProfileViewModel(
              getProfileUseCase: getProfileUseCase,
            ),
          ),
      ],
      child: _ClientFormView(user: user, client: client),
    );
  }
}

class _ClientFormView extends StatefulWidget {
  final User user;
  final Client? client;

  const _ClientFormView({
    required this.user,
    this.client,
  });

  @override
  State<_ClientFormView> createState() => _ClientFormViewState();
}

class _ClientFormViewState extends State<_ClientFormView> {
  static const double _anchoBarraBase = 58.0;

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _documentoCtrl;
  late final TextEditingController _correoCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _observacionCtrl;

  @override
  void initState() {
    super.initState();
    final clienteActual = widget.client;
    _nombreCtrl = TextEditingController(text: clienteActual?.nombre ?? '');
    _documentoCtrl = TextEditingController(text: clienteActual?.documento ?? '');
    _correoCtrl = TextEditingController(text: clienteActual?.correo ?? '');
    _telefonoCtrl = TextEditingController(text: clienteActual?.telefono ?? '');
    _observacionCtrl =
        TextEditingController(text: clienteActual?.observacion ?? '');

    Future.microtask(() {
      if (!mounted) return;
      context.read<ProfileViewModel>().cargarPerfil(widget.user.id);
    });
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _documentoCtrl.dispose();
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    _observacionCtrl.dispose();
    super.dispose();
  }

  /// Guarda o actualiza el cliente delegando la lógica al [ClientFormViewModel].
  Future<void> _guardarCliente() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<ClientFormViewModel>();
    try {
      final clienteGuardado = await vm.guardarCliente(
        nombre: _nombreCtrl.text,
        documento: _documentoCtrl.text,
        correo: _correoCtrl.text,
        telefono: _telefonoCtrl.text,
        observacion: _observacionCtrl.text,
      );
      if (mounted) {
        AppMessenger.showSuccessSnackBar(
          context,
          vm.esEdicion
              ? 'Cliente "${clienteGuardado.nombre}" actualizado correctamente'
              : 'Cliente "${clienteGuardado.nombre}" creado exitosamente',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AppMessenger.showErrorSnackBar(
          context,
          'No fue posible guardar el cliente: $e',
        );
      }
    }
  }

  /// Despliega el menú contextual de perfil
  void _mostrarMenuPerfil(BuildContext context, Profile? profile) {
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
                      : null,
                  child: profile?.avatarPath == null
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.nombre,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.user.correo,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                Icons.lock_reset_rounded,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: const Text('Cambiar clave'),
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
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Cerrar sesión',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmarCerrarSesion(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Confirmación para cerrar sesión
  void _confirmarCerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

  /// Genera los items de pestañas laterales
  List<AppFolderTabItem> _obtenerItemsPestanas(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return [
      AppFolderTabItem(
        indice: 0,
        titulo: 'Clientes',
        icono: Icons.people_alt_outlined,
        colorAcento: colorScheme.secondary,
        onTap: () => Navigator.pop(context),
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
    final vm = context.watch<ClientFormViewModel>();
    final profileVm = context.watch<ProfileViewModel>();
    final profile = profileVm.profile;
    final imageProvider = profile?.avatarPath != null
        ? AssetImage(profile!.avatarPath) as ImageProvider
        : null;

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
                          titulo: vm.esEdicion ? 'Editar Cliente' : 'Nuevo Cliente',
                          onBack: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 40.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  AppTextField(
                                    controller: _nombreCtrl,
                                    label: 'Nombre completo o Razón Social',
                                    hint: 'Ej. Ana María Martínez',
                                    icono: Icons.person_outline_rounded,
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Ingresa el nombre del cliente';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  AppTextField(
                                    controller: _documentoCtrl,
                                    label: 'Documento o Identificación',
                                    hint: 'Ej. CC 1020304050 o NIT',
                                    icono: Icons.badge_outlined,
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Ingresa la identificación';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  AppTextField(
                                    controller: _correoCtrl,
                                    label: 'Correo Electrónico',
                                    hint: 'cliente@ejemplo.com',
                                    icono: Icons.email_outlined,
                                    tipoTeclado: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 14),
                                  AppTextField(
                                    controller: _telefonoCtrl,
                                    label: 'Teléfono de Contacto',
                                    hint: '+57 300 123 4567',
                                    icono: Icons.phone_outlined,
                                    tipoTeclado: TextInputType.phone,
                                  ),
                                  const SizedBox(height: 14),
                                  AppTextField(
                                    controller: _observacionCtrl,
                                    label: 'Observación',
                                    hint:
                                        'Notas o comentarios sobre el cliente o la negociación...',
                                    icono: Icons.notes_rounded,
                                    tipoTeclado: TextInputType.multiline,
                                    minLines: 2,
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            colorScheme.outline.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.verified_outlined,
                                              color: colorScheme.primary,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Estado Operativo',
                                                style: theme.textTheme.bodyMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: InkWell(
                                                onTap: () =>
                                                    vm.seleccionarEstado('Activo'),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 150,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: vm.estadoSeleccionado ==
                                                            'Activo'
                                                        ? Colors.green
                                                            .withValues(alpha: 0.18)
                                                        : colorScheme
                                                            .surfaceContainerHighest
                                                            .withValues(alpha: 0.4),
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                    border: Border.all(
                                                      color: vm.estadoSeleccionado ==
                                                              'Activo'
                                                          ? Colors.green
                                                          : Colors.transparent,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    'Activo',
                                                    style: TextStyle(
                                                      color: vm.estadoSeleccionado ==
                                                              'Activo'
                                                          ? Colors.green.shade800
                                                          : colorScheme
                                                              .onSurfaceVariant,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: InkWell(
                                                onTap: () =>
                                                    vm.seleccionarEstado('Inactivo'),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 150,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: vm.estadoSeleccionado ==
                                                            'Inactivo'
                                                        ? colorScheme.error
                                                            .withValues(alpha: 0.15)
                                                        : colorScheme
                                                            .surfaceContainerHighest
                                                            .withValues(alpha: 0.4),
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                    border: Border.all(
                                                      color: vm.estadoSeleccionado ==
                                                              'Inactivo'
                                                          ? colorScheme.error
                                                          : Colors.transparent,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    'Inactivo',
                                                    style: TextStyle(
                                                      color: vm.estadoSeleccionado ==
                                                              'Inactivo'
                                                          ? colorScheme.error
                                                          : colorScheme
                                                              .onSurfaceVariant,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  AppButton(
                                    texto: vm.guardando
                                        ? 'Guardando...'
                                        : (vm.esEdicion
                                            ? 'Guardar Cambios'
                                            : 'Crear Cliente'),
                                    icono: Icons.check_circle_outline_rounded,
                                    onPressed: vm.guardando ? null : _guardarCliente,
                                  ),
                                ],
                              ),
                            ),
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
    );
  }
}
