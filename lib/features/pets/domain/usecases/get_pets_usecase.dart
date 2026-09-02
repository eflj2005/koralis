// =============================================================================
// ⚠️ [DEPRECATED / BORRAR] - CÓDIGO DE REFERENCIA TEMPORAL HEREDADO (TRANSICIÓN A KORALIS)
// =============================================================================

import '../entities/pet.dart';
import '../repositories/pet_repository.dart';

/// Caso de uso para obtener el listado de mascotas registradas.
/// 
/// ⚠️ **OBSOLETO**: Mantenido temporalmente como referencia arquitectónica. Pendiente de borrar.
// ignore: deprecated_member_use_from_same_package
@Deprecated('Código de referencia temporal heredado. Será eliminado al construir los módulos financieros de Koralis.')
class GetPetsUseCase {
  // ignore: deprecated_member_use_from_same_package
  final PetRepository repository;

  GetPetsUseCase(this.repository);

  // ignore: deprecated_member_use_from_same_package
  Future<List<Pet>> execute() async {
    return await repository.getPets();
  }
}
