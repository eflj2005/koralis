import 'package:flutter/material.dart';
import 'package:koralis_app/features/auth/presentation/login_screen.dart';
import 'package:koralis_app/features/auth/presentation/sign_up_screen.dart';
import 'package:koralis_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:koralis_app/features/profile/presentation/profile_screen.dart';
import 'package:koralis_app/features/clients/presentation/clients_screen.dart';
import 'package:koralis_app/features/clients/presentation/client_form_screen.dart';
import 'package:koralis_app/features/instruments/presentation/instruments_screen.dart';
import 'package:koralis_app/features/instruments/presentation/instrument_form_screen.dart';
import 'package:koralis_app/features/transactions/presentation/transactions_screen.dart';
import 'package:koralis_app/features/transactions/presentation/transaction_form_screen.dart';
import 'package:koralis_app/features/auth/domain/entities/user.dart';
import 'package:koralis_app/features/profile/domain/entities/profile.dart';

/// Enrutador principal de la aplicación Koralis.
/// Gestiona la generación dinámica de rutas nombradas.
class AppRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/sign_up':
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case '/dashboard':
        final user = settings.arguments as User;
        return MaterialPageRoute(builder: (_) => DashboardScreen(user: user));
      case '/clients':
        final user = settings.arguments as User;
        return MaterialPageRoute(builder: (_) => ClientsScreen(user: user));
      case '/client_form':
        if (settings.arguments is ClientFormArgs) {
          final args = settings.arguments as ClientFormArgs;
          return MaterialPageRoute(
            builder: (_) => ClientFormScreen(
              user: args.user,
              client: args.client,
            ),
          );
        } else if (settings.arguments is User) {
          final user = settings.arguments as User;
          return MaterialPageRoute(
            builder: (_) => ClientFormScreen(user: user),
          );
        }
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/instruments':
        final user = settings.arguments as User;
        return MaterialPageRoute(
          builder: (_) => InstrumentsScreen(user: user),
        );
      case '/instrument_form':
        if (settings.arguments is InstrumentFormArgs) {
          final args = settings.arguments as InstrumentFormArgs;
          return MaterialPageRoute(
            builder: (_) => InstrumentFormScreen(
              user: args.user,
              instrument: args.instrument,
            ),
          );
        } else if (settings.arguments is User) {
          final user = settings.arguments as User;
          return MaterialPageRoute(
            builder: (_) => InstrumentFormScreen(user: user),
          );
        }
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/transactions':
        final user = settings.arguments as User;
        return MaterialPageRoute(
          builder: (_) => TransactionsScreen(user: user),
        );
      case '/transaction_form':
        if (settings.arguments is TransactionFormArgs) {
          final args = settings.arguments as TransactionFormArgs;
          return MaterialPageRoute(
            builder: (_) => TransactionFormScreen(
              user: args.user,
              transaction: args.transaction,
              clienteIdPreseleccionado: args.clienteIdPreseleccionado,
            ),
          );
        } else if (settings.arguments is User) {
          final user = settings.arguments as User;
          return MaterialPageRoute(
            builder: (_) => TransactionFormScreen(user: user),
          );
        }
        return MaterialPageRoute(builder: (_) => const LoginScreen());
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
