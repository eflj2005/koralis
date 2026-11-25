# Changelog — Koralis App

Todos los cambios notables de este proyecto están documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.7.3] — 2026-11-25

### Removed
- Eliminación definitiva de las mecánicas *legacy* de aportes en instrumentos (`_cargarAportesLegacy`, `aportesMostrados`, estados de carga/error legacy en `InstrumentFormViewModel` e `InstrumentFormScreen`, y la migración legacy al revertir de `Activo` a `Borrador` en `ProcessInstrumentSaveUseCase`).

### Changed
- Actualizadas las pruebas de `instruments` (`instrument_form_view_model_test.dart`, `process_instrument_save_usecase_test.dart` e `instrument_form_screen_test.dart`) al modelo vigente de aportes explícitos.

---

## [2.7.2] — 2026-11-25

### Added
- Pruebas unitarias en `transactions_view_model_test.dart` para la resolución del número de instrumento y en `instrument_form_view_model_test.dart` para la validación de número obligatorio.

### Changed
- `TransactionsViewModel` resuelve el número legible del instrumento (`obtenerNumeroInstrumento`) desde el catálogo de instrumentos sin usar `instrumentoId` como respaldo.
- `TransactionsScreen` muestra el número del instrumento tanto en las tarjetas de la lista como en el modal de detalle (*Instrumento Asociado*).
- Reforzada la obligatoriedad del campo `numero` en `ProcessInstrumentSaveUseCase` e `InstrumentFormViewModel`.

---

## [2.7.1] — 2026-11-25

### Added
- Prueba unitaria en `clients_view_model_test.dart` para verificar el cálculo de `saldoDisponible` con ingresos, egresos, saldo negativo y cero.

### Changed
- `ClientsScreen` calcula y muestra el saldo disponible real de cada cliente (`cliente.saldoDisponible`) con formato monetario igual a Transacciones (`$ 1.500.000,00`, y en color de error cuando es negativo) tanto en las tarjetas como en la ficha de detalle.

---

## [2.7.0] — 2026-11-25

### Changed
- **Documentación de arquitectura MVVM (`Fase 5`):**
  - Actualizado `docs/architecture/clean_architecture.md` con el patrón MVVM usando `provider`, nuevo diagrama de dependencias (`Views -> ViewModels -> Domain <- Data`), ciclo de vida de los ViewModels, catálogo por módulo y estrategia de pruebas unitarias.
  - Actualizado `CHANGELOG.md` con el desglose incremental de versiones de la migración MVVM.

---

## [2.6.0] — 2026-11-25

### Added
- **ViewModels y pruebas de `auth` (`Fase 4`):**
  - Nuevos ViewModels `LoginViewModel`, `SignUpViewModel` y `ForgotPasswordViewModel` con inicialización perezosa de casos de uso y protección frente a `dispose()`.
  - Nuevas suites de pruebas unitarias `login_view_model_test.dart`, `sign_up_view_model_test.dart` y `forgot_password_view_model_test.dart`.

### Changed
- Migración de `LoginScreen`, `SignUpFormSheet` y `ForgotPasswordFormSheet` a MVVM con `provider`.
- `AppRouter` (`lib/app/router.dart`) inyecta `LoginViewModel` en las rutas de inicio de sesión.
- `DashboardScreen` y `ProfileScreen` consumen el `ProfileViewModel` global compartido y limpian su caché al cerrar sesión.

---

## [2.5.0] — 2026-11-25

### Added
- **ViewModels y pruebas de `instruments` (`Fase 3`):**
  - Nuevos ViewModels `InstrumentsViewModel` e `InstrumentFormViewModel`.
  - Nuevas suites de pruebas unitarias `instruments_view_model_test.dart` e `instrument_form_view_model_test.dart`.

### Changed
- Refactorización de `InstrumentsScreen` e `InstrumentFormScreen` al patrón MVVM con `provider` y provisión de sus ViewModels desde `AppRouter`.

---

## [2.4.0] — 2026-11-25

### Added
- **ViewModels y pruebas de `transactions` (`Fase 2`):**
  - Nuevos ViewModels `TransactionsViewModel` y `TransactionFormViewModel`.
  - Nuevas suites de pruebas unitarias `transactions_view_model_test.dart` y `transaction_form_view_model_test.dart`.

### Changed
- Refactorización de `TransactionsScreen` y `TransactionFormScreen` al patrón MVVM con `provider` y provisión de sus ViewModels desde `AppRouter`.

---

## [2.3.0] — 2026-11-25

### Added
- **Base de `provider`, estado global de perfil y piloto `clients` (`Fase 0 + Fase 1`):**
  - Agregada la dependencia `provider: ^6.1.2` en `pubspec.yaml` y configurado `MultiProvider` global en `lib/main.dart` con `ProfileViewModel`.
  - Nuevos ViewModels `ClientsViewModel` y `ClientFormViewModel`.
  - Nuevas suites de pruebas unitarias `profile_view_model_test.dart`, `clients_view_model_test.dart` y `client_form_view_model_test.dart`.

### Changed
- Refactorización piloto del módulo `clients` (`ClientsScreen` y `ClientFormScreen`) al patrón MVVM con `provider` e inyección de ViewModels en `AppRouter`.

---

## [2.2.0] — 2026-11-25

### Added
- **Aportes diferidos en Instrumentos Financieros:**
  - Nueva entidad `InstrumentContribution` y campo `aportes` en `Instrument` con persistencia en Cloud Firestore.
  - Nuevo caso de uso `ProcessInstrumentSaveUseCase` para generar transacciones automáticas de inversión solo al guardar en estado `Activo` (con re-validación de saldo disponible, idempotencia y rollback defensivo) y reversarlas automáticamente al volver de `Activo` a `Borrador`.
- **Gesto pan/swipe reutilizable en listas (`core`):**
  - Nuevo modelo `AppSwipeAction` y propiedad `accionesSwipe` en `AppListCard` para revelar acciones **Editar** y **Eliminar** al deslizar horizontalmente de derecha a izquierda.
- **Procesos de eliminación con integridad referencial:**
  - `deleteClient` en `ClientRepository` y `DeleteClientUseCase` (bloquea eliminación si el cliente tiene instrumentos o transacciones asociadas).
  - `DeleteInstrumentUseCase` (permite eliminar solo instrumentos en estado `Borrador` sin aportes ni transacciones asociadas).
  - Eliminación de transacciones manuales (`Recarga` y `Retiro`) en `TransactionsScreen` con confirmación y notificación del nuevo saldo disponible del cliente (incluso si resulta negativo).
- **Pruebas unitarias y de interfaz:**
  - Nuevas suites `process_instrument_save_usecase_test.dart`, `delete_client_usecase_test.dart` y `delete_instrument_usecase_test.dart`, además de pruebas de swipe, eliminación y `DatePickerDialog` localizado en clientes, instrumentos y transacciones.

### Changed
- `InstrumentFormScreen`: el registro, edición y eliminación de aportes en `Borrador` se persiste directamente en el documento del instrumento sin descontar saldo del cliente hasta la activación.
- `ClientsScreen`, `InstrumentsScreen` y `TransactionsScreen`: la acción de editar se trasladó al botón **Editar** del gesto swipe (solo en transacciones manuales para `TransactionsScreen`) y se retiró el botón de editar de las fichas informativas.
- Documentación actualizada en `docs/features/instruments.md` y `docs/core/catalogo_widgets.md`.

### Fixed
- **Localización de campos de fecha (`DatePicker`):** integración de `flutter_localizations` en `pubspec.yaml` y configuración de `localizationsDelegates` y `supportedLocales` en `lib/main.dart`, corrigiendo errores de localización al abrir selectores de fecha en transacciones.
- **Configuración de compilación Android (Gradle):** ajustes en `android/app/build.gradle.kts`, `android/gradle.properties` y `.vscode/settings.json` para resolver error de build en Gradle.

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
