# Changelog — Koralis App

Todos los cambios notables de este proyecto están documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.1.0] — 2026-10-02

### Added
- **Centro de Documentación Técnica en `docs/`:**
  - Documentación del Paquete Core: [sistema_de_diseno.md](file:///d:/Projects/Flutter/koralis/docs/core/sistema_de_diseno.md), [catalogo_widgets.md](file:///d:/Projects/Flutter/koralis/docs/core/catalogo_widgets.md), [servicios_firebase.md](file:///d:/Projects/Flutter/koralis/docs/core/servicios_firebase.md) y [utilidades_y_errores.md](file:///d:/Projects/Flutter/koralis/docs/core/utilidades_y_errores.md).
  - Documentación de Módulos de Negocio: [auth.md](file:///d:/Projects/Flutter/koralis/docs/features/auth.md), [instruments.md](file:///d:/Projects/Flutter/koralis/docs/features/instruments.md), [transactions.md](file:///d:/Projects/Flutter/koralis/docs/features/transactions.md) y [clients_and_dashboard.md](file:///d:/Projects/Flutter/koralis/docs/features/clients_and_dashboard.md).
  - Documentación de Arquitectura y Seguridad: [aislamiento_multiusuario.md](file:///d:/Projects/Flutter/koralis/docs/architecture/aislamiento_multiusuario.md), [seguridad_firestore.md](file:///d:/Projects/Flutter/koralis/docs/architecture/seguridad_firestore.md) y [clean_architecture.md](file:///d:/Projects/Flutter/koralis/docs/architecture/clean_architecture.md).
  - Índice maestro navegable en [docs/README.md](file:///d:/Projects/Flutter/koralis/docs/README.md).
- Comentarios Dartdoc en español para `CoreColors` y `CoreTypography` en [constants.dart](file:///d:/Projects/Flutter/koralis/packages/core/lib/src/constants.dart).
- Suite de pruebas de aislamiento multi-tenant en [multi_user_isolation_test.dart](file:///d:/Projects/Flutter/koralis/test/features/multi_user_isolation_test.dart).

### Removed
- **Eliminación definitiva del módulo legado `features/pets/`**: borrado de datasources, repositorios, entidades, casos de uso, pantallas y [README_BORRAR.md](file:///d:/Projects/Flutter/koralis/lib/features/pets/README_BORRAR.md).
- Eliminación de la suite de pruebas unitarias `test/features/pets/pet_test.dart`.
- Eliminación de la ruta `'/pets'` en [router.dart](file:///d:/Projects/Flutter/koralis/lib/app/router.dart).
- Eliminación de la constante de colección `colMascotas` en [firebase_firestore_config.dart](file:///d:/Projects/Flutter/koralis/lib/app/firebase_firestore_config.dart).

### Changed
- Actualización integral de [README.md](file:///d:/Projects/Flutter/koralis/README.md) en la raíz: catálogo completo de rutas nombradas, características financieras actuales, arquitectura multiusuario y enlace central hacia `docs/`.

---

## [2.0.2+9] — 2026-07-14

### Added
- Tests unitarios básicos para las entidades de dominio (`User`, `Profile`) en la carpeta `test/features/`.
- Diagrama de navegación del proyecto documentando el flujo completo de pantallas y transiciones.
- Diagrama de arquitectura del sistema mostrando la interacción entre capas y el paquete `core`.
- Documento de plan de mantenimiento para los próximos 6 meses (Agosto 2026 – Enero 2027).

### Changed
- `README.md` reemplazado por documentación profesional: descripción, instalación, ejecución, arquitectura, estructura de carpetas y tabla de rutas.

---

## [2.0.1+8] — 2026-07-12

### Added
- Módulo `dashboard`: pantalla principal post-login.
- Módulo `profile`: pantalla de perfil con avatar, nombre, correo y botones de acción.
- `AppMenuButton`: widget reutilizable en el paquete `core` para ítems de menú con ícono, título y flecha.
- `showUnderConstructionDialog`: modal de `BottomSheet` en el paquete `core` para funciones en desarrollo, con mensaje e ícono de construcción.
- `AppSpinner`: widget de carga circular con imagen central configurable desde `styles.dart` vía `CoreThemeExtension`.
- `LoadingWidget`: overlay de pantalla completa con `AppSpinner` y texto "Cargando...".
- `EmptyWidget`: widget genérico para estados vacíos con mensaje e ícono personalizables.
- Texto curvo "Koralis" en `LoginScreen` utilizando el paquete `flutter_arc_text`.
- Lógica de **cierre de sesión** en `ProfileScreen` usando `pushNamedAndRemoveUntil` para limpiar el stack de navegación.
- Botones "Olvidaste tu contraseña" y "Regístrate" en `LoginScreen` conectados al modal de construcción.

### Changed
- `CoreTheme.buildTheme()`: ahora acepta el parámetro `spinnerImage` para inyectar la ruta de la imagen del spinner desde la aplicación cliente.
- `CoreThemeExtension`: nueva clase `ThemeExtension` en el paquete `core` para transmitir configuraciones adicionales al tema sin romper la interfaz pública.
- Paquete `core`: desacoplado completamente de colores y tipografía específicos. Las constantes de `CoreColors` y `CoreTypography` retornan a los valores por defecto de Flutter.

---

## [1.1.0+7] — 2026-07-12 *(tag: v1.1.0)*

### Added
- `lib/app/styles.dart`: nuevo archivo central de identidad visual. Define `KoralisColors`, `KoralisTypography` y `AppStyles.theme`.
- `lib/app/router.dart`: enrutamiento nombrado centralizado con `AppRouter.onGenerateRoute`. Reemplaza la navegación directa por `push()` en cada widget.
- Rutas registradas: `/` (Login), `/dashboard` (Dashboard + `User`), `/profile` (Profile + `Profile`).
- `main.dart`: configuración de `MaterialApp` con `theme: AppStyles.theme` e `onGenerateRoute: AppRouter.onGenerateRoute`.

### Changed
- Sistema de temas migrado: los colores de la app se trasladaron a `KoralisColors` dentro de `styles.dart`.
- `CoreTheme.buildTheme()`: parámetros de color convertidos en argumentos opcionales con valores de fábrica neutros.
- Imports de features ajustados a convención híbrida: relativos dentro de la misma feature, absolutos para paquetes externos.

---

## [1.0.1] — 2026-07-12

### Added
- Feature `auth`: módulo completo con capas `domain` (entidad `User`, interfaz `AuthRepository`, caso de uso `LoginUseCase`) y `data` (`AuthRepositoryImpl`).
- Feature `profile`: módulo con entidad `Profile`, `ProfileRepository`, `GetProfileUseCase` y `ProfileRepositoryImpl`.
- `LoginScreen`: pantalla de inicio de sesión con formulario de correo y contraseña, validaciones y spinner de carga.
- Imágenes y assets base: logo, avatar y GIF del spinner (`base_spinner.gif`).

### Changed
- Paquete `core` extendido con `CoreValidators`: validaciones reutilizables de correo electrónico y contraseña.
- `AppButton`, `AppTextField` añadidos al paquete `core` como widgets reutilizables y estilizados.

---

## [1.0.0] — 2026-07-10 *(tag: v1.0.0)*

### Added
- Creación del paquete interno `packages/core` como librería Flutter reutilizable.
- `CoreTheme` con `buildTheme()`: sistema de temas parametrizable que genera un `ThemeData` de Material 3 a partir de inyección de colores y tipografía.
- `CoreColors`: constantes de colores de fábrica con los valores por defecto de Flutter.
- `CoreTypography`: estilos de texto de fábrica para `titleLarge`, `titleMedium`, `bodyLarge`, `bodyMedium` y `labelLarge`.
- Estructura base del proyecto siguiendo Clean Architecture: separación por `features/` con subcarpetas `domain/`, `data/` y `presentation/`.
- `pubspec.yaml` configurado con versión `1.0.0`, dependencias iniciales y referencia al paquete local `core`.
- Archivo `analysis_options.yaml` con reglas de linting estándar de Flutter.

---

> **Nota:** Las versiones anteriores a `1.0.0` corresponden al commit inicial de Flutter (`Start Commit`) generado automáticamente por el framework y no tienen cambios de producto documentables.
