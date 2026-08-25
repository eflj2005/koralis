import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/core.dart';

/// Paleta de colores principal para la aplicación Koralis basada en la guía de diseño.
class KoralisColors {
  /// Color primario violeta (#5F4CDF).
  static const Color primary = Color(0xFF5F4CDF);

  /// Color secundario índigo (#4638A4).
  static const Color secondary = Color(0xFF4638A4);

  /// Color terciario violeta pizarra (#4E446D).
  static const Color tertiary = Color(0xFF4E446D);

  /// Color neutral oscuro para texto principal y componentes invertidos (#2A2833).
  static const Color neutral = Color(0xFF2A2833);

  /// Color de fondo general de la aplicación: color secundario iluminado al 80% con blanco (#DAD7ED).
  static const Color background = Color(0xFFDAD7ED);

  /// Color de superficie para tarjetas y contenedores.
  static const Color surface = Color(0xFFFFFFFF);

  /// Color de texto principal.
  static const Color textPrimary = Color(0xFF2A2833);

  /// Color de texto secundario y elementos atenuados.
  static const Color textSecondary = Color(0xFF6E6A7C);

  /// Color para acciones destructivas o estados de error.
  static const Color error = Color(0xFFBA1A1A);
}

/// Tipografía corporativa para Koralis con soporte completo para caracteres en español (ñ, tildes, etc.).
class KoralisTypography {
  static const List<String> _fuentesRespaldo = [
    'Roboto',
    'Noto Sans',
    'Segoe UI',
    'Arial',
    'sans-serif',
  ];

  /// Tipografía Manrope para títulos principales.
  static TextStyle get titleLarge => GoogleFonts.manrope(
    color: KoralisColors.textPrimary,
    fontWeight: FontWeight.w700,
    fontSize: 26,
    textStyle: const TextStyle(fontFamilyFallback: _fuentesRespaldo),
  );

  /// Tipografía Manrope para títulos medianos.
  static TextStyle get titleMedium => GoogleFonts.manrope(
    color: KoralisColors.textPrimary,
    fontWeight: FontWeight.w700,
    fontSize: 20,
    textStyle: const TextStyle(fontFamilyFallback: _fuentesRespaldo),
  );

  /// Tipografía Hanken Grotesk para textos de cuerpo grande.
  static TextStyle get bodyLarge => GoogleFonts.hankenGrotesk(
    color: KoralisColors.textPrimary,
    fontSize: 18,
    textStyle: const TextStyle(fontFamilyFallback: _fuentesRespaldo),
  );

  /// Tipografía Hanken Grotesk para textos de cuerpo estándar.
  static TextStyle get bodyMedium => GoogleFonts.hankenGrotesk(
    color: KoralisColors.textSecondary,
    fontSize: 16,
    textStyle: const TextStyle(fontFamilyFallback: _fuentesRespaldo),
  );

  /// Tipografía Hanken Grotesk para etiquetas y botones.
  static TextStyle get labelLarge => GoogleFonts.hankenGrotesk(
    fontWeight: FontWeight.w700,
    fontSize: 18,
    letterSpacing: 0.5,
    textStyle: const TextStyle(fontFamilyFallback: _fuentesRespaldo),
  );
}

class AppStyles {
  /// Tema principal de la aplicación Koralis.
  static ThemeData get theme {
    return CoreTheme.buildTheme(
      primary: KoralisColors.primary,
      onPrimary: Colors.white,
      secondary: KoralisColors.secondary,
      onSecondary: Colors.white,
      tertiary: KoralisColors.tertiary,
      onTertiary: Colors.white,
      surface: KoralisColors.surface,
      onSurface: KoralisColors.textPrimary,
      error: KoralisColors.error,
      onError: Colors.white,
      background: KoralisColors.background,
      spinnerImage: 'images/base_spinner.gif',
      spinnerBackgroundColor: Colors.blueGrey,
      spinnerBackgroundOpacity: 0.50,
      textTheme: TextTheme(
        titleLarge: KoralisTypography.titleLarge,
        titleMedium: KoralisTypography.titleMedium,
        bodyLarge: KoralisTypography.bodyLarge,
        bodyMedium: KoralisTypography.bodyMedium,
        labelLarge: KoralisTypography.labelLarge,
      ),
    );
  }
}
