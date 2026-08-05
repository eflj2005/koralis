import 'package:core/core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Opciones de configuración predeterminadas de Firebase para el proyecto Koralis.
/// 
/// Contiene las llaves de acceso y parámetros de conexión específicos por plataforma.
class DefaultFirebaseOptions {
  /// Retorna las opciones de Firebase según la plataforma de ejecución actual.
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions no se ha configurado para la plataforma Web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions no se ha configurado para macOS.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions no se ha configurado para Windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions no se ha configurado para Linux.',
        );
      default:
        throw UnsupportedError(
          'Plataforma no soportada para FirebaseOptions.',
        );
    }
  }

  /// Llaves y parámetros de conexión para la plataforma Android.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDm1yioCwLDLWrjHyaZf0Wp5FPXmJnzcyY',
    appId: '1:504734441226:android:ea3c92b0f9ab2aa1b0e4f3',
    messagingSenderId: '504734441226',
    projectId: 'packandgo-c47fd',
    storageBucket: 'packandgo-c47fd.firebasestorage.app',
  );

  /// Llaves y parámetros de conexión para la plataforma iOS.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBDbVhK5W2ST2o_R32_Fsrig-TmbicLMv0',
    appId: '1:504734441226:ios:a5f0741390a1fe05b0e4f3',
    messagingSenderId: '504734441226',
    projectId: 'packandgo-c47fd',
    storageBucket: 'packandgo-c47fd.firebasestorage.app',
    iosClientId:
        '504734441226-5olef9cgjm32b54ldnf1381pqahi0l1h.apps.googleusercontent.com',
    iosBundleId: 'com.edwinacubillos.testApp3',
  );
}

/// Gestor centralizado e inicializador de Firebase específico para la aplicación Koralis.
/// 
/// Abstrae y expone los servicios genéricos independientes provenientes del paquete [core].
class AppFirebase {
  static final AppFirebase _instance = AppFirebase._internal();

  /// Instancias únicas de los 3 servicios de Firebase provistos por el paquete core.
  late final FirebaseAuthService auth;
  late final FirestoreService firestore;
  late final FirebaseStorageService storage;

  bool _isInitialized = false;

  /// Retorna la instancia singleton de [AppFirebase].
  factory AppFirebase() {
    return _instance;
  }

  AppFirebase._internal();

  /// Inicializa la app de Firebase con las opciones del proyecto Koralis y configura los servicios.
  static Future<AppFirebase> initialize() async {
    if (!_instance._isInitialized) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _instance.auth = FirebaseAuthService();
      _instance.firestore = FirestoreService();
      _instance.storage = FirebaseStorageService();

      _instance._isInitialized = true;
    }
    return _instance;
  }
}
