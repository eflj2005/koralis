# 🐾 PetCare App

Aplicación móvil desarrollada en **Flutter** para la gestión integral de mascotas. Permite registrar mascotas, gestionar perfiles de usuario y navegar entre módulos de forma estructurada, todo respaldado por una base de datos local SQLite.

---

## 📋 Tabla de Contenidos

- [Descripción](#-descripción)
- [Características](#-características)
- [Tecnologías y Dependencias](#-tecnologías-y-dependencias)
- [Requisitos Previos](#-requisitos-previos)
- [Instalación](#-instalación)
- [Ejecución](#-ejecución)
- [Arquitectura](#-arquitectura)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Credenciales de Prueba](#-credenciales-de-prueba)
- [Contribuir](#-contribuir)
- [Licencia](#-licencia)

---

## 📖 Descripción

PetCare App es un proyecto de referencia que combina una arquitectura limpia (**Clean Architecture**) con un sistema de temas y componentes desacoplado. El paquete interno `core` actúa como una librería agnóstica reutilizable en cualquier otro proyecto Flutter, mientras que la lógica propia de PetCare reside exclusivamente en la carpeta `lib/app`.

## ✅ Características

- **Autenticación** de usuario (login con correo y contraseña).
- **Dashboard** principal con resumen de mascotas registradas.
- **Gestión de mascotas**: listado con nombre, raza, edad y peso.
- **Perfil de usuario** con avatar y opción de cierre de sesión.
- **Cierre de sesión** con borrado completo del historial de navegación.
- **Modal "En Construcción"** reutilizable para funcionalidades pendientes.
- **Spinner de carga** personalizable desde la configuración de estilos de la app.
- **Texto en arco** en la pantalla de login para la marca PetCare.
- **Soporte de temas** totalmente parametrizable mediante inyección de colores y tipografía.

---

## 🛠 Tecnologías y Dependencias

| Paquete | Versión | Uso |
|---|---|---|
| `flutter` | SDK | Framework principal |
| `sqflite` | ^2.x | Base de datos local SQLite (vía paquete `core`) |
| `google_fonts` | ^8.1.0 | Tipografía Comic Neue |
| `flutter_arc_text` | ^0.6.0 | Texto curvo en pantalla de Login |
| `cupertino_icons` | ^1.0.8 | Íconos estilo iOS |

> El paquete interno `packages/core` encapsula `sqflite`, `DatabaseService`, widgets reutilizables y el sistema de theming.

---

## 📦 Requisitos Previos

Antes de instalar, asegúrate de tener configurado:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) **>= 3.11.1**
- [Dart SDK](https://dart.dev/get-dart) **>= 3.11.1**
- Un emulador Android/iOS o dispositivo físico conectado
- `flutter doctor` sin errores críticos

```bash
# Verificar instalación de Flutter
flutter doctor
```

---

## 🚀 Instalación

1. **Clona el repositorio**
   ```bash
   git clone https://github.com/tu-usuario/petcare_app.git
   cd petcare_app
   ```

2. **Instala las dependencias del paquete `core`**
   ```bash
   cd packages/core
   flutter pub get
   cd ../..
   ```

3. **Instala las dependencias de la aplicación principal**
   ```bash
   flutter pub get
   ```

---

## ▶️ Ejecución

```bash
# Modo desarrollo (con hot-reload)
flutter run

# Ejecutar en un dispositivo específico
flutter run -d <device-id>

# Listar dispositivos disponibles
flutter devices

# Compilar APK de release para Android
flutter build apk --release

# Compilar para iOS (requiere macOS)
flutter build ios --release
```

> **Nota:** Al ejecutar por primera vez, la base de datos SQLite se creará automáticamente y se poblarán los datos de prueba iniciales (usuario administrador y mascotas de ejemplo).

---

## 🏗 Arquitectura

El proyecto sigue los principios de **Clean Architecture** propuestos por Robert C. Martin, organizados en tres capas bien diferenciadas por responsabilidad:

### Capas

#### `presentation/`
Contiene Widgets y Screens de Flutter. Es la capa más externa y solo conoce a la capa de Dominio. Jamás interactúa directamente con la base de datos.

#### `domain/`
Es el corazón del negocio. Contiene:
- **Entities**: Modelos puros de datos sin dependencias externas (`User`, `Pet`, `Profile`).
- **Repositories (Interfaces)**: Contratos abstractos que dictan qué operaciones existen, sin importar cómo se implementan.
- **Use Cases**: Orquestadores de lógica de negocio. Usan las interfaces del repositorio.

#### `data/`
Es la capa técnica que implementa los contratos definidos en `domain/`. Aquí viven los `RepositoryImpl` que realizan las consultas reales a SQLite a través del `AppDatabase`.

### Regla de Dependencias

```
Presentación  →  Dominio  ←  Datos
```

Las capas externas siempre dependen de las internas. El Dominio nunca importa archivos de Presentación ni de Datos, garantizando que la lógica de negocio sea testeable e independiente de cualquier tecnología.

### Paquete `core` (Librería Interna)

Ubicado en `packages/core/`, es una librería agnóstica de negocio que provee:

- `CoreTheme` / `CoreThemeExtension`: Sistema de temas parametrizable por inyección.
- `DatabaseService`: Wrapper genérico sobre `sqflite`.
- Widgets reutilizables: `AppButton`, `AppTextField`, `AppSpinner`, `LoadingWidget`, `EmptyWidget`, `AppMenuButton`, `showUnderConstructionDialog`.
- `CoreValidators`: Validadores de formularios.
- `CoreColors` / `CoreTypography`: Constantes de fábrica (colores base de Flutter).

La identidad visual de PetCare se inyecta desde `lib/app/styles.dart`, manteniendo el `core` libre de dependencias de marca.

---

## 📁 Estructura del Proyecto

```
petcare_app/
├── lib/
│   ├── app/
│   │   ├── database.dart      # AppDatabase (SQLite + datos semilla)
│   │   ├── router.dart        # AppRouter (rutas nombradas)
│   │   └── styles.dart        # AppStyles, PetCareColors, PetCareTypography
│   ├── features/
│   │   ├── auth/              # Módulo de autenticación
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── dashboard/         # Módulo de dashboard
│   │   ├── pets/              # Módulo de mascotas
│   │   └── profile/           # Módulo de perfil de usuario
│   └── main.dart
├── packages/
│   └── core/                  # Librería interna reutilizable
│       └── lib/
│           └── src/
│               ├── constants.dart
│               ├── theme.dart
│               ├── validators.dart
│               └── widgets.dart
├── images/                    # Assets estáticos (GIF, avatares)
├── pubspec.yaml
└── README.md
```

### Rutas de Navegación

| Ruta | Pantalla | Requiere Argumento |
|---|---|---|
| `/` | `LoginScreen` | No |
| `/dashboard` | `DashboardScreen` | `User` |
| `/pets` | `PetsScreen` | No |
| `/profile` | `ProfileScreen` | `Profile` |

---

## 🔑 Credenciales de Prueba

Al iniciar la aplicación por primera vez, se crean automáticamente los siguientes datos de prueba:

| Campo | Valor |
|---|---|
| **Correo** | `admin@petcare.com` |
| **Contraseña** | `PetCare123*` |

> Estos datos son generados por el método `_seedInitialData` en `lib/app/database.dart` y **solo se insertan una vez** al crear la base de datos.

---

## 🤝 Contribuir

1. Haz un fork del repositorio.
2. Crea una rama para tu feature: `git checkout -b feature/nueva-funcionalidad`.
3. Realiza tus cambios respetando la arquitectura existente.
4. Ejecuta el analizador antes de hacer commit: `dart analyze`.
5. Envía un Pull Request describiendo los cambios.

---

## 📄 Licencia

Este proyecto es de uso privado. Todos los derechos reservados.
