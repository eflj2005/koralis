import 'package:flutter/material.dart';
import 'package:flutter_arc_text/flutter_arc_text.dart';
import 'package:core/core.dart';
import '../domain/usecases/login_usecase.dart';
import '../data/repositories/auth_repository_impl.dart';

/// Pantalla de inicio de sesión.
/// Solo contiene estructura visual, sin lógica de autenticación funcional.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginUseCase _loginUseCase;

  @override
  void initState() {
    super.initState();
    // Instancia manual temporal (idealmente usar Inyección de Dependencias como get_it)
    _loginUseCase = LoginUseCase(AuthRepositoryImpl());
  }

  /// Controlador para el campo de correo electrónico
  final TextEditingController _emailController = TextEditingController();

  /// Controlador para el campo de contraseña
  final TextEditingController _passwordController = TextEditingController();

  /// Llave del formulario para validación
  final _formKey = GlobalKey<FormState>();

  /// Indica si el proceso de carga está activo
  bool _cargando = false;

  @override
  void dispose() {
    // Liberar recursos de los controladores al destruir el widget
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Ejecuta el proceso de inicio de sesión llamando al caso de uso
  void _onIngresarPressed() async {
    // Validar formulario primero
    if (!_formKey.currentState!.validate()) return;

    // Evitar doble activación si ya está cargando
    if (_cargando) return;

    setState(() => _cargando = true);

    try {
      final email = _emailController.text;
      final password = _passwordController.text;

      // Llamada a la capa de dominio
      final user = await _loginUseCase.execute(email, password);

      if (!mounted) return;

      // Navegar a Dashboard usando la ruta nombrada y pasando el usuario como argumento
      Navigator.pushReplacementNamed(context, '/dashboard', arguments: user);
    } catch (e) {
      if (!mounted) return;
      final mensajeError = AppErrorHandler.parseMessage(e);
      AppMessenger.showErrorSnackBar(context, mensajeError);
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
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
                                Icons.pets,
                                size: 72,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            ArcText(
                              radius: 55,
                              text: 'P E T   C A R E',
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
                        'Bienvenido',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 26,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ingresa tus credenciales para continuar',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 40),

                      // --- Campo: Correo electrónico ---
                      AppTextField(
                        label: 'Correo electrónico',
                        hint: 'ejemplo@correo.com',
                        icono: Icons.email_outlined,
                        controller: _emailController,
                        tipoTeclado: TextInputType.emailAddress,
                        validator: CoreValidators.email,
                      ),
                      const SizedBox(height: 16),

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

                      // --- Enlace: ¿Olvidaste tu contraseña? ---
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            showUnderConstructionDialog(
                              context,
                              accion: 'Recuperar contraseña',
                            );
                          },
                          child: const Text('¿Olvidaste tu contraseña?'),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- Botón principal: Ingresar ---
                      AppButton(
                        texto: 'Ingresar',
                        icono: Icons.login,
                        onPressed: _onIngresarPressed,
                      ),
                      const SizedBox(height: 16),

                      // --- Enlace: Registrarse ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('¿No tienes cuenta?'),
                          TextButton(
                            onPressed: () {
                              showUnderConstructionDialog(
                                context,
                                accion: 'Registro de usuario',
                              );
                            },
                            child: const Text('Regístrate'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // --- Overlay de carga: visible solo cuando _cargando es true ---
          if (_cargando) const LoadingWidget(),
        ],
      ),
    );
  }
}
