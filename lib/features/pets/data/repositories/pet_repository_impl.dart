import '../../domain/entities/pet.dart';
import '../../domain/repositories/pet_repository.dart';
import 'package:koralis_app/app/database.dart';

class PetRepositoryImpl implements PetRepository {
  final AppDatabase _db = AppDatabase();

  @override
  Future<List<Pet>> getPets() async {
    // Retraso opcional para simular red/UX
    await Future.delayed(const Duration(seconds: 1));

    final petsData = await _db.getPets();

    return petsData.map((data) {
      return Pet(
        id: data['id'] as int,
        nombre: data['nombre'] as String,
        edad: data['edad'] as int,
        raza: data['raza'] as String,
        peso: (data['peso'] as num).toDouble(),
        imagen: data['imagen'] as int,
      );
    }).toList();
  }
}
