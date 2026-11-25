import 'package:flutter_test/flutter_test.dart';
import 'package:koralis_app/features/profile/domain/entities/profile.dart';
import 'package:koralis_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:koralis_app/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:koralis_app/features/profile/presentation/viewmodels/profile_view_model.dart';

class _FakeProfileRepo implements ProfileRepository {
  int callCount = 0;
  bool shouldFail = false;

  @override
  Future<Profile> getProfile(String userId) async {
    callCount++;
    if (shouldFail) {
      throw Exception('Error simulado al consultar perfil');
    }
    return Profile(
      id: 'prof-$userId',
      userId: userId,
      nombre: 'Usuario Prueba',
      correo: 'usuario@koralis.com',
      avatarPath: 'images/avatar.png',
    );
  }
}

void main() {
  group('ProfileViewModel', () {
    test('Carga el perfil y reutiliza caché en llamadas sucesivas salvo forzar=true', () async {
      final repo = _FakeProfileRepo();
      final vm = ProfileViewModel(
        getProfileUseCase: GetProfileUseCase(repo),
      );

      expect(vm.profile, isNull);
      expect(vm.isLoading, isFalse);

      await vm.cargarPerfil('user-1');
      expect(vm.profile?.id, equals('prof-user-1'));
      expect(vm.isLoading, isFalse);
      expect(vm.errorMessage, isNull);
      expect(repo.callCount, equals(1));

      // Segunda llamada para el mismo usuario usa caché
      await vm.cargarPerfil('user-1');
      expect(repo.callCount, equals(1));

      // Con forzar=true vuelve a consultar
      await vm.cargarPerfil('user-1', forzar: true);
      expect(repo.callCount, equals(2));
    });

    test('Registra errorMessage si falla la consulta y limpiar() reinicia el estado', () async {
      final repo = _FakeProfileRepo()..shouldFail = true;
      final vm = ProfileViewModel(
        getProfileUseCase: GetProfileUseCase(repo),
      );

      await vm.cargarPerfil('user-1');
      expect(vm.profile, isNull);
      expect(vm.isLoading, isFalse);
      expect(vm.errorMessage, contains('Error simulado'));

      repo.shouldFail = false;
      await vm.cargarPerfil('user-1');
      expect(vm.profile, isNotNull);

      vm.limpiar();
      expect(vm.profile, isNull);
      expect(vm.errorMessage, isNull);
    });
  });
}
