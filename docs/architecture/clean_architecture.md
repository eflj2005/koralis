# 🏛 Arquitectura Limpia y Patrones de Diseño (`architecture/clean_architecture`)

**Koralis** implementa los principios de **Clean Architecture** (Arquitectura Limpia) propuestos por Robert C. Martin, adaptados al ecosistema moderno de **Flutter**. El objetivo es aislar la lógica de negocio de los detalles técnicos de infraestructura, servicios externos y marcos de presentación.

---

## 🎯 Regla de Dependencia

Las dependencias del código solo pueden apuntar **hacia adentro**, hacia la Capa de Dominio:

```mermaid
graph TD
    subgraph Capa Externa [Detalles / Infraestructura]
        UI["Presentación — Views (Screens & Widgets)"]
        VM["Presentación — ViewModels (ChangeNotifier / Provider)"]
        Data["Capa de Datos: Firestore, Firebase Auth, SQLite"]
    end

    subgraph Capa Central [Negocio Inmutable]
        Domain["Capa de Dominio: Entidades & Casos de Uso"]
    end

    UI -->|Observa y dispara acciones| VM
    VM -->|Orquesta| Domain
    Data -->|Implementa contratos de| Domain
```

---

## 🏗 Las Tres Capas Fundamentales

Cada módulo dentro de [lib/features/](file:///d:/Projects/Flutter/koralis/lib/features) se organiza en tres capas estrictamente separadas:

### 1. Capa de Dominio (`domain/`)
Es el corazón del software. No contiene importaciones de Flutter UI ni de paquetes de infraestructura (como Firebase o SQLite). Es código Dart puro.

- **Entidades:** Clases inmutables que modelan los conceptos del negocio y encapsulan cálculos financieros (e.g. [Instrument](file:///d:/Projects/Flutter/koralis/lib/features/instruments/domain/entities/instrument.dart), [Client](file:///d:/Projects/Flutter/koralis/lib/features/clients/domain/entities/client.dart), [Transaction](file:///d:/Projects/Flutter/koralis/lib/features/transactions/domain/entities/transaction.dart)).
- **Contratos de Repositorio:** Interfaces abstractas que definen qué operaciones de datos necesita el negocio, sin importar de dónde provienen los datos:
  ```dart
  abstract class InstrumentRepository {
    Future<List<Instrument>> getInstruments(String userId);
    Future<void> saveInstrument(Instrument instrument);
    Future<void> deleteInstrument(String userId, String instrumentId);
  }
  ```
- **Casos de Uso (Use Cases):** Clases con una única responsabilidad (*Single Responsibility Principle*) que orquestan el flujo de datos para una acción específica (e.g. `GetClientsUseCase`, `SaveTransactionUseCase`).

### 2. Capa de Datos (`data/`)
Implementa los contratos definidos por el dominio, conectándose con los servicios externos.

- **Modelos y DTOs:** Adaptadores que deserializan y serializan mapas de Firestore (`fromMap` / `toMap`).
- **Implementaciones de Repositorio:** Clases concretas (e.g. `InstrumentRepositoryImpl`) que consumen el [FirestoreService](file:///d:/Projects/Flutter/koralis/packages/core/lib/src/firebase/firestore_service.dart) del paquete Core y traducen los documentos a entidades de dominio.

### 3. Capa de Presentación (`presentation/`) — Patrón MVVM con `provider`
Responsable de capturar la interacción del usuario, gestionar el estado de pantalla y renderizar la interfaz gráfica, desacoplada de la lógica de negocio mediante **Model-View-ViewModel (MVVM)** con el paquete `provider`.

- **Views (`Screens` y `Widgets`):** Vistas registradas en [router.dart](file:///d:/Projects/Flutter/koralis/lib/app/router.dart) y componentes visuales contextuales (por ejemplo, `InstrumentsScreen`, `TransactionFormScreen`, `SignUpFormSheet`). Se encargan únicamente de renderizar la UI, mantener controladores efímeros de formulario (`TextEditingController`, `GlobalKey<FormState>`), observar el estado reactivo (`context.watch<T>()`) y delegar acciones al ViewModel (`context.read<T>()`).
- **ViewModels (`presentation/viewmodels/`):** Clases que extienden `ChangeNotifier`. Encapsulan el estado de la vista (`cargando`, `errorMensaje`, filtros, listas, selecciones), inicializan perezosamente sus casos de uso y repositorios para evitar acoplamiento temprano con Firebase en pruebas, y protegen `notifyListeners()` frente a `dispose()`.
- **Ciclo de vida e inyección con `provider`:**
  - **Estado global compartido:** registrado en `MultiProvider` dentro de [main.dart](file:///d:/Projects/Flutter/koralis/lib/main.dart) (`ProfileViewModel`).
  - **ViewModels por ruta:** inyectados por `AppRouter` en [router.dart](file:///d:/Projects/Flutter/koralis/lib/app/router.dart) mediante `ChangeNotifierProvider` (`LoginViewModel`, `ClientsViewModel`, `ClientFormViewModel`, `InstrumentsViewModel`, `InstrumentFormViewModel`, `TransactionsViewModel`, `TransactionFormViewModel`).
  - **Compatibilidad con pruebas aisladas:** las vistas verifican si el ViewModel ya existe en el árbol y crean un `ChangeNotifierProvider` local de respaldo cuando se montan directamente en widget tests.

#### Catálogo de ViewModels por módulo
- `auth`: `LoginViewModel`, `SignUpViewModel`, `ForgotPasswordViewModel`.
- `profile` (global, compartido con `dashboard`): `ProfileViewModel`.
- `clients`: `ClientsViewModel`, `ClientFormViewModel`.
- `instruments`: `InstrumentsViewModel`, `InstrumentFormViewModel`.
- `transactions`: `TransactionsViewModel`, `TransactionFormViewModel`.

---

## 📦 Rol del Paquete Interno `packages/core`

Para evitar la duplicación de código y mantener la pureza de las capas:

- [packages/core](file:///d:/Projects/Flutter/koralis/packages/core) actúa como una **librería agnóstica de infraestructura transversal**.
- Expone:
  - Sistema de temas y diseño ([theme.dart](file:///d:/Projects/Flutter/koralis/packages/core/lib/src/theme.dart)).
  - Componentes gráficos reutilizables ([widgets.dart](file:///d:/Projects/Flutter/koralis/packages/core/lib/src/widgets.dart)).
  - Servicios de conexión Firebase y SQLite ([firestore_service.dart](file:///d:/Projects/Flutter/koralis/packages/core/lib/src/firebase/firestore_service.dart)).
  - Validadores y formateadores de datos ([validators.dart](file:///d:/Projects/Flutter/koralis/packages/core/lib/src/validators.dart)).
- **Regla de Oro:** Ningún archivo dentro de `packages/core` puede importar clases de `lib/features/`.

---

## 🧪 Inversión de Control y Testabilidad

Al desacoplar las implementaciones mediante interfaces abstractas en el dominio y ViewModels basados en `ChangeNotifier` en la presentación, el sistema puede someterse a pruebas rápidas y deterministas mediante dobles de prueba (*fakes* o *mocks*) —tanto a nivel de reglas de negocio ([multi_user_isolation_test.dart](file:///d:/Projects/Flutter/koralis/test/features/multi_user_isolation_test.dart)) como de estado y flujo de presentación en las suites unitarias de ViewModels bajo `test/features/`— sin necesidad de conectarse a emuladores ni a bases de datos en vivo.
