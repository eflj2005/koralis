import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';
import 'package:koralis_app/features/instruments/data/repositories/instrument_repository_impl.dart';
import 'package:koralis_app/features/instruments/domain/entities/instrument.dart';

/// Implementación simulada de [FirestoreService] para probar la persistencia de instrumentos.
class FakeFirestoreService implements FirestoreService {
  final Map<String, Map<String, Map<String, dynamic>>> _storage = {};
  int _idCounter = 0;

  @override
  String newDocumentId(String collectionPath) {
    _idCounter++;
    return 'fakeInstDocIdAlfa${_idCounter.toString().padLeft(4, '0')}';
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

  @override
  Future<void> deleteDocument({
    required String collectionPath,
    required String docId,
  }) async {
    _storage[collectionPath]?.remove(docId);
  }
}

void main() {
  group('InstrumentRepositoryImpl - Persistencia e Identificadores Alfanuméricos', () {
    late FakeFirestoreService fakeFirestore;
    late InstrumentRepositoryImpl repository;

    setUp(() {
      fakeFirestore = FakeFirestoreService();
      repository = InstrumentRepositoryImpl(firestore: fakeFirestore);
    });

    test('saveInstrument debe asignar un ID alfanumérico si el instrumento es nuevo con ID vacío', () async {
      final nuevoInstrumento = Instrument(
        id: '', // Se envía vacío desde el formulario de creación
        numero: 'CDT-998877',
        entidad: 'Bancolombia',
        fechaApertura: DateTime(2026, 4, 1),
        dias: 180,
        tasaIea: 11.5,
        valorInvertido: 5000000,
        rendimientoTProyec: 287500,
      );

      await repository.saveInstrument(nuevoInstrumento);

      final instrumentos = await repository.getInstruments();
      expect(instrumentos.length, equals(1));
      final guardado = instrumentos.first;
      expect(guardado.numero, equals('CDT-998877'));
      expect(guardado.entidad, equals('Bancolombia'));
      // Debe haber generado un ID alfanumérico y no numérico
      expect(guardado.id, startsWith('fakeInstDocIdAlfa'));
      expect(guardado.id.contains(RegExp(r'[a-zA-Z]')), isTrue);
    });

    test('saveInstrument debe conservar el ID existente en modo edición', () async {
      final existente = Instrument(
        id: 'instExistenteAlfa99',
        numero: 'CDT-112233',
        entidad: 'Davivienda',
        fechaApertura: DateTime(2026, 1, 1),
        dias: 90,
        tasaIea: 10.0,
        valorInvertido: 10000000,
        rendimientoTProyec: 250000,
      );

      await repository.saveInstrument(existente);

      final instrumentos = await repository.getInstruments();
      expect(instrumentos.length, equals(1));
      expect(instrumentos.first.id, equals('instExistenteAlfa99'));
    });

    test('saveInstrument y getInstruments deben serializar y deserializar aportes correctamente', () async {
      final fechaAporte = DateTime(2026, 5, 2, 9, 15);
      final instrumentoConAportes = Instrument(
        id: 'instConAportes1',
        numero: 'CDT-AP-01',
        entidad: 'Bancolombia',
        fechaApertura: DateTime(2026, 5, 1),
        dias: 90,
        tasaIea: 11.0,
        valorInvertido: 15000000,
        rendimientoTProyec: 400000,
        estado: 'Borrador',
        aportes: [
          InstrumentContribution(
            clienteId: 'cli-1',
            clienteNombre: 'Carlos Santana',
            valor: 10000000,
            fecha: fechaAporte,
          ),
          InstrumentContribution(
            clienteId: 'cli-2',
            clienteNombre: 'Mariana Pajón',
            valor: 5000000,
            fecha: fechaAporte,
            transaccionId: 'inv_instConAportes1_cli-2',
          ),
        ],
      );

      await repository.saveInstrument(instrumentoConAportes);

      final recuperados = await repository.getInstruments();
      expect(recuperados.length, equals(1));
      final inst = recuperados.first;
      expect(inst.aportes.length, equals(2));
      expect(inst.aportes[0].clienteId, equals('cli-1'));
      expect(inst.aportes[0].valor, equals(10000000));
      expect(inst.aportes[0].transaccionId, isNull);
      expect(inst.aportes[1].clienteId, equals('cli-2'));
      expect(inst.aportes[1].transaccionId, equals('inv_instConAportes1_cli-2'));
    });
  });
}
