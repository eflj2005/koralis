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
import '../domain/usecases/save_transaction_usecase.dart';
import '../domain/repositories/transaction_repository.dart';
import '../data/repositories/transaction_repository_impl.dart';

/// Argumentos para la navegación hacia la pantalla de formulario de transacción.
class TransactionFormArgs {
  final User user;
  final Transaction? transaction;
  final String? clienteIdPreseleccionado;

  const TransactionFormArgs({
    required this.user,
    this.transaction,
    this.clienteIdPreseleccionado,
  });
}

/// Pantalla para la creación y edición de transacciones financieras.
class TransactionFormScreen extends StatefulWidget {
  final User user;
  final Transaction? transaction;
  final String? clienteIdPreseleccionado;
  final SaveTransactionUseCase? saveTransactionUseCase;
  final GetClientsUseCase? getClientsUseCase;
  final GetProfileUseCase? getProfileUseCase;

  const TransactionFormScreen({
    super.key,
    required this.user,
    this.transaction,
    this.clienteIdPreseleccionado,
    this.saveTransactionUseCase,
    this.getClientsUseCase,
    this.getProfileUseCase,
  });

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  static const double _anchoBarraBase = 58.0;

  final _formKey = GlobalKey<FormState>();

  String? _clienteIdSeleccionado;
  String? _clienteNombreSeleccionado;
  late TransactionType _tipoSeleccionado;
  late DateTime _fecha;
  late final TextEditingController _valorCtrl;
  late final TextEditingController _observacionCtrl;

  bool _guardando = false;
  bool _cargandoClientes = true;
  List<Client> _clientesDisponibles = [];

  late final SaveTransactionUseCase _saveTransactionUseCase;
  late final GetClientsUseCase _getClientsUseCase;
  late final GetProfileUseCase _getProfileUseCase;
  Future<Profile>? _profileFuture;

  bool get _esEdicion => widget.transaction != null;
  bool get _esAutomatica =>
      _esEdicion &&
      (widget.transaction!.tipo == TransactionType.inversion ||
          widget.transaction!.tipo == TransactionType.retorno);

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;

    _tipoSeleccionado = tx?.tipo ?? TransactionType.recarga;
    _fecha = tx?.fecha ?? DateTime.now();
    _clienteIdSeleccionado = tx?.clienteId ?? widget.clienteIdPreseleccionado;
    _clienteNombreSeleccionado = tx?.clienteNombre;

    _valorCtrl = TextEditingController(
      text: tx != null ? tx.valor.toStringAsFixed(2) : '',
    );
    _observacionCtrl = TextEditingController(text: tx?.observacion ?? '');

    TransactionRepository? txRepo;
    TransactionRepository obtenerTxRepo() => txRepo ??= TransactionRepositoryImpl();

    _saveTransactionUseCase = widget.saveTransactionUseCase ??
        SaveTransactionUseCase(obtenerTxRepo());
    _getClientsUseCase = widget.getClientsUseCase ??
        GetClientsUseCase(ClientRepositoryImpl());
    _getProfileUseCase =
        widget.getProfileUseCase ?? GetProfileUseCase(ProfileRepositoryImpl());

    _cargarInicial();
  }

  Future<void> _cargarInicial() async {
    setState(() {
      _profileFuture = _getProfileUseCase.execute(widget.user.id);
    });

    try {
      final clientes = await _getClientsUseCase.execute();
      if (mounted) {
        setState(() {
          _clientesDisponibles = clientes;
          _cargandoClientes = false;

          if (_clienteIdSeleccionado != null &&
              (_clienteNombreSeleccionado == null || _clienteNombreSeleccionado!.isEmpty)) {
            final encontrado = clientes.where((c) => c.id == _clienteIdSeleccionado);
            if (encontrado.isNotEmpty) {
              _clienteNombreSeleccionado = encontrado.first.nombre;
            }
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _cargandoClientes = false);
      }
    }
  }

  @override
  void dispose() {
    _valorCtrl.dispose();
    _observacionCtrl.dispose();
    super.dispose();
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

  Future<void> _seleccionarFecha(BuildContext context) async {
    if (_esAutomatica) return;
    final DateTime? seleccionada = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      locale: const Locale('es', 'CO'),
    );

    if (seleccionada != null && seleccionada != _fecha) {
      setState(() => _fecha = seleccionada);
    }
  }

  void _guardarTransaccion() async {
    if (!_formKey.currentState!.validate()) return;

    if (_clienteIdSeleccionado == null || _clienteIdSeleccionado!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un cliente')),
      );
      return;
    }

    final double valor =
        double.tryParse(_valorCtrl.text.replaceAll(',', '.').trim()) ?? 0.0;
    if (valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El valor debe ser mayor a 0')),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final nuevaTx = Transaction(
        id: widget.transaction?.id ?? '',
        clienteId: _clienteIdSeleccionado!,
        clienteNombre: _clienteNombreSeleccionado ?? '',
        tipo: _tipoSeleccionado,
        valor: valor,
        fecha: _fecha,
        instrumentoId: widget.transaction?.instrumentoId,
        observacion: _observacionCtrl.text.trim(),
        fechaCreacion: widget.transaction?.fechaCreacion,
      );

      await _saveTransactionUseCase.execute(nuevaTx);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _esEdicion
                  ? 'Transacción actualizada correctamente'
                  : 'Transacción registrada con éxito',
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
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
          Navigator.pop(context);
          Navigator.pushNamed(context, '/clients', arguments: widget.user);
        },
      ),
      AppFolderTabItem(
        indice: 1,
        titulo: 'Instrumentos',
        icono: Icons.paid_outlined,
        colorAcento: colorScheme.primary,
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/instruments', arguments: widget.user);
        },
      ),
      AppFolderTabItem(
        indice: 2,
        titulo: 'Transacciones',
        icono: Icons.receipt_long_outlined,
        colorAcento: colorScheme.tertiary,
        onTap: () => Navigator.pop(context),
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
                          titulo: _esEdicion ? 'Detalle Transacción' : 'Nueva Transacción',
                          subtitulo: _esAutomatica
                              ? 'Transacción generada automáticamente'
                              : 'Registro de movimiento de cuenta',
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
                                  if (_esAutomatica) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceContainerHighest
                                            .withValues(alpha: 0.35),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: colorScheme.outline
                                              .withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.lock_outline_rounded,
                                            size: 20,
                                            color: colorScheme.primary,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Esta transacción fue creada automáticamente por un instrumento financiero y está en modo solo lectura.',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  // --- 1. Selector de Cliente ---
                                  if (_cargandoClientes)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16.0),
                                      child: Center(
                                        child: SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                    )
                                  else
                                    DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      initialValue: _clienteIdSeleccionado,
                                      decoration: InputDecoration(
                                        labelText: 'Cliente *',
                                        prefixIcon: const Icon(
                                          Icons.person_outline_rounded,
                                          size: 20,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        filled: true,
                                        fillColor: colorScheme.surface,
                                        isDense: true,
                                      ),
                                      items: _clientesDisponibles.map((c) {
                                        return DropdownMenuItem<String>(
                                          value: c.id,
                                          child: Text(
                                            c.nombre,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: _esAutomatica
                                          ? null
                                          : (val) {
                                              setState(() {
                                                _clienteIdSeleccionado = val;
                                                final sel = _clientesDisponibles
                                                    .firstWhere((c) => c.id == val);
                                                _clienteNombreSeleccionado = sel.nombre;
                                              });
                                            },
                                      validator: (val) {
                                        if (val == null || val.isEmpty) {
                                          return 'Selecciona un cliente';
                                        }
                                        return null;
                                      },
                                    ),
                                  const SizedBox(height: 16),

                                  // --- 2. Selector de Tipo de Transacción ---
                                  Text(
                                    'Tipo de Transacción *',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  if (_esAutomatica)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _tipoSeleccionado.colorSugerido
                                            .withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _tipoSeleccionado.colorSugerido
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _tipoSeleccionado.icono,
                                            color: _tipoSeleccionado.colorSugerido,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            _tipoSeleccionado.etiqueta,
                                            style: TextStyle(
                                              color: _tipoSeleccionado.colorSugerido,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildTarjetaTipoManual(
                                            tipo: TransactionType.recarga,
                                            titulo: 'Recarga (+)',
                                            descripcion: 'Aumenta disponible',
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildTarjetaTipoManual(
                                            tipo: TransactionType.retiro,
                                            titulo: 'Retiro (-)',
                                            descripcion: 'Disminuye disponible',
                                          ),
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 16),

                                  // --- 3. Fecha ---
                                  InkWell(
                                    onTap: () => _seleccionarFecha(context),
                                    borderRadius: BorderRadius.circular(12),
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Fecha *',
                                        prefixIcon: const Icon(
                                          Icons.calendar_today_outlined,
                                          size: 20,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        filled: true,
                                        fillColor: colorScheme.surface,
                                        isDense: true,
                                      ),
                                      child: Text(
                                        _formatearFecha(_fecha),
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // --- 4. Valor Monetario ---
                                  if (_esAutomatica)
                                    InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Valor de la Transacción (\$)',
                                        prefixIcon: const Icon(
                                          Icons.attach_money_rounded,
                                          size: 20,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        filled: true,
                                        fillColor: colorScheme.surfaceContainerHighest
                                            .withValues(alpha: 0.3),
                                        isDense: true,
                                      ),
                                      child: Text(
                                        _formatearMoneda(widget.transaction!.valor),
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  else
                                    AppTextField(
                                      controller: _valorCtrl,
                                      label: 'Valor de la Transacción (\$) *',
                                      hint: 'Ej. 500000',
                                      icono: Icons.attach_money_rounded,
                                      tipoTeclado:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return 'Ingresa el monto';
                                        }
                                        final parsed = double.tryParse(
                                          val.replaceAll(',', '.').trim(),
                                        );
                                        if (parsed == null || parsed <= 0) {
                                          return 'Monto inválido (debe ser mayor a 0)';
                                        }
                                        return null;
                                      },
                                    ),
                                  const SizedBox(height: 16),

                                  // --- 5. Referencia Instrumento (informativa) ---
                                  if (widget.transaction?.instrumentoId != null &&
                                      widget.transaction!.instrumentoId!.isNotEmpty) ...[
                                    InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Instrumento Referenciado',
                                        prefixIcon: const Icon(
                                          Icons.account_balance_wallet_outlined,
                                          size: 20,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        filled: true,
                                        fillColor: colorScheme.surfaceContainerHighest
                                            .withValues(alpha: 0.3),
                                        isDense: true,
                                      ),
                                      child: Text(
                                        widget.transaction!.instrumentoId!,
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  // --- 6. Observación ---
                                  if (_esAutomatica)
                                    InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Observación',
                                        prefixIcon: const Icon(
                                          Icons.notes_rounded,
                                          size: 20,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        filled: true,
                                        fillColor: colorScheme.surfaceContainerHighest
                                            .withValues(alpha: 0.3),
                                        isDense: true,
                                      ),
                                      child: Text(
                                        _observacionCtrl.text.isNotEmpty
                                            ? _observacionCtrl.text
                                            : 'Sin observaciones',
                                        style: TextStyle(color: colorScheme.onSurface),
                                      ),
                                    )
                                  else
                                    AppTextField(
                                      controller: _observacionCtrl,
                                      label: 'Observación',
                                      hint: 'Detalles, referencia bancaria o notas...',
                                      icono: Icons.notes_rounded,
                                      tipoTeclado: TextInputType.multiline,
                                      minLines: 2,
                                      maxLines: 3,
                                    ),
                                  const SizedBox(height: 28),

                                  // --- Botón de Guardar ---
                                  if (!_esAutomatica)
                                    AppButton(
                                      texto: _guardando
                                          ? 'Guardando...'
                                          : (_esEdicion
                                              ? 'Guardar Cambios'
                                              : 'Registrar Transacción'),
                                      icono: Icons.check_circle_outline_rounded,
                                      onPressed:
                                          _guardando ? null : _guardarTransaccion,
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

  Widget _buildTarjetaTipoManual({
    required TransactionType tipo,
    required String titulo,
    required String descripcion,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final seleccionada = _tipoSeleccionado == tipo;
    final colorAcento = tipo.colorSugerido;

    return InkWell(
      onTap: () => setState(() => _tipoSeleccionado = tipo),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: seleccionada
              ? colorAcento.withValues(alpha: 0.15)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionada
                ? colorAcento
                : colorScheme.outline.withValues(alpha: 0.25),
            width: seleccionada ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  tipo.icono,
                  size: 18,
                  color: seleccionada ? colorAcento : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      titulo,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: seleccionada ? colorAcento : colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                descripcion,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
