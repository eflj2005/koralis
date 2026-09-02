import 'package:flutter/material.dart';
import 'package:core/core.dart';
import '../../domain/usecases/send_password_reset_email_usecase.dart';
import '../../data/repositories/auth_repository_impl.dart';

/// Modal emergente para solicitar el restablecimiento de contraseña vía correo.
class ForgotPasswordFormSheet extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordFormSheet({super.key, this.initialEmail});

  @override
  State<ForgotPasswordFormSheet> createState() =>
      _ForgotPasswordFormSheetState();
}

class _ForgotPasswordFormSheetState extends State<ForgotPasswordFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final SendPasswordResetEmailUseCase _sendPasswordResetEmailUseCase;
  late final TextEditingController _emailController;

  String? _errorMensaje;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _sendPasswordResetEmailUseCase =
        SendPasswordResetEmailUseCase(AuthRepositoryImpl());
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onEnviarPressed() async {
    setState(() => _errorMensaje = null);

    if (!_formKey.currentState!.validate()) return;
    if (_cargando) return;

    setState(() => _cargando = true);

    try {
      final email = _emailController.text.trim();
      await _sendPasswordResetEmailUseCase.execute(email);

      if (!mounted) return;
      // Cierra el modal retornando el correo confirmado
      Navigator.of(context).pop(email);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMensaje = AppErrorHandler.parseMessage(e);
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
              // --- Ícono y Encabezado ---
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_reset_rounded,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Recuperar contraseña',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ingresa tu correo registrado y te enviaremos un enlace seguro para restablecer tu contraseña.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // --- Banner de error ---
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
                const SizedBox(height: 16),
              ],

              // --- Campo Correo Electrónico ---
              AppTextField(
                label: 'Correo electrónico',
                hint: 'ejemplo@correo.com',
                icono: Icons.email_outlined,
                controller: _emailController,
                tipoTeclado: TextInputType.emailAddress,
                validator: CoreValidators.email,
              ),
              const SizedBox(height: 24),

              // --- Botón de Acción ---
              AppButton(
                texto: 'Enviar enlace de recuperación',
                icono: Icons.send_rounded,
                onPressed: _cargando ? null : _onEnviarPressed,
              ),
              const SizedBox(height: 12),

              // --- Cancelar / Volver ---
              Center(
                child: TextButton(
                  onPressed: _cargando ? null : () => Navigator.of(context).pop(),
                  child: const Text('Volver al inicio de sesión'),
                ),
              ),
            ],
          ),
        ),

        // --- Overlay de carga ---
        if (_cargando)
          const Positioned.fill(
            child: LoadingWidget(),
          ),
      ],
    );
  }
}

/// Helper para invocar el modal de recuperación de contraseña.
Future<String?> showForgotPasswordModalBottomSheet(
  BuildContext context, {
  String? initialEmail,
}) {
  return showAppModalBottomSheet<String>(
    context,
    child: ForgotPasswordFormSheet(initialEmail: initialEmail),
  );
}
