import 'package:flutter_test/flutter_test.dart';
import 'package:koralis_app/features/profile/domain/entities/profile.dart';

void main() {
  group('Profile Feature - Profile Entity', () {
    test('Debe crear una instancia de Profile con los datos correctos', () {
      // Arrange: id y userId son String (IDs de Firestore y Firebase Auth)
      const id = 'profile-doc-abc';
      const userId = 'uid-firebase-xyz';
      const avatarPath = 'images/avatar.png';
      const nombre = 'Maria Gomez';
      const correo = 'maria@koralis.com';

      // Act
      final profile = Profile(
        id: id,
        userId: userId,
        avatarPath: avatarPath,
        nombre: nombre,
        correo: correo,
      );

      // Assert
      expect(profile.id, equals(id));
      expect(profile.userId, equals(userId));
      expect(profile.avatarPath, equals(avatarPath));
      expect(profile.nombre, equals(nombre));
      expect(profile.correo, equals(correo));
    });
  });
}
