import 'package:core/core.dart';
import 'package:koralis_app/app/firebase.dart';
import 'package:koralis_app/app/firebase_firestore_config.dart';
import '../../domain/entities/bank.dart';
import '../../domain/repositories/bank_repository.dart';

/// Implementación del repositorio de bancos que consulta la colección 'banks' en Cloud Firestore.
class BankRepositoryImpl implements BankRepository {
  final FirestoreService _firestore;

  BankRepositoryImpl({FirestoreService? firestore})
      : _firestore = firestore ?? AppFirebase().firestore;

  @override
  Future<List<Bank>> getBanks() async {
    try {
      final docs = await _firestore.getCollection(
        collectionPath: FirebaseFirestoreConfig.colBancos,
      );

      final bancos = docs
          .map((data) => Bank.fromMap(data, id: data['id'] as String?))
          .where((b) => b.nombre.isNotEmpty)
          .toList();

      // Ordenar alfabéticamente por nombre de banco
      bancos.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
      return bancos;
    } catch (_) {
      return <Bank>[];
    }
  }
}
