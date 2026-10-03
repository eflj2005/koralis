# 🔐 Módulo de Autenticación y Perfil (`features/auth`)

El módulo de autenticación administra el ciclo de vida de la sesión del usuario en **Koralis**, la persistencia de credenciales mediante Firebase Authentication y la gestión del perfil de usuario en Cloud Firestore.

---

## 🏗 Arquitectura del Módulo

Sigue estrictamente **Clean Architecture**:

```text
lib/features/auth/
├── domain/
│   ├── entities/
│   │   └── user.dart              # Entidad inmutable de usuario
│   ├── repositories/
│   │   └── auth_repository.dart   # Contrato abstracto del repositorio
│   └── usecases/
│       ├── sign_in_usecase.dart   # Caso de uso: Inicio de sesión
│       ├── sign_up_usecase.dart   # Caso de uso: Registro de cuenta
│       ├── sign_out_usecase.dart  # Caso de uso: Cierre de sesión
│       └── ...
├── data/
│   ├── datasources/               # Conexión directa con FirebaseAuthService
│   └── repositories/
│       └── auth_repository_impl.dart
└── presentation/
    ├── login_screen.dart          # Pantalla principal de acceso
    ├── sign_up_screen.dart        # Pantalla de registro de nuevos usuarios
    └── widgets/
        └── forgot_password_form_sheet.dart # Modal para recuperación de clave
```

---

## 👤 Entidad de Dominio: `User`

Ubicación: [user.dart](file:///d:/Projects/Flutter/koralis/lib/features/auth/domain/entities/user.dart)

Representa al usuario autenticado dentro del ecosistema Koralis:

| Propiedad | Tipo | Descripción |
|---|---|---|
| `id` | `String` | Identificador único (`uid`) provisto por Firebase Auth. |
| `email` | `String` | Correo electrónico principal del usuario. |
| `displayName` | `String?` | Nombre o alias público para encabezados. |
| `photoUrl` | `String?` | URL de la imagen de avatar del perfil. |

---

## 🔄 Flujos Funcionales

### 1. Inicio de Sesión (`LoginScreen`)
- **Ruta:** `'/'`
- **Componentes Clave:**
  - Campo de correo con validador estricto de sintaxis `CoreValidators.email`.
  - Campo de contraseña con selector de visibilidad y validador de complejidad `CoreValidators.password`.
  - Efecto de marca Koralis mediante texto en arco (`flutter_arc_text`).
  - Botón de recuperación de clave que despliega la hoja inferior [forgot_password_form_sheet.dart](file:///d:/Projects/Flutter/koralis/lib/features/auth/presentation/widgets/forgot_password_form_sheet.dart).
- **Transición de éxito:** Navega a `'/dashboard'` inyectando la entidad `User` como argumento de ruta.

### 2. Registro de Usuario (`SignUpScreen`)
- **Ruta:** `'/sign_up'`
- Valida confirmación de contraseña en cliente antes de consultar Firebase.
- Al crearse exitosamente la credencial en Firebase Auth, se inicializa el documento correspondiente en la colección `users/{userId}` y su respectivo `profiles/{userId}` en Cloud Firestore.

### 3. Recuperación de Contraseña
- Dispara `FirebaseAuthService.sendPasswordResetEmail(email)`.
- Maneja excepciones con `AppErrorHandler.parseMessage(e)` para notificar al usuario en español si el correo no existe o presenta errores de formato.

### 4. Cierre de Sesión
- Ejecuta `SignOutUseCase`.
- Limpia todo el historial del navegador mediante `Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false)` para prevenir que el usuario retroceda a pantallas privadas tras salir.
