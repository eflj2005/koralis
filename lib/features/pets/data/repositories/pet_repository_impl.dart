// =============================================================================
// ⚠️ [DEPRECATED / BORRAR] - CÓDIGO DE REFERENCIA TEMPORAL (PETCARE)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:koralis_app/app/firebase.dart';
import 'package:koralis_app/app/firebase_firestore_config.dart';
import '../../domain/entities/pet.dart';
import '../../domain/repositories/pet_repository.dart';

/// Implementación del repositorio de mascotas usando Cloud Firestore.
/// 
/// ⚠️ **OBSOLETO**: Mantenido temporalmente como referencia arquitectónica. Pendiente de borrar.
// ignore: deprecated_member_use_from_same_package
@Deprecated('Código de referencia temporal de PetCare. Será eliminado al construir Koralis.')
// ignore: deprecated_member_use_from_same_package
class PetRepositoryImpl implements PetRepository {
  /// Servicio de Firestore provisto por [AppFirebase].
  final _firestore = AppFirebase().firestore;

  @override
  // ignore: deprecated_member_use_from_same_package
  Future<List<Pet>> getPets() async {
    // Obtener todos los documentos de la colección de mascotas
    final docs = await _firestore.getCollection(
      collectionPath: FirebaseFirestoreConfig.colMascotas,
    );

    // Mapear cada documento a la entidad [Pet]
    return docs.map((data) {
      // ignore: deprecated_member_use_from_same_package
      return Pet(
        id: data['id'] as String,
        nombre: data['nombre'] as String? ?? '',
        edad: (data['edad'] as num?)?.toInt() ?? 0,
        raza: data['raza'] as String? ?? '',
        peso: (data['peso'] as num?)?.toDouble() ?? 0.0,
        iconoCodigo: (data['iconoCodigo'] as num?)?.toInt() ?? Icons.pets.codePoint,
      );
    }).toList();
  }
}
