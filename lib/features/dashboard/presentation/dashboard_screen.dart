import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:koralis_app/features/auth/domain/entities/user.dart';
import 'package:koralis_app/features/pets/domain/entities/pet.dart';
import 'package:koralis_app/features/pets/domain/usecases/get_pets_usecase.dart';
import 'package:koralis_app/features/pets/data/repositories/pet_repository_impl.dart';
import 'package:koralis_app/features/profile/domain/entities/profile.dart';
import 'package:koralis_app/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:koralis_app/features/profile/data/repositories/profile_repository_impl.dart';

class DashboardScreen extends StatefulWidget {
  final User user;

  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final GetProfileUseCase _getProfileUseCase;
  late final GetPetsUseCase _getPetsUseCase;

  Future<Profile>? _profileFuture;
  Future<List<Pet>>? _petsFuture;

  @override
  void initState() {
    super.initState();
    _getProfileUseCase = GetProfileUseCase(ProfileRepositoryImpl());
    _getPetsUseCase = GetPetsUseCase(PetRepositoryImpl());

    // Iniciar carga del perfil usando el id del usuario autenticado
    _profileFuture = _getProfileUseCase.execute(widget.user.id);
    _petsFuture = _getPetsUseCase.execute();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        elevation: 0,
        actions: [
          FutureBuilder<Profile>(
            future: _profileFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final profile = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/profile',
                        arguments: profile,
                      );
                    },
                    child: CircleAvatar(
                      backgroundImage: AssetImage(profile.avatarPath),
                      radius: 20,
                    ),
                  ),
                );
              }
              // Estado de carga o sin datos
              return const Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: CircleAvatar(radius: 20, child: Icon(Icons.person)),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // --- Mensaje de Bienvenida ---
              Text(
                '¡Bienvenido!',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.user.nombre,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 32,
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // --- Tarjeta de Cantidad de Mascotas ---
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.pets,
                      size: 48,
                      color: colorScheme.onSecondaryContainer.withValues(
                        alpha: 0.7,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Cantidad de mascotas',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<Pet>>(
                      future: _petsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            height: 56,
                            child: Center(child: AppSpinner(size: 40)),
                          );
                        }

                        final count = snapshot.hasData
                            ? snapshot.data!.length
                            : 0;
                        return Text(
                          '$count',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 56,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // --- Opciones / Botones de Menú ---
              AppMenuButton(
                title: 'Ver Mascotas',
                icon: Icons.list_alt_rounded,
                onTap: () {
                  Navigator.pushNamed(context, '/pets');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
