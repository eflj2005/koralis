import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:core/core.dart' hide Transaction;
import 'package:koralis_app/features/auth/domain/entities/user.dart';
import 'package:koralis_app/features/auth/presentation/widgets/forgot_password_form_sheet.dart';
import 'package:koralis_app/features/profile/domain/entities/profile.dart';
import 'package:koralis_app/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:koralis_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:koralis_app/features/clients/domain/entities/client.dart';
import 'package:koralis_app/features/clients/domain/usecases/get_clients_usecase.dart';
import 'package:koralis_app/features/clients/data/repositories/client_repository_impl.dart';
import 'package:koralis_app/features/transactions/domain/entities/transaction.dart';
import 'package:koralis_app/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:koralis_app/features/transactions/domain/usecases/save_transaction_usecase.dart';
import 'package:koralis_app/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:koralis_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import '../domain/entities/instrument.dart';
import '../domain/usecases/save_instrument_usecase.dart';
import '../domain/repositories/instrument_repository.dart';
import '../data/repositories/instrument_repository_impl.dart';
import '../domain/entities/bank.dart';
import '../domain/usecases/get_banks_usecase.dart';
import '../data/repositories/bank_repository_impl.dart';

/// Argumentos para la navegación hacia la pantalla de formulario de instrumento.
class InstrumentFormArgs {
  final User user;
  final Instrument? instrument;

  const InstrumentFormArgs({required this.user, this.instrument});
}

/// Pantalla independiente para la creación y edición de instrumentos financieros.
class InstrumentFormScreen extends StatefulWidget {
  final User user;
  final Instrument? instrument;
  final SaveInstrumentUseCase? saveInstrumentUseCase;
  final GetProfileUseCase? getProfileUseCase;
  final GetBanksUseCase? getBanksUseCase;
  final GetTransactionsUseCase? getTransactionsUseCase;
  final GetClientsUseCase? getClientsUseCase;
  final SaveTransactionUseCase? saveTransactionUseCase;
  final DeleteTransactionUseCase? deleteTransactionUseCase;

  const InstrumentFormScreen({
    super.key,
    required this.user,
    this.instrument,
    this.saveInstrumentUseCase,
    this.getProfileUseCase,
    this.getBanksUseCase,
    this.getTransactionsUseCase,
    this.getClientsUseCase,
    this.saveTransactionUseCase,
    this.deleteTransactionUseCase,
  });

  @override
  State<InstrumentFormScreen> createState() => _InstrumentFormScreenState();
}

class _InstrumentFormScreenState extends State<InstrumentFormScreen> {
  static const double _anchoBarraBase = 58.0;

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _numeroCtrl;
  late final TextEditingController _entidadCtrl;
  late DateTime _fechaApertura;
  late final TextEditingController _diasCtrl;
  late final TextEditingController _tasaIeaCtrl;
  late final TextEditingController _valorInvertidoCtrl;
  late final TextEditingController _rendimientoTProyecCtrl;
  late final TextEditingController _retencionPorcentajeCtrl;
  late final TextEditingController _observacionCtrl;
  late String _estado;

  bool _guardando = false;

  late final SaveInstrumentUseCase _saveInstrumentUseCase;
  late final GetProfileUseCase _getProfileUseCase;
  late final GetBanksUseCase _getBanksUseCase;
  Future<Profile>? _profileFuture;
  Future<List<Transaction>>? _transaccionesAsociadasFuture;

  List<Bank> _bancos = [];
  bool _cargandoBancos = true;

  bool get _esEdicion => widget.instrument != null;

  @override
  void initState() {
    super.initState();
    InstrumentRepository? repo;
    InstrumentRepository obtenerRepositorio() =>
        repo ??= InstrumentRepositoryImpl();

    _saveInstrumentUseCase =
        widget.saveInstrumentUseCase ??
        SaveInstrumentUseCase(obtenerRepositorio());
    _getProfileUseCase =
        widget.getProfileUseCase ?? GetProfileUseCase(ProfileRepositoryImpl());
    _getBanksUseCase =
        widget.getBanksUseCase ?? GetBanksUseCase(BankRepositoryImpl());

    if (_esEdicion) {
      _transaccionesAsociadasFuture = _cargarTransaccionesAsociadas();
    }

    final actual = widget.instrument;
    _numeroCtrl = TextEditingController(text: actual?.numero ?? '');
    _entidadCtrl = TextEditingController(text: actual?.entidad ?? '');
    _fechaApertura = actual?.fechaApertura ?? DateTime.now();
    _diasCtrl = TextEditingController(
      text: actual != null ? actual.dias.toString() : '',
    );
    _tasaIeaCtrl = TextEditingController(
      text: actual != null ? actual.tasaIea.toStringAsFixed(2) : '',
    );
    _valorInvertidoCtrl = TextEditingController(
      text: actual != null ? actual.valorInvertido.toStringAsFixed(0) : '',
    );
    _rendimientoTProyecCtrl = TextEditingController(
      text: actual != null ? actual.rendimientoTProyec.toStringAsFixed(0) : '',
    );
    _retencionPorcentajeCtrl = TextEditingController(
      text: actual != null
          ? actual.retencionPorcentaje.toStringAsFixed(2)
          : '4.00',
    );
    _observacionCtrl = TextEditingController(text: actual?.observacion ?? '');
    _estado = actual?.estado ?? 'Borrador';

    // Escuchadores reactivos para recalcular valores en vivo
    _diasCtrl.addListener(_actualizarCalculos);
    _valorInvertidoCtrl.addListener(_actualizarCalculos);
    _rendimientoTProyecCtrl.addListener(_actualizarCalculos);
    _retencionPorcentajeCtrl.addListener(_actualizarCalculos);

    _profileFuture = _getProfileUseCase.execute(widget.user.id);
    _cargarBancos();
  }

  /// Carga asíncronamente las entidades bancarias registradas en la colección 'banks'.
  Future<void> _cargarBancos() async {
    try {
      final bancos = await _getBanksUseCase.execute();
      if (mounted) {
        setState(() {
          _bancos = bancos;
          _cargandoBancos = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _cargandoBancos = false);
      }
    }
  }

  /// Carga asíncronamente las transacciones registradas para obtener las inversiones asociadas.
  Future<List<Transaction>> _cargarTransaccionesAsociadas() async {
    try {
      final useCase = widget.getTransactionsUseCase ??
          GetTransactionsUseCase(TransactionRepositoryImpl());
      return await useCase.execute();
    } catch (_) {
      // En pruebas unitarias donde Firebase no esté inicializado o no haya mock,
      // retorna una lista vacía de forma segura sin provocar excepciones.
      return [];
    }
  }

  /// Carga asíncronamente los clientes registrados en la colección 'clients'.
  Future<List<Client>> _cargarClientesDisponibles() async {
    try {
      final useCase = widget.getClientsUseCase ??
          GetClientsUseCase(ClientRepositoryImpl());
      return await useCase.execute();
    } catch (_) {
      // En pruebas unitarias donde Firebase no esté inicializado o no haya mock,
      // retorna una lista vacía de forma segura.
      return [];
    }
  }

  /// Guarda o actualiza una transacción de inversión asociada al cliente y a este instrumento.
  Future<void> _ejecutarGuardarAporte(Transaction tx) async {
    final useCase = widget.saveTransactionUseCase ??
        SaveTransactionUseCase(TransactionRepositoryImpl());
    await useCase.execute(tx);
  }

  /// Elimina una transacción de inversión asociada a este instrumento y reintegra el saldo al cliente.
  Future<void> _ejecutarEliminarAporte(Transaction tx) async {
    final useCase = widget.deleteTransactionUseCase ??
        DeleteTransactionUseCase(TransactionRepositoryImpl());
    await useCase.execute(tx.id, clienteId: tx.clienteId);
  }

  /// Solicita confirmación y elimina un aporte de cliente reintegrando el valor al disponible.
  Future<void> _confirmarEliminarAporte(
    BuildContext context,
    Transaction tx,
  ) async {
    if (_estado != 'Borrador') {
      AppMessenger.showInfoSnackBar(
        context,
        'Los aportes solo pueden eliminarse mientras el instrumento esté en estado "Borrador"',
      );
      return;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                'Eliminar Aporte',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de eliminar el aporte de ${_formatearMoneda(tx.valor)} perteneciente a ${tx.clienteNombre}?\n\n'
          'El monto será reintegrado automáticamente al saldo disponible del cliente.',
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

    if (confirmar == true && mounted) {
      try {
        await _ejecutarEliminarAporte(tx);
        if (mounted) {
          setState(() {
            _transaccionesAsociadasFuture = _cargarTransaccionesAsociadas();
          });
          AppMessenger.showSuccessSnackBar(
            this.context,
            'Aporte de ${_formatearMoneda(tx.valor)} eliminado correctamente',
          );
        }
      } catch (e) {
        if (mounted) {
          AppMessenger.showErrorSnackBar(
            this.context,
            'No fue posible eliminar el aporte: $e',
          );
        }
      }
    }
  }

  /// Genera los items de la lista desplegable de entidades financieras.
  List<DropdownMenuItem<String>> _generarItemsBancos() {
    final valorActual = _entidadCtrl.text.trim();
    final items = <DropdownMenuItem<String>>[];

    // Si el instrumento en edición tiene una entidad previa que no está en la colección,
    // se agrega dinámicamente para permitir su selección sin errores de aserción.
    if (valorActual.isNotEmpty &&
        !_bancos.any((b) => b.nombre == valorActual)) {
      items.add(
        DropdownMenuItem<String>(
          value: valorActual,
          child: Text(valorActual, overflow: TextOverflow.ellipsis),
        ),
      );
    }

    for (final banco in _bancos) {
      items.add(
        DropdownMenuItem<String>(
          value: banco.nombre,
          child: Text(banco.nombre, overflow: TextOverflow.ellipsis),
        ),
      );
    }

    return items;
  }

  void _actualizarCalculos() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _diasCtrl.removeListener(_actualizarCalculos);
    _valorInvertidoCtrl.removeListener(_actualizarCalculos);
    _rendimientoTProyecCtrl.removeListener(_actualizarCalculos);
    _retencionPorcentajeCtrl.removeListener(_actualizarCalculos);

    _numeroCtrl.dispose();
    _entidadCtrl.dispose();
    _diasCtrl.dispose();
    _tasaIeaCtrl.dispose();
    _valorInvertidoCtrl.dispose();
    _rendimientoTProyecCtrl.dispose();
    _retencionPorcentajeCtrl.dispose();
    _observacionCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Getters de Cálculos Reactivos
  // ---------------------------------------------------------------------------

  int get _dias => int.tryParse(_diasCtrl.text.trim()) ?? 0;

  DateTime get _fechaCierre => _fechaApertura.add(Duration(days: _dias));

  double get _valorInvertido =>
      double.tryParse(_valorInvertidoCtrl.text.replaceAll(',', '.').trim()) ??
      0.0;

  double get _rendimientoTProyec =>
      double.tryParse(
        _rendimientoTProyecCtrl.text.replaceAll(',', '.').trim(),
      ) ??
      0.0;

  double get _valorRecibido => _valorInvertido + _rendimientoTProyec;

  double get _rendimientos => _valorRecibido - _valorInvertido;

  double get _retencionPorcentaje =>
      double.tryParse(
        _retencionPorcentajeCtrl.text.replaceAll(',', '.').trim(),
      ) ??
      0.0;

  double get _retencionValor => _rendimientos * (_retencionPorcentaje / 100.0);

  double get _valorFinalRend => _rendimientos - _retencionValor;

  String _formatearMoneda(double valor) {
    final partes = valor.toStringAsFixed(2).split('.');
    final entero = partes[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '\$ $entero,${partes[1]}';
  }

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();
    return '$dia/$mes/$anio';
  }

  Future<void> _seleccionarFechaApertura(BuildContext context) async {
    final DateTime? seleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaApertura,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Seleccionar Fecha de Apertura',
    );
    if (seleccionada != null && seleccionada != _fechaApertura) {
      setState(() {
        _fechaApertura = seleccionada;
      });
    }
  }

  Future<void> _guardarInstrumento() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    // Si es edición conserva el ID existente, si es nuevo se envía vacío para que
    // la capa de datos asigne el identificador alfanumérico nativo de Cloud Firestore.
    final id = widget.instrument?.id ?? '';
    final fechaCreacion = widget.instrument?.fechaCreacion ?? DateTime.now();

    final instrumento = Instrument(
      id: id,
      numero: _numeroCtrl.text.trim(),
      entidad: _entidadCtrl.text.trim(),
      fechaApertura: _fechaApertura,
      dias: _dias,
      tasaIea:
          double.tryParse(_tasaIeaCtrl.text.replaceAll(',', '.').trim()) ?? 0.0,
      valorInvertido: _valorInvertido,
      rendimientoTProyec: _rendimientoTProyec,
      retencionPorcentaje: _retencionPorcentaje,
      observacion: _observacionCtrl.text.trim(),
      estado: _estado,
      fechaCreacion: fechaCreacion,
      participaciones: widget.instrument?.participaciones ?? const [],
    );

    try {
      await _saveInstrumentUseCase.execute(instrumento);
      if (mounted) {
        AppMessenger.showSuccessSnackBar(
          context,
          _esEdicion
              ? 'Instrumento "${instrumento.numero}" actualizado correctamente'
              : 'Instrumento "${instrumento.numero}" creado exitosamente',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        AppMessenger.showErrorSnackBar(
          context,
          'No fue posible guardar el instrumento: $e',
        );
      }
    }
  }

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
                  backgroundImage:
                      (profile?.avatarPath != null &&
                          profile!.avatarPath.isNotEmpty)
                      ? AssetImage(profile.avatarPath)
                      : null,
                  child:
                      (profile?.avatarPath == null ||
                          profile!.avatarPath.isEmpty)
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
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
                  child: ForgotPasswordFormSheet(
                    initialEmail: widget.user.correo,
                  ),
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
        onTap: () => Navigator.pop(context),
      ),
      AppFolderTabItem(
        indice: 2,
        titulo: 'Transacciones',
        icono: Icons.receipt_long_outlined,
        colorAcento: colorScheme.tertiary,
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/transactions', arguments: widget.user);
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
            // 1. CAPA DE CONTENIDO: FORMULARIO DE INSTRUMENTO
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
                        AppHeaderTitle(
                          titulo: _esEdicion
                              ? 'Editar Instrumento'
                              : 'Nuevo Instrumento',
                          onBack: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: DefaultTabController(
                            length: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // --- Barra de Pestañas Segmentada ---
                                Container(
                                  height: 42,
                                  margin: const EdgeInsets.only(bottom: 14),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TabBar(
                                    indicator: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    indicatorSize: TabBarIndicatorSize.tab,
                                    dividerColor: Colors.transparent,
                                    labelColor: Colors.white,
                                    unselectedLabelColor:
                                        colorScheme.onSurfaceVariant,
                                    labelStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    unselectedLabelStyle: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                    tabs: const [
                                      Tab(text: 'Generalidades'),
                                      Tab(text: 'Aportes'),
                                      Tab(text: 'Resultados'),
                                    ],
                                  ),
                                ),

                                // --- Contenido de las Pestañas ---
                                Expanded(
                                  child: TabBarView(
                                    physics: const BouncingScrollPhysics(),
                                    children: [
                                      // Tab 1: Generalidades (Formulario base)
                                      SingleChildScrollView(
                                        physics: const BouncingScrollPhysics(),
                                        padding: const EdgeInsets.only(
                                          top: 10.0,
                                          bottom: 40.0,
                                        ),
                                        child: Form(
                                          key: _formKey,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                  // --- Sección 1: Datos Base ---
                                  AppTextField(
                                    controller: _numeroCtrl,
                                    label: 'Número de Instrumento / Folio',
                                    hint: 'Ej. CDT-2024-001 o N° Contrato',
                                    icono: Icons.tag_rounded,
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Ingresa el número identificador';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),

                                  // --- Fila: Entidad Financiera y Plazo ---
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Entidad Financiera (Dropdown con colección 'banks', flex 5 / ~63%)
                                      Expanded(
                                        flex: 4,
                                        child: AppDropdownField<String>(
                                          label: 'Entidad Financiera',
                                          hint: _cargandoBancos
                                              ? 'Cargando...'
                                              : 'Selecciona',
                                          icono: Icons.account_balance_outlined,
                                          isLoading: _cargandoBancos,
                                          value: _entidadCtrl.text.isNotEmpty
                                              ? _entidadCtrl.text
                                              : null,
                                          items: _generarItemsBancos(),
                                          onChanged: (nuevaEntidad) {
                                            setState(() {
                                              _entidadCtrl.text =
                                                  nuevaEntidad ?? '';
                                            });
                                          },
                                          validator: (val) {
                                            if (val == null ||
                                                val.trim().isEmpty) {
                                              return 'Selecciona la entidad';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // Plazo en Días (Compacto, máximo 3 dígitos, flex 3 / ~37%)
                                      Expanded(
                                        flex: 3,
                                        child: AppTextField(
                                          controller: _diasCtrl,
                                          label: 'Plazo (Días)',
                                          hint: 'Ej. 90',
                                          icono: Icons.timelapse_rounded,
                                          tipoTeclado: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(3),
                                          ],
                                          validator: (val) {
                                            if (val == null ||
                                                val.trim().isEmpty) {
                                              return 'Requerido';
                                            }
                                            final dias = int.tryParse(
                                              val.trim(),
                                            );
                                            if (dias == null ||
                                                dias <= 0 ||
                                                dias > 999) {
                                              return 'Máx 3 dígitos';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  // --- Fila: Fecha Apertura y Fecha Cierre ---
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Fecha Apertura (Selector interactivo)
                                      Expanded(
                                        child: InkWell(
                                          onTap: () =>
                                              _seleccionarFechaApertura(
                                                context,
                                              ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: 'Fecha Apertura',
                                              prefixIcon: const Padding(
                                                padding: EdgeInsets.only(
                                                  left: 10,
                                                  right: 4,
                                                ),
                                                child: Icon(
                                                  Icons.calendar_today_outlined,
                                                  size: 20,
                                                ),
                                              ),
                                              prefixIconConstraints:
                                                  const BoxConstraints(
                                                    minWidth: 36,
                                                    minHeight: 40,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              filled: true,
                                              fillColor: Colors.white,
                                              isDense: true,
                                            ),
                                            child: Text(
                                              _formatearFecha(_fechaApertura),
                                              style: TextStyle(
                                                color: colorScheme.onSurface,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // Fecha Cierre (Calculada automáticamente)
                                      Expanded(
                                        child: InputDecorator(
                                          decoration: InputDecoration(
                                            labelText: 'Fecha Cierre',
                                            prefixIcon: Padding(
                                              padding: const EdgeInsets.only(
                                                left: 10,
                                                right: 4,
                                              ),
                                              child: Icon(
                                                Icons.event_available_rounded,
                                                size: 20,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                            prefixIconConstraints:
                                                const BoxConstraints(
                                                  minWidth: 36,
                                                  minHeight: 40,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            filled: true,
                                            fillColor: colorScheme
                                                .surfaceContainerHighest
                                                .withValues(alpha: 0.3),
                                            isDense: true,
                                          ),
                                          child: Text(
                                            _formatearFecha(_fechaCierre),
                                            style: TextStyle(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  // --- Fila: Valor Invertido y Tasa I.E.A. ---
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Entrada para el capital invertido (flex 3 / ~60%)
                                      Expanded(
                                        flex: 3,
                                        child: AppTextField(
                                          controller: _valorInvertidoCtrl,
                                          label: 'Valor Invertido (\$)',
                                          hint: 'Ej. 50000000',
                                          icono: Icons.attach_money_rounded,
                                          tipoTeclado:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          validator: (val) {
                                            if (val == null ||
                                                double.tryParse(
                                                      val
                                                          .replaceAll(',', '.')
                                                          .trim(),
                                                    ) ==
                                                    null) {
                                              return 'Ingresa el capital invertido';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // Entrada para el porcentaje de tasa I.E.A. (flex 2 / ~40%)
                                      Expanded(
                                        flex: 2,
                                        child: AppTextField(
                                          controller: _tasaIeaCtrl,
                                          label: '% Tasa I.E.A.',
                                          hint: 'Ej. 11.50',
                                          icono: Icons.percent_rounded,
                                          tipoTeclado:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          validator: (val) {
                                            if (val == null ||
                                                double.tryParse(
                                                      val
                                                          .replaceAll(',', '.')
                                                          .trim(),
                                                    ) ==
                                                    null) {
                                              return 'Ingresa una tasa válida';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  // --- Fila: Rendimiento Proyectado y Retención % ---
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Entrada para el valor monetario de rendimiento proyectado (flex 3 / ~60%)
                                      Expanded(
                                        flex: 3,
                                        child: AppTextField(
                                          controller: _rendimientoTProyecCtrl,
                                          label: 'Rendimiento T. Proyec. (\$)',
                                          hint: 'Ej. 2500000',
                                          icono: Icons.trending_up_rounded,
                                          tipoTeclado:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          validator: (val) {
                                            if (val == null ||
                                                double.tryParse(
                                                      val
                                                          .replaceAll(',', '.')
                                                          .trim(),
                                                    ) ==
                                                    null) {
                                              return 'Ingresa el rendimiento proyectado';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // Entrada para el porcentaje de retención (flex 2 / ~40%)
                                      Expanded(
                                        flex: 2,
                                        child: AppTextField(
                                          controller: _retencionPorcentajeCtrl,
                                          label: 'Retención %',
                                          hint: '4.00',
                                          icono: Icons.price_check_rounded,
                                          tipoTeclado:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),

                                  // --- Selector de Estado Operativo (Activo / Cerrado) ---
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: colorScheme.outline.withValues(alpha: 0.3),
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
                                                style: theme.textTheme.bodyMedium?.copyWith(
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
                                            // 1. Botón interactivo para estado 'Borrador' (de primeras)
                                            Expanded(
                                              child: InkWell(
                                                onTap: () => setState(() => _estado = 'Borrador'),
                                                borderRadius: BorderRadius.circular(8),
                                                child: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 150),
                                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                                  decoration: BoxDecoration(
                                                    color: _estado == 'Borrador'
                                                        ? Colors.amber.withValues(alpha: 0.18)
                                                        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(
                                                      color: _estado == 'Borrador'
                                                          ? Colors.amber.shade700
                                                          : Colors.transparent,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    'Borrador',
                                                    style: TextStyle(
                                                      color: _estado == 'Borrador'
                                                          ? Colors.amber.shade800
                                                          : colorScheme.onSurfaceVariant,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // 2. Botón interactivo para estado 'Activo'
                                            Expanded(
                                              child: InkWell(
                                                onTap: () => setState(() => _estado = 'Activo'),
                                                borderRadius: BorderRadius.circular(8),
                                                child: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 150),
                                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                                  decoration: BoxDecoration(
                                                    color: _estado == 'Activo'
                                                        ? Colors.green.withValues(alpha: 0.18)
                                                        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(
                                                      color: _estado == 'Activo'
                                                          ? Colors.green
                                                          : Colors.transparent,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    'Activo',
                                                    style: TextStyle(
                                                      color: _estado == 'Activo'
                                                          ? Colors.green.shade800
                                                          : colorScheme.onSurfaceVariant,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // 3. Botón interactivo para estado 'Cerrado'
                                            Expanded(
                                              child: InkWell(
                                                onTap: () => setState(() => _estado = 'Cerrado'),
                                                borderRadius: BorderRadius.circular(8),
                                                child: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 150),
                                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                                  decoration: BoxDecoration(
                                                    color: _estado == 'Cerrado'
                                                        ? Colors.grey.withValues(alpha: 0.22)
                                                        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(
                                                      color: _estado == 'Cerrado'
                                                          ? Colors.grey.shade600
                                                          : Colors.transparent,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    'Cerrado',
                                                    style: TextStyle(
                                                      color: _estado == 'Cerrado'
                                                          ? Colors.grey.shade800
                                                          : colorScheme.onSurfaceVariant,
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
                                  const SizedBox(height: 14),

                                  // --- Observación (2 renglones de alto fijo) ---
                                  AppTextField(
                                    controller: _observacionCtrl,
                                    label: 'Observación',
                                    hint:
                                        'Comentarios sobre la colocación o condiciones...',
                                    icono: Icons.notes_rounded,
                                    tipoTeclado: TextInputType.multiline,
                                    minLines: 2,
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 28),

                                  // --- Botón Guardar / Actualizar ---
                                  AppButton(
                                    texto: _guardando
                                        ? 'Guardando...'
                                        : (_esEdicion
                                              ? 'Guardar Cambios'
                                              : 'Registrar Instrumento'),
                                    icono: Icons.check_circle_outline_rounded,
                                    onPressed: _guardando
                                        ? null
                                        : _guardarInstrumento,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Tab 2: Aportes
                          _buildTabAportes(context),

                          // Tab 3: Resultados
                          _buildTabResultados(context),
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
    ),
  ],
),

            // ===============================================================
            // 2. NAVEGACIÓN LATERAL MODULAR DEL CORE
            // Solapa "Instrumentos" activa (índice 1)
            // ===============================================================
            AppSidebarNavigation(
              anchoBarra: _anchoBarraBase,
              insigniaFlotante: FutureBuilder<Profile>(
                future: _profileFuture,
                builder: (context, snapshot) {
                  final profile = snapshot.data;
                  final imageProvider =
                      (profile?.avatarPath != null &&
                          profile!.avatarPath.isNotEmpty)
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
                indiceSeleccionado: 1,
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

  Widget _buildFilaMetrica({
    required String titulo,
    required String valor,
    required Color colorTexto,
    bool esNegrita = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            titulo,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            valor,
            style: TextStyle(
              color: colorTexto,
              fontWeight: esNegrita ? FontWeight.bold : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  /// Abre la hoja modal emergente para registrar o modificar un aporte de cliente a este instrumento.
  Future<void> _abrirModalNuevoAporte(
    BuildContext context, {
    Transaction? aporteAEditar,
    List<Transaction>? aportesExistentes,
  }) async {
    // Restricción 4: Solo se permite gestionar aportes en estado Borrador
    if (_estado != 'Borrador') {
      AppMessenger.showInfoSnackBar(
        context,
        'Los aportes solo pueden gestionarse mientras el instrumento esté en estado "Borrador"',
      );
      return;
    }

    if (!_esEdicion || widget.instrument == null) {
      AppMessenger.showInfoSnackBar(
        context,
        'Debes registrar el instrumento antes de asociar aportes de clientes',
      );
      return;
    }

    final esModificacion = aporteAEditar != null;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final valorAporteCtrl = TextEditingController(
      text: esModificacion ? aporteAEditar.valor.toStringAsFixed(0) : '',
    );
    final modalFormKey = GlobalKey<FormState>();

    List<Client> clientesDisponibles = [];
    bool cargandoClientes = true;
    Client? clienteSeleccionado;
    bool guardandoAporte = false;
    String? errorCarga;

    await showAppModalBottomSheet(
      context,
      child: StatefulBuilder(
        builder: (modalContext, setModalState) {
          if (cargandoClientes && errorCarga == null) {
            Future.wait([
              _cargarClientesDisponibles(),
              aportesExistentes != null
                  ? Future.value(aportesExistentes)
                  : _cargarTransaccionesAsociadas(),
            ]).then((resultados) {
              if (modalContext.mounted) {
                final todosLosClientes = resultados[0] as List<Client>;
                final txs = resultados[1] as List<Transaction>;
                final instId = widget.instrument!.id;
                final instNum = widget.instrument!.numero;
                final aportesInst = txs.where((t) {
                  final esInversion = t.tipo == TransactionType.inversion;
                  final ref = t.instrumentoId ?? '';
                  return esInversion && (ref == instId || ref == instNum);
                }).toList();

                setModalState(() {
                  if (esModificacion) {
                    // En edición el cliente se mantiene fijo y se precarga su entidad
                    clienteSeleccionado = todosLosClientes.firstWhere(
                      (c) => c.id == aporteAEditar.clienteId,
                      orElse: () => Client(
                        id: aporteAEditar.clienteId,
                        nombre: aporteAEditar.clienteNombre,
                        documento: '',
                        correo: '',
                        telefono: '',
                      ),
                    );
                    clientesDisponibles = [clienteSeleccionado!];
                  } else {
                    // Restricción 1: Un mismo cliente no puede aportar más de una vez por instrumento
                    final idsClientesConAporte =
                        aportesInst.map((t) => t.clienteId).toSet();
                    clientesDisponibles = todosLosClientes
                        .where((c) =>
                            c.estado == 'Activo' &&
                            !idsClientesConAporte.contains(c.id))
                        .toList();
                  }
                  cargandoClientes = false;
                });
              }
            }).catchError((err) {
              if (modalContext.mounted) {
                setModalState(() {
                  errorCarga = 'No fue posible consultar clientes: $err';
                  cargandoClientes = false;
                });
              }
            });
          }

          // Cálculo del disponible real para el aporte:
          // En modificación, se suma el valor actual de este aporte al disponible del cliente.
          final saldoLibre = clienteSeleccionado?.saldoDisponible ?? 0.0;
          final disponibleMaximo = esModificacion
              ? (saldoLibre + aporteAEditar.valor)
              : saldoLibre;

          return Material(
            color: Colors.transparent,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Form(
                key: modalFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Encabezado del modal
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            esModificacion
                                ? Icons.edit_note_rounded
                                : Icons.savings_outlined,
                            color: colorScheme.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                esModificacion
                                    ? 'Modificar Aporte de Inversión'
                                    : 'Nuevo Aporte de Inversión',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Instrumento: ${widget.instrument!.numero}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(modalContext),
                          tooltip: 'Cerrar',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    if (cargandoClientes)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (errorCarga != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          errorCarga!,
                          style: TextStyle(
                            color: colorScheme.error,
                            fontSize: 13,
                          ),
                        ),
                      )
                    else if (!esModificacion && clientesDisponibles.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Todos los clientes activos ya cuentan con un aporte registrado en este instrumento.',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      // 1. Selector o Visualizador de Cliente
                      if (esModificacion)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_rounded,
                                color: colorScheme.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cliente Inversor',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${clienteSeleccionado?.nombre ?? aporteAEditar.clienteNombre}${clienteSeleccionado?.documento.isNotEmpty == true ? " - ${clienteSeleccionado!.documento}" : ""}',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        AppDropdownField<String>(
                          label: 'Cliente Inversor *',
                          hint: 'Selecciona el cliente...',
                          icono: Icons.person_search_rounded,
                          value: clienteSeleccionado?.id,
                          items: clientesDisponibles.map((c) {
                            final docInfo = c.documento.isNotEmpty
                                ? ' - ${c.documento}'
                                : '';
                            return DropdownMenuItem<String>(
                              value: c.id,
                              child: Text(
                                '${c.nombre}$docInfo',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (id) {
                            setModalState(() {
                              clienteSeleccionado = clientesDisponibles
                                  .firstWhere((c) => c.id == id);
                            });
                          },
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Selecciona un cliente';
                            }
                            return null;
                          },
                        ),
                      const SizedBox(height: 14),

                      // 2. Tarjeta Informativa de Saldo Disponible
                      if (clienteSeleccionado != null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: disponibleMaximo > 0
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: disponibleMaximo > 0
                                  ? Colors.green.withValues(alpha: 0.35)
                                  : Colors.amber.shade700,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                disponibleMaximo > 0
                                    ? Icons.account_balance_wallet_outlined
                                    : Icons.warning_amber_rounded,
                                color: disponibleMaximo > 0
                                    ? Colors.green.shade800
                                    : Colors.amber.shade900,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      esModificacion
                                          ? 'Disponible Máximo para este Aporte'
                                          : (disponibleMaximo > 0
                                              ? 'Saldo Disponible del Cliente'
                                              : 'Sin Saldo Disponible'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: disponibleMaximo > 0
                                            ? Colors.green.shade900
                                            : Colors.amber.shade900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatearMoneda(disponibleMaximo),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: disponibleMaximo > 0
                                            ? Colors.green.shade900
                                            : Colors.amber.shade900,
                                      ),
                                    ),
                                    if (esModificacion) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        '(Saldo libre: ${_formatearMoneda(saldoLibre)} + Aporte actual: ${_formatearMoneda(aporteAEditar.valor)})',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // 3. Valor a Invertir
                      AppTextField(
                        controller: valorAporteCtrl,
                        label: 'Valor a Invertir (\$)',
                        hint: 'Ej. 5000000',
                        icono: Icons.attach_money_rounded,
                        tipoTeclado: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Ingresa el valor a invertir';
                          }
                          final monto =
                              double.tryParse(val.replaceAll(',', '.').trim());
                          if (monto == null || monto <= 0) {
                            return 'Ingresa un valor mayor a cero';
                          }
                          if (clienteSeleccionado != null &&
                              monto > disponibleMaximo) {
                            return 'Supera el disponible (${_formatearMoneda(disponibleMaximo)})';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 22),

                      // 4. Botón de Confirmación
                      AppButton(
                        texto: guardandoAporte
                            ? 'Guardando...'
                            : (esModificacion
                                ? 'Actualizar Aporte'
                                : 'Registrar Aporte'),
                        icono: Icons.check_circle_outline_rounded,
                        onPressed: guardandoAporte
                            ? null
                            : () async {
                                if (!modalFormKey.currentState!.validate()) {
                                  return;
                                }
                                if (clienteSeleccionado == null) return;

                                final monto = double.parse(
                                  valorAporteCtrl.text
                                      .replaceAll(',', '.')
                                      .trim(),
                                );

                                setModalState(() => guardandoAporte = true);

                                try {
                                  if (esModificacion) {
                                    final txActualizada =
                                        aporteAEditar.copyWith(
                                      valor: monto,
                                      observacion:
                                          'Aporte a instrumento ${widget.instrument!.numero}',
                                    );

                                    await _ejecutarGuardarAporte(txActualizada);

                                    if (context.mounted) {
                                      Navigator.pop(modalContext);
                                      setState(() {
                                        _transaccionesAsociadasFuture =
                                            _cargarTransaccionesAsociadas();
                                      });
                                      AppMessenger.showSuccessSnackBar(
                                        context,
                                        'Aporte de ${_formatearMoneda(monto)} actualizado para ${clienteSeleccionado!.nombre}',
                                      );
                                    }
                                  } else {
                                    final nuevaTx = Transaction(
                                      id: '',
                                      clienteId: clienteSeleccionado!.id,
                                      clienteNombre:
                                          clienteSeleccionado!.nombre,
                                      tipo: TransactionType.inversion,
                                      valor: monto,
                                      fecha: DateTime.now(),
                                      instrumentoId: widget.instrument!.id,
                                      observacion:
                                          'Aporte a instrumento ${widget.instrument!.numero}',
                                    );

                                    await _ejecutarGuardarAporte(nuevaTx);

                                    if (context.mounted) {
                                      Navigator.pop(modalContext);
                                      setState(() {
                                        _transaccionesAsociadasFuture =
                                            _cargarTransaccionesAsociadas();
                                      });
                                      AppMessenger.showSuccessSnackBar(
                                        context,
                                        'Aporte de ${_formatearMoneda(monto)} registrado para ${clienteSeleccionado!.nombre}',
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (modalContext.mounted) {
                                    setModalState(
                                        () => guardandoAporte = false);
                                    AppMessenger.showErrorSnackBar(
                                      modalContext,
                                      'Error al procesar aporte: $e',
                                    );
                                  }
                                }
                              },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Construye la pestaña 2 (Aportes):
  /// Muestra la lista de clientes que han realizado transacciones de tipo "Inversión" asociadas a este instrumento.
  Widget _buildTabAportes(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final esBorrador = _estado == 'Borrador';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 10.0, bottom: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 20,
                color: colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Aportes de Clientes (Inversión)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Restricción 4: El botón Agregar Aporte solo está disponible en estado Borrador
              if (_esEdicion && esBorrador) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _abrirModalNuevoAporte(context),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Agregar Aporte'),
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Banner informativo si el instrumento no está en estado Borrador
          if (_esEdicion && !esBorrador)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.amber.shade700.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 20,
                    color: Colors.amber.shade900,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'El instrumento está en estado "$_estado". Los aportes solo pueden agregarse, modificarse o eliminarse mientras esté en "Borrador".',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (!_esEdicion)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.25,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Los clientes y sus aportes de inversión se asociarán una vez que el instrumento sea registrado.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            FutureBuilder<List<Transaction>>(
              future: _transaccionesAsociadasFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Error al consultar aportes asociados: ${snapshot.error}',
                      style: TextStyle(
                        color: colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  );
                }

                final todas = snapshot.data ?? [];
                final instId = widget.instrument!.id;
                final instNum = widget.instrument!.numero;

                final inversiones = todas.where((t) {
                  final esInversion = t.tipo == TransactionType.inversion;
                  final ref = t.instrumentoId ?? '';
                  final coincide =
                      ref.isNotEmpty && (ref == instId || ref == instNum);
                  return esInversion && coincide;
                }).toList();

                if (inversiones.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.25,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          color: colorScheme.onSurfaceVariant,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No hay transacciones de inversión vinculadas a este instrumento todavía.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final totalAportado = inversiones.fold<double>(
                  0.0,
                  (sum, tx) => sum + tx.valor,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Resumen general de aportes acumulados
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.35,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Total Aportado (${inversiones.length}):',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _formatearMoneda(totalAportado),
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...inversiones.map((tx) {
                      final inicial = tx.clienteNombre.isNotEmpty
                          ? tx.clienteNombre[0].toUpperCase()
                          : '?';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor:
                                      colorScheme.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  child: Text(
                                    inicial,
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.clienteNombre.isNotEmpty
                                            ? tx.clienteNombre
                                            : 'Cliente',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatearFecha(tx.fecha),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _formatearMoneda(tx.valor),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Controles 2 y 3: Modificar y Eliminar disponibles en estado Borrador
                            if (esBorrador) ...[
                              const SizedBox(height: 6),
                              Divider(
                                height: 1,
                                color:
                                    colorScheme.outline.withValues(alpha: 0.12),
                              ),
                              const SizedBox(height: 2),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  alignment: WrapAlignment.end,
                                  children: [
                                    InkWell(
                                      onTap: () => _abrirModalNuevoAporte(
                                        context,
                                        aporteAEditar: tx,
                                        aportesExistentes: inversiones,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.edit_outlined,
                                              size: 14,
                                              color: colorScheme.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Modificar',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () =>
                                          _confirmarEliminarAporte(context, tx),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.delete_outline_rounded,
                                              size: 14,
                                              color: colorScheme.error,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Eliminar',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: colorScheme.error,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  /// Construye la pestaña 3 (Resultados):
  /// - Resumen Financiero Calculado reactivo (Valor Recibido, Rendimientos Brutos, Retención $, Valor Final Rend.)
  Widget _buildTabResultados(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 10.0, bottom: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ===============================================================
          // BLOQUE FINANCIERO REACTIVO: CÁLCULOS EN TIEMPO REAL
          // ===============================================================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Resumen Financiero Calculado',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 1. Valor Recibido
                _buildFilaMetrica(
                  titulo: 'Valor Recibido:',
                  valor: _formatearMoneda(_valorRecibido),
                  colorTexto: colorScheme.onSurface,
                  esNegrita: true,
                ),
                const Divider(height: 18),

                // 2. Rendimientos
                _buildFilaMetrica(
                  titulo: 'Rendimientos Brutos:',
                  valor: _formatearMoneda(_rendimientos),
                  colorTexto: colorScheme.primary,
                  esNegrita: true,
                ),
                const Divider(height: 18),

                // 3. Retención en Fuente ($)
                _buildFilaMetrica(
                  titulo:
                      'Retención (${_retencionPorcentaje.toStringAsFixed(2)}%):',
                  valor: _formatearMoneda(_retencionValor),
                  colorTexto: colorScheme.error,
                  esNegrita: true,
                ),
                const SizedBox(height: 14),

                // 4. Valor Final Rend. (Destacado)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Valor Final Rend.',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Rendimiento Neto Disponible',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _formatearMoneda(_valorFinalRend),
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
