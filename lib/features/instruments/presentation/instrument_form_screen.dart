import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:core/core.dart' hide Transaction;
import 'package:provider/provider.dart';
import 'package:koralis_app/features/auth/domain/entities/user.dart';
import 'package:koralis_app/features/auth/presentation/widgets/forgot_password_form_sheet.dart';
import 'package:koralis_app/features/profile/domain/entities/profile.dart';
import 'package:koralis_app/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:koralis_app/features/profile/presentation/viewmodels/profile_view_model.dart';
import 'package:koralis_app/features/clients/domain/entities/client.dart';
import 'package:koralis_app/features/clients/domain/usecases/get_clients_usecase.dart';
import 'package:koralis_app/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:koralis_app/features/transactions/domain/usecases/save_transaction_usecase.dart';
import 'package:koralis_app/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import '../domain/entities/instrument.dart';
import '../domain/usecases/save_instrument_usecase.dart';
import '../domain/usecases/process_instrument_save_usecase.dart';
import '../domain/usecases/get_banks_usecase.dart';
import 'viewmodels/instrument_form_view_model.dart';

/// Argumentos para la navegación hacia la pantalla de formulario de instrumento.
class InstrumentFormArgs {
  final User user;
  final Instrument? instrument;

  const InstrumentFormArgs({required this.user, this.instrument});
}

/// Pantalla independiente para la creación y edición de instrumentos financieros (arquitectura MVVM con `provider`).
class InstrumentFormScreen extends StatelessWidget {
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
    final tieneFormVm = _tieneProvider<InstrumentFormViewModel>(context);
    final tieneProfileVm = _tieneProvider<ProfileViewModel>(context);

    if (tieneFormVm && tieneProfileVm) {
      return _InstrumentFormView(user: user);
    }

    return MultiProvider(
      providers: [
        if (!tieneFormVm)
          ChangeNotifierProvider<InstrumentFormViewModel>(
            create: (_) => InstrumentFormViewModel(
              userId: user.id,
              instrumentInicial: instrument,
              saveInstrumentUseCase: saveInstrumentUseCase,
              getBanksUseCase: getBanksUseCase,
              getTransactionsUseCase: getTransactionsUseCase,
              getClientsUseCase: getClientsUseCase,
              saveTransactionUseCase: saveTransactionUseCase,
              deleteTransactionUseCase: deleteTransactionUseCase,
            ),
          ),
        if (!tieneProfileVm)
          ChangeNotifierProvider<ProfileViewModel>(
            create: (_) => ProfileViewModel(
              getProfileUseCase: getProfileUseCase,
            ),
          ),
      ],
      child: _InstrumentFormView(user: user),
    );
  }
}

class _InstrumentFormView extends StatefulWidget {
  final User user;

  const _InstrumentFormView({required this.user});

  @override
  State<_InstrumentFormView> createState() => _InstrumentFormViewState();
}

class _InstrumentFormViewState extends State<_InstrumentFormView> {
  static const double _anchoBarraBase = 58.0;

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _numeroCtrl;
  late final TextEditingController _entidadCtrl;
  late final TextEditingController _diasCtrl;
  late final TextEditingController _tasaIeaCtrl;
  late final TextEditingController _valorInvertidoCtrl;
  late final TextEditingController _rendimientoTProyecCtrl;
  late final TextEditingController _retencionPorcentajeCtrl;
  late final TextEditingController _observacionCtrl;

  @override
  void initState() {
    super.initState();
    final vm = context.read<InstrumentFormViewModel>();
    final actual = vm.instrumentInicial;

    _numeroCtrl = TextEditingController(text: actual?.numero ?? '');
    _entidadCtrl = TextEditingController(text: actual?.entidad ?? '');
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
      text: actual != null ? actual.retencionPorcentaje.toStringAsFixed(2) : '4.00',
    );
    _observacionCtrl = TextEditingController(text: actual?.observacion ?? '');

    _diasCtrl.addListener(_sincronizarCalculos);
    _valorInvertidoCtrl.addListener(_sincronizarCalculos);
    _rendimientoTProyecCtrl.addListener(_sincronizarCalculos);
    _retencionPorcentajeCtrl.addListener(_sincronizarCalculos);

    Future.microtask(() {
      if (!mounted) return;
      context.read<InstrumentFormViewModel>().inicializar();
      context.read<ProfileViewModel>().cargarPerfil(widget.user.id);
    });
  }

  void _sincronizarCalculos() {
    if (!mounted) return;
    context.read<InstrumentFormViewModel>().actualizarCalculos(
          dias: int.tryParse(_diasCtrl.text.trim()) ?? 0,
          valorInvertido:
              double.tryParse(_valorInvertidoCtrl.text.replaceAll(',', '.').trim()) ??
                  0.0,
          rendimientoTProyec: double.tryParse(
                _rendimientoTProyecCtrl.text.replaceAll(',', '.').trim(),
              ) ??
              0.0,
          retencionPorcentaje: double.tryParse(
                _retencionPorcentajeCtrl.text.replaceAll(',', '.').trim(),
              ) ??
              0.0,
        );
  }

  @override
  void dispose() {
    _diasCtrl.removeListener(_sincronizarCalculos);
    _valorInvertidoCtrl.removeListener(_sincronizarCalculos);
    _rendimientoTProyecCtrl.removeListener(_sincronizarCalculos);
    _retencionPorcentajeCtrl.removeListener(_sincronizarCalculos);

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

  Future<void> _seleccionarFechaApertura(
    BuildContext context,
    InstrumentFormViewModel vm,
  ) async {
    final DateTime? seleccionada = await showDatePicker(
      context: context,
      initialDate: vm.fechaApertura,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Seleccionar Fecha de Apertura',
    );
    if (seleccionada != null && seleccionada != vm.fechaApertura) {
      vm.seleccionarFechaApertura(seleccionada);
    }
  }

  List<DropdownMenuItem<String>> _generarItemsBancos(
    InstrumentFormViewModel vm,
  ) {
    final valorActual = _entidadCtrl.text.trim();
    final items = <DropdownMenuItem<String>>[];

    if (valorActual.isNotEmpty &&
        !vm.bancos.any((b) => b.nombre == valorActual)) {
      items.add(
        DropdownMenuItem<String>(
          value: valorActual,
          child: Text(valorActual, overflow: TextOverflow.ellipsis),
        ),
      );
    }

    for (final banco in vm.bancos) {
      items.add(
        DropdownMenuItem<String>(
          value: banco.nombre,
          child: Text(banco.nombre, overflow: TextOverflow.ellipsis),
        ),
      );
    }

    return items;
  }

  Future<bool> _confirmarReversionABorrador(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.undo_rounded,
              color: Colors.amber.shade800,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Revertir a Borrador',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: const Text(
          'Al regresar este instrumento a estado "Borrador", se eliminarán automáticamente '
          'las transacciones de inversión generadas y se reintegrará el saldo disponible a los clientes.\n\n'
          'Los aportes se conservarán en borrador para que puedas ajustarlos antes de volver a activar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.amber.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Confirmar Reversión'),
          ),
        ],
      ),
    );
    return confirmar == true;
  }

  Future<void> _mostrarDialogoSaldoInsuficiente(
    BuildContext context,
    InsufficientBalanceException error,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Saldo Insuficiente para Activar',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'No es posible activar el instrumento porque uno o más clientes no cuentan con saldo disponible suficiente:',
              ),
              const SizedBox(height: 12),
              ...error.faltantes.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.clienteNombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          f.clienteNoEncontrado
                              ? 'El cliente ya no existe o no está disponible.'
                              : 'Aporte requerido: ${_formatearMoneda(f.montoRequerido)}\nDisponible actual: ${_formatearMoneda(f.saldoDisponible)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarInstrumento(InstrumentFormViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;

    if (vm.requiereConfirmacionReversion) {
      final confirmado = await _confirmarReversionABorrador(context);
      if (!confirmado || !mounted) return;
    }

    try {
      final resultado = await vm.guardarInstrumento(
        numero: _numeroCtrl.text,
        entidad: _entidadCtrl.text,
        tasaIea:
            double.tryParse(_tasaIeaCtrl.text.replaceAll(',', '.').trim()) ?? 0.0,
        observacion: _observacionCtrl.text,
      );

      if (!mounted) return;
      final numero = resultado.instrumentoGuardado.numero;
      final String mensaje;
      if (resultado.transaccionesGeneradas > 0) {
        mensaje =
            'Instrumento "$numero" activado con ${resultado.transaccionesGeneradas} transacción(es) de inversión';
      } else if (resultado.transaccionesReversadas > 0) {
        mensaje =
            'Instrumento "$numero" revertido a Borrador y ${resultado.transaccionesReversadas} transacción(es) reintegrada(s)';
      } else {
        mensaje = vm.esEdicion
            ? 'Instrumento "$numero" actualizado correctamente'
            : 'Instrumento "$numero" creado exitosamente';
      }
      AppMessenger.showSuccessSnackBar(context, mensaje);
      Navigator.pop(context, true);
    } on InsufficientBalanceException catch (e) {
      if (mounted) {
        await _mostrarDialogoSaldoInsuficiente(context, e);
      }
    } on InvalidInstrumentStateTransitionException catch (e) {
      if (mounted) {
        AppMessenger.showInfoSnackBar(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        AppMessenger.showErrorSnackBar(
          context,
          'No fue posible guardar el instrumento: $e',
        );
      }
    }
  }

  /// Solicita confirmación y elimina un aporte en estado Borrador sin afectar saldos.
  Future<void> _confirmarEliminarAporte(
    BuildContext context,
    InstrumentFormViewModel vm,
    InstrumentContribution aporte,
  ) async {
    if (!vm.puedeGestionarAportes) {
      AppMessenger.showInfoSnackBar(
        context,
        'Los aportes solo pueden eliminarse mientras el instrumento esté guardado en estado "Borrador"',
      );
      return;
    }

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
                'Eliminar Aporte',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de eliminar el aporte de ${_formatearMoneda(aporte.valor)} perteneciente a ${aporte.clienteNombre}?\n\n'
          'El aporte está en borrador y aún no ha afectado el saldo disponible del cliente.',
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
        await vm.eliminarAporteEnBorrador(aporte.clienteId);
        if (mounted) {
          AppMessenger.showSuccessSnackBar(
            this.context,
            'Aporte de ${_formatearMoneda(aporte.valor)} eliminado correctamente',
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

  /// Abre la hoja modal emergente para registrar o modificar un aporte en borrador (sin descontar saldo aún).
  Future<void> _abrirModalNuevoAporte(
    BuildContext context,
    InstrumentFormViewModel vm, {
    InstrumentContribution? aporteAEditar,
  }) async {
    if (!vm.puedeGestionarAportes) {
      AppMessenger.showInfoSnackBar(
        context,
        'Los aportes solo pueden gestionarse mientras el instrumento esté guardado en estado "Borrador"',
      );
      return;
    }

    if (!vm.esEdicion || vm.instrumentInicial == null) {
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
    bool consultaIniciada = false;
    Client? clienteSeleccionado;
    bool guardandoAporte = false;
    String? errorCarga;

    await showAppModalBottomSheet(
      context,
      child: StatefulBuilder(
        builder: (modalContext, setModalState) {
          if (!consultaIniciada && cargandoClientes && errorCarga == null) {
            consultaIniciada = true;
            vm.cargarClientesDisponibles().then((todosLosClientes) {
              if (modalContext.mounted) {
                setModalState(() {
                  if (esModificacion) {
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
                    final idsClientesConAporte =
                        vm.aportes.map((a) => a.clienteId).toSet();
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

          final disponibleMaximo = clienteSeleccionado?.saldoDisponible ?? 0.0;

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
                                'Instrumento: ${vm.instrumentInicial!.numero}',
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
                          value: clientesDisponibles
                                  .any((c) => c.id == clienteSeleccionado?.id)
                              ? clienteSeleccionado?.id
                              : null,
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
                                  .cast<Client?>()
                                  .firstWhere(
                                    (c) => c?.id == id,
                                    orElse: () => null,
                                  );
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
                                        '(Aporte actual en borrador: ${_formatearMoneda(aporteAEditar.valor)} • aún no descontado)',
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
                                  await vm.guardarAporteEnBorrador(
                                    cliente: clienteSeleccionado!,
                                    monto: monto,
                                    aporteAEditar: aporteAEditar,
                                  );

                                  if (context.mounted) {
                                    Navigator.pop(modalContext);
                                    AppMessenger.showSuccessSnackBar(
                                      context,
                                      esModificacion
                                          ? 'Aporte de ${_formatearMoneda(monto)} actualizado para ${clienteSeleccionado!.nombre}'
                                          : 'Aporte de ${_formatearMoneda(monto)} registrado en borrador para ${clienteSeleccionado!.nombre}',
                                    );
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
                  backgroundImage: (profile?.avatarPath != null &&
                          profile!.avatarPath.isNotEmpty)
                      ? AssetImage(profile.avatarPath)
                      : null,
                  child: (profile?.avatarPath == null ||
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
    final vm = context.watch<InstrumentFormViewModel>();
    final profileVm = context.watch<ProfileViewModel>();
    final profile = profileVm.profile;
    final imageProvider =
        (profile?.avatarPath != null && profile!.avatarPath.isNotEmpty)
            ? AssetImage(profile.avatarPath) as ImageProvider
            : null;

    return PopScope(
      canPop: !vm.huboCambiosPersistidos,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, true);
        }
      },
      child: Scaffold(
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
                            titulo: vm.esEdicion
                                ? 'Editar Instrumento'
                                : 'Nuevo Instrumento',
                            onBack: () =>
                                Navigator.pop(context, vm.huboCambiosPersistidos),
                          ),
                          Expanded(
                            child: DefaultTabController(
                              length: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
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
                                  Expanded(
                                    child: TabBarView(
                                      physics: const BouncingScrollPhysics(),
                                      children: [
                                        _buildTabGeneralidades(
                                          context,
                                          vm: vm,
                                          theme: theme,
                                          colorScheme: colorScheme,
                                        ),
                                        _buildTabAportes(context, vm),
                                        _buildTabResultados(context, vm),
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
              AppSidebarNavigation(
                anchoBarra: _anchoBarraBase,
                insigniaFlotante: AppFloatingProfileBadge(
                  proveedorImagen: imageProvider,
                  onTap: () => _mostrarMenuPerfil(context, profile),
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
      ),
    );
  }

  Widget _buildTabGeneralidades(
    BuildContext context, {
    required InstrumentFormViewModel vm,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 10.0, bottom: 40.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: AppDropdownField<String>(
                    label: 'Entidad Financiera',
                    hint: vm.cargandoBancos ? 'Cargando...' : 'Selecciona',
                    icono: Icons.account_balance_outlined,
                    isLoading: vm.cargandoBancos,
                    value:
                        _entidadCtrl.text.isNotEmpty ? _entidadCtrl.text : null,
                    items: _generarItemsBancos(vm),
                    onChanged: (nuevaEntidad) {
                      setState(() {
                        _entidadCtrl.text = nuevaEntidad ?? '';
                      });
                    },
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Selecciona la entidad';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: AppTextField(
                    controller: _diasCtrl,
                    label: 'Plazo (Días)',
                    hint: 'Ej. 90',
                    icono: Icons.timelapse_rounded,
                    tipoTeclado: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Requerido';
                      }
                      final dias = int.tryParse(val.trim());
                      if (dias == null || dias <= 0 || dias > 999) {
                        return 'Máx 3 dígitos';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _seleccionarFechaApertura(context, vm),
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Fecha Apertura',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 10, right: 4),
                          child: Icon(Icons.calendar_today_outlined, size: 20),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 40,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                      ),
                      child: Text(
                        _formatearFecha(vm.fechaApertura),
                        style: TextStyle(color: colorScheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Fecha Cierre',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 10, right: 4),
                        child: Icon(
                          Icons.event_available_rounded,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 40,
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
                      _formatearFecha(vm.fechaCierre),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: AppTextField(
                    controller: _valorInvertidoCtrl,
                    label: 'Valor Invertido (\$)',
                    hint: 'Ej. 50000000',
                    icono: Icons.attach_money_rounded,
                    tipoTeclado: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (val) {
                      if (val == null ||
                          double.tryParse(val.replaceAll(',', '.').trim()) ==
                              null) {
                        return 'Ingresa el capital invertido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    controller: _tasaIeaCtrl,
                    label: '% Tasa I.E.A.',
                    hint: 'Ej. 11.50',
                    icono: Icons.percent_rounded,
                    tipoTeclado: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (val) {
                      if (val == null ||
                          double.tryParse(val.replaceAll(',', '.').trim()) ==
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: AppTextField(
                    controller: _rendimientoTProyecCtrl,
                    label: 'Rendimiento T. Proyec. (\$)',
                    hint: 'Ej. 2500000',
                    icono: Icons.trending_up_rounded,
                    tipoTeclado: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (val) {
                      if (val == null ||
                          double.tryParse(val.replaceAll(',', '.').trim()) ==
                              null) {
                        return 'Ingresa el rendimiento proyectado';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    controller: _retencionPorcentajeCtrl,
                    label: 'Retención %',
                    hint: '4.00',
                    icono: Icons.price_check_rounded,
                    tipoTeclado: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
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
                      _buildBotonEstado(
                        vm: vm,
                        valorEstado: 'Borrador',
                        colorActivo: Colors.amber,
                        colorTextoActivo: Colors.amber.shade800,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(width: 8),
                      _buildBotonEstado(
                        vm: vm,
                        valorEstado: 'Activo',
                        colorActivo: Colors.green,
                        colorTextoActivo: Colors.green.shade800,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(width: 8),
                      _buildBotonEstado(
                        vm: vm,
                        valorEstado: 'Cerrado',
                        colorActivo: Colors.grey,
                        colorTextoActivo: Colors.grey.shade800,
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _observacionCtrl,
              label: 'Observación',
              hint: 'Comentarios sobre la colocación o condiciones...',
              icono: Icons.notes_rounded,
              tipoTeclado: TextInputType.multiline,
              minLines: 2,
              maxLines: 2,
            ),
            const SizedBox(height: 28),
            AppButton(
              texto: vm.guardando
                  ? 'Guardando...'
                  : (vm.esEdicion
                      ? 'Guardar Cambios'
                      : 'Registrar Instrumento'),
              icono: Icons.check_circle_outline_rounded,
              onPressed:
                  vm.guardando ? null : () => _guardarInstrumento(vm),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonEstado({
    required InstrumentFormViewModel vm,
    required String valorEstado,
    required Color colorActivo,
    required Color colorTextoActivo,
    required ColorScheme colorScheme,
  }) {
    final seleccionado = vm.estado == valorEstado;
    return Expanded(
      child: InkWell(
        onTap: () => vm.seleccionarEstado(valorEstado),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: seleccionado
                ? colorActivo.withValues(alpha: 0.18)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: seleccionado ? colorActivo : Colors.transparent,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            valorEstado,
            style: TextStyle(
              color:
                  seleccionado ? colorTextoActivo : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
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

  Widget _buildListaAportesVisual({
    required BuildContext context,
    required InstrumentFormViewModel vm,
    required List<InstrumentContribution> aportes,
    required bool puedeGestionar,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (aportes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
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
                vm.estadoPersistido == 'Borrador'
                    ? 'No hay aportes registrados en este instrumento todavía.'
                    : 'No hay transacciones de inversión vinculadas a este instrumento todavía.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final totalAportado = aportes.fold<double>(0.0, (sum, a) => sum + a.valor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Total Aportado (${aportes.length}):',
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
        ...aportes.map((aporte) {
          final inicial = aporte.clienteNombre.isNotEmpty
              ? aporte.clienteNombre[0].toUpperCase()
              : '?';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                          colorScheme.primary.withValues(alpha: 0.15),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            aporte.clienteNombre.isNotEmpty
                                ? aporte.clienteNombre
                                : 'Cliente',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatearFecha(aporte.fecha),
                            style: theme.textTheme.bodySmall?.copyWith(
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
                        _formatearMoneda(aporte.valor),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                if (puedeGestionar) ...[
                  const SizedBox(height: 6),
                  Divider(
                    height: 1,
                    color: colorScheme.outline.withValues(alpha: 0.12),
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
                            vm,
                            aporteAEditar: aporte,
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
                              _confirmarEliminarAporte(context, vm, aporte),
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
  }

  Widget _buildTabAportes(BuildContext context, InstrumentFormViewModel vm) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final esBorradorSeleccionado = vm.estado == 'Borrador';
    final puedeGestionarAportes = vm.puedeGestionarAportes;

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
              if (puedeGestionarAportes) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _abrirModalNuevoAporte(context, vm),
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
          if (puedeGestionarAportes)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Los aportes en Borrador no descuentan el saldo del cliente hasta guardar el instrumento en estado "Activo".',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (vm.esEdicion &&
              esBorradorSeleccionado &&
              vm.estadoPersistido != 'Borrador')
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
                    Icons.save_outlined,
                    size: 20,
                    color: Colors.amber.shade900,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Guarda el cambio de estado a "Borrador" en la pestaña Generalidades para reversar las transacciones y habilitar la edición de aportes.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (vm.esEdicion && !esBorradorSeleccionado)
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
                      'El instrumento está en estado "${vm.estado}". Los aportes solo pueden agregarse, modificarse o eliminarse mientras esté en "Borrador".',
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
          if (!vm.esEdicion)
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
            _buildListaAportesVisual(
              context: context,
              vm: vm,
              aportes: vm.aportes,
              puedeGestionar: puedeGestionarAportes,
            ),
        ],
      ),
    );
  }

  Widget _buildTabResultados(BuildContext context, InstrumentFormViewModel vm) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 10.0, bottom: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                _buildFilaMetrica(
                  titulo: 'Valor Recibido:',
                  valor: _formatearMoneda(vm.valorRecibido),
                  colorTexto: colorScheme.onSurface,
                  esNegrita: true,
                ),
                const Divider(height: 18),
                _buildFilaMetrica(
                  titulo: 'Rendimientos Brutos:',
                  valor: _formatearMoneda(vm.rendimientos),
                  colorTexto: colorScheme.primary,
                  esNegrita: true,
                ),
                const Divider(height: 18),
                _buildFilaMetrica(
                  titulo:
                      'Retención (${vm.retencionPorcentaje.toStringAsFixed(2)}%):',
                  valor: _formatearMoneda(vm.retencionValor),
                  colorTexto: colorScheme.error,
                  esNegrita: true,
                ),
                const SizedBox(height: 14),
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
                          _formatearMoneda(vm.valorFinalRend),
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
