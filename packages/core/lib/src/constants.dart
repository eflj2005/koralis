import 'package:flutter/material.dart';

/// Paleta de colores base y de respaldo del paquete Core.
///
/// Proporciona valores predeterminados seguros en caso de que la aplicación
/// consumidora no inyecte una configuración cromática específica.
class CoreColors {
  /// Color de acción principal por defecto.
  static const Color primary = Colors.blue;

  /// Color secundario de acento por defecto.
  static const Color secondary = Colors.amber;

  /// Color terciario de soporte por defecto.
  static const Color tertiary = Colors.teal;

  /// Color de fondo general de pantalla.
  static const Color background = Colors.white;

  /// Color de superficie para tarjetas y modales.
  static const Color surface = Colors.white;

  /// Color de texto de alto contraste para encabezados.
  static const Color textPrimary = Colors.black87;

  /// Color de texto atenuado para descripciones secundarias.
  static const Color textSecondary = Colors.black54;

  /// Color semántico para alertas, errores o acciones destructivas.
  static const Color error = Colors.red;
}

/// Escala tipográfica predeterminada del paquete Core.
///
/// Define estilos de texto canónicos para títulos, cuerpos de texto y etiquetas.
class CoreTypography {
  /// Estilo para títulos principales de gran tamaño (26 px, negrita).
  static const TextStyle titleLarge = TextStyle(
    color: CoreColors.textPrimary,
    fontWeight: FontWeight.w700,
    fontSize: 26,
  );

  /// Estilo para títulos medianos y subtítulos destacados (20 px, negrita).
  static const TextStyle titleMedium = TextStyle(
    color: CoreColors.textPrimary,
    fontWeight: FontWeight.w700,
    fontSize: 20,
  );

  /// Estilo para texto de cuerpo destacado o entradas de formulario (18 px).
  static const TextStyle bodyLarge = TextStyle(
    color: CoreColors.textPrimary,
    fontSize: 18,
  );

  /// Estilo para texto de cuerpo estándar o secundario (16 px).
  static const TextStyle bodyMedium = TextStyle(
    color: CoreColors.textSecondary,
    fontSize: 16,
  );

  /// Estilo para etiquetas interactivas y botones (18 px, negrita, espacio 0.5).
  static const TextStyle labelLarge = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 18,
    letterSpacing: 0.5,
  );
}