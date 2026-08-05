import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_errors.dart';

/// Servicio genérico desacoplado para la gestión de archivos y almacenamiento en Firebase Storage.
class FirebaseStorageService {
  final FirebaseStorage _storage;

  /// Constructor que permite inyectar una instancia de [FirebaseStorage].
  /// Si no se especifica, se utiliza la instancia singleton por defecto.
  FirebaseStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Obtiene la instancia subyacente de [FirebaseStorage].
  FirebaseStorage get instance => _storage;

  /// Sube un archivo local [file] a la ruta de almacenamiento especificada en [storagePath].
  /// 
  /// Opcionalmente recibe [metadata] para definir tipos de contenido (e.g. `image/jpeg`).
  /// Retorna la URL pública de descarga del archivo subido.
  Future<String> uploadFile({
    required String storagePath,
    required File file,
    SettableMetadata? metadata,
  }) async {
    try {
      final Reference ref = _storage.ref().child(storagePath);
      final UploadTask uploadTask = ref.putFile(file, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw FirebaseErrors.mapMessage(e.code);
    } catch (e) {
      throw FirebaseErrors.getErrorMessage(e);
    }
  }

  /// Sube datos en formato binario ([bytes]) a la ruta especificada en [storagePath].
  /// 
  /// Útil para la subida de imágenes procesadas en memoria o plataformas web.
  /// Retorna la URL pública de descarga del archivo subido.
  Future<String> uploadData({
    required String storagePath,
    required Uint8List bytes,
    SettableMetadata? metadata,
  }) async {
    try {
      final Reference ref = _storage.ref().child(storagePath);
      final UploadTask uploadTask = ref.putData(bytes, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw FirebaseErrors.mapMessage(e.code);
    } catch (e) {
      throw FirebaseErrors.getErrorMessage(e);
    }
  }

  /// Elimina un archivo de Firebase Storage especificando su ruta en el storage ([storagePath]).
  Future<void> deleteFile(String storagePath) async {
    try {
      final Reference ref = _storage.ref().child(storagePath);
      await ref.delete();
    } on FirebaseException catch (e) {
      throw FirebaseErrors.mapMessage(e.code);
    } catch (e) {
      throw FirebaseErrors.getErrorMessage(e);
    }
  }

  /// Elimina un archivo de Firebase Storage utilizando directamente su URL pública de descarga [url].
  Future<void> deleteFileByUrl(String url) async {
    try {
      final Reference ref = _storage.refFromURL(url);
      await ref.delete();
    } on FirebaseException catch (e) {
      throw FirebaseErrors.mapMessage(e.code);
    } catch (e) {
      throw FirebaseErrors.getErrorMessage(e);
    }
  }

  /// Obtiene la URL pública de descarga para un archivo almacenado en [storagePath].
  Future<String> getDownloadUrl(String storagePath) async {
    try {
      return await _storage.ref().child(storagePath).getDownloadURL();
    } on FirebaseException catch (e) {
      throw FirebaseErrors.mapMessage(e.code);
    } catch (e) {
      throw FirebaseErrors.getErrorMessage(e);
    }
  }
}
