import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_errors.dart';

/// Servicio genérico desacoplado para realizar operaciones CRUD y consultas en Cloud Firestore.
class FirestoreService {
  final FirebaseFirestore _firestore;

  /// Constructor que permite inyectar una instancia de [FirebaseFirestore].
  /// Si no se proporciona, se utiliza la instancia por defecto `FirebaseFirestore.instance`.
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Obtiene la instancia subyacente de [FirebaseFirestore].
  FirebaseFirestore get instance => _firestore;

  /// Crea un nuevo documento en la colección [collectionPath].
  /// 
  /// Si [docId] es nulo o no se especifica, Firestore generará un ID único de forma automática.
  /// Retorna el ID del documento creado o actualizado.
  Future<String> setDocument({
    required String collectionPath,
    required Map<String, dynamic> data,
    String? docId,
    bool merge = true,
  }) async {
    try {
      final collectionRef = _firestore.collection(collectionPath);
      final docRef = docId != null ? collectionRef.doc(docId) : collectionRef.doc();
      
      await docRef.set(data, SetOptions(merge: merge));
      return docRef.id;
    } on FirebaseException catch (e) {
      throw FirebaseErrors.mapMessage(e.code);
    } catch (e) {
      throw FirebaseErrors.getErrorMessage(e);
    }
  }

  /// Actualiza campos específicos de un documento existente en [collectionPath] con ID [docId].
  Future<void> updateDocument({
    required String collectionPath,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).update(data);
    } on FirebaseException catch (e) {
      throw FirebaseErrors.mapMessage(e.code);
    } catch (e) {
      throw FirebaseErrors.getErrorMessage(e);
    }
  }

  /// Elimina un documento específico en [collectionPath] identificado por [docId].
  Future<void> deleteDocument({
    required String collectionPath,
    required String docId,
  }) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).delete();
    } on FirebaseException catch (e) {
      throw FirebaseErrors.mapMessage(e.code);
    } catch (e) {
      throw FirebaseErrors.getErrorMessage(e);
    }
  }

  /// Obtiene los datos de un documento específico como un `Map<String, dynamic>`.
  /// 
  /// Retorna `null` si el documento no existe en la base de datos.
  Future<Map<String, dynamic>?> getDocument({
    required String collectionPath,
    required String docId,
  }) async {
    try {
      final docSnapshot =
          await _firestore.collection(collectionPath).doc(docId).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        data['id'] = docSnapshot.id;
        return data;
      }
      return null;
    } on FirebaseException catch (e) {
      throw FirebaseErrors.mapMessage(e.code);
    } catch (e) {
      throw FirebaseErrors.getErrorMessage(e);
    }
  }

  /// Obtiene una lista de documentos de la colección [collectionPath].
  /// 
  /// Permite aplicar filtros, ordenamiento o límites mediante el parámetro opcional [queryBuilder].
  Future<List<Map<String, dynamic>>> getCollection({
    required String collectionPath,
    Query Function(Query query)? queryBuilder,
  }) async {
    try {
      Query query = _firestore.collection(collectionPath);
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } on FirebaseException catch (e) {
      throw FirebaseErrors.mapMessage(e.code);
    } catch (e) {
      throw FirebaseErrors.getErrorMessage(e);
    }
  }

  /// Transmite en tiempo real (Stream) los datos de un documento específico.
  Stream<Map<String, dynamic>?> streamDocument({
    required String collectionPath,
    required String docId,
  }) {
    return _firestore
        .collection(collectionPath)
        .doc(docId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        data['id'] = snapshot.id;
        return data;
      }
      return null;
    });
  }

  /// Transmite en tiempo real (Stream) la lista de documentos de una colección.
  /// 
  /// Soporta el filtrado de consultas mediante [queryBuilder].
  Stream<List<Map<String, dynamic>>> streamCollection({
    required String collectionPath,
    Query Function(Query query)? queryBuilder,
  }) {
    Query query = _firestore.collection(collectionPath);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }

    return query.snapshots().map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
}
