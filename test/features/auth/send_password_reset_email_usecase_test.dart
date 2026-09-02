import 'package:flutter_test/flutter_test.dart';
import 'package:koralis_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:koralis_app/features/auth/domain/usecases/send_password_reset_email_usecase.dart';
import 'package:koralis_app/features/auth/domain/entities/user.dart';

class MockAuthRepository implements AuthRepository {
  String? ultimoCorreoRecibido;
  bool debeLanzarError = false;

  @override
  Future<void> sendPasswordResetEmail(String correo) async {
    if (debeLanzarError) {
      throw Exception('Usuario no encontrado');
    }
    ultimoCorreoRecibido = correo;
  }

  @override
  Future<User> login(String correo, String contrasena) => throw UnimplementedError();

  @override
  Future<User> signUp({
    required String nombre,
    required String correo,
    required String contrasena,
    required String nacimiento,
  }) => throw UnimplementedError();

  @override
  Future<void> resendVerificationEmail(String correo, String contrasena) =>
      throw UnimplementedError();
}

void main() {
  group('SendPasswordResetEmailUseCase Tests', () {
    late MockAuthRepository mockRepository;
    late SendPasswordResetEmailUseCase useCase;

    setUp(() {
      mockRepository = MockAuthRepository();
      useCase = SendPasswordResetEmailUseCase(mockRepository);
    });

    test('Debe delegar el envío de correo al AuthRepository correctamente', () async {
      const correo = 'test@koralis.com';

      await useCase.execute(correo);

      expect(mockRepository.ultimoCorreoRecibido, equals(correo));
    });

    test('Debe propagar la excepción cuando el repositorio falla', () async {
      mockRepository.debeLanzarError = true;

      expect(
        () => useCase.execute('desconocido@koralis.com'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
