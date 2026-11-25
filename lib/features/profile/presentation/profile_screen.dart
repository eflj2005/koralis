import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:provider/provider.dart';
import '../../profile/domain/entities/profile.dart';
import 'viewmodels/profile_view_model.dart';

class ProfileScreen extends StatelessWidget {
  final Profile profile;

  const ProfileScreen({super.key, required this.profile});

  Profile _resolverPerfil(BuildContext context) {
    try {
      return context.watch<ProfileViewModel>().profile ?? profile;
    } on ProviderNotFoundException {
      return profile;
    }
  }

  void _limpiarPerfilSiExiste(BuildContext context) {
    try {
      context.read<ProfileViewModel>().limpiar();
    } on ProviderNotFoundException {
      // Pantalla abierta de forma aislada sin ProfileViewModel en el árbol.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final perfilActual = _resolverPerfil(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // --- Avatar ---
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.primary,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      perfilActual.avatarPath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.person, size: 80),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- Datos del Usuario ---
              Text(
                perfilActual.nombre,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 28,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                perfilActual.correo,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),

              // --- Botón de Edición ---
              AppButton(
                texto: 'Editar Perfil',
                icono: Icons.edit_outlined,
                onPressed: () {
                  showUnderConstructionDialog(context, accion: 'Editar Perfil');
                },
              ),
              const SizedBox(height: 16),

              // --- Botón de Cerrar Sesión ---
              AppButton(
                texto: 'Cerrar Sesión',
                icono: Icons.logout,
                color: colorScheme.error,
                onPressed: () {
                  _limpiarPerfilSiExiste(context);
                  // Retorna a la pantalla de inicio (login) borrando todo el historial
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
