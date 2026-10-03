import 'package:core/core.dart';
import '../firebase_options.dart';
import 'firebase_auth_config.dart';
import 'firebase_firestore_config.dart';
import 'firebase_storage_config.dart';

/// Gestor centralizado e inicializador de Firebase específico para la aplicación Koralis.
///
/// Abstrae y expone los servicios genéricos independientes provenientes del paquete [core].
/// Cada servicio es construido e instanciado a través de su respectivo archivo de configuración:
/// - Autenticación → [FirebaseAuthConfig]
/// - Base de datos  → [FirebaseFirestoreConfig]
/// - Almacenamiento → [FirebaseStorageConfig]
class AppFirebase {
  static final AppFirebase _instance = AppFirebase._internal();

  /// Instancias internas de los servicios de Firebase
  FirebaseAuthService? _auth;
  FirestoreService? _firestore;
  FirebaseStorageService? _storage;

  bool _isInitialized = false;

  /// Retorna la instancia singleton de [AppFirebase].
  factory AppFirebase() {
    return _instance;
  }

  AppFirebase._internal();

  /// Servicio de autenticación con inicialización segura
  FirebaseAuthService get auth =>
      _auth ??= FirebaseAuthConfig.buildService();

  /// Servicio de Cloud Firestore con inicialización segura
  FirestoreService get firestore =>
      _firestore ??= FirebaseFirestoreConfig.buildService();

  /// Servicio de Firebase Storage con inicialización segura
  FirebaseStorageService get storage =>
      _storage ??= FirebaseStorageConfig.buildService();

  /// Retorna si Firebase ha sido inicializado explícitamente en la aplicación.
  bool get isInitialized => _isInitialized;

  /// Retorna el UID del usuario actual de manera segura y resiliente sin lanzar excepción
  /// cuando Firebase no ha sido inicializado (como en pruebas unitarias puras).
  String? get currentUidSafe {
    if (!_isInitialized && _auth == null) return null;
    try {
      return auth.currentUid;
    } catch (_) {
      return null;
    }
  }

  /// Inicializa la app de Firebase con las opciones del proyecto Koralis.
  /// Cada servicio es construido desde su archivo de configuración individual.
  static Future<AppFirebase> initialize() async {
    if (!_instance._isInitialized) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Construcción e inicialización explícita de los servicios
      _instance._auth = FirebaseAuthConfig.buildService();
      _instance._firestore = FirebaseFirestoreConfig.buildService();
      _instance._storage = FirebaseStorageConfig.buildService();

      _instance._isInitialized = true;
    }
    return _instance;
  }
}
