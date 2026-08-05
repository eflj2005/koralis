library;

export 'src/theme.dart';
export 'src/constants.dart';
export 'src/widgets.dart';
export 'src/extensions.dart';
export 'src/helpers.dart';
export 'src/validators.dart';
export 'src/services.dart';

// Servicios genéricos de Firebase
export 'src/firebase/firebase_auth_service.dart';
export 'src/firebase/firestore_service.dart';
export 'src/firebase/firebase_storage_service.dart';
export 'src/firebase/firebase_errors.dart';

// Exportar dependencias requeridas por la capa de datos
export 'package:sqflite/sqflite.dart';
export 'package:firebase_core/firebase_core.dart';
export 'package:cloud_firestore/cloud_firestore.dart' show Query, SetOptions, FieldValue;
export 'package:firebase_storage/firebase_storage.dart' show SettableMetadata;
