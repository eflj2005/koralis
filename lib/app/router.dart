import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:koralis_app/features/auth/presentation/login_screen.dart';
import 'package:koralis_app/features/auth/presentation/sign_up_screen.dart';
import 'package:koralis_app/features/auth/presentation/viewmodels/login_view_model.dart';
import 'package:koralis_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:koralis_app/features/profile/presentation/profile_screen.dart';
import 'package:koralis_app/features/clients/presentation/clients_screen.dart';
import 'package:koralis_app/features/clients/presentation/client_form_screen.dart';
import 'package:koralis_app/features/clients/presentation/viewmodels/clients_view_model.dart';
import 'package:koralis_app/features/clients/presentation/viewmodels/client_form_view_model.dart';
import 'package:koralis_app/features/instruments/presentation/instruments_screen.dart';
import 'package:koralis_app/features/instruments/presentation/instrument_form_screen.dart';
import 'package:koralis_app/features/instruments/presentation/viewmodels/instruments_view_model.dart';
import 'package:koralis_app/features/instruments/presentation/viewmodels/instrument_form_view_model.dart';
import 'package:koralis_app/features/transactions/presentation/transactions_screen.dart';
import 'package:koralis_app/features/transactions/presentation/transaction_form_screen.dart';
import 'package:koralis_app/features/transactions/presentation/viewmodels/transactions_view_model.dart';
import 'package:koralis_app/features/transactions/presentation/viewmodels/transaction_form_view_model.dart';
import 'package:koralis_app/features/auth/domain/entities/user.dart';
import 'package:koralis_app/features/profile/domain/entities/profile.dart';

/// Enrutador principal de la aplicación Koralis.
/// Gestiona la generación dinámica de rutas nombradas.
class AppRouter {
  static Route<dynamic> _buildLoginRoute() {
    return MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider<LoginViewModel>(
        create: (_) => LoginViewModel(),
        child: const LoginScreen(),
      ),
    );
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return _buildLoginRoute();
      case '/sign_up':
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case '/dashboard':
        final user = settings.arguments as User;
        return MaterialPageRoute(builder: (_) => DashboardScreen(user: user));
      case '/clients':
        final user = settings.arguments as User;
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<ClientsViewModel>(
            create: (_) => ClientsViewModel(userId: user.id),
            child: ClientsScreen(user: user),
          ),
        );
      case '/client_form':
        if (settings.arguments is ClientFormArgs) {
          final args = settings.arguments as ClientFormArgs;
          return MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider<ClientFormViewModel>(
              create: (_) => ClientFormViewModel(
                userId: args.user.id,
                clientInicial: args.client,
              ),
              child: ClientFormScreen(
                user: args.user,
                client: args.client,
              ),
            ),
          );
        } else if (settings.arguments is User) {
          final user = settings.arguments as User;
          return MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider<ClientFormViewModel>(
              create: (_) => ClientFormViewModel(userId: user.id),
              child: ClientFormScreen(user: user),
            ),
          );
        }
        return _buildLoginRoute();
      case '/instruments':
        final user = settings.arguments as User;
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<InstrumentsViewModel>(
            create: (_) => InstrumentsViewModel(userId: user.id),
            child: InstrumentsScreen(user: user),
          ),
        );
      case '/instrument_form':
        if (settings.arguments is InstrumentFormArgs) {
          final args = settings.arguments as InstrumentFormArgs;
          return MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider<InstrumentFormViewModel>(
              create: (_) => InstrumentFormViewModel(
                userId: args.user.id,
                instrumentInicial: args.instrument,
              ),
              child: InstrumentFormScreen(
                user: args.user,
                instrument: args.instrument,
              ),
            ),
          );
        } else if (settings.arguments is User) {
          final user = settings.arguments as User;
          return MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider<InstrumentFormViewModel>(
              create: (_) => InstrumentFormViewModel(userId: user.id),
              child: InstrumentFormScreen(user: user),
            ),
          );
        }
        return _buildLoginRoute();
      case '/transactions':
        final user = settings.arguments as User;
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<TransactionsViewModel>(
            create: (_) => TransactionsViewModel(userId: user.id),
            child: TransactionsScreen(user: user),
          ),
        );
      case '/transaction_form':
        if (settings.arguments is TransactionFormArgs) {
          final args = settings.arguments as TransactionFormArgs;
          return MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider<TransactionFormViewModel>(
              create: (_) => TransactionFormViewModel(
                userId: args.user.id,
                transactionInicial: args.transaction,
                clienteIdPreseleccionado: args.clienteIdPreseleccionado,
              ),
              child: TransactionFormScreen(
                user: args.user,
                transaction: args.transaction,
                clienteIdPreseleccionado: args.clienteIdPreseleccionado,
              ),
            ),
          );
        } else if (settings.arguments is User) {
          final user = settings.arguments as User;
          return MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider<TransactionFormViewModel>(
              create: (_) => TransactionFormViewModel(userId: user.id),
              child: TransactionFormScreen(user: user),
            ),
          );
        }
        return _buildLoginRoute();
      case '/profile':
        final profile = settings.arguments as Profile;
        return MaterialPageRoute(
          builder: (_) => ProfileScreen(profile: profile),
        );
      default:
        return _buildLoginRoute();
    }
  }
}
