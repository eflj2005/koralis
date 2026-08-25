import 'package:flutter/material.dart';
import 'constants.dart';

/// Extensión de tema para pasar configuraciones específicas al paquete core.
class CoreThemeExtension extends ThemeExtension<CoreThemeExtension> {
  /// Ruta del recurso de imagen central para el spinner.
  final String? spinnerImagePath;

  /// Color base de fondo para el contenedor circular del spinner.
  final Color? spinnerBackgroundColor;

  /// Opacidad (0.0 a 1.0) para el fondo del spinner.
  final double? spinnerBackgroundOpacity;

  CoreThemeExtension({
    this.spinnerImagePath,
    this.spinnerBackgroundColor,
    this.spinnerBackgroundOpacity,
  });

  @override
  CoreThemeExtension copyWith({
    String? spinnerImagePath,
    Color? spinnerBackgroundColor,
    double? spinnerBackgroundOpacity,
  }) {
    return CoreThemeExtension(
      spinnerImagePath: spinnerImagePath ?? this.spinnerImagePath,
      spinnerBackgroundColor:
          spinnerBackgroundColor ?? this.spinnerBackgroundColor,
      spinnerBackgroundOpacity:
          spinnerBackgroundOpacity ?? this.spinnerBackgroundOpacity,
    );
  }

  @override
  CoreThemeExtension lerp(ThemeExtension<CoreThemeExtension>? other, double t) {
    if (other is! CoreThemeExtension) return this;
    return CoreThemeExtension(
      spinnerImagePath: other.spinnerImagePath,
      spinnerBackgroundColor:
          Color.lerp(spinnerBackgroundColor, other.spinnerBackgroundColor, t),
      spinnerBackgroundOpacity:
          other.spinnerBackgroundOpacity ?? spinnerBackgroundOpacity,
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
    Color? spinnerBackgroundColor,
    double? spinnerBackgroundOpacity,
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
      canvasColor: background,
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
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: primary,
        headerForegroundColor: onPrimary,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: background,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: background,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: finalTextTheme,
      extensions: [
        CoreThemeExtension(
          spinnerImagePath: spinnerImage,
          spinnerBackgroundColor: spinnerBackgroundColor,
          spinnerBackgroundOpacity: spinnerBackgroundOpacity,
        ),
      ],
    );
  }
}
