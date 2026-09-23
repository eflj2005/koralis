import 'package:core/core.dart';
import 'package:koralis_app/app/firebase.dart';
import 'package:koralis_app/app/firebase_firestore_config.dart';
import '../../domain/entities/client.dart';
import '../../domain/repositories/client_repository.dart';

/// Implementación concreta del repositorio de clientes utilizando Cloud Firestore.
///
/// La colección `'clients'` se crea dinámicamente en Firestore al registrar
/// el primer cliente. Si la colección aún no contiene registros, retorna una lista vacía.
class ClientRepositoryImpl implements ClientRepository {
  /// Servicio de Cloud Firestore provisto por [AppFirebase] o inyectado para pruebas.
  final FirestoreService _firestore;

  ClientRepositoryImpl({FirestoreService? firestore})
      : _firestore = firestore ?? AppFirebase().firestore;

  @override
  Future<List<Client>> getClients() async {
    try {
      // Consultar todos los documentos de la colección 'clients'
      final docs = await _firestore.getCollection(
        collectionPath: FirebaseFirestoreConfig.colClientes,
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

        return Client(
          id: data['id'] as String? ?? '',
          nombre: data['nombre'] as String? ?? '',
          documento: data['documento'] as String? ?? '',
          correo: data['correo'] as String? ?? '',
          telefono: data['telefono'] as String? ?? '',
          observacion: data['observacion'] as String? ?? (data['tipo'] as String? ?? ''),
          estado: data['estado'] as String? ?? 'Activo',
          fechaCreacion: fecha,
        );
      }).toList();
    } catch (_) {
      // Si la colección aún no existe en Firestore o no hay conectividad, retorna lista vacía segura
      return <Client>[];
    }
  }

  @override
  Future<void> addClient(Client client) async {
    final Map<String, dynamic> datos = {
      'nombre': client.nombre.trim(),
      'documento': client.documento.trim(),
      'correo': client.correo.trim(),
      'telefono': client.telefono.trim(),
      'observacion': client.observacion.trim(),
      'estado': client.estado,
      'fechaCreacion': client.fechaCreacion.millisecondsSinceEpoch,
    };

    // Al guardar el documento se crea la colección 'clients' si no existía previamente
    await _firestore.setDocument(
      collectionPath: FirebaseFirestoreConfig.colClientes,
      data: datos,
      docId: client.id.isNotEmpty ? client.id : null,
    );
  }
}
