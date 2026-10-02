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
  });
}
