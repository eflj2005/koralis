import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart' hide Transaction;
import 'package:koralis_app/app/firebase_firestore_config.dart';
import 'package:koralis_app/features/clients/data/repositories/client_repository_impl.dart';
import 'package:koralis_app/features/clients/domain/entities/client.dart';
import 'package:koralis_app/features/instruments/data/repositories/instrument_repository_impl.dart';
import 'package:koralis_app/features/instruments/data/repositories/bank_repository_impl.dart';
import 'package:koralis_app/features/instruments/domain/entities/instrument.dart';
import 'package:koralis_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:koralis_app/features/transactions/domain/entities/transaction.dart';

/// Implementación simulada en memoria de [FirestoreService] para validar rutas de aislamiento multiusuario.
class FakeMultiUserFirestoreService implements FirestoreService {
  final Map<String, Map<String, Map<String, dynamic>>> almacenamiento = {};

  @override
  String newDocumentId(String collectionPath) {
    return 'doc_${DateTime.now().microsecondsSinceEpoch}';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<String> setDocument({
    required String collectionPath,
    required Map<String, dynamic> data,
    String? docId,
    bool merge = true,
  }) async {
    final coleccion = almacenamiento.putIfAbsent(collectionPath, () => {});
    final id = docId ?? 'id_auto_${coleccion.length + 1}';
    if (merge && coleccion.containsKey(id)) {
      coleccion[id]!.addAll(data);
    } else {
      coleccion[id] = Map<String, dynamic>.from(data)..['id'] = id;
    }
    return id;
  }

  @override
  Future<Map<String, dynamic>?> getDocument({
    required String collectionPath,
    required String docId,
  }) async {
    final coleccion = almacenamiento[collectionPath];
    if (coleccion == null || !coleccion.containsKey(docId)) return null;
    return Map<String, dynamic>.from(coleccion[docId]!);
  }

  @override
  Future<List<Map<String, dynamic>>> getCollection({
    required String collectionPath,
    dynamic queryBuilder,
  }) async {
    final coleccion = almacenamiento[collectionPath];
    if (coleccion == null) return [];
    return coleccion.values.map((doc) => Map<String, dynamic>.from(doc)).toList();
  }
}

void main() {
  group('Aislamiento Multiusuario en Repositorios (Opción A)', () {
    late FakeMultiUserFirestoreService fakeFirestore;

    setUp(() {
      fakeFirestore = FakeMultiUserFirestoreService();
    });

    test('ClientRepositoryImpl debe persistir y consultar en users/{userId}/clients', () async {
      const usuario1 = 'usuario-101';
      const usuario2 = 'usuario-202';

      final repoUsuario1 = ClientRepositoryImpl(
        firestore: fakeFirestore,
        userId: usuario1,
      );
      final repoUsuario2 = ClientRepositoryImpl(
        firestore: fakeFirestore,
        userId: usuario2,
      );

      // Crear cliente para usuario 1
      final clienteU1 = Client(
        id: 'cli-u1',
        nombre: 'Cliente del Usuario 1',
        documento: '11111111',
        correo: 'u1@test.com',
        telefono: '3001111111',
      );
      await repoUsuario1.addClient(clienteU1);

      // Crear cliente para usuario 2
      final clienteU2 = Client(
        id: 'cli-u2',
        nombre: 'Cliente del Usuario 2',
        documento: '22222222',
        correo: 'u2@test.com',
        telefono: '3002222222',
      );
      await repoUsuario2.addClient(clienteU2);

      // Verificar que los datos físicos quedaron en subcolecciones separadas
      expect(
        fakeFirestore.almacenamiento.containsKey('users/$usuario1/clients'),
        isTrue,
      );
      expect(
        fakeFirestore.almacenamiento.containsKey('users/$usuario2/clients'),
        isTrue,
      );

      // Usuario 1 solo debe ver sus clientes
      final clientesU1 = await repoUsuario1.getClients();
      expect(clientesU1.length, 1);
      expect(clientesU1.first.id, 'cli-u1');
      expect(clientesU1.first.nombre, 'Cliente del Usuario 1');
      expect(clientesU1.first.userId, usuario1);

      // Usuario 2 solo debe ver sus clientes
      final clientesU2 = await repoUsuario2.getClients();
      expect(clientesU2.length, 1);
      expect(clientesU2.first.id, 'cli-u2');
      expect(clientesU2.first.nombre, 'Cliente del Usuario 2');
      expect(clientesU2.first.userId, usuario2);
    });

    test('InstrumentRepositoryImpl debe persistir y consultar en users/{userId}/instruments', () async {
      const usuarioA = 'usuario-alfa';
      const usuarioB = 'usuario-beta';

      final repoAlfa = InstrumentRepositoryImpl(
        firestore: fakeFirestore,
        userId: usuarioA,
      );
      final repoBeta = InstrumentRepositoryImpl(
        firestore: fakeFirestore,
        userId: usuarioB,
      );

      final instAlfa = Instrument(
        id: 'inst-alfa',
        numero: 'CDT-ALFA-01',
        entidad: 'Bancolombia',
        fechaApertura: DateTime(2026, 1, 1),
        dias: 90,
        tasaIea: 12.5,
        valorInvertido: 10000000.0,
        rendimientoTProyec: 300000.0,
      );
      await repoAlfa.saveInstrument(instAlfa);

      // Verificar que está en users/usuario-alfa/instruments
      expect(
        fakeFirestore.almacenamiento.containsKey('users/$usuarioA/instruments'),
        isTrue,
      );

      // Alfa debe ver su instrumento
      final instrumentosAlfa = await repoAlfa.getInstruments();
      expect(instrumentosAlfa.length, 1);
      expect(instrumentosAlfa.first.numero, 'CDT-ALFA-01');
      expect(instrumentosAlfa.first.userId, usuarioA);

      // Beta NO debe ver el instrumento de Alfa
      final instrumentosBeta = await repoBeta.getInstruments();
      expect(instrumentosBeta, isEmpty);
    });

    test('TransactionRepositoryImpl debe guardar transacciones en el cliente del usuario activo', () async {
      const usuarioX = 'usuario-x';
      const usuarioY = 'usuario-y';

      final txRepoX = TransactionRepositoryImpl(
        firestore: fakeFirestore,
        userId: usuarioX,
      );
      final txRepoY = TransactionRepositoryImpl(
        firestore: fakeFirestore,
        userId: usuarioY,
      );

      // Sembrar cliente en el espacio del usuario X
      await fakeFirestore.setDocument(
        collectionPath: 'users/$usuarioX/clients',
        docId: 'cli-x-1',
        data: {
          'id': 'cli-x-1',
          'nombre': 'Cliente de X',
          'transacciones': <Map<String, dynamic>>[],
        },
      );

      // Guardar transacción a través de txRepoX
      final txX = Transaction(
        id: 'tx-001',
        clienteId: 'cli-x-1',
        clienteNombre: 'Cliente de X',
        tipo: TransactionType.recarga,
        valor: 500000.0,
        fecha: DateTime(2026, 3, 1),
      );
      await txRepoX.saveTransaction(txX);

      // Las transacciones de X deben contener la nueva transacción
      final txListX = await txRepoX.getTransactions();
      expect(txListX.length, 1);
      expect(txListX.first.id, 'tx-001');

      // Las transacciones de Y deben estar completamente vacías
      final txListY = await txRepoY.getTransactions();
      expect(txListY, isEmpty);
    });

    test('BankRepositoryImpl debe continuar operando sobre la colección global "banks"', () async {
      // Sembrar bancos globales en la colección raíz
      await fakeFirestore.setDocument(
        collectionPath: FirebaseFirestoreConfig.colBancos,
        docId: 'bank-1',
        data: {'id': 'bank-1', 'nombre': 'Bancolombia'},
      );
      await fakeFirestore.setDocument(
        collectionPath: FirebaseFirestoreConfig.colBancos,
        docId: 'bank-2',
        data: {'id': 'bank-2', 'nombre': 'Davivienda'},
      );

      final bankRepo = BankRepositoryImpl(firestore: fakeFirestore);
      final bancos = await bankRepo.getBanks();

      expect(bancos.length, 2);
      expect(bancos.map((b) => b.nombre), containsAll(['Bancolombia', 'Davivienda']));
    });
  });
}
