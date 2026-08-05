import 'package:flutter_test/flutter_test.dart';
import 'package:koralis_app/features/auth/domain/entities/user.dart';

void main() {
  group('Auth Feature - User Entity', () {
    test('Debe crear una instancia de User con los datos correctos', () {
      // Arrange
      const id = 1;
      const nombre = 'Juan Perez';
      const correo = 'juan@petcare.com';

      // Act
      final user = User(id: id, nombre: nombre, correo: correo);

      // Assert
      expect(user.id, equals(id));
      expect(user.nombre, equals(nombre));
      expect(user.correo, equals(correo));
    });
  });
}
