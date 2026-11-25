import 'package:flutter_test/flutter_test.dart';
import 'package:koralis_app/features/auth/domain/entities/user.dart';
import 'package:koralis_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:koralis_app/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:koralis_app/features/auth/presentation/viewmodels/sign_up_view_model.dart';

class _FakeAuthRepository implements AuthRepository {
  Object? signUpError;
  String? ultimoNombre;
  String? ultimoCorreo;
  String? ultimoNacimiento;

  @override
  Future<User> signUp({
    required String nombre,
    required String correo,
    required String contrasena,
    required String nacimiento,
  }) async {
    ultimoNombre = nombre;
    ultimoCorreo = correo;
    ultimoNacimiento = nacimiento;
    if (signUpError != null) throw signUpError!;
    return User(
      id: 'u-nuevo',
      nombre: nombre,
      correo: correo,
      nacimiento: nacimiento,
    );
  }

  @override
  Future<User> login(String correo, String contrasena) =>
      throw UnimplementedError();

  @override
  Future<void> resendVerificationEmail(String correo, String contrasena) =>
      throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail(String correo) =>
      throw UnimplementedError();
}

void main() {
  group('SignUpViewModel', () {
    test('seleccionarFechaNacimiento actualiza fecha y limpia errorMensaje', () {
      final vm = SignUpViewModel(signUpUseCase: SignUpUseCase(_FakeAuthRepository()));
      vm.setError('Error previo');

      final fecha = DateTime(1998, 5, 14);
      vm.seleccionarFechaNacimiento(fecha);

      expect(vm.selectedBirthDate, fecha);
      expect(vm.errorMensaje, isNull);
    });

    test('setError actualiza errorMensaje', () {
      final vm = SignUpViewModel(signUpUseCase: SignUpUseCase(_FakeAuthRepository()));

      vm.setError('Campos inválidos');
      expect(vm.errorMensaje, 'Campos inválidos');

      vm.setError(null);
      expect(vm.errorMensaje, isNull);
    });

    test('registrarUsuario exitoso retorna correo normalizado y apaga cargando', () async {
      final repo = _FakeAuthRepository();
      final vm = SignUpViewModel(signUpUseCase: SignUpUseCase(repo));

      final correo = await vm.registrarUsuario(
        nombre: '  Ana María  ',
        correo: '  ana@koralis.com ',
        contrasena: 'Password123',
        nacimiento: '14/05/1998',
      );

      expect(correo, 'ana@koralis.com');
      expect(repo.ultimoNombre, 'Ana María');
      expect(repo.ultimoCorreo, 'ana@koralis.com');
      expect(repo.ultimoNacimiento, '14/05/1998');
      expect(vm.cargando, isFalse);
      expect(vm.errorMensaje, isNull);
    });

    test('registrarUsuario con error guarda errorMensaje y relanza', () async {
      final repo = _FakeAuthRepository()
        ..signUpError = Exception('El correo ya está registrado');
      final vm = SignUpViewModel(signUpUseCase: SignUpUseCase(repo));

      await expectLater(
        vm.registrarUsuario(
          nombre: 'Ana',
          correo: 'ana@koralis.com',
          contrasena: 'Password123',
          nacimiento: '14/05/1998',
        ),
        throwsException,
      );

      expect(vm.cargando, isFalse);
      expect(vm.errorMensaje, 'El correo ya está registrado');
    });
  });
}
