import '../entities/pet.dart';
import '../repositories/pet_repository.dart';

class GetPetsUseCase {
  final PetRepository repository;

  GetPetsUseCase(this.repository);

  Future<List<Pet>> execute() async {
    return await repository.getPets();
  }
}
