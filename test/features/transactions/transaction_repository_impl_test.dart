import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart' hide Transaction;
import 'package:koralis_app/app/firebase_firestore_config.dart';
import 'package:koralis_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:koralis_app/features/transactions/domain/entities/transaction.dart';

class FakeFirestoreService implements FirestoreService {
  final Map<String, Map<String, Map<String, dynamic>>> _storage = {};

  void seedClient(String id, Map<String, dynamic> data) {
    _storage.putIfAbsent(FirebaseFirestoreConfig.colClientes, () => {});
    _storage[FirebaseFirestoreConfig.colClientes]![id] = {
      'id': id,
      ...data,
    };
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
    final id = docId ?? 'doc_${col.length + 1}';
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
  group('TransactionRepositoryImpl - Persistencia Embebida en Cliente', () {
    late FakeFirestoreService fakeFirestore;
    late TransactionRepositoryImpl repository;

    setUp(() {
      fakeFirestore = FakeFirestoreService();
      repository = TransactionRepositoryImpl(firestore: fakeFirestore);

      // Sembrar clientes de prueba
      fakeFirestore.seedClient('cli-1', {
        'nombre': 'Carlos Gómez',
        'documento': '12345678',
        'transacciones': <Map<String, dynamic>>[],
      });
      fakeFirestore.seedClient('cli-2', {
        'nombre': 'Mariana Duarte',
        'documento': '87654321',
        'transacciones': <Map<String, dynamic>>[],
      });
    });

    test('saveTransaction debe registrar la transacción en el subobjeto del cliente', () async {
      final tx = Transaction(
        id: 'tx-100',
        clienteId: 'cli-1',
        clienteNombre: 'Carlos Gómez',
        tipo: TransactionType.recarga,
        valor: 1500000.0,
        fecha: DateTime(2026, 3, 1),
        observacion: 'Abono inicial',
      );

      await repository.saveTransaction(tx);

      final clienteDoc = await fakeFirestore.getDocument(
        collectionPath: FirebaseFirestoreConfig.colClientes,
        docId: 'cli-1',
      );

      expect(clienteDoc, isNotNull);
      final transacciones = clienteDoc![FirebaseFirestoreConfig.campoTransacciones] as List;
      expect(transacciones.length, 1);
      expect(transacciones.first['id'], 'tx-100');
      expect(transacciones.first['valor'], 1500000.0);
      expect(transacciones.first['tipo'], 'recarga');
      expect(transacciones.first['observacion'], 'Abono inicial');
    });

    test('saveTransaction debe actualizar una transacción existente en el array', () async {
      final tx1 = Transaction(
        id: 'tx-100',
        clienteId: 'cli-1',
        clienteNombre: 'Carlos Gómez',
        tipo: TransactionType.recarga,
        valor: 1500000.0,
        fecha: DateTime(2026, 3, 1),
      );
      await repository.saveTransaction(tx1);

      // Actualizar monto
      final txActualizada = tx1.copyWith(valor: 2000000.0, observacion: 'Monto corregido');
      await repository.saveTransaction(txActualizada);

      final transacciones = await repository.getTransactions(clienteId: 'cli-1');
      expect(transacciones.length, 1);
      expect(transacciones.first.valor, 2000000.0);
      expect(transacciones.first.observacion, 'Monto corregido');
    });

    test('getTransactions sin clienteId debe unificar y ordenar transacciones de todos los clientes', () async {
      final txCli1 = Transaction(
        id: 'tx-1',
        clienteId: 'cli-1',
        clienteNombre: 'Carlos Gómez',
        tipo: TransactionType.recarga,
        valor: 1000000.0,
        fecha: DateTime(2026, 3, 1),
      );
      final txCli2 = Transaction(
        id: 'tx-2',
        clienteId: 'cli-2',
        clienteNombre: 'Mariana Duarte',
        tipo: TransactionType.retiro,
        valor: 300000.0,
        fecha: DateTime(2026, 3, 5), // Más reciente
      );

      await repository.saveTransaction(txCli1);
      await repository.saveTransaction(txCli2);

      final todas = await repository.getTransactions();
      expect(todas.length, 2);
      // La más reciente primero
      expect(todas.first.id, 'tx-2');
      expect(todas.first.clienteNombre, 'Mariana Duarte');
      expect(todas.last.id, 'tx-1');
      expect(todas.last.clienteNombre, 'Carlos Gómez');
    });

    test('deleteTransaction debe remover la transacción del subobjeto del cliente', () async {
      final tx = Transaction(
        id: 'tx-1',
        clienteId: 'cli-1',
        clienteNombre: 'Carlos Gómez',
        tipo: TransactionType.recarga,
        valor: 500000.0,
        fecha: DateTime(2026, 3, 1),
      );
      await repository.saveTransaction(tx);

      expect((await repository.getTransactions(clienteId: 'cli-1')).length, 1);

      await repository.deleteTransaction('tx-1', clienteId: 'cli-1');

      expect((await repository.getTransactions(clienteId: 'cli-1')).isEmpty, isTrue);
    });
  });
}
