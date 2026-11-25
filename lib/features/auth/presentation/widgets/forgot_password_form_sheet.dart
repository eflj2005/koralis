import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:provider/provider.dart';
import '../../domain/usecases/send_password_reset_email_usecase.dart';
import '../viewmodels/forgot_password_view_model.dart';

/// Modal emergente para solicitar el restablecimiento de contraseña vía correo.
class ForgotPasswordFormSheet extends StatelessWidget {
  final String? initialEmail;
  final SendPasswordResetEmailUseCase? sendPasswordResetEmailUseCase;

  const ForgotPasswordFormSheet({
    super.key,
    this.initialEmail,
    this.sendPasswordResetEmailUseCase,
  });

  bool _tieneProvider(BuildContext context) {
    try {
      Provider.of<ForgotPasswordViewModel>(context, listen: false);
      return true;
    } on ProviderNotFoundException {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final debeCrearProviderLocal =
        sendPasswordResetEmailUseCase != null || !_tieneProvider(context);

    if (debeCrearProviderLocal) {
      return ChangeNotifierProvider<ForgotPasswordViewModel>(
        create: (_) => ForgotPasswordViewModel(
          sendPasswordResetEmailUseCase: sendPasswordResetEmailUseCase,
        ),
        child: _ForgotPasswordFormSheetContent(initialEmail: initialEmail),
      );
    }

    return _ForgotPasswordFormSheetContent(initialEmail: initialEmail);
  }
}

class _ForgotPasswordFormSheetContent extends StatefulWidget {
  final String? initialEmail;

  const _ForgotPasswordFormSheetContent({this.initialEmail});

  @override
  State<_ForgotPasswordFormSheetContent> createState() =>
      _ForgotPasswordFormSheetContentState();
}

class _ForgotPasswordFormSheetContentState
    extends State<_ForgotPasswordFormSheetContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onEnviarPressed() async {
    final vm = context.read<ForgotPasswordViewModel>();
    vm.limpiarError();

    if (!_formKey.currentState!.validate()) return;
    if (vm.cargando) return;

    try {
      final email = await vm.enviarEnlace(_emailController.text);

      if (!mounted) return;
      // Cierra el modal retornando el correo confirmado
      Navigator.of(context).pop(email);
    } catch (_) {
      // El error queda registrado en el ViewModel y se muestra en el banner.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = context.watch<ForgotPasswordViewModel>();
    final cargando = vm.cargando;
    final errorMensaje = vm.errorMensaje;

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
              if (errorMensaje != null) ...[
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
                          errorMensaje,
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
                onPressed: cargando ? null : _onEnviarPressed,
              ),
              const SizedBox(height: 12),

              // --- Cancelar / Volver ---
              Center(
                child: TextButton(
                  onPressed: cargando ? null : () => Navigator.of(context).pop(),
                  child: const Text('Volver al inicio de sesión'),
                ),
              ),
            ],
          ),
        ),

        // --- Overlay de carga ---
        if (cargando)
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
