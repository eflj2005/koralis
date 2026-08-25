import 'package:koralis_app/app/firebase.dart';
import 'package:koralis_app/app/firebase_firestore_config.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implementación del repositorio de autenticación usando Firebase Authentication
/// y Cloud Firestore para la gestión de usuarios y perfiles.
class AuthRepositoryImpl implements AuthRepository {
  /// Servicio de autenticación provisto por [AppFirebase].
  final _auth = AppFirebase().auth;

  /// Servicio de Firestore provisto por [AppFirebase].
  final _firestore = AppFirebase().firestore;

  @override
  Future<User> login(String correo, String contrasena) async {
    // 1. Autenticar contra Firebase Authentication
    final uid = await _auth.signInWithEmail(
      email: correo.trim(),
      password: contrasena,
    );

    if (uid == null) {
      throw Exception('No se pudo obtener el identificador de usuario autenticado.');
    }

    // 2. Obtener datos extendidos del usuario desde Firestore
    final data = await _firestore.getDocument(
      collectionPath: FirebaseFirestoreConfig.colUsuarios,
      docId: uid,
    );

    if (data == null) {
      // Si aún no existe documento en Firestore, retornar usuario con datos básicos de Auth
      return User(
        id: uid,
        nombre: _auth.currentUser?.displayName ?? 'Usuario',
        correo: correo.trim(),
      );
    }

    return User(
      id: uid,
      nombre: data['nombre'] as String? ?? _auth.currentUser?.displayName ?? 'Usuario',
      correo: data['correo'] as String? ?? correo.trim(),
      nacimiento: (data['nacimiento'] ?? data['cumpleanos']) as String?,
    );
  }

  @override
  Future<User> signUp({
    required String nombre,
    required String correo,
    required String contrasena,
    required String nacimiento,
  }) async {
    // 1. Crear el registro en Firebase Authentication
    final uid = await _auth.signUpWithEmail(
      email: correo.trim(),
      password: contrasena,
    );

    if (uid == null) {
      throw Exception('No se pudo crear el usuario en Firebase Authentication.');
    }

    final ahora = DateTime.now().toIso8601String();

    // 2. Crear documento de usuario en la colección "users" de Cloud Firestore relacionado por UID
    await _firestore.setDocument(
      collectionPath: FirebaseFirestoreConfig.colUsuarios,
      docId: uid,
      data: {
        'nombre': nombre.trim(),
        'correo': correo.trim(),
        'nacimiento': nacimiento.trim(),
        FirebaseFirestoreConfig.campoCreatedAt: ahora,
        FirebaseFirestoreConfig.campoUpdatedAt: ahora,
      },
    );

    // 3. Retornar la entidad de dominio con toda la información
    return User(
      id: uid,
      nombre: nombre.trim(),
      correo: correo.trim(),
      nacimiento: nacimiento.trim(),
    );
  }
}
