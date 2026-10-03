# 🚀 Koralis App

Aplicación móvil desarrollada en **Flutter** para la gestión y análisis integral de inversiones, instrumentos financieros (CDTs, pagarés, bonos) y administración de cartera de clientes bajo una **arquitectura multiusuario con aislamiento estricto (Multi-Tenancy)** en Cloud Firestore.

El proyecto está construido bajo los principios de **Clean Architecture**, soportado por un paquete interno desacoplado y agnóstico denominado [packages/core](file:///d:/Projects/Flutter/koralis/packages/core).

---

## 📋 Tabla de Contenidos

- [Características Principales](#-características-principales)
- [Centro de Documentación Técnica](#-centro-de-documentación-técnica)
- [Tecnologías y Dependencias](#-tecnologías-y-dependencias)
- [Requisitos Previos](#-requisitos-previos)
- [Instalación y Configuración](#-instalación-y-configuración)
- [Ejecución](#-ejecución)
- [Rutas de Navegación](#-rutas-de-navegación)
- [Credenciales de Prueba](#-credenciales-de-prueba)
- [Pruebas y Análisis de Calidad](#-pruebas-y-análisis-de-calidad)
- [Licencia](#-licencia)

---

## ✨ Características Principales

- **🔐 Autenticación y Perfil:** Acceso seguro con correo y contraseña vía Firebase Auth, recuperación de clave con validación estricta y sesión persistente.
- **📊 Dashboard Inmersivo:** Pantalla principal a toda vista sin barra superior convencional, con barra lateral de 58 px, insignia de perfil flotante y menú de navegación con solapas de carpetas físicas verticales giradas 90°.
- **👥 Cartera de Clientes:** Listado ordenado alfabéticamente (A-Z) en bloques `AppListCard`, historial transaccional embebido y cálculo automático del saldo disponible.
- **📈 Instrumentos Financieros:** Captura y monitoreo de inversiones en formulario reactivo de 3 pestañas (*Datos*, *Aportes*, *Resultados*), cálculo automático de vencimientos, retención en la fuente y rendimientos netos. Incluye **bloqueo estricto de aportes en estado Activo**.
- **💸 Transacciones Financieras:** Registro clasificado de movimientos (*Recarga*, *Inversión*, *Retorno*, *Retiro*), filtros combinados por cliente y tipo, validación contra sobregiros y soporte de comprobantes multimedia.
- **🛡 Aislamiento Multiusuario (Multi-Tenancy):** Partición canónica de datos por usuario (`users/{userId}/...`) en Firestore, blindada mediante políticas de seguridad en `firestore.rules`.
- **🎨 Sistema de Diseño Desacoplado:** Inyección de paleta corporativa `KoralisColors`, fuentes Manrope y Hanken Grotesk (`google_fonts`) y loaders personalizables vía `CoreThemeExtension`.

---

## 📚 Centro de Documentación Técnica

Toda la documentación técnica, arquitectónica y funcional se encuentra detallada en la carpeta [docs/](file:///d:/Projects/Flutter/koralis/docs):

```text
docs/
├── README.md                    # Índice maestro navegable
├── core/                        # Paquete interno agnóstico 'core'
│   ├── sistema_de_diseno.md     # Paleta KoralisColors, tipografía y CoreThemeExtension
│   ├── catalogo_widgets.md      # Catálogo de 7 tipologías de widgets reutilizables
│   ├── servicios_firebase.md    # Wrappers de Firestore, FirebaseAuth y Storage
│   └── utilidades_y_errores.md  # CoreValidators, AppErrorHandler y DatabaseService
├── features/                    # Módulos funcionales de negocio
│   ├── auth.md                  # Ciclo de autenticación y sesiones
│   ├── instruments.md           # Modelos de inversión, fórmulas y reglas de negocio
│   ├── transactions.md          # Tipología de flujos de caja y saldo disponible
│   └── clients_and_dashboard.md # Cartera de clientes y dashboard inmersivo
└── architecture/                # Fundamentos y seguridad
    ├── aislamiento_multiusuario.md # Estructura multi-tenant en Cloud Firestore
    ├── seguridad_firestore.md      # Desglose de políticas en firestore.rules
    └── clean_architecture.md       # Separación de capas e inversión de control
```

---

## 🛠 Tecnologías y Dependencias

| Paquete | Versión | Propósito |
|---|---|---|
| `flutter` | SDK | Framework base para desarrollo móvil multiplataforma. |
| `firebase_core` | ^4.13.0 | Inicialización del ecosistema Firebase. |
| `cloud_firestore`| Transversal | Base de datos NoSQL reactiva en tiempo real. |
| `firebase_auth` | Transversal | Autenticación y gestión de usuarios. |
| `firebase_storage`| Transversal | Almacenamiento de archivos y comprobantes en la nube. |
| `google_fonts` | ^8.1.0 | Tipografías corporativas Manrope y Hanken Grotesk. |
| `flutter_arc_text`| ^0.6.0 | Renderizado tipográfico en curva en la pantalla de bienvenida. |
| `cupertino_icons` | ^1.0.8 | Iconografía complementaria estilo iOS. |
| `sqflite` | Transversal | Persistencia y caché local en base de datos relacional. |

---

## 📦 Requisitos Previos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) **>= 3.11.1**
- [Dart SDK](https://dart.dev/get-dart) **>= 3.11.1**
- Emulador Android / iOS o dispositivo físico configurado en modo depuración.
- Verificación del entorno:
  ```bash
  flutter doctor
  ```

---

## 🚀 Instalación y Configuración

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/tu-organizacion/koralis_app.git
   cd koralis_app
   ```

2. **Obtener dependencias del paquete Core:**
   ```bash
   cd packages/core
   flutter pub get
   cd ../..
   ```

3. **Obtener dependencias de la aplicación principal:**
   ```bash
   flutter pub get
   ```

---

## ▶️ Ejecución

```bash
# Ejecutar en modo desarrollo
flutter run

# Ejecutar en un dispositivo o emulador específico
flutter run -d <device-id>

# Compilar release para Android (APK)
flutter build apk --release

# Compilar bundle para Google Play Store
flutter build appbundle --release
```

---

## 🗺 Rutas de Navegación

Las rutas se gestionan de forma centralizada a través de [AppRouter](file:///d:/Projects/Flutter/koralis/lib/app/router.dart):

| Ruta | Pantalla | Argumentos Requeridos |
|---|---|---|
| `/` | [LoginScreen](file:///d:/Projects/Flutter/koralis/lib/features/auth/presentation/login_screen.dart) | Ninguno |
| `/sign_up` | [SignUpScreen](file:///d:/Projects/Flutter/koralis/lib/features/auth/presentation/sign_up_screen.dart) | Ninguno |
| `/dashboard` | [DashboardScreen](file:///d:/Projects/Flutter/koralis/lib/features/dashboard/presentation/dashboard_screen.dart) | `User` |
| `/clients` | [ClientsScreen](file:///d:/Projects/Flutter/koralis/lib/features/clients/presentation/clients_screen.dart) | `User` |
| `/client_form` | [ClientFormScreen](file:///d:/Projects/Flutter/koralis/lib/features/clients/presentation/client_form_screen.dart) | `ClientFormArgs` o `User` |
| `/instruments` | [InstrumentsScreen](file:///d:/Projects/Flutter/koralis/lib/features/instruments/presentation/instruments_screen.dart) | `User` |
| `/instrument_form`| [InstrumentFormScreen](file:///d:/Projects/Flutter/koralis/lib/features/instruments/presentation/instrument_form_screen.dart) | `InstrumentFormArgs` o `User` |
| `/transactions` | [TransactionsScreen](file:///d:/Projects/Flutter/koralis/lib/features/transactions/presentation/transactions_screen.dart) | `User` |
| `/transaction_form`| [TransactionFormScreen](file:///d:/Projects/Flutter/koralis/lib/features/transactions/presentation/transaction_form_screen.dart) | `TransactionFormArgs` o `User` |
| `/profile` | [ProfileScreen](file:///d:/Projects/Flutter/koralis/lib/features/profile/presentation/profile_screen.dart) | `Profile` |

---

## 🔑 Credenciales de Prueba

Para pruebas de acceso en entornos de desarrollo:

| Parámetro | Valor |
|---|---|
| **Correo** | `admin@koralis.com` |
| **Contraseña** | `Koralis123*` |

---

## 🧪 Pruebas y Análisis de Calidad

```bash
# Ejecutar análisis estático (Linter)
flutter analyze

# Ejecutar suite completa de pruebas unitarias y de widgets
flutter test

# Ejecutar específicamente pruebas de aislamiento multiusuario
flutter test test/features/multi_user_isolation_test.dart
```

---

## 📄 Licencia

Este proyecto es propiedad privada de **Koralis**. Todos los derechos reservados.
