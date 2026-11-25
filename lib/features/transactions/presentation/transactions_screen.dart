import 'package:flutter/material.dart';
import 'package:core/core.dart' hide Transaction;
import 'package:provider/provider.dart';
import 'package:koralis_app/features/auth/domain/entities/user.dart';
import 'package:koralis_app/features/auth/presentation/widgets/forgot_password_form_sheet.dart';
import 'package:koralis_app/features/clients/domain/usecases/get_clients_usecase.dart';
import 'package:koralis_app/features/profile/domain/entities/profile.dart';
import 'package:koralis_app/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:koralis_app/features/profile/presentation/viewmodels/profile_view_model.dart';
import '../domain/entities/transaction.dart';
import '../domain/usecases/get_transactions_usecase.dart';
import '../domain/usecases/delete_transaction_usecase.dart';
import 'transaction_form_screen.dart';
import 'viewmodels/transactions_view_model.dart';

/// Pantalla principal para la consulta y gestión de transacciones financieras (arquitectura MVVM con `provider`).
class TransactionsScreen extends StatelessWidget {
  final User user;
  final GetTransactionsUseCase? getTransactionsUseCase;
  final DeleteTransactionUseCase? deleteTransactionUseCase;
  final GetProfileUseCase? getProfileUseCase;
  final GetClientsUseCase? getClientsUseCase;

  const TransactionsScreen({
    super.key,
    required this.user,
    this.getTransactionsUseCase,
    this.deleteTransactionUseCase,
    this.getProfileUseCase,
    this.getClientsUseCase,
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
    final tieneTxVm = _tieneProvider<TransactionsViewModel>(context);
    final tieneProfileVm = _tieneProvider<ProfileViewModel>(context);

    if (tieneTxVm && tieneProfileVm) {
      return _TransactionsView(user: user);
    }

    return MultiProvider(
      providers: [
        if (!tieneTxVm)
          ChangeNotifierProvider<TransactionsViewModel>(
            create: (_) => TransactionsViewModel(
              userId: user.id,
              getTransactionsUseCase: getTransactionsUseCase,
              deleteTransactionUseCase: deleteTransactionUseCase,
              getClientsUseCase: getClientsUseCase,
            ),
          ),
        if (!tieneProfileVm)
          ChangeNotifierProvider<ProfileViewModel>(
            create: (_) => ProfileViewModel(
              getProfileUseCase: getProfileUseCase,
            ),
          ),
      ],
      child: _TransactionsView(user: user),
    );
  }
}

class _TransactionsView extends StatefulWidget {
  final User user;

  const _TransactionsView({required this.user});

  @override
  State<_TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<_TransactionsView> {
  static const double _anchoBarraBase = 58.0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<TransactionsViewModel>().cargarDatos();
      context.read<ProfileViewModel>().cargarPerfil(widget.user.id);
    });
  }

  Future<void> _seleccionarFechaInicial(
    BuildContext context,
    TransactionsViewModel vm,
  ) async {
    final DateTime? seleccionada = await showDatePicker(
      context: context,
      initialDate: vm.fechaInicial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (seleccionada != null && mounted) {
      final ok = vm.actualizarFechaInicial(seleccionada);
      if (!ok) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(
            content: Text(
              'La fecha inicial no puede ser posterior a la fecha final',
            ),
          ),
        );
      }
    }
  }

  Future<void> _seleccionarFechaFinal(
    BuildContext context,
    TransactionsViewModel vm,
  ) async {
    final DateTime? seleccionada = await showDatePicker(
      context: context,
      initialDate: vm.fechaFinal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (seleccionada != null && mounted) {
      final ok = vm.actualizarFechaFinal(seleccionada);
      if (!ok) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(
            content: Text(
              'La fecha final no puede ser anterior a la fecha inicial',
            ),
          ),
        );
      }
    }
  }

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();
    return '$dia/$mes/$anio';
  }

  String _formatearMoneda(double valor) {
    final partes = valor.toStringAsFixed(2).split('.');
    final entero = partes[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '\$ $entero,${partes[1]}';
  }

  void _navegarNuevaTransaccion(BuildContext context) async {
    final bool? creado = await Navigator.pushNamed(
      context,
      '/transaction_form',
      arguments: TransactionFormArgs(user: widget.user),
    ) as bool?;

    if (creado == true && context.mounted) {
      context.read<TransactionsViewModel>().cargarDatos();
    }
  }

  void _navegarEditarTransaccion(
    BuildContext context,
    Transaction transaccion,
  ) async {
    final bool? actualizado = await Navigator.pushNamed(
      context,
      '/transaction_form',
      arguments: TransactionFormArgs(
        user: widget.user,
        transaction: transaccion,
      ),
    ) as bool?;

    if (actualizado == true && context.mounted) {
      context.read<TransactionsViewModel>().cargarDatos();
    }
  }

  /// Solicita confirmación, elimina una transacción manual y notifica el nuevo saldo del cliente.
  Future<void> _confirmarEliminarTransaccion(
    BuildContext context,
    Transaction tx,
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
              child: Text(
                'Eliminar Transacción',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de eliminar la ${tx.tipo.etiqueta.toLowerCase()} de ${_formatearMoneda(tx.valor)} del cliente ${tx.clienteNombre}?',
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
      final nuevoSaldo = await this.context
          .read<TransactionsViewModel>()
          .eliminarTransaccion(tx);
      final saldoTexto = nuevoSaldo < 0
          ? '- ${_formatearMoneda(nuevoSaldo.abs())}'
          : _formatearMoneda(nuevoSaldo);

      if (!mounted) return;
      if (nuevoSaldo < 0) {
        AppMessenger.showErrorSnackBar(
          this.context,
          'Transacción eliminada. Nuevo saldo de ${tx.clienteNombre}: $saldoTexto (saldo negativo)',
        );
      } else {
        AppMessenger.showSuccessSnackBar(
          this.context,
          'Transacción eliminada. Nuevo saldo de ${tx.clienteNombre}: $saldoTexto',
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppMessenger.showErrorSnackBar(
        this.context,
        'No fue posible eliminar la transacción: $e',
      );
    }
  }

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
                context.read<ProfileViewModel>().limpiar();
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

  void _mostrarMenuPerfil(BuildContext context, Profile? profile) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                CircleAvatar(
                  radius: 28,
                  backgroundImage:
                      (profile?.avatarPath != null && profile!.avatarPath.isNotEmpty)
                          ? AssetImage(profile.avatarPath)
                          : null,
                  child: (profile?.avatarPath == null || profile!.avatarPath.isEmpty)
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.nombre ?? widget.user.nombre,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile?.correo ?? widget.user.correo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.lock_reset_rounded),
              title: const Text('Restablecer contraseña'),
              subtitle: const Text('Solicita el correo de recuperación'),
              onTap: () {
                Navigator.pop(context);
                showAppModalBottomSheet(
                  context,
                  child: ForgotPasswordFormSheet(
                    initialEmail: profile?.correo ?? widget.user.correo,
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout_rounded, color: colorScheme.error),
              title: Text(
                'Cerrar sesión',
                style: TextStyle(
                  color: colorScheme.error,
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

  List<AppFolderTabItem> _obtenerItemsPestanas(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return [
      AppFolderTabItem(
        indice: 0,
        titulo: 'Clientes',
        icono: Icons.people_alt_outlined,
        colorAcento: colorScheme.secondary,
        onTap: () {
          Navigator.pushReplacementNamed(context, '/clients', arguments: widget.user);
        },
      ),
      AppFolderTabItem(
        indice: 1,
        titulo: 'Instrumentos',
        icono: Icons.paid_outlined,
        colorAcento: colorScheme.primary,
        onTap: () {
          Navigator.pushReplacementNamed(context, '/instruments', arguments: widget.user);
        },
      ),
      AppFolderTabItem(
        indice: 2,
        titulo: 'Transacciones',
        icono: Icons.receipt_long_outlined,
        colorAcento: colorScheme.tertiary,
        onTap: () {},
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

  void _mostrarFichaDetalle(BuildContext context, Transaction transaccion) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final esManual = transaccion.tipo == TransactionType.recarga ||
        transaccion.tipo == TransactionType.retiro;

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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: transaccion.tipo.colorSugerido.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    transaccion.tipo.icono,
                    color: transaccion.tipo.colorSugerido,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaccion.clienteNombre,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Fecha: ${_formatearFecha(transaccion.fecha)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                AppBadge(
                  texto: transaccion.tipo.etiqueta,
                  color: transaccion.tipo.colorSugerido,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            ListTile(
              dense: true,
              leading: const Icon(Icons.attach_money_rounded),
              title: const Text('Valor de la Transacción'),
              subtitle: Text(
                '${transaccion.tipo.signo} ${_formatearMoneda(transaccion.valor)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: transaccion.tipo.esIngreso
                      ? Colors.green.shade800
                      : Colors.amber.shade900,
                ),
              ),
            ),
            if (transaccion.instrumentoId != null &&
                transaccion.instrumentoId!.isNotEmpty)
              ListTile(
                dense: true,
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Instrumento Asociado'),
                subtitle: Text(transaccion.instrumentoId!),
              ),
            if (transaccion.observacion.isNotEmpty)
              ListTile(
                dense: true,
                leading: const Icon(Icons.notes_rounded),
                title: const Text('Observación'),
                subtitle: Text(transaccion.observacion),
              ),
            const SizedBox(height: 14),
            if (!esManual)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Generada automáticamente por el instrumento financiero.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final vm = context.watch<TransactionsViewModel>();
    final profileVm = context.watch<ProfileViewModel>();
    final profile = profileVm.profile;
    final imageProvider =
        (profile?.avatarPath != null && profile!.avatarPath.isNotEmpty)
            ? AssetImage(profile.avatarPath) as ImageProvider
            : null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: AppFloatingActionButton(
        icono: Icons.add_rounded,
        mensajeTooltip: 'Nueva Transacción',
        onPressed: () => _navegarNuevaTransaccion(context),
      ),
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
                          titulo: 'Transacciones',
                          onBack: () => Navigator.pushReplacementNamed(
                            context,
                            '/dashboard',
                            arguments: widget.user,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String?>(
                                      isExpanded: true,
                                      initialValue: (vm.filtroClienteId == null ||
                                              vm.clientesDisponibles.any(
                                                (c) => c.id == vm.filtroClienteId,
                                              ))
                                          ? vm.filtroClienteId
                                          : null,
                                      decoration: InputDecoration(
                                        labelText: 'Cliente',
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.person_outline_rounded,
                                          size: 18,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        filled: true,
                                        fillColor: colorScheme.surface,
                                      ),
                                      items: [
                                        const DropdownMenuItem<String?>(
                                          value: null,
                                          child: Text(
                                            'Todos los clientes',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ),
                                        ...vm.clientesDisponibles.map(
                                          (c) => DropdownMenuItem<String?>(
                                            value: c.id,
                                            child: Text(
                                              c.nombre,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  const TextStyle(fontSize: 13),
                                            ),
                                          ),
                                        ),
                                      ],
                                      onChanged: vm.setFiltroCliente,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: DropdownButtonFormField<TransactionType?>(
                                      isExpanded: true,
                                      initialValue: vm.filtroTipo,
                                      decoration: InputDecoration(
                                        labelText: 'Tipo',
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.filter_list_rounded,
                                          size: 18,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        filled: true,
                                        fillColor: colorScheme.surface,
                                      ),
                                      items: [
                                        const DropdownMenuItem<TransactionType?>(
                                          value: null,
                                          child: Text(
                                            'Todos los tipos',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ),
                                        ...TransactionType.values.map(
                                          (tipo) =>
                                              DropdownMenuItem<TransactionType?>(
                                            value: tipo,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  tipo.icono,
                                                  size: 16,
                                                  color: tipo.colorSugerido,
                                                ),
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Text(
                                                    tipo.etiqueta,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                      onChanged: vm.setFiltroTipo,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () =>
                                          _seleccionarFechaInicial(context, vm),
                                      borderRadius: BorderRadius.circular(12),
                                      child: InputDecorator(
                                        decoration: InputDecoration(
                                          labelText: 'Desde',
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.calendar_today_outlined,
                                            size: 16,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: colorScheme.surface,
                                        ),
                                        child: Text(
                                          _formatearFecha(vm.fechaInicial),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colorScheme.onSurface,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () =>
                                          _seleccionarFechaFinal(context, vm),
                                      borderRadius: BorderRadius.circular(12),
                                      child: InputDecorator(
                                        decoration: InputDecoration(
                                          labelText: 'Hasta',
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.event_outlined,
                                            size: 16,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: colorScheme.surface,
                                        ),
                                        child: Text(
                                          _formatearFecha(vm.fechaFinal),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colorScheme.onSurface,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    tooltip: 'Restablecer al mes actual',
                                    icon: const Icon(
                                      Icons.restart_alt_rounded,
                                      size: 20,
                                    ),
                                    onPressed: vm.restablecerMesActual,
                                    visualDensity: VisualDensity.compact,
                                    style: IconButton.styleFrom(
                                      backgroundColor: colorScheme
                                          .surfaceContainerHighest
                                          .withValues(alpha: 0.4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _buildListaTransacciones(
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
                indiceSeleccionado: 2,
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

  Widget _buildListaTransacciones(
    BuildContext context, {
    required TransactionsViewModel vm,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    if (vm.isLoading && vm.transacciones.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage != null && vm.transacciones.isEmpty) {
      return Center(
        child: Text(
          'Error al cargar transacciones: ${vm.errorMessage}',
          style: TextStyle(color: colorScheme.error),
        ),
      );
    }

    final filtradas = vm.transaccionesFiltradas;

    if (filtradas.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: colorScheme.primary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 14),
            Text(
              vm.hayFiltrosActivos
                  ? 'No se encontraron transacciones con los filtros seleccionados'
                  : 'No hay transacciones registradas',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80.0),
      itemCount: filtradas.length,
      itemBuilder: (context, index) {
        final tx = filtradas[index];
        final esManual = tx.tipo == TransactionType.recarga ||
            tx.tipo == TransactionType.retiro;
        final refInst = (tx.instrumentoId != null &&
                tx.instrumentoId!.isNotEmpty)
            ? ' • Inst: ${tx.instrumentoId}'
            : '';

        return AppListCard(
          titulo: tx.clienteNombre.isNotEmpty
              ? tx.clienteNombre
              : 'Cliente no asignado',
          subtitulo: '${_formatearFecha(tx.fecha)}$refInst',
          detalle: tx.observacion.isNotEmpty ? tx.observacion : null,
          colorAcento: tx.tipo.colorSugerido,
          iconoAvatar: tx.tipo.icono,
          badge: AppBadge(
            texto: tx.tipo.etiqueta,
            color: tx.tipo.colorSugerido,
          ),
          pie: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                '${tx.tipo.signo} ${_formatearMoneda(tx.valor)}',
                style: TextStyle(
                  color: tx.tipo.esIngreso
                      ? Colors.green.shade800
                      : Colors.amber.shade900,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          onTap: () => _mostrarFichaDetalle(context, tx),
          accionesSwipe: esManual
              ? [
                  AppSwipeAction(
                    etiqueta: 'Editar',
                    icono: Icons.edit_outlined,
                    colorFondo: colorScheme.primary,
                    onTap: () => _navegarEditarTransaccion(context, tx),
                  ),
                  AppSwipeAction(
                    etiqueta: 'Eliminar',
                    icono: Icons.delete_outline_rounded,
                    colorFondo: colorScheme.error,
                    onTap: () => _confirmarEliminarTransaccion(context, tx),
                  ),
                ]
              : null,
        );
      },
    );
  }
}
