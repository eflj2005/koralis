import 'package:flutter/material.dart';
import 'package:core/core.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../data/repositories/auth_repository_impl.dart';

/// Formulario interactivo de registro de nuevos usuarios de Koralis,
/// diseñado para ser renderizado dentro de un modal emergente [AppModalBottomSheet].
class SignUpFormSheet extends StatefulWidget {
  const SignUpFormSheet({super.key});

  @override
  State<SignUpFormSheet> createState() => _SignUpFormSheetState();
}

class _SignUpFormSheetState extends State<SignUpFormSheet> {
  /// Llave global para la gestión y validación del formulario
  final _formKey = GlobalKey<FormState>();

  /// Caso de uso de registro
  late final SignUpUseCase _signUpUseCase;

  /// Controlador para el campo de nombre completo
  final TextEditingController _nameController = TextEditingController();

  /// Controlador para el campo de fecha de nacimiento
  final TextEditingController _nacimientoController = TextEditingController();

  /// Controlador para el campo de correo electrónico
  final TextEditingController _emailController = TextEditingController();

  /// Controlador para el campo de confirmación de correo electrónico
  final TextEditingController _confirmEmailController =
      TextEditingController();

  /// Controlador para el campo de contraseña
  final TextEditingController _passwordController = TextEditingController();

  /// Controlador para el campo de confirmación de contraseña
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  /// Fecha de nacimiento seleccionada
  DateTime? _selectedBirthDate;

  /// Mensaje de error visible dentro del modal
  String? _errorMensaje;

  /// Indica si hay una operación de registro en progreso
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _signUpUseCase = SignUpUseCase(AuthRepositoryImpl());
  }

  @override
  void dispose() {
    // Liberación de recursos de los controladores
    _nameController.dispose();
    _nacimientoController.dispose();
    _emailController.dispose();
    _confirmEmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Despliega el selector de fecha (DatePicker) para elegir la fecha de nacimiento
  Future<void> _seleccionarFechaNacimiento() async {
    final DateTime ahora = DateTime.now();
    final DateTime fechaInicial =
        _selectedBirthDate ?? DateTime(ahora.year - 25, ahora.month, ahora.day);

    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: fechaInicial,
      firstDate: DateTime(1930),
      lastDate: ahora,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Selecciona tu fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (fechaSeleccionada != null) {
      setState(() {
        _selectedBirthDate = fechaSeleccionada;
        _errorMensaje = null;
        // Formato legible DD/MM/AAAA
        final dia = fechaSeleccionada.day.toString().padLeft(2, '0');
        final mes = fechaSeleccionada.month.toString().padLeft(2, '0');
        final anio = fechaSeleccionada.year;
        _nacimientoController.text = '$dia/$mes/$anio';
      });
    }
  }

  /// Ejecuta el proceso de registro validando credenciales y creando registros en Firebase
  Future<void> _onRegistrarsePressed() async {
    setState(() => _errorMensaje = null);

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _errorMensaje = 'Por favor completa y corrige los campos señalados.';
      });
      return;
    }

    if (_cargando) return;

    setState(() => _cargando = true);

    try {
      final correoRegistrado = _emailController.text.trim();

      // 1. Ejecutar el registro en Firebase Auth y Firestore (envía correo de confirmación y cierra sesión)
      await _signUpUseCase.execute(
        nombre: _nameController.text.trim(),
        correo: correoRegistrado,
        contrasena: _passwordController.text,
        nacimiento: _nacimientoController.text.trim(),
      );

      if (!mounted) return;

      // 2. Cerrar el modal emergente de registro retornando el correo registrado
      Navigator.of(context).pop(correoRegistrado);
    } catch (e) {
      if (!mounted) return;
      final mensajeError = AppErrorHandler.parseMessage(e);
      setState(() {
        _errorMensaje = mensajeError;
      });
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Encabezado con título y botón de cierre ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person_add_alt_1_rounded,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Crear Cuenta',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Cerrar',
                    onPressed: _cargando
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Ingresa tus datos para registrarte en Koralis',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              // --- Banner de error visible en el modal ---
              if (_errorMensaje != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: theme.colorScheme.onErrorContainer,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMensaje!,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // --- Campo: Nombre completo ---
              AppTextField(
                label: 'Nombre completo',
                hint: 'Ej. Juan Pérez',
                icono: Icons.person_outline,
                controller: _nameController,
                tipoTeclado: TextInputType.text,
                textCapitalization: TextCapitalization.words,
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'El nombre completo es obligatorio';
                  }
                  if (valor.trim().length < 3) {
                    return 'Ingrese un nombre válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // --- Campo: Fecha de nacimiento con selector ---
              GestureDetector(
                onTap: _cargando ? null : _seleccionarFechaNacimiento,
                child: AbsorbPointer(
                  child: AppTextField(
                    label: 'Fecha de nacimiento',
                    hint: 'DD/MM/AAAA',
                    icono: Icons.calendar_today_outlined,
                    controller: _nacimientoController,
                    tipoTeclado: TextInputType.datetime,
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return 'Seleccione su fecha de nacimiento';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // --- Campo: Correo electrónico ---
              AppTextField(
                label: 'Correo electrónico',
                hint: 'ejemplo@correo.com',
                icono: Icons.email_outlined,
                controller: _emailController,
                tipoTeclado: TextInputType.emailAddress,
                validator: CoreValidators.email,
              ),
              const SizedBox(height: 12),

              // --- Campo: Confirmar correo electrónico ---
              AppTextField(
                label: 'Confirmar correo electrónico',
                hint: 'ejemplo@correo.com',
                icono: Icons.mark_email_read_outlined,
                controller: _confirmEmailController,
                tipoTeclado: TextInputType.emailAddress,
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Confirme su correo electrónico';
                  }
                  if (valor.trim() != _emailController.text.trim()) {
                    return 'Los correos electrónicos no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // --- Campo: Contraseña ---
              AppTextField(
                label: 'Contraseña',
                hint: '••••••••',
                icono: Icons.lock_outlined,
                controller: _passwordController,
                esOscuro: true,
                validator: CoreValidators.password,
              ),
              const SizedBox(height: 12),

              // --- Campo: Confirmar contraseña ---
              AppTextField(
                label: 'Confirmar contraseña',
                hint: '••••••••',
                icono: Icons.lock_reset_outlined,
                controller: _confirmPasswordController,
                esOscuro: true,
                validator: (valor) {
                  if (valor == null || valor.isEmpty) {
                    return 'Confirme su contraseña';
                  }
                  if (valor != _passwordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // --- Botón principal: Registrarse ---
              AppButton(
                texto: 'Registrarse',
                icono: Icons.person_add_alt_1,
                onPressed: _cargando ? null : _onRegistrarsePressed,
              ),
              const SizedBox(height: 12),

              // --- Enlace: Cancelar / Iniciar sesión ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('¿Ya tienes una cuenta?'),
                  TextButton(
                    onPressed: _cargando
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Inicia sesión'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // --- Overlay de carga mientras se crea el usuario ---
        if (_cargando)
          const Positioned.fill(
            child: LoadingWidget(),
          ),
      ],
    );
  }
}

/// Función helper para abrir el formulario de registro en el modal emergente genérico.
Future<String?> showSignUpModalBottomSheet(BuildContext context) {
  return showAppModalBottomSheet<String>(
    context,
    child: const SignUpFormSheet(),
  );
}
