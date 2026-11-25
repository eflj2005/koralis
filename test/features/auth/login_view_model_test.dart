import 'package:flutter_test/flutter_test.dart';
import 'package:koralis_app/features/auth/domain/entities/user.dart';
import 'package:koralis_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:koralis_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:koralis_app/features/auth/domain/usecases/resend_email_verification_usecase.dart';
import 'package:koralis_app/features/auth/presentation/viewmodels/login_view_model.dart';

class _FakeAuthRepository implements AuthRepository {
  User? loginResult;
  Object? loginError;
  Object? resendError;

  String? ultimoCorreoLogin;
  String? ultimoCorreoReenvio;
  String? ultimaContrasenaReenvio;

  @override
  Future<User> login(String correo, String contrasena) async {
    ultimoCorreoLogin = correo;
    if (loginError != null) throw loginError!;
    return loginResult ??
        User(
          id: 'u-1',
          nombre: 'Edwin Londoño',
          correo: correo,
          correoVerificado: true,
        );
  }

  @override
  Future<void> resendVerificationEmail(String correo, String contrasena) async {
    ultimoCorreoReenvio = correo;
    ultimaContrasenaReenvio = contrasena;
    if (resendError != null) throw resendError!;
  }

  @override
  Future<void> sendPasswordResetEmail(String correo) async {}

  @override
  Future<User> signUp({
    required String nombre,
    required String correo,
    required String contrasena,
    required String nacimiento,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  group('LoginViewModel', () {
    test('iniciarSesion exitoso retorna User y deja cargando en false sin error', () async {
      final repo = _FakeAuthRepository();
      final vm = LoginViewModel(
        loginUseCase: LoginUseCase(repo),
        resendEmailVerificationUseCase: ResendEmailVerificationUseCase(repo),
      );

      final user = await vm.iniciarSesion(
        correo: '  edwin@koralis.com  ',
        contrasena: 'Password123',
      );

      expect(repo.ultimoCorreoLogin, 'edwin@koralis.com');
      expect(user.id, 'u-1');
      expect(vm.cargando, isFalse);
      expect(vm.errorMensaje, isNull);
    });

    test('iniciarSesion con error guarda errorMensaje limpio y relanza', () async {
      final repo = _FakeAuthRepository()
        ..loginError = Exception('Credenciales incorrectas');
      final vm = LoginViewModel(
        loginUseCase: LoginUseCase(repo),
        resendEmailVerificationUseCase: ResendEmailVerificationUseCase(repo),
      );

      await expectLater(
        vm.iniciarSesion(
          correo: 'edwin@koralis.com',
          contrasena: 'bad',
        ),
        throwsException,
      );

      expect(vm.cargando, isFalse);
      expect(vm.errorMensaje, 'Credenciales incorrectas');
    });

    test('esErrorCorreoNoVerificado detecta mensajes de verificación y confirmación', () {
      final repo = _FakeAuthRepository();
      final vm = LoginViewModel(
        loginUseCase: LoginUseCase(repo),
        resendEmailVerificationUseCase: ResendEmailVerificationUseCase(repo),
      );

      expect(
        vm.esErrorCorreoNoVerificado('Tu correo no ha sido verificado aún.'),
        isTrue,
      );
      expect(
        vm.esErrorCorreoNoVerificado('Falta verificación de cuenta.'),
        isTrue,
      );
      expect(
        vm.esErrorCorreoNoVerificado('Pendiente confirmación de email.'),
        isTrue,
      );
      expect(
        vm.esErrorCorreoNoVerificado('Contraseña incorrecta.'),
        isFalse,
      );
    });

    test('reenviarConfirmacion delega al ResendEmailVerificationUseCase', () async {
      final repo = _FakeAuthRepository();
      final vm = LoginViewModel(
        loginUseCase: LoginUseCase(repo),
        resendEmailVerificationUseCase: ResendEmailVerificationUseCase(repo),
      );

      await vm.reenviarConfirmacion(
        correo: '  edwin@koralis.com ',
        contrasena: 'Secret123',
      );

      expect(repo.ultimoCorreoReenvio, 'edwin@koralis.com');
      expect(repo.ultimaContrasenaReenvio, 'Secret123');
      expect(vm.cargando, isFalse);
      expect(vm.errorMensaje, isNull);
    });
  });
}
