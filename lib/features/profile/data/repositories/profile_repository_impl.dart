import 'package:koralis_app/app/firebase.dart';
import 'package:koralis_app/app/firebase_firestore_config.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';

/// Implementación del repositorio de perfil de usuario usando Cloud Firestore.
class ProfileRepositoryImpl implements ProfileRepository {
  /// Servicio de Firestore provisto por [AppFirebase].
  final _firestore = AppFirebase().firestore;

  @override
  Future<Profile> getProfile(String userId) async {
    // Obtener el documento de perfil usando el UID de Firebase Authentication como ID
    final data = await _firestore.getDocument(
      collectionPath: FirebaseFirestoreConfig.colPerfiles,
      docId: userId,
    );

    if (data == null) {
      throw Exception('Perfil no encontrado para el usuario $userId');
    }

    return Profile(
      id: data['id'] as String,
      userId: userId,
      avatarPath: data['avatarPath'] as String? ?? '',
      nombre: data['nombre'] as String? ?? '',
      correo: data['correo'] as String? ?? '',
    );
  }
}
