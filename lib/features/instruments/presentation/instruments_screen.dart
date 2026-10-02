import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:koralis_app/features/auth/domain/entities/user.dart';
import 'package:koralis_app/features/auth/presentation/widgets/forgot_password_form_sheet.dart';
import 'package:koralis_app/features/profile/domain/entities/profile.dart';
import 'package:koralis_app/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:koralis_app/features/profile/data/repositories/profile_repository_impl.dart';
import '../domain/entities/instrument.dart';
import '../domain/usecases/get_instruments_usecase.dart';
import '../domain/usecases/save_instrument_usecase.dart';
import '../domain/repositories/instrument_repository.dart';
import '../data/repositories/instrument_repository_impl.dart';
import 'instrument_form_screen.dart';

/// Pantalla principal para la visualización y gestión de instrumentos financieros.
class InstrumentsScreen extends StatefulWidget {
  final User user;
  final GetInstrumentsUseCase? getInstrumentsUseCase;
  final SaveInstrumentUseCase? saveInstrumentUseCase;
  final GetProfileUseCase? getProfileUseCase;

  const InstrumentsScreen({
    super.key,
    required this.user,
    this.getInstrumentsUseCase,
    this.saveInstrumentUseCase,
    this.getProfileUseCase,
  });

  @override
  State<InstrumentsScreen> createState() => _InstrumentsScreenState();
}

class _InstrumentsScreenState extends State<InstrumentsScreen> {
  static const double _anchoBarraBase = 58.0;

  late final GetInstrumentsUseCase _getInstrumentsUseCase;
  late final GetProfileUseCase _getProfileUseCase;

  Future<List<Instrument>>? _instrumentosFuture;
  Future<Profile>? _profileFuture;

  @override
  void initState() {
    super.initState();
    InstrumentRepository? repo;
    InstrumentRepository obtenerRepositorio() =>
        repo ??= InstrumentRepositoryImpl();

    _getInstrumentsUseCase =
        widget.getInstrumentsUseCase ??
        GetInstrumentsUseCase(obtenerRepositorio());
    _getProfileUseCase =
        widget.getProfileUseCase ?? GetProfileUseCase(ProfileRepositoryImpl());

    _cargarDatos();
  }

  void _cargarDatos() {
    setState(() {
      _instrumentosFuture = _getInstrumentsUseCase.execute();
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

  void _navegarNuevoInstrumento(BuildContext context) async {
    final bool? creado =
        await Navigator.pushNamed(
              context,
              '/instrument_form',
              arguments: InstrumentFormArgs(user: widget.user),
            )
            as bool?;

    if (creado == true) {
      _cargarDatos();
    }
  }

  void _navegarEditarInstrumento(
    BuildContext context,
    Instrument instrumento,
  ) async {
    final bool? editado =
        await Navigator.pushNamed(
              context,
              '/instrument_form',
              arguments: InstrumentFormArgs(
                user: widget.user,
                instrument: instrumento,
              ),
            )
            as bool?;

    if (editado == true) {
      _cargarDatos();
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
          Navigator.pushReplacementNamed(
            context,
            '/clients',
            arguments: widget.user,
          );
        },
      ),
      AppFolderTabItem(
        indice: 1,
        titulo: 'Instrumentos',
        icono: Icons.paid_outlined,
        colorAcento: colorScheme.primary,
        onTap: () {},
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

  void _mostrarFichaRapida(BuildContext context, Instrument instrumento) {
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        instrumento.entidad,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'N° ${instrumento.numero}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppBadge(
                      texto: instrumento.estado,
                      color: instrumento.estado == 'Activo'
                          ? Colors.green
                          : (instrumento.estado == 'Borrador'
                              ? Colors.amber.shade700
                              : Colors.grey.shade600),
                    ),
                    const SizedBox(width: 6),
                    AppBadge(
                      texto:
                          '${instrumento.tasaIea.toStringAsFixed(2)}% I.E.A.',
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            ListTile(
              dense: true,
              leading: const Icon(Icons.date_range_outlined),
              title: const Text('Período de Inversión'),
              subtitle: Text(
                'Apertura: ${_formatearFecha(instrumento.fechaApertura)}  •  Cierre: ${_formatearFecha(instrumento.fechaCierre)} (${instrumento.dias} días)',
              ),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.attach_money_rounded),
              title: const Text('Valor Invertido'),
              subtitle: Text(
                _formatearMoneda(instrumento.valorInvertido),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.call_received_rounded),
              title: const Text('Valor Recibido'),
              subtitle: Text(
                _formatearMoneda(instrumento.valorRecibido),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.trending_up_rounded),
              title: const Text('Rendimientos Brutos'),
              subtitle: Text(_formatearMoneda(instrumento.rendimientos)),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.price_check_rounded),
              title: Text(
                'Retención en la Fuente (${instrumento.retencionPorcentaje.toStringAsFixed(2)}%)',
              ),
              subtitle: Text(
                '- ${_formatearMoneda(instrumento.retencionValor)}',
                style: TextStyle(color: colorScheme.error),
              ),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.verified_rounded),
              title: const Text('Valor Final Rend. (Neto)'),
              subtitle: Text(
                _formatearMoneda(instrumento.valorFinalRend),
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (instrumento.observacion.isNotEmpty)
              ListTile(
                dense: true,
                leading: const Icon(Icons.notes_rounded),
                title: const Text('Observación'),
                subtitle: Text(instrumento.observacion),
              ),
            const SizedBox(height: 14),
            AppButton(
              texto: 'Editar Instrumento',
              icono: Icons.edit_outlined,
              onPressed: () {
                Navigator.pop(context);
                _navegarEditarInstrumento(context, instrumento);
              },
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
        mensajeTooltip: 'Nuevo Instrumento',
        onPressed: () => _navegarNuevoInstrumento(context),
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
                          titulo: 'Instrumentos',
                          onBack: () => Navigator.pushReplacementNamed(
                            context,
                            '/dashboard',
                            arguments: widget.user,
                          ),
                        ),
                        Expanded(
                          child: FutureBuilder<List<Instrument>>(
                            future: _instrumentosFuture,
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
                                    'Error al cargar instrumentos: ${snapshot.error}',
                                    style: TextStyle(color: colorScheme.error),
                                  ),
                                );
                              }

                              final instrumentos = snapshot.data ?? [];

                              if (instrumentos.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.paid_outlined,
                                        size: 64,
                                        color: colorScheme.primary.withValues(
                                          alpha: 0.35,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        'No hay instrumentos registrados',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Presiona el botón (+) para agregar tu primera colocación.',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
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
                                itemCount: instrumentos.length,
                                itemBuilder: (context, index) {
                                  final inst = instrumentos[index];

                                  return AppListCard(
                                    // Título enfocado en la entidad financiera sin el número de instrumento
                                    titulo: inst.entidad.isNotEmpty
                                        ? inst.entidad
                                        : 'Instrumento',
                                    subtitulo:
                                        'Apertura: ${_formatearFecha(inst.fechaApertura)}  •  Cierre: ${_formatearFecha(inst.fechaCierre)}',
                                    detalle:
                                        'Invertido: ${_formatearMoneda(inst.valorInvertido)}  •  Recibido: ${_formatearMoneda(inst.valorRecibido)}',
                                    colorAcento: colorScheme.primary,
                                    fusionarSubtituloSiMultilinea: true,
                                    badge: AppBadge(
                                      texto: inst.estado,
                                      color: inst.estado == 'Activo'
                                          ? Colors.green
                                          : (inst.estado == 'Borrador'
                                              ? Colors.amber.shade700
                                              : Colors.grey.shade600),
                                    ),
                                    pie: Row(
                                      children: [
                                        // Badge indicador de la tasa pactada (% I.E.A.)
                                        AppBadge(
                                          texto:
                                              '${inst.tasaIea.toStringAsFixed(2)}% I.E.A.',
                                          color: colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerRight,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Valor Final Rend: ',
                                                  style: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: colorScheme
                                                            .onSurfaceVariant,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                ),
                                                Text(
                                                  _formatearMoneda(
                                                    inst.valorFinalRend,
                                                  ),
                                                  style: TextStyle(
                                                    color:
                                                        Colors.green.shade800,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () =>
                                        _mostrarFichaRapida(context, inst),
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
}
