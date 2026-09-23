import 'package:flutter/material.dart';
import 'package:flutter_arc_text/flutter_arc_text.dart';
import 'package:core/core.dart';
import '../domain/usecases/login_usecase.dart';
import '../domain/usecases/resend_email_verification_usecase.dart';
import '../data/repositories/auth_repository_impl.dart';
import 'widgets/sign_up_form_sheet.dart';
import 'widgets/forgot_password_form_sheet.dart';

/// Pantalla de inicio de sesión de la aplicación Koralis con validación obligatoria de correo verificado.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// Caso de uso para inicio de sesión
  late final LoginUseCase _loginUseCase;

  /// Caso de uso para reenvío de correo de confirmación
  late final ResendEmailVerificationUseCase _resendVerificationUseCase;

  @override
  void initState() {
    super.initState();
    final authRepository = AuthRepositoryImpl();
    _loginUseCase = LoginUseCase(authRepository);
    _resendVerificationUseCase = ResendEmailVerificationUseCase(authRepository);
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

    // Limpiar notificaciones previas en pantalla
    AppMessenger.clear(context);

    setState(() => _cargando = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      // Llamada a la capa de dominio (valida credenciales y estado de correo verificado)
      final user = await _loginUseCase.execute(email, password);

      if (!mounted) return;

      // Limpiar cualquier notificación o error residual antes de navegar al dashboard
      AppMessenger.clear(context);

      // Navegar a Dashboard usando la ruta nombrada y pasando el usuario como argumento
      Navigator.pushReplacementNamed(context, '/dashboard', arguments: user);
    } catch (e) {
      if (!mounted) return;
      final mensajeError = AppErrorHandler.parseMessage(e);
      final esNoVerificado =
          mensajeError.toLowerCase().contains('no ha sido verificado') ||
          mensajeError.toLowerCase().contains('verificación') ||
          mensajeError.toLowerCase().contains('confirmación');

      if (esNoVerificado) {
        // Mostrar diálogo interactivo para reenviar el enlace de confirmación
        _mostrarDialogoReenvio(context, email, password);
      } else {
        AppMessenger.showErrorSnackBar(context, mensajeError);
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  /// Muestra un modal informativo cuando el correo aún no está verificado, permitiendo reenviarlo
  void _mostrarDialogoReenvio(
    BuildContext context,
    String email,
    String password,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final dialogTheme = Theme.of(dialogContext);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.mark_email_unread_outlined,
                color: dialogTheme.colorScheme.error,
                size: 28,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Correo no verificado',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Text(
            'Tu cuenta aún no ha sido activada.\n\nHemos enviado un enlace de confirmación a:\n$email\n\nSi no lo has recibido o ha expirado, puedes solicitar un nuevo enlace ahora mismo.',
            style: dialogTheme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cerrar'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Reenviar enlace'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _reenviarCorreoConfirmacion(email, password);
              },
            ),
          ],
        );
      },
    );
  }

  /// Reenvía el correo de confirmación de registro
  Future<void> _reenviarCorreoConfirmacion(
    String email,
    String password,
  ) async {
    setState(() => _cargando = true);
    try {
      await _resendVerificationUseCase.execute(
        correo: email,
        contrasena: password,
      );
      if (!mounted) return;
      AppMessenger.showSnackBar(
        context,
        mensaje:
            'Correo de confirmación reenviado con éxito a $email. Revisa tu bandeja de entrada.',
      );
    } catch (e) {
      if (!mounted) return;
      final error = AppErrorHandler.parseMessage(e);
      AppMessenger.showErrorSnackBar(context, error);
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  /// Abre el formulario modal de registro y si el registro es exitoso, muestra el diálogo de confirmación
  void _abrirModalRegistro() async {
    final correo = await showSignUpModalBottomSheet(context);
    if (correo != null && mounted) {
      _mostrarDialogoConfirmacionRegistro(context, correo);
    }
  }

  /// Muestra un diálogo informativo tras registrarse con éxito, indicando que se debe confirmar el correo
  void _mostrarDialogoConfirmacionRegistro(
    BuildContext context,
    String correo,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final dialogTheme = Theme.of(dialogContext);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.mark_email_read_outlined,
                color: dialogTheme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Confirma tu correo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Tu cuenta ha sido creada exitosamente!',
                style: dialogTheme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: dialogTheme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Hemos enviado un enlace de confirmación a:',
                style: dialogTheme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                correo,
                style: dialogTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Por favor verifica tu bandeja de entrada (o carpeta de spam) y activa tu cuenta para poder iniciar sesión.',
                style: dialogTheme.textTheme.bodyMedium?.copyWith(
                  color: dialogTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );

    AppMessenger.showSnackBar(
      context,
      mensaje:
          'Correo de confirmación enviado a $correo. Revisa tu bandeja de entrada.',
    );
  }

  /// Abre el modal de recuperación de contraseña y muestra confirmación al completarse
  void _abrirModalRecuperarContrasena() async {
    final correo = await showForgotPasswordModalBottomSheet(
      context,
      initialEmail: _emailController.text.trim(),
    );

    if (correo != null && mounted) {
      _mostrarDialogoConfirmacionRecuperacion(context, correo);
    }
  }

  /// Muestra diálogo informativo tras enviar el enlace de recuperación
  void _mostrarDialogoConfirmacionRecuperacion(
    BuildContext context,
    String correo,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final dialogTheme = Theme.of(dialogContext);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.mark_email_read_outlined,
                color: dialogTheme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Correo enviado',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hemos enviado las instrucciones para restablecer tu contraseña a:',
                style: dialogTheme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              Text(
                correo,
                style: dialogTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Revisa tu bandeja de entrada (y la carpeta de spam) y sigue el enlace para definir una nueva contraseña.',
                style: dialogTheme.textTheme.bodyMedium?.copyWith(
                  color: dialogTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // --- Imagen ilustrativa de fondo con transparencia y cobertura total ---
          Positioned.fill(
            child: Opacity(
              opacity: 1,
              child: Image.asset('images/fondo_inicio.png', fit: BoxFit.cover),
            ),
          ),

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
                        height: 180,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 10),
                              // Logo principal de la aplicación Koralis
                              child: Image.asset(
                                'images/logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            ArcText(
                              radius: 100,
                              text: 'K O R A L I S',
                              textStyle:
                                  theme.textTheme.titleLarge?.copyWith(
                                    fontSize: 50,
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
                        'Gestión de instrumentos financieros',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 48),

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
                          onPressed: _abrirModalRecuperarContrasena,
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
                            onPressed: _abrirModalRegistro,
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
