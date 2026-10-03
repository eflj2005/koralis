# 🎨 Sistema de Diseño y Theming (Core)

El paquete [packages/core](file:///d:/Projects/Flutter/koralis/packages/core) implementa una arquitectura de diseño basada en tokens desacoplados. La librería define contratos visuales agnósticos mediante `CoreTheme` y `CoreThemeExtension`, permitiendo que la aplicación consumidora (en este caso, **Koralis**) inyecte su identidad visual corporativa sin generar dependencias rígidas.

---

## 📐 Arquitectura del Theming

La infraestructura temática se encuentra estructurada en:

- [theme.dart](file:///d:/Projects/Flutter/koralis/packages/core/lib/src/theme.dart): Contiene la factoría [CoreTheme](file:///d:/Projects/Flutter/koralis/packages/core/lib/src/theme.dart#L49) y la extensión [CoreThemeExtension](file:///d:/Projects/Flutter/koralis/packages/core/lib/src/theme.dart#L5).
- [constants.dart](file:///d:/Projects/Flutter/koralis/packages/core/lib/src/constants.dart): Define valores de contingencia por defecto (`CoreColors` y `CoreTypography`).
- [styles.dart](file:///d:/Projects/Flutter/koralis/lib/app/styles.dart): Implementación específica de Koralis con paletas reales y tipografías corporativas.

```
       +---------------------------------------------+
       |           packages/core (Agnóstico)         |
       |  CoreColors, CoreTypography, CoreTheme      |
       +---------------------------------------------+
                              ▲
                              │ Inyección de configuración
       +---------------------------------------------+
       |            lib/app (Específico)             |
       |   KoralisColors, KoralisTypography,         |
       |   AppStyles (GoogleFonts, assets locales)   |
       +---------------------------------------------+
```

---

## 🎨 Tokens de Color Corporativos (Koralis)

La paleta cromática se define en [styles.dart](file:///d:/Projects/Flutter/koralis/lib/app/styles.dart) bajo la clase `KoralisColors`:

| Token | Código Hexadecimal | Propósito |
|---|---|---|
| `primary` | `#5F4CDF` | Violeta vibrante: botones de acción principal, indicadores activos. |
| `secondary` | `#4638A4` | Índigo profundo: navegación lateral, carpetas seleccionadas. |
| `tertiary` | `#4E446D` | Violeta pizarra: acentos secundarios y badges de estado. |
| `background` | `#DAD7ED` | Fondo general de pantallas (secundario iluminado con 80% blanco). |
| `surface` | `#FFFFFF` | Superficies de tarjetas, formularios y modales. |
| `textPrimary` | `#2A2833` | Títulos, encabezados y texto principal de alto contraste. |
| `textSecondary` | `#6E6A7C` | Subtítulos, descripciones secundarias y etiquetas atenuadas. |
| `neutral` | `#2A2833` | Elementos de soporte e inversión. |
| `error` | `#BA1A1A` | Notificaciones destructivas, advertencias de riesgo y validaciones fallidas. |

---

## 🔤 Tipografía Corporativa

Se utilizan fuentes de Google Fonts optimizadas para el idioma español (soporte completo de caracteres con tilde, diéresis y la letra `ñ`), integradas con fuentes de reserva seguras del sistema operativo:

1. **Manrope (Títulos y Jerarquía Superior):**
   - `titleLarge`: Tamaño 26px, peso bold (w700). Usado en encabezados principales y balances globales.
   - `titleMedium`: Tamaño 20px, peso bold (w700). Usado en títulos de secciones y modales.

2. **Hanken Grotesk (Cuerpo, Formularios y Botones):**
   - `bodyLarge`: Tamaño 18px, peso normal (w400). Usado en campos de entrada y texto destacado.
   - `bodyMedium`: Tamaño 16px, peso normal (w400). Usado en etiquetas descriptivas y listas.
   - `labelLarge`: Tamaño 18px, peso bold (w700), espaciado de letras 0.5. Usado en botones de acción.

---

## 🧩 Extensión de Tema: `CoreThemeExtension`

Para evitar contaminar el `ThemeData` estándar con propiedades propietarias de la interfaz, el paquete `core` expone `CoreThemeExtension`. Esta extensión permite configurar dinámicamente el comportamiento de los indicadores de carga:

```dart
class CoreThemeExtension extends ThemeExtension<CoreThemeExtension> {
  final String? spinnerImagePath;             // Ruta al gif/imagen del spinner
  final Color? spinnerBackgroundColor;        // Color de fondo del contenedor
  final double? spinnerBackgroundOpacity;    // Opacidad aplicada al fondo
}
```

### Configuración en la aplicación:
```dart
final ThemeData koralisTheme = CoreTheme.buildTheme(
  primary: KoralisColors.primary,
  secondary: KoralisColors.secondary,
  background: KoralisColors.background,
  surface: KoralisColors.surface,
  spinnerImage: 'images/base_spinner.gif',
  spinnerBackgroundColor: Colors.blueGrey,
  spinnerBackgroundOpacity: 0.50,
  textTheme: TextTheme(...),
);
```

### Consumo en Widgets:
```dart
final coreExtension = Theme.of(context).extension<CoreThemeExtension>();
final spinnerAsset = coreExtension?.spinnerImagePath;
```

---

## 🚀 Buenas Prácticas de Implementación

1. **Nunca usar colores literales:** Evitar `Colors.blue` o `Color(0xFF...)` en pantallas de presentación; siempre referenciar `Theme.of(context).colorScheme` o `KoralisColors`.
2. **Respetar la escala tipográfica:** Usar `Theme.of(context).textTheme` para garantizar coherencia en tamaños y legibilidad.
3. **Soporte accesible:** Todos los textos principales deben mantener una relación de contraste mínima de 4.5:1 respecto a los fondos.
