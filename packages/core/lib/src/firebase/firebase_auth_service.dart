import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_errors.dart';

/// Servicio genérico desacoplado para la gestión de Autenticación con Firebase.
///
/// Soporta múltiples proveedores de autenticación:
/// - Correo electrónico y contraseña (siempre disponible).
/// - Google Sign-In (opcional: se habilita inyectando una instancia de [GoogleSignIn]).
///
/// Si [googleSignIn] es `null`, los métodos de Google lanzarán [UnsupportedError].
class FirebaseAuthService {
  final FirebaseAuth _auth;

  /// Instancia de GoogleSignIn. Si es `null`, el proveedor Google está deshabilitado.
  final GoogleSignIn? _googleSignIn;

  /// Indica si el proveedor de Google Sign-In está habilitado en este servicio.
  bool get googleSignInEnabled => _googleSignIn != null;

  /// Constructor que permite inyectar instancias de [FirebaseAuth] y opcionalmente [GoogleSignIn].
  ///
  /// - Para usar **solo correo**, omitir o pasar `null` en [googleSignIn].
  /// - Para habilitar **Google Sign-In**, pasar una instancia configurada de [GoogleSignIn].
  FirebaseAuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn;

  /// Obtiene el usuario actualmente autenticado o `null` si no hay sesión activa.
  User? get currentUser => _auth.currentUser;

  /// Stream para escuchar los cambios en el estado de autenticación (login/logout).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Obtiene el UID del usuario actual o `null` si no ha iniciado sesión.
  String? get currentUid => _auth.currentUser?.uid;

  /// Obtiene el correo electrónico del usuario actual o un mensaje por defecto.
  String get currentUserEmail =>
      _auth.currentUser?.email ?? 'Sin correo registrado';

  /// Indica si existe una sesión activa válida.
  bool get isAuthenticated => _auth.currentUser != null;

  // ---------------------------------------------------------------------------
  // Autenticación por Correo y Contraseña
  // ---------------------------------------------------------------------------

  /// Registra un nuevo usuario utilizando correo electrónico y contraseña.
  ///
  /// Retorna el UID del nuevo usuario si el registro es exitoso.
  /// Lanza una excepción con un código/mensaje procesado en caso de falla.
  Future<String?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user?.uid;
    } on FirebaseAuthException catch (e) {
      throw FirebaseErrors.mapMessage(e.code);
    } catch (e) {
      throw FirebaseErrors.getErrorMessage(e);
    }
  }

  /// Inicia sesión con correo electrónico y contraseña.
  ///
  /// Retorna el UID del usuario autenticado.
  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user?.uid;
    } on FirebaseAuthException catch (e) {
      throw FirebaseErrors.mapMessage(e.code);
    } catch (e) {
      throw FirebaseErrors.getErrorMessage(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Autenticación con Google Sign-In (Opcional)
  // ---------------------------------------------------------------------------

  /// Inicia sesión utilizando credenciales de Google.
  ///
  /// Retorna el UID del usuario si la autenticación por Google se completa,
  /// o `null` si el usuario cancela la selección de cuenta.
  ///
  /// Lanza [UnsupportedError] si Google Sign-In no fue habilitado al construir el servicio.
  Future<String?> signInWithGoogle() async {
    if (_googleSignIn == null) {
      throw UnsupportedError(
        'Google Sign-In no está habilitado en este proyecto. '
        'Inyecta una instancia de GoogleSignIn al crear FirebaseAuthService.',
      );
    }
    try {
      // Forzar cierre de sesión previo en GoogleSignIn para permitir selección de cuenta
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // El usuario canceló la interacción de inicio de sesión
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      return userCredential.user?.uid;
    } on FirebaseAuthException catch (e) {
      throw FirebaseErrors.mapMessage(e.code);
    } catch (e) {
      throw FirebaseErrors.getErrorMessage(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Métodos Comunes
  // ---------------------------------------------------------------------------

  /// Envía un correo electrónico de recuperación de contraseña al correo especificado.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw FirebaseErrors.mapMessage(e.code);
    } catch (e) {
      throw FirebaseErrors.getErrorMessage(e);
    }
  }

  /// Cierra la sesión activa del usuario.
  /// Si Google Sign-In está habilitado, también cierra la sesión de Google.
  Future<void> signOut() async {
    try {
      final futures = <Future>[_auth.signOut()];
      if (_googleSignIn != null) {
        futures.add(_googleSignIn.signOut());
      }
      await Future.wait(futures);
    } catch (e) {
      throw FirebaseErrors.getErrorMessage(e);
    }
  }
}
