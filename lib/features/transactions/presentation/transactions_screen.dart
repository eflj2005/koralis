import 'package:flutter/material.dart';
import 'package:core/core.dart' hide Transaction;
import 'package:koralis_app/features/auth/domain/entities/user.dart';
import 'package:koralis_app/features/auth/presentation/widgets/forgot_password_form_sheet.dart';
import 'package:koralis_app/features/clients/domain/entities/client.dart';
import 'package:koralis_app/features/clients/domain/usecases/get_clients_usecase.dart';
import 'package:koralis_app/features/clients/data/repositories/client_repository_impl.dart';
import 'package:koralis_app/features/profile/domain/entities/profile.dart';
import 'package:koralis_app/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:koralis_app/features/profile/data/repositories/profile_repository_impl.dart';
import '../domain/entities/transaction.dart';
import '../domain/usecases/get_transactions_usecase.dart';
import '../domain/repositories/transaction_repository.dart';
import '../data/repositories/transaction_repository_impl.dart';
import 'transaction_form_screen.dart';

/// Pantalla principal para la consulta y gestión de transacciones financieras.
class TransactionsScreen extends StatefulWidget {
  final User user;
  final GetTransactionsUseCase? getTransactionsUseCase;
  final GetProfileUseCase? getProfileUseCase;
  final GetClientsUseCase? getClientsUseCase;

  const TransactionsScreen({
    super.key,
    required this.user,
    this.getTransactionsUseCase,
    this.getProfileUseCase,
    this.getClientsUseCase,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  static const double _anchoBarraBase = 58.0;

  late final GetTransactionsUseCase _getTransactionsUseCase;
  late final GetProfileUseCase _getProfileUseCase;
  late final GetClientsUseCase _getClientsUseCase;

  Future<List<Transaction>>? _transaccionesFuture;
  Future<Profile>? _profileFuture;
  List<Client> _clientesDisponibles = [];

  // Filtros reactivos
  String? _filtroClienteId; // null = Todos los clientes
  TransactionType? _filtroTipo; // null = Todos los tipos
  late DateTime _fechaInicial;
  late DateTime _fechaFinal;

  @override
  void initState() {
    super.initState();
    final ahora = DateTime.now();
    _fechaInicial = DateTime(ahora.year, ahora.month, 1);
    _fechaFinal = DateTime(ahora.year, ahora.month + 1, 0, 23, 59, 59);

    TransactionRepository? repo;
    TransactionRepository obtenerRepositorio() =>
        repo ??= TransactionRepositoryImpl(userId: widget.user.id);

    _getTransactionsUseCase = widget.getTransactionsUseCase ??
        GetTransactionsUseCase(obtenerRepositorio());
    _getProfileUseCase =
        widget.getProfileUseCase ?? GetProfileUseCase(ProfileRepositoryImpl());
    _getClientsUseCase = widget.getClientsUseCase ??
        GetClientsUseCase(ClientRepositoryImpl(userId: widget.user.id));

    _cargarDatos();
  }

  void _cargarDatos() {
    setState(() {
      _transaccionesFuture = _getTransactionsUseCase.execute();
      _profileFuture = _getProfileUseCase.execute(widget.user.id);
    });
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    try {
      final clientes = await _getClientsUseCase.execute();
      if (mounted) {
        setState(() {
          _clientesDisponibles = clientes;
        });
      }
    } catch (_) {
      // Ignorar fallas de conexión seguras
    }
  }

  bool _esMesActual() {
    final ahora = DateTime.now();
    final primerDia = DateTime(ahora.year, ahora.month, 1);
    final ultimoDia = DateTime(ahora.year, ahora.month + 1, 0, 23, 59, 59);

    return _fechaInicial.year == primerDia.year &&
        _fechaInicial.month == primerDia.month &&
        _fechaInicial.day == primerDia.day &&
        _fechaFinal.year == ultimoDia.year &&
        _fechaFinal.month == ultimoDia.month &&
        _fechaFinal.day == ultimoDia.day;
  }

  void _restablecerMesActual() {
    final ahora = DateTime.now();
    setState(() {
      _fechaInicial = DateTime(ahora.year, ahora.month, 1);
      _fechaFinal = DateTime(ahora.year, ahora.month + 1, 0, 23, 59, 59);
    });
  }

  Future<void> _seleccionarFechaInicial(BuildContext context) async {
    final DateTime? seleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaInicial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      locale: const Locale('es', 'CO'),
    );

    if (seleccionada != null) {
      final normalizada =
          DateTime(seleccionada.year, seleccionada.month, seleccionada.day);
      if (normalizada.isAfter(_fechaFinal)) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La fecha inicial no puede ser posterior a la fecha final'),
          ),
        );
        return;
      }
      setState(() => _fechaInicial = normalizada);
    }
  }

  Future<void> _seleccionarFechaFinal(BuildContext context) async {
    final DateTime? seleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaFinal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      locale: const Locale('es', 'CO'),
    );

    if (seleccionada != null) {
      final normalizada = DateTime(
        seleccionada.year,
        seleccionada.month,
        seleccionada.day,
        23,
        59,
        59,
      );
      if (normalizada.isBefore(_fechaInicial)) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La fecha final no puede ser anterior a la fecha inicial'),
          ),
        );
        return;
      }
      setState(() => _fechaFinal = normalizada);
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

    if (creado == true) {
      _cargarDatos();
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

    if (actualizado == true) {
      _cargarDatos();
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
        onTap: () {
          // Ya nos encontramos en Transacciones
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

            if (esManual)
              AppButton(
                texto: 'Editar Transacción',
                icono: Icons.edit_outlined,
                onPressed: () {
                  Navigator.pop(context);
                  _navegarEditarTransaccion(context, transaccion);
                },
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18, color: colorScheme.onSurfaceVariant),
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

                        // Panel de Filtros: Fila 1 (Dropdowns Cliente y Tipo) + Fila 2 (Rango Fechas)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Fila 1: Cliente y Tipo
                              Row(
                                children: [
                                  // Selector de Cliente
                                  Expanded(
                                    child: DropdownButtonFormField<String?>(
                                      isExpanded: true,
                                      initialValue: _filtroClienteId,
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
                                        ..._clientesDisponibles.map(
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
                                      onChanged: (val) =>
                                          setState(() => _filtroClienteId = val),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Selector de Tipo
                                  Expanded(
                                    child: DropdownButtonFormField<TransactionType?>(
                                      isExpanded: true,
                                      initialValue: _filtroTipo,
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
                                      onChanged: (val) =>
                                          setState(() => _filtroTipo = val),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Fila 2: Rango de Fechas (Desde / Hasta) y botón restablecer
                              Row(
                                children: [
                                  // Fecha Desde
                                  Expanded(
                                    child: InkWell(
                                      onTap: () =>
                                          _seleccionarFechaInicial(context),
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
                                          _formatearFecha(_fechaInicial),
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
                                  // Fecha Hasta
                                  Expanded(
                                    child: InkWell(
                                      onTap: () =>
                                          _seleccionarFechaFinal(context),
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
                                          _formatearFecha(_fechaFinal),
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
                                  // Botón restablecer al mes actual
                                  IconButton(
                                    tooltip: 'Restablecer al mes actual',
                                    icon: const Icon(
                                      Icons.restart_alt_rounded,
                                      size: 20,
                                    ),
                                    onPressed: _restablecerMesActual,
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
                          child: FutureBuilder<List<Transaction>>(
                            future: _transaccionesFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    'Error al cargar transacciones: ${snapshot.error}',
                                    style: TextStyle(color: colorScheme.error),
                                  ),
                                );
                              }

                              final List<Transaction> todas =
                                  snapshot.data ?? [];
                              final List<Transaction> filtradas = todas.where((t) {
                                final coincideCliente =
                                    _filtroClienteId == null ||
                                        t.clienteId == _filtroClienteId;
                                final coincideTipo = _filtroTipo == null ||
                                    t.tipo == _filtroTipo;

                                // Comparación normalizada por fecha (inclusiva a nivel de día)
                                final fechaTx = DateTime(
                                  t.fecha.year,
                                  t.fecha.month,
                                  t.fecha.day,
                                );
                                final inicio = DateTime(
                                  _fechaInicial.year,
                                  _fechaInicial.month,
                                  _fechaInicial.day,
                                );
                                final fin = DateTime(
                                  _fechaFinal.year,
                                  _fechaFinal.month,
                                  _fechaFinal.day,
                                );
                                final coincideFecha =
                                    !fechaTx.isBefore(inicio) &&
                                        !fechaTx.isAfter(fin);

                                return coincideCliente &&
                                    coincideTipo &&
                                    coincideFecha;
                              }).toList();

                              if (filtradas.isEmpty) {
                                final bool hayFiltrosActivos =
                                    _filtroClienteId != null ||
                                        _filtroTipo != null ||
                                        !_esMesActual();

                                return Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.receipt_long_outlined,
                                        size: 64,
                                        color: colorScheme.primary
                                            .withValues(alpha: 0.35),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        hayFiltrosActivos
                                            ? 'No se encontraron transacciones con los filtros seleccionados'
                                            : 'No hay transacciones registradas',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
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
                                  final refInst = (tx.instrumentoId != null &&
                                          tx.instrumentoId!.isNotEmpty)
                                      ? ' • Inst: ${tx.instrumentoId}'
                                      : '';

                                  return AppListCard(
                                    titulo: tx.clienteNombre.isNotEmpty
                                        ? tx.clienteNombre
                                        : 'Cliente no asignado',
                                    subtitulo:
                                        '${_formatearFecha(tx.fecha)}$refInst',
                                    detalle: tx.observacion.isNotEmpty
                                        ? tx.observacion
                                        : null,
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
            AppSidebarNavigation(
              anchoBarra: _anchoBarraBase,
              insigniaFlotante: FutureBuilder<Profile>(
                future: _profileFuture,
                builder: (context, snapshot) {
                  final profile = snapshot.data;
                  final imageProvider =
                      (profile?.avatarPath != null && profile!.avatarPath.isNotEmpty)
                          ? AssetImage(profile.avatarPath) as ImageProvider
                          : null;

                  return AppFloatingProfileBadge(
                    proveedorImagen: imageProvider,
                    onTap: () => _mostrarMenuPerfil(context, profile),
                  );
                },
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
}
