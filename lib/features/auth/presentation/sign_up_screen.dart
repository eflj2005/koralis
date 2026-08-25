import 'package:flutter/material.dart';
import 'package:flutter_arc_text/flutter_arc_text.dart';
import 'package:core/core.dart';

/// Pantalla de registro de nuevos usuarios de la aplicación Koralis.
///
/// Contiene la estructura visual del formulario de registro con campos para:
/// - Nombre completo
/// - Fecha de nacimiento
/// - Correo electrónico
/// - Confirmación de correo electrónico
/// - Contraseña
/// - Confirmación de contraseña
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  /// Llave global para la gestión y validación del formulario
  final _formKey = GlobalKey<FormState>();

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

  /// Estado de carga (preparado para cuando se integre la lógica de negocio)
  final bool _cargando = false;

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
        // Formato legible DD/MM/AAAA
        final dia = fechaSeleccionada.day.toString().padLeft(2, '0');
        final mes = fechaSeleccionada.month.toString().padLeft(2, '0');
        final anio = fechaSeleccionada.year;
        _nacimientoController.text = '$dia/$mes/$anio';
      });
    }
  }

  /// Acción al presionar el botón de registro (UI preparada para lógica futura)
  void _onRegistrarsePressed() {
    if (!_formKey.currentState!.validate()) return;

    // Validación visual temporal
    showUnderConstructionDialog(
      context,
      accion: 'Creación de cuenta Koralis',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28.0,
                  vertical: 24.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Encabezado / Logo ---
                      SizedBox(
                        height: 140,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 10),
                              child: Icon(
                                Icons.account_balance_rounded,
                                size: 72,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            ArcText(
                              radius: 55,
                              text: 'K O R A L I S',
                              textStyle:
                                  theme.textTheme.titleLarge?.copyWith(
                                    fontSize: 22,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ) ??
                                  const TextStyle(),
                              startAngle: 0,
                              startAngleAlignment: StartAngleAlignment.center,
                              placement: Placement.outside,
                              direction: Direction.clockwise,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Crear Cuenta',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 26,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Regístrate para gestionar tus instrumentos financieros',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 32),

                      // --- Campo: Nombre completo ---
                      AppTextField(
                        label: 'Nombre completo',
                        hint: 'Ej. Juan Pérez',
                        icono: Icons.person_outline,
                        controller: _nameController,
                        tipoTeclado: TextInputType.text,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),

                      // --- Campo: Fecha de nacimiento con selector ---
                      GestureDetector(
                        onTap: _seleccionarFechaNacimiento,
                        child: AbsorbPointer(
                          child: AppTextField(
                            label: 'Fecha de nacimiento',
                            hint: 'DD/MM/AAAA',
                            icono: Icons.calendar_today_outlined,
                            controller: _nacimientoController,
                            tipoTeclado: TextInputType.datetime,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- Campo: Correo electrónico ---
                      AppTextField(
                        label: 'Correo electrónico',
                        hint: 'ejemplo@correo.com',
                        icono: Icons.email_outlined,
                        controller: _emailController,
                        tipoTeclado: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // --- Campo: Confirmar correo electrónico ---
                      AppTextField(
                        label: 'Confirmar correo electrónico',
                        hint: 'ejemplo@correo.com',
                        icono: Icons.mark_email_read_outlined,
                        controller: _confirmEmailController,
                        tipoTeclado: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // --- Campo: Contraseña ---
                      AppTextField(
                        label: 'Contraseña',
                        hint: '••••••••',
                        icono: Icons.lock_outlined,
                        controller: _passwordController,
                        esOscuro: true,
                      ),
                      const SizedBox(height: 16),

                      // --- Campo: Confirmar contraseña ---
                      AppTextField(
                        label: 'Confirmar contraseña',
                        hint: '••••••••',
                        icono: Icons.lock_reset_outlined,
                        controller: _confirmPasswordController,
                        esOscuro: true,
                      ),
                      const SizedBox(height: 28),

                      // --- Botón principal: Registrarse ---
                      AppButton(
                        texto: 'Registrarse',
                        icono: Icons.person_add_alt_1,
                        onPressed: _onRegistrarsePressed,
                      ),
                      const SizedBox(height: 20),

                      // --- Enlace: Volver a Iniciar Sesión ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('¿Ya tienes una cuenta?'),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Inicia sesión'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // --- Overlay de carga visual si está activo ---
          if (_cargando) const LoadingWidget(),
        ],
      ),
    );
  }
}
