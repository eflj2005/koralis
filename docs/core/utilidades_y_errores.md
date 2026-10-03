# 🛠 Utilidades, Validadores y Manejo de Errores (Core)

El paquete [packages/core](file:///d:/Projects/Flutter/koralis/packages/core) provee herramientas transversales para validar entradas de usuario, gestionar persistencia local y transformar excepciones de bajo nivel en mensajes claros y en español.

---

## 🔍 1. Validadores de Entrada: CoreValidators

Ubicación: [validators.dart](file:///d:/Projects/Flutter/koralis/packages/core/lib/src/validators.dart)

Centraliza reglas de validación utilizadas en formularios de autenticación y captura de datos.

### `CoreValidators.email(String? value)`
- **Propósito:** Valida que el texto ingresado no esté vacío y cumpla con la estructura canónica de correo electrónico (`usuario@dominio.extension`).
- **Retornos:**
  - `null`: Correo válido.
  - `'El correo no puede estar vacío'`: Entrada nula o vacía.
  - `'Ingrese un correo electrónico válido'`: Formato erróneo.

```dart
AppTextField(
  label: 'Correo',
  validator: CoreValidators.email,
)
```

### `CoreValidators.password(String? value)`
- **Propósito:** Aplica directivas de seguridad para credenciales:
  1. Longitud mínima de 6 caracteres.
  2. Al menos una letra mayúscula con **soporte completo para caracteres en español** (acepta `Ñ` y vocales con tilde `Á, É, Í, Ó, Ú`).
  3. Al menos un dígito numérico (`0-9`).
- **Retornos:** Mensaje explicativo en caso de incumplir cualquier directiva o `null` si es segura.

```dart
AppTextField(
  label: 'Contraseña',
  esOscuro: true,
  validator: CoreValidators.password,
)
```

---

## 🛡 2. Manejador Centralizado: AppErrorHandler

Ubicación: [app_error_handler.dart](file:///d:/Projects/Flutter/koralis/packages/core/lib/src/helpers/app_error_handler.dart)

Analiza polimórficamente cualquier excepción ocurrida en la aplicación (`Object? error`) y entrega un mensaje en español comprensible para el usuario, protegiendo a la interfaz de fallos no controlados:

```dart
try {
  await repository.ejecutarOperacion();
} catch (e) {
  final mensaje = AppErrorHandler.parseMessage(e);
  AppMessenger.showError(context, error: mensaje);
}
```

### Jerarquía de Evaluación

| Tipo de Excepción | Criterio de Resolución | Mensaje Resultante al Usuario |
|---|---|---|
| `FirebaseException` | Delega en `FirebaseErrors.mapMessage(error.code)`. | Traducción contextual (e.g. "Contraseña incorrecta"). |
| `SocketException` | Fallo de socket a nivel de sistema operativo. | "No hay conexión a internet. Verifica tu red e inténtalo de nuevo." |
| `TimeoutException` | La petición excedió el tiempo límite pactado. | "La solicitud ha superado el tiempo de espera. Inténtalo más tarde." |
| `FormatException` | Inconsistencias al decodificar tipos o JSON. | "Error en la estructura de los datos procesados." |
| `String` | Texto plano recibido en el `catch`. | Si ya es una oración en español la conserva; si es un código de error, lo traduce. |
| Otras excepciones | Excepciones no controladas o genéricas. | Limpia el prefijo técnico `Exception:` y expone el mensaje limpio. |

---

## 💾 3. Persistencia Local SQLite: DatabaseService

Ubicación: [services.dart](file:///d:/Projects/Flutter/koralis/packages/core/lib/src/services.dart)

Clase base genérica que encapsula `sqflite` con inicialización perezosa (*lazy loading*), asegurando una única conexión abierta para bases de datos relacionales locales:

```dart
final dbService = DatabaseService(
  dbName: 'koralis_cache.db',
  version: 1,
  onCreate: (db, version) async {
    await db.execute('''
      CREATE TABLE transacciones_offline (
        id TEXT PRIMARY KEY,
        monto REAL,
        fecha TEXT
      )
    ''');
  },
);

final db = await dbService.database;
```

---

## 📋 Resumen de Mejores Prácticas

1. **Nunca exponer trazas técnicas al usuario:** Los objetos de error nunca deben imprimirse crudos en diálogos o snackbars; siempre pasarlos por `AppErrorHandler.parseMessage(e)`.
2. **Validar antes de enviar a red:** Los formularios deben ejecutar validadores sincrónicos en cliente (`CoreValidators`) para reducir peticiones innecesarias a la nube.
