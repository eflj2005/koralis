// =============================================================================
// ⚠️ [DEPRECATED / BORRAR] - CÓDIGO DE REFERENCIA TEMPORAL (PETCARE)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:core/core.dart';
import '../../pets/domain/entities/pet.dart';
import '../../pets/domain/usecases/get_pets_usecase.dart';
import '../../pets/data/repositories/pet_repository_impl.dart';

/// Pantalla de listado de mascotas.
/// 
/// ⚠️ **OBSOLETO**: Mantenido temporalmente como referencia arquitectónica. Pendiente de borrar.
// ignore: deprecated_member_use_from_same_package
@Deprecated('Código de referencia temporal de PetCare. Será eliminado al construir Koralis.')
class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key});

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

// ignore: deprecated_member_use_from_same_package
class _PetsScreenState extends State<PetsScreen> {
  // ignore: deprecated_member_use_from_same_package
  late final GetPetsUseCase _getPetsUseCase;
  // ignore: deprecated_member_use_from_same_package
  Future<List<Pet>>? _petsFuture;

  @override
  void initState() {
    super.initState();
    // ignore: deprecated_member_use_from_same_package
    _getPetsUseCase = GetPetsUseCase(PetRepositoryImpl());
    _loadPets();
  }

  void _loadPets() {
    setState(() {
      _petsFuture = _getPetsUseCase.execute();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Mascotas'),
        centerTitle: true,
      ),
      // ignore: deprecated_member_use_from_same_package
      body: FutureBuilder<List<Pet>>(
        future: _petsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          } else if (snapshot.hasError) {
            return const EmptyWidget(
              titulo: 'Error al cargar las mascotas',
              icono: Icons.error_outline,
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const EmptyWidget(
              titulo: 'Aún no tienes mascotas registradas.',
              icono: Icons.pets,
            );
          }

          final pets = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pets.length,
            itemBuilder: (context, index) {
              final pet = pets[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    radius: 28,
                    child: Icon(
                      // ignore: non_const_argument_for_const_parameter
                      IconData(pet.iconoCodigo, fontFamily: 'MaterialIcons'),
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 28,
                    ),
                  ),
                  title: Text(
                    pet.nombre,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  subtitle: Text(
                    'Raza: ${pet.raza}\nEdad: ${pet.edad} años',
                    style: theme.textTheme.bodyMedium,
                  ),
                  isThreeLine: true,
                  trailing: Text(
                    '${pet.peso} kg',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showUnderConstructionDialog(context, accion: 'Agregar mascota');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
