import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/core.dart';

class PetCareColors {
  static const Color greenPastel = Color(0xFFA8D5BA);
  static const Color greenDark = Color(0xFF6FA37F);
  static const Color yellowPastel = Color(0xFFF6E7A1);
  static const Color yellowDark = Color(0xFFD4C36A);
  static const Color bluePastel = Color(0xFFAECFEF);
  static const Color blueDark = Color(0xFF6F9FCB);

  static const Color background = Color(0xFFF8FBF8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF31423A);
  static const Color textSecondary = Color(0xFF5F6F67);
  static const Color error = Color(0xFFE8A0A0);
}

class PetCareTypography {
  static TextStyle get titleLarge => GoogleFonts.comicNeue(
    color: PetCareColors.textPrimary,
    fontWeight: FontWeight.w700,
    fontSize: 26,
  );

  static TextStyle get titleMedium => GoogleFonts.comicNeue(
    color: PetCareColors.textPrimary,
    fontWeight: FontWeight.w700,
    fontSize: 20,
  );

  static TextStyle get bodyLarge =>
      GoogleFonts.comicNeue(color: PetCareColors.textPrimary, fontSize: 18);

  static TextStyle get bodyMedium =>
      GoogleFonts.comicNeue(color: PetCareColors.textSecondary, fontSize: 16);

  static TextStyle get labelLarge => GoogleFonts.comicNeue(
    fontWeight: FontWeight.w700,
    fontSize: 18,
    letterSpacing: 0.5,
  );
}

class AppStyles {
  /// Tema principal de la aplicación.
  /// Llama al constructor de temas del paquete core pasando los colores y tipografía de PetCare.
  static ThemeData get theme {
    return CoreTheme.buildTheme(
      primary: PetCareColors.greenPastel,
      onPrimary: Colors.black87,
      secondary: PetCareColors.bluePastel,
      onSecondary: Colors.black87,
      tertiary: PetCareColors.yellowPastel,
      onTertiary: Colors.black87,
      surface: PetCareColors.surface,
      onSurface: PetCareColors.textPrimary,
      error: PetCareColors.error,
      onError: Colors.black87,
      background: PetCareColors.background,
      spinnerImage: 'images/base_spinner.gif',
      textTheme: TextTheme(
        titleLarge: PetCareTypography.titleLarge,
        titleMedium: PetCareTypography.titleMedium,
        bodyLarge: PetCareTypography.bodyLarge,
        bodyMedium: PetCareTypography.bodyMedium,
        labelLarge: PetCareTypography.labelLarge,
      ),
    );
  }
}
