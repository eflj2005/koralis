// =============================================================================
// ⚠️ [DEPRECATED / BORRAR] - CÓDIGO DE REFERENCIA TEMPORAL HEREDADO (TRANSICIÓN A KORALIS)
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:koralis_app/features/pets/domain/entities/pet.dart';

void main() {
  group('Pets Feature - Pet Entity', () {
    test('Debe crear una instancia de Pet con los datos correctos', () {
      // Arrange: id es String (ID de documento Firestore), iconoCodigo reemplaza imagen
      const id = 'pet-doc-xyz';
      const nombre = 'Firulais';
      const edad = 3;
      const raza = 'Mestizo';
      const peso = 15.5;
      const iconoCodigo = 0xe000;

      // Act
      // ignore: deprecated_member_use_from_same_package
      final pet = Pet(
        id: id,
        nombre: nombre,
        edad: edad,
        raza: raza,
        peso: peso,
        iconoCodigo: iconoCodigo,
      );

      // Assert
      expect(pet.id, equals(id));
      expect(pet.nombre, equals(nombre));
      expect(pet.edad, equals(edad));
      expect(pet.raza, equals(raza));
      expect(pet.peso, equals(peso));
      expect(pet.iconoCodigo, equals(iconoCodigo));
    });
  });
}
