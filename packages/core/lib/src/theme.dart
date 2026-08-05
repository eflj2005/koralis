import 'package:flutter/material.dart';
import 'constants.dart';

/// Extensión de tema para pasar configuraciones específicas al paquete core.
class CoreThemeExtension extends ThemeExtension<CoreThemeExtension> {
  final String? spinnerImagePath;

  CoreThemeExtension({this.spinnerImagePath});

  @override
  CoreThemeExtension copyWith({String? spinnerImagePath}) {
    return CoreThemeExtension(
      spinnerImagePath: spinnerImagePath ?? this.spinnerImagePath,
    );
  }

  @override
  CoreThemeExtension lerp(ThemeExtension<CoreThemeExtension>? other, double t) {
    if (other is! CoreThemeExtension) return this;
    return CoreThemeExtension(
      spinnerImagePath: other.spinnerImagePath,
    );
  }
}

class CoreTheme {
  /// Genera un ThemeData personalizado usando los colores de fábrica por defecto si no se especifican.
  static ThemeData buildTheme({
    Color primary = CoreColors.primary,
    Color onPrimary = Colors.white,
    Color secondary = CoreColors.secondary,
    Color onSecondary = Colors.black87,
    Color tertiary = CoreColors.tertiary,
    Color onTertiary = Colors.white,
    Color surface = CoreColors.surface,
    Color onSurface = CoreColors.textPrimary,
    Color error = CoreColors.error,
    Color onError = Colors.white,
    Color background = CoreColors.background,
    TextTheme? textTheme,
    String? spinnerImage,
  }) {
    final colorScheme = ColorScheme.light(
      primary: primary,
      onPrimary: onPrimary,
      secondary: secondary,
      onSecondary: onSecondary,
      tertiary: tertiary,
      onTertiary: onTertiary,
      surface: surface,
      onSurface: onSurface,
      error: error,
      onError: onError,
    );

    final finalTextTheme = textTheme ?? const TextTheme(
      titleLarge: CoreTypography.titleLarge,
      titleMedium: CoreTypography.titleMedium,
      bodyLarge: CoreTypography.bodyLarge,
      bodyMedium: CoreTypography.bodyMedium,
      labelLarge: CoreTypography.labelLarge,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      textTheme: finalTextTheme,
      extensions: [
        CoreThemeExtension(spinnerImagePath: spinnerImage),
      ],
    );
  }
}
