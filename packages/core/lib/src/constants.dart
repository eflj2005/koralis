import 'package:flutter/material.dart';

class CoreColors {
  static const Color primary = Colors.blue;
  static const Color secondary = Colors.amber;
  static const Color tertiary = Colors.teal;
  
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;
  static const Color error = Colors.red;
}

class CoreTypography {
  static const TextStyle titleLarge = TextStyle(
    color: CoreColors.textPrimary,
    fontWeight: FontWeight.w700,
    fontSize: 26,
  );

  static const TextStyle titleMedium = TextStyle(
    color: CoreColors.textPrimary,
    fontWeight: FontWeight.w700,
    fontSize: 20,
  );

  static const TextStyle bodyLarge = TextStyle(
    color: CoreColors.textPrimary,
    fontSize: 18,
  );

  static const TextStyle bodyMedium = TextStyle(
    color: CoreColors.textSecondary,
    fontSize: 16,
  );

  static const TextStyle labelLarge = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 18,
    letterSpacing: 0.5,
  );
}