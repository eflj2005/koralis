import 'package:core/core.dart';
import 'package:koralis_app/app/firebase.dart';
import 'package:koralis_app/app/firebase_firestore_config.dart';
import '../../domain/entities/instrument.dart';
import '../../domain/repositories/instrument_repository.dart';

/// Implementación concreta del repositorio de instrumentos utilizando Cloud Firestore.
class InstrumentRepositoryImpl implements InstrumentRepository {
  /// Servicio de Cloud Firestore provisto por [AppFirebase] o inyectado para pruebas.
  final FirestoreService _firestore;

  InstrumentRepositoryImpl({FirestoreService? firestore})
      : _firestore = firestore ?? AppFirebase().firestore;

  @override
  Future<List<Instrument>> getInstruments() async {
    try {
      final docs = await _firestore.getCollection(
        collectionPath: FirebaseFirestoreConfig.colInstrumentos,
      );

      return docs.map((data) {
        DateTime fechaApertura = DateTime.now();
        if (data['fechaApertura'] != null) {
          if (data['fechaApertura'] is int) {
            fechaApertura =
                DateTime.fromMillisecondsSinceEpoch(data['fechaApertura'] as int);
          } else if (data['fechaApertura'] is String) {
            fechaApertura =
                DateTime.tryParse(data['fechaApertura'] as String) ?? DateTime.now();
          }
        }

        DateTime fechaCreacion = DateTime.now();
        if (data['fechaCreacion'] != null) {
          if (data['fechaCreacion'] is int) {
            fechaCreacion =
                DateTime.fromMillisecondsSinceEpoch(data['fechaCreacion'] as int);
          } else if (data['fechaCreacion'] is String) {
            fechaCreacion =
                DateTime.tryParse(data['fechaCreacion'] as String) ?? DateTime.now();
          }
        }

        final rawShares = data['participaciones'] as List<dynamic>? ?? [];
        final participaciones = rawShares
            .whereType<Map<String, dynamic>>()
            .map((m) => InstrumentClientShare.fromMap(m))
            .toList();

        return Instrument(
          id: data['id'] as String? ?? '',
          numero: data['numero'] as String? ?? '',
          entidad: data['entidad'] as String? ?? '',
          fechaApertura: fechaApertura,
          dias: (data['dias'] as num?)?.toInt() ?? 0,
          tasaIea: (data['tasaIea'] as num?)?.toDouble() ?? 0.0,
          valorInvertido: (data['valorInvertido'] as num?)?.toDouble() ?? 0.0,
          rendimientoTProyec:
              (data['rendimientoTProyec'] as num?)?.toDouble() ?? 0.0,
          retencionPorcentaje:
              (data['retencionPorcentaje'] as num?)?.toDouble() ?? 4.0,
          observacion: data['observacion'] as String? ?? '',
          estado: data['estado'] as String? ?? 'Activo',
          fechaCreacion: fechaCreacion,
          participaciones: participaciones,
        );
      }).toList();
    } catch (_) {
      return <Instrument>[];
    }
  }

  @override
  Future<void> saveInstrument(Instrument instrument) async {
    final Map<String, dynamic> datos = {
      'numero': instrument.numero.trim(),
      'entidad': instrument.entidad.trim(),
      'fechaApertura': instrument.fechaApertura.millisecondsSinceEpoch,
      'dias': instrument.dias,
      'tasaIea': instrument.tasaIea,
      'valorInvertido': instrument.valorInvertido,
      'rendimientoTProyec': instrument.rendimientoTProyec,
      'retencionPorcentaje': instrument.retencionPorcentaje,
      'observacion': instrument.observacion.trim(),
      'estado': instrument.estado,
      'fechaCreacion': instrument.fechaCreacion.millisecondsSinceEpoch,
      'participaciones': instrument.participaciones.map((p) => p.toMap()).toList(),
    };

    await _firestore.setDocument(
      collectionPath: FirebaseFirestoreConfig.colInstrumentos,
      data: datos,
      docId: instrument.id.isNotEmpty ? instrument.id : null,
    );
  }

  @override
  Future<void> deleteInstrument(String id) async {
    await _firestore.deleteDocument(
      collectionPath: FirebaseFirestoreConfig.colInstrumentos,
      docId: id,
    );
  }
}
