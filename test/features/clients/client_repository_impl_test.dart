import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart' hide Transaction;
import 'package:koralis_app/features/clients/data/repositories/client_repository_impl.dart';
import 'package:koralis_app/features/clients/domain/entities/client.dart';

/// Implementación simulada de [FirestoreService] para probar la generación y persistencia de clientes.
class FakeFirestoreService implements FirestoreService {
  final Map<String, Map<String, Map<String, dynamic>>> _storage = {};
  int _idCounter = 0;

  @override
  String newDocumentId(String collectionPath) {
    _idCounter++;
    // Genera un identificador alfanumérico simulando el formato de 20 caracteres de Firestore
    return 'fakeDocIdAlfanum${_idCounter.toString().padLeft(4, '0')}';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Map<String, dynamic>?> getDocument({
    required String collectionPath,
    required String docId,
  }) async {
    final col = _storage[collectionPath];
    if (col == null || !col.containsKey(docId)) return null;
    return Map<String, dynamic>.from(col[docId]!);
  }

  @override
  Future<String> setDocument({
    required String collectionPath,
    required Map<String, dynamic> data,
    String? docId,
    bool merge = true,
  }) async {
    final col = _storage.putIfAbsent(collectionPath, () => {});
    final id = docId ?? newDocumentId(collectionPath);
    if (merge && col.containsKey(id)) {
      col[id]!.addAll(data);
    } else {
      col[id] = Map<String, dynamic>.from(data)..['id'] = id;
    }
    return id;
  }

  @override
  Future<List<Map<String, dynamic>>> getCollection({
    required String collectionPath,
    dynamic queryBuilder,
  }) async {
    final col = _storage[collectionPath];
    if (col == null) return [];
    return col.values.map((v) => Map<String, dynamic>.from(v)).toList();
  }
}

void main() {
  group('ClientRepositoryImpl - Persistencia e Identificadores Alfanuméricos', () {
    late FakeFirestoreService fakeFirestore;
    late ClientRepositoryImpl repository;

    setUp(() {
      fakeFirestore = FakeFirestoreService();
      repository = ClientRepositoryImpl(firestore: fakeFirestore);
    });

    test('addClient debe generar un ID alfanumérico de Firestore cuando el cliente tiene ID vacío', () async {
      final nuevoCliente = Client(
        id: '', // Se envía vacío desde el formulario de creación
        nombre: 'Andrés Cepeda',
        documento: 'CC 12345678',
        correo: 'andres@koralis.com',
        telefono: '+57 300 123 4567',
        observacion: 'Cliente nuevo',
      );

      await repository.addClient(nuevoCliente);

      final clientes = await repository.getClients();
      expect(clientes.length, equals(1));
      final guardado = clientes.first;
      expect(guardado.nombre, equals('Andrés Cepeda'));
      expect(guardado.documento, equals('CC 12345678'));
      // Debe haber generado un ID alfanumérico y no numérico
      expect(guardado.id, startsWith('fakeDocIdAlfanum'));
      expect(guardado.id.contains(RegExp(r'[a-zA-Z]')), isTrue);
    });

    test('addClient debe conservar el ID existente cuando se edita un cliente', () async {
      final clienteExistente = Client(
        id: 'idExistenteAlfa123',
        nombre: 'Andrés Cepeda Editado',
        documento: 'CC 12345678',
        correo: 'andres@koralis.com',
        telefono: '+57 300 123 4567',
      );

      await repository.addClient(clienteExistente);

      final clientes = await repository.getClients();
      expect(clientes.length, equals(1));
      expect(clientes.first.id, equals('idExistenteAlfa123'));
    });
  });
}
