import 'package:flutter_test/flutter_test.dart';
import 'package:koralis_app/features/pets/domain/entities/pet.dart';

void main() {
  group('Pets Feature - Pet Entity', () {
    test('Debe crear una instancia de Pet con los datos correctos', () {
      // Arrange
      const id = 1;
      const nombre = 'Firulais';
      const edad = 3;
      const raza = 'Mestizo';
      const peso = 15.5;
      const imagen = 0xe000;

      // Act
      final pet = Pet(
        id: id,
        nombre: nombre,
        edad: edad,
        raza: raza,
        peso: peso,
        imagen: imagen,
      );

      // Assert
      expect(pet.id, equals(id));
      expect(pet.nombre, equals(nombre));
      expect(pet.edad, equals(edad));
      expect(pet.raza, equals(raza));
      expect(pet.peso, equals(peso));
      expect(pet.imagen, equals(imagen));
    });
  });
}
