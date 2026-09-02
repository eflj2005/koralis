import 'package:flutter_test/flutter_test.dart';
import 'package:koralis_app/features/auth/domain/entities/user.dart';

void main() {
  group('Auth Feature - User Entity', () {
    test('Debe crear una instancia de User con los datos correctos y estado de correo por defecto', () {
      // Arrange
      const id = 'uid-abc-123';
      const nombre = 'Juan Perez';
      const correo = 'juan@koralis.com';
      const nacimiento = '15/08/1995';

      // Act
      final user = User(
        id: id,
        nombre: nombre,
        correo: correo,
        nacimiento: nacimiento,
      );

      // Assert
      expect(user.id, equals(id));
      expect(user.nombre, equals(nombre));
      expect(user.correo, equals(correo));
      expect(user.nacimiento, equals(nacimiento));
      expect(user.correoVerificado, isFalse);
    });

    test('Debe crear una instancia de User con correoVerificado explícito en true', () {
      // Arrange & Act
      final user = User(
        id: 'uid-verified-123',
        nombre: 'Maria Gomez',
        correo: 'maria@koralis.com',
        correoVerificado: true,
      );

      // Assert
      expect(user.correoVerificado, isTrue);
    });
  });
}
