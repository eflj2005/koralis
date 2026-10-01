import 'package:flutter/material.dart';
import 'package:core/core.dart' hide Transaction;
import 'package:koralis_app/features/auth/domain/entities/user.dart';
import 'package:koralis_app/features/auth/presentation/widgets/forgot_password_form_sheet.dart';
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

  const TransactionsScreen({
    super.key,
    required this.user,
    this.getTransactionsUseCase,
    this.getProfileUseCase,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  static const double _anchoBarraBase = 58.0;

  late final GetTransactionsUseCase _getTransactionsUseCase;
  late final GetProfileUseCase _getProfileUseCase;

  Future<List<Transaction>>? _transaccionesFuture;
  Future<Profile>? _profileFuture;

  TransactionType? _filtroTipo; // null = Todas

  @override
  void initState() {
    super.initState();
    TransactionRepository? repo;
    TransactionRepository obtenerRepositorio() =>
        repo ??= TransactionRepositoryImpl();

    _getTransactionsUseCase = widget.getTransactionsUseCase ??
        GetTransactionsUseCase(obtenerRepositorio());
    _getProfileUseCase =
        widget.getProfileUseCase ?? GetProfileUseCase(ProfileRepositoryImpl());

    _cargarDatos();
  }

  void _cargarDatos() {
    setState(() {
      _transaccionesFuture = _getTransactionsUseCase.execute();
      _profileFuture = _getProfileUseCase.execute(widget.user.id);
    });
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
                          subtitulo: 'Historial de ingresos, retiros y colocaciones',
                          onBack: () => Navigator.pushReplacementNamed(
                            context,
                            '/dashboard',
                            arguments: widget.user,
                          ),
                        ),

                        // Barra de filtros horizontales
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              _buildChipFiltro(
                                etiqueta: 'Todas',
                                seleccionado: _filtroTipo == null,
                                onTap: () => setState(() => _filtroTipo = null),
                              ),
                              const SizedBox(width: 8),
                              _buildChipFiltro(
                                etiqueta: 'Recargas',
                                seleccionado: _filtroTipo == TransactionType.recarga,
                                colorAcento: TransactionType.recarga.colorSugerido,
                                onTap: () => setState(
                                  () => _filtroTipo = TransactionType.recarga,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildChipFiltro(
                                etiqueta: 'Inversiones',
                                seleccionado: _filtroTipo == TransactionType.inversion,
                                colorAcento: TransactionType.inversion.colorSugerido,
                                onTap: () => setState(
                                  () => _filtroTipo = TransactionType.inversion,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildChipFiltro(
                                etiqueta: 'Retornos',
                                seleccionado: _filtroTipo == TransactionType.retorno,
                                colorAcento: TransactionType.retorno.colorSugerido,
                                onTap: () => setState(
                                  () => _filtroTipo = TransactionType.retorno,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildChipFiltro(
                                etiqueta: 'Retiros',
                                seleccionado: _filtroTipo == TransactionType.retiro,
                                colorAcento: TransactionType.retiro.colorSugerido,
                                onTap: () => setState(
                                  () => _filtroTipo = TransactionType.retiro,
                                ),
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

                              final List<Transaction> todas = snapshot.data ?? [];
                              final List<Transaction> filtradas = _filtroTipo == null
                                  ? todas
                                  : todas.where((t) => t.tipo == _filtroTipo).toList();

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
                                        _filtroTipo == null
                                            ? 'No hay transacciones registradas'
                                            : 'No hay transacciones de tipo ${_filtroTipo!.etiqueta}',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
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

  Widget _buildChipFiltro({
    required String etiqueta,
    required bool seleccionado,
    required VoidCallback onTap,
    Color? colorAcento,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colorBase = colorAcento ?? colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: seleccionado
              ? colorBase.withValues(alpha: 0.18)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: seleccionado
                ? colorBase
                : colorScheme.outline.withValues(alpha: 0.2),
            width: seleccionado ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          etiqueta,
          style: TextStyle(
            fontSize: 12,
            fontWeight: seleccionado ? FontWeight.bold : FontWeight.w500,
            color: seleccionado ? colorBase : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
