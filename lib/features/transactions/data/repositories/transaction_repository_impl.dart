import 'package:core/core.dart' hide Transaction;
import 'package:koralis_app/app/firebase.dart';
import 'package:koralis_app/app/firebase_firestore_config.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

/// Implementación concreta del repositorio de transacciones embebidas
/// en el registro de cada cliente (`users/{userId}/clients/{clienteId}`).
///
/// Garantiza aislamiento total por usuario al operar sobre los clientes
/// correspondientes al usuario activo o inyectado.
class TransactionRepositoryImpl implements TransactionRepository {
  /// Servicio de Cloud Firestore provisto por [AppFirebase] o inyectado para pruebas.
  final FirestoreService _firestore;

  /// Identificador explícito del usuario propietario.
  final String? _userId;

  TransactionRepositoryImpl({
    FirestoreService? firestore,
    String? userId,
  })  : _firestore = firestore ?? AppFirebase().firestore,
        _userId = userId;

  /// Resuelve la ruta de la colección de clientes según el usuario activo o inyectado.
  String get _collectionPath {
    final uid = _userId ?? AppFirebase().currentUidSafe;
    if (uid != null && uid.trim().isNotEmpty) {
      return FirebaseFirestoreConfig.coleccionClientes(uid.trim());
    }
    return FirebaseFirestoreConfig.colClientes;
  }

  @override
  Future<List<Transaction>> getTransactions({String? clienteId}) async {
    try {
      final List<Transaction> resultado = [];
      final path = _collectionPath;

      if (clienteId != null && clienteId.trim().isNotEmpty) {
        // Consultar el documento específico del cliente del usuario
        final clientDoc = await _firestore.getDocument(
          collectionPath: path,
          docId: clienteId.trim(),
        );

        if (clientDoc != null) {
          final clienteNombre = clientDoc['nombre'] as String? ?? '';
          final rawList = clientDoc[FirebaseFirestoreConfig.campoTransacciones];
          if (rawList is List) {
            for (final item in rawList.whereType<Map>()) {
              final map = Map<String, dynamic>.from(item);
              final txId = map['id'] as String? ?? '';
              final tx = Transaction.fromMap(map, txId);
              resultado.add(
                tx.copyWith(
                  clienteId: clienteId.trim(),
                  clienteNombre: tx.clienteNombre.isNotEmpty
                      ? tx.clienteNombre
                      : clienteNombre,
                ),
              );
            }
          }
        }
      } else {
        // Consultar todos los clientes del usuario y unificar sus transacciones
        final clientDocs = await _firestore.getCollection(
          collectionPath: path,
        );

        for (final clientDoc in clientDocs) {
          final cId = clientDoc['id'] as String? ?? '';
          final cNombre = clientDoc['nombre'] as String? ?? '';
          final rawList = clientDoc[FirebaseFirestoreConfig.campoTransacciones];

          if (rawList is List) {
            for (final item in rawList.whereType<Map>()) {
              final map = Map<String, dynamic>.from(item);
              final txId = map['id'] as String? ?? '';
              final tx = Transaction.fromMap(map, txId);
              resultado.add(
                tx.copyWith(
                  clienteId: tx.clienteId.isNotEmpty ? tx.clienteId : cId,
                  clienteNombre: tx.clienteNombre.isNotEmpty
                      ? tx.clienteNombre
                      : cNombre,
                ),
              );
            }
          }
        }
      }

      // Orden cronológico descendente (las más recientes primero)
      resultado.sort((a, b) => b.fecha.compareTo(a.fecha));
      return resultado;
    } catch (_) {
      return <Transaction>[];
    }
  }

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    final cId = transaction.clienteId.trim();
    if (cId.isEmpty) {
      throw ArgumentError('clienteId no puede estar vacío');
    }

    final path = _collectionPath;

    final clientDoc = await _firestore.getDocument(
      collectionPath: path,
      docId: cId,
    );

    if (clientDoc == null) {
      throw StateError('El cliente con ID $cId no existe en Firestore para este usuario');
    }

    final rawList = List<Map<String, dynamic>>.from(
      (clientDoc[FirebaseFirestoreConfig.campoTransacciones] as List?)
              ?.whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m)) ??
          [],
    );

    // Asignar ID existente o generar uno alfanumérico estándar de Firestore
    final txId = transaction.id.trim().isNotEmpty
        ? transaction.id.trim()
        : _firestore.newDocumentId(FirebaseFirestoreConfig.campoTransacciones);

    final clienteNombre = transaction.clienteNombre.trim().isNotEmpty
        ? transaction.clienteNombre.trim()
        : (clientDoc['nombre'] as String? ?? '');

    final txCompleta = transaction.copyWith(
      id: txId,
      clienteId: cId,
      clienteNombre: clienteNombre,
    );

    final txMap = txCompleta.toMap();
    txMap['id'] = txId;

    final existingIndex =
        rawList.indexWhere((m) => (m['id'] as String? ?? '') == txId);
    if (existingIndex >= 0) {
      rawList[existingIndex] = txMap;
    } else {
      rawList.insert(0, txMap);
    }

    await _firestore.setDocument(
      collectionPath: path,
      docId: cId,
      data: {
        FirebaseFirestoreConfig.campoTransacciones: rawList,
      },
      merge: true,
    );
  }

  @override
  Future<void> deleteTransaction(String id, {String? clienteId}) async {
    final path = _collectionPath;

    if (clienteId != null && clienteId.trim().isNotEmpty) {
      await _eliminarDeCliente(clienteId.trim(), id, path);
      return;
    }

    // Si no se proporcionó clienteId, buscar en todos los clientes del usuario
    final clientDocs = await _firestore.getCollection(
      collectionPath: path,
    );

    for (final doc in clientDocs) {
      final rawList = doc[FirebaseFirestoreConfig.campoTransacciones];
      if (rawList is List) {
        final existe = rawList.any((m) => m is Map && (m['id'] == id));
        if (existe) {
          final cId = doc['id'] as String? ?? '';
          if (cId.isNotEmpty) {
            await _eliminarDeCliente(cId, id, path);
            break;
          }
        }
      }
    }
  }

  Future<void> _eliminarDeCliente(String cId, String txId, String path) async {
    final clientDoc = await _firestore.getDocument(
      collectionPath: path,
      docId: cId,
    );
    if (clientDoc == null) return;

    final rawList = List<Map<String, dynamic>>.from(
      (clientDoc[FirebaseFirestoreConfig.campoTransacciones] as List?)
              ?.whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m)) ??
          [],
    );

    rawList.removeWhere((m) => (m['id'] as String? ?? '') == txId);

    await _firestore.setDocument(
      collectionPath: path,
      docId: cId,
      data: {
        FirebaseFirestoreConfig.campoTransacciones: rawList,
      },
      merge: true,
    );
  }
}

