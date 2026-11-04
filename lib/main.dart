import 'package:flutter/material.dart';
import 'package:koralis_app/app/firebase.dart';
import 'package:koralis_app/app/router.dart';
import 'package:koralis_app/app/styles.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: const [
        Locale('es', 'CO'),
        Locale('es', ''),
        Locale('en', '')
      ],
      localeResolutionCallback: (deviceLocale, supportedLocales){
        if (deviceLocale != null){
          for(final supportedLocale in supportedLocales){
            if(supportedLocale.languageCode == deviceLocale.languageCode){
              return supportedLocale;
            }
          }
        }
        return const Locale('es', 'CO');
      }
    );
  }
}
