// =============================================================================
// ⚠️ [DEPRECATED / BORRAR] - CÓDIGO DE REFERENCIA TEMPORAL (PETCARE)
// =============================================================================

import '../entities/pet.dart';
import '../repositories/pet_repository.dart';

/// Caso de uso para obtener el listado de mascotas registradas.
/// 
/// ⚠️ **OBSOLETO**: Mantenido temporalmente como referencia arquitectónica. Pendiente de borrar.
// ignore: deprecated_member_use_from_same_package
@Deprecated('Código de referencia temporal de PetCare. Será eliminado al construir Koralis.')
class GetPetsUseCase {
  // ignore: deprecated_member_use_from_same_package
  final PetRepository repository;

  GetPetsUseCase(this.repository);

  // ignore: deprecated_member_use_from_same_package
  Future<List<Pet>> execute() async {
    return await repository.getPets();
  }
}
