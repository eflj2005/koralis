import 'package:koralis_app/app/firebase.dart';
import 'package:koralis_app/app/firebase_firestore_config.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implementación del repositorio de autenticación usando Firebase Authentication
/// y Cloud Firestore para la gestión de usuarios, perfiles y verificación de correo.
class AuthRepositoryImpl implements AuthRepository {
  /// Servicio de autenticación provisto por [AppFirebase].
  final _auth = AppFirebase().auth;

  /// Servicio de Firestore provisto por [AppFirebase].
  final _firestore = AppFirebase().firestore;

  @override
  Future<User> login(String correo, String contrasena) async {
    final correoLimpio = correo.trim();

    // 1. Autenticar contra Firebase Authentication
    final uid = await _auth.signInWithEmail(
      email: correoLimpio,
      password: contrasena,
    );

    if (uid == null) {
      throw Exception('No se pudo obtener el identificador de usuario autenticado.');
    }

    // 2. Refrescar el estado del usuario para obtener el valor actualizado de emailVerified
    await _auth.reloadCurrentUser();

    // 3. Validar obligatoriamente si el correo está verificado
    if (!_auth.isEmailVerified) {
      // Cerrar la sesión activa temporal para evitar accesos no autorizados
      await _auth.signOut();
      throw Exception(
        'Tu correo electrónico no ha sido verificado. Por favor revisa tu bandeja de entrada o haz clic en reenviar correo de confirmación.',
      );
    }

    // 4. Obtener datos extendidos del usuario desde Firestore
    final data = await _firestore.getDocument(
      collectionPath: FirebaseFirestoreConfig.colUsuarios,
      docId: uid,
    );

    if (data == null) {
      // Si aún no existe documento en Firestore, retornar usuario con datos básicos de Auth
      return User(
        id: uid,
        nombre: _auth.currentUser?.displayName ?? 'Usuario',
        correo: correoLimpio,
        correoVerificado: true,
      );
    }

    return User(
      id: uid,
      nombre: data['nombre'] as String? ?? _auth.currentUser?.displayName ?? 'Usuario',
      correo: data['correo'] as String? ?? correoLimpio,
      nacimiento: (data['nacimiento'] ?? data['cumpleanos']) as String?,
      correoVerificado: true,
    );
  }

  @override
  Future<User> signUp({
    required String nombre,
    required String correo,
    required String contrasena,
    required String nacimiento,
  }) async {
    final correoLimpio = correo.trim();
    final nombreLimpio = nombre.trim();
    final nacimientoLimpio = nacimiento.trim();

    // 1. Crear el registro en Firebase Authentication y disparar automáticamente el correo de verificación
    final uid = await _auth.signUpWithEmail(
      email: correoLimpio,
      password: contrasena,
      sendVerification: true,
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
        'nombre': nombreLimpio,
        'correo': correoLimpio,
        'nacimiento': nacimientoLimpio,
        FirebaseFirestoreConfig.campoCreatedAt: ahora,
        FirebaseFirestoreConfig.campoUpdatedAt: ahora,
      },
    );

    // 3. Cerrar la sesión inmediata para asegurar que el usuario verifique antes de ingresar
    await _auth.signOut();

    // 4. Retornar la entidad de dominio con toda la información y estado no verificado
    return User(
      id: uid,
      nombre: nombreLimpio,
      correo: correoLimpio,
      nacimiento: nacimientoLimpio,
      correoVerificado: false,
    );
  }

  @override
  Future<void> resendVerificationEmail(String correo, String contrasena) async {
    final correoLimpio = correo.trim();
    await _auth.sendEmailVerificationFor(
      email: correoLimpio,
      password: contrasena,
    );
  }

  @override
  Future<void> sendPasswordResetEmail(String correo) async {
    final correoLimpio = correo.trim();
    await _auth.sendPasswordResetEmail(correoLimpio);
  }
}
