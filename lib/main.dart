import 'package:flutter/material.dart';
import 'package:koralis_app/app/firebase.dart';
import 'package:koralis_app/app/router.dart';
import 'package:koralis_app/app/styles.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicialización centralizada de Firebase y sus servicios para Koralis
  await AppFirebase.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Koralis",
      theme: AppStyles.theme,
      initialRoute: '/',
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
