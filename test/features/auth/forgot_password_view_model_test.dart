import 'package:flutter_test/flutter_test.dart';
import 'package:koralis_app/features/auth/domain/entities/user.dart';
import 'package:koralis_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:koralis_app/features/auth/domain/usecases/send_password_reset_email_usecase.dart';
import 'package:koralis_app/features/auth/presentation/viewmodels/forgot_password_view_model.dart';

class _FakeAuthRepository implements AuthRepository {
  Object? resetError;
  String? ultimoCorreo;

  @override
  Future<void> sendPasswordResetEmail(String correo) async {
    ultimoCorreo = correo;
    if (resetError != null) throw resetError!;
  }

  @override
  Future<User> login(String correo, String contrasena) =>
      throw UnimplementedError();

  @override
  Future<void> resendVerificationEmail(String correo, String contrasena) =>
      throw UnimplementedError();

  @override
  Future<User> signUp({
    required String nombre,
    required String correo,
    required String contrasena,
    required String nacimiento,
  }) =>
      throw UnimplementedError();
}

void main() {
  group('ForgotPasswordViewModel', () {
    test('enviarEnlace exitoso retorna correo normalizado y apaga cargando', () async {
      final repo = _FakeAuthRepository();
      final vm = ForgotPasswordViewModel(
        sendPasswordResetEmailUseCase: SendPasswordResetEmailUseCase(repo),
      );

      final correo = await vm.enviarEnlace('  usuario@koralis.com  ');

      expect(correo, 'usuario@koralis.com');
      expect(repo.ultimoCorreo, 'usuario@koralis.com');
      expect(vm.cargando, isFalse);
      expect(vm.errorMensaje, isNull);
    });

    test('enviarEnlace con error guarda errorMensaje y relanza', () async {
      final repo = _FakeAuthRepository()
        ..resetError = Exception('Usuario no encontrado');
      final vm = ForgotPasswordViewModel(
        sendPasswordResetEmailUseCase: SendPasswordResetEmailUseCase(repo),
      );

      await expectLater(
        vm.enviarEnlace('noexiste@koralis.com'),
        throwsException,
      );

      expect(vm.cargando, isFalse);
      expect(vm.errorMensaje, 'Usuario no encontrado');
    });
  });
}
