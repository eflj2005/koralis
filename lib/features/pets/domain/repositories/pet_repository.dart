// =============================================================================
// ⚠️ [DEPRECATED / BORRAR] - CÓDIGO DE REFERENCIA TEMPORAL (PETCARE)
// =============================================================================

import '../entities/pet.dart';

/// Contrato de repositorio para la gestión de mascotas.
/// 
/// ⚠️ **OBSOLETO**: Mantenido temporalmente como referencia arquitectónica. Pendiente de borrar.
// ignore: deprecated_member_use_from_same_package
@Deprecated('Código de referencia temporal de PetCare. Será eliminado al construir Koralis.')
abstract class PetRepository {
  // ignore: deprecated_member_use_from_same_package
  Future<List<Pet>> getPets();
}
