import 'package:core/core.dart' hide Transaction;
import 'package:koralis_app/app/firebase.dart';
import 'package:koralis_app/app/firebase_firestore_config.dart';
import 'package:koralis_app/features/transactions/domain/entities/transaction.dart';
import '../../domain/entities/client.dart';
import '../../domain/repositories/client_repository.dart';

/// Implementación concreta del repositorio de clientes utilizando Cloud Firestore.
///
/// Soporta arquitectura multiusuario aislando los clientes bajo la ruta jerárquica
/// `users/{userId}/clients`. Si no se especifica un `userId`, se resuelve dinámicamente
/// a partir de la sesión activa en [AppFirebase].
class ClientRepositoryImpl implements ClientRepository {
  /// Servicio de Cloud Firestore provisto por [AppFirebase] o inyectado para pruebas.
  final FirestoreService _firestore;

  /// Identificador explícito del usuario propietario de los clientes.
  final String? _userId;

  ClientRepositoryImpl({
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
  Future<List<Client>> getClients() async {
    try {
      final path = _collectionPath;

      // Consultar todos los documentos de la colección de clientes del usuario
      final docs = await _firestore.getCollection(
        collectionPath: path,
      );

      // Mapear cada documento a la entidad de dominio [Client]
      return docs.map((data) {
        DateTime fecha = DateTime.now();
        if (data['fechaCreacion'] != null) {
          if (data['fechaCreacion'] is int) {
            fecha = DateTime.fromMillisecondsSinceEpoch(data['fechaCreacion'] as int);
          } else if (data['fechaCreacion'] is String) {
            fecha = DateTime.tryParse(data['fechaCreacion'] as String) ?? DateTime.now();
          }
        }

        final rawTxList = data[FirebaseFirestoreConfig.campoTransacciones];
        List<Transaction> txs = [];
        if (rawTxList is List) {
          txs = rawTxList
              .whereType<Map>()
              .map((m) => Transaction.fromMap(
                    Map<String, dynamic>.from(m),
                    m['id'] as String?,
                  ))
              .toList();
        }

        return Client(
          id: data['id'] as String? ?? '',
          nombre: data['nombre'] as String? ?? '',
          documento: data['documento'] as String? ?? '',
          correo: data['correo'] as String? ?? '',
          telefono: data['telefono'] as String? ?? '',
          observacion: data['observacion'] as String? ?? (data['tipo'] as String? ?? ''),
          estado: data['estado'] as String? ?? 'Activo',
          transacciones: txs,
          fechaCreacion: fecha,
          userId: data['userId'] as String? ?? _userId ?? AppFirebase().currentUidSafe,
        );
      }).toList();
    } catch (_) {
      // Si la colección aún no existe en Firestore o no hay conectividad, retorna lista vacía segura
      return <Client>[];
    }
  }

  @override
  Future<void> addClient(Client client) async {
    final path = _collectionPath;
    final uidActual = client.userId ?? _userId ?? AppFirebase().currentUidSafe;

    // Si el cliente no posee un identificador previo, se genera uno alfanumérico nativo de Firestore
    final docId = client.id.trim().isNotEmpty
        ? client.id.trim()
        : _firestore.newDocumentId(path);

    final Map<String, dynamic> datos = {
      'nombre': client.nombre.trim(),
      'documento': client.documento.trim(),
      'correo': client.correo.trim(),
      'telefono': client.telefono.trim(),
      'observacion': client.observacion.trim(),
      'estado': client.estado,
      'fechaCreacion': client.fechaCreacion.millisecondsSinceEpoch,
    };

    if (uidActual != null && uidActual.trim().isNotEmpty) {
      datos['userId'] = uidActual.trim();
    }

    if (client.transacciones.isNotEmpty) {
      datos[FirebaseFirestoreConfig.campoTransacciones] =
          client.transacciones.map((t) => t.toMap()).toList();
    }

    // Persistir en la ruta aislada del usuario
    await _firestore.setDocument(
      collectionPath: path,
      data: datos,
      docId: docId,
    );
  }
}

