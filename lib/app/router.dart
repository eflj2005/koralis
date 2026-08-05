import 'package:flutter/material.dart';
import 'package:koralis_app/features/auth/presentation/login_screen.dart';
import 'package:koralis_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:koralis_app/features/pets/presentation/pets_screen.dart';
import 'package:koralis_app/features/profile/presentation/profile_screen.dart';
import 'package:koralis_app/features/auth/domain/entities/user.dart';
import 'package:koralis_app/features/profile/domain/entities/profile.dart';

class AppRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/dashboard':
        final user = settings.arguments as User;
        return MaterialPageRoute(builder: (_) => DashboardScreen(user: user));
      case '/pets':
        return MaterialPageRoute(builder: (_) => const PetsScreen());
      case '/profile':
        final profile = settings.arguments as Profile;
        return MaterialPageRoute(
          builder: (_) => ProfileScreen(profile: profile),
        );
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
