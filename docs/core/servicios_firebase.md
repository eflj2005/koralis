# ☁️ Servicios Firebase Agnósticos (Core)

El paquete [packages/core](file:///d:/Projects/Flutter/koralis/packages/core) encapsula el SDK de Firebase en wrappers reutilizables y desacoplados ubicados en [packages/core/lib/src/firebase/](file:///d:/Projects/Flutter/koralis/packages/core/lib/src/firebase).

El objetivo principal de esta capa es:
1. **Evitar la fuga de dependencias externas:** La lógica de negocio no interactúa directamente con los tipos nativos de Firebase cuando no es necesario.
2. **Traducción automática de errores:** Capturar cualquier `FirebaseException` o `FirebaseAuthException` y mapearla automáticamente a mensajes amigables y profesionales en español.
3. **Inyección de dependencias:** Todos los constructores admiten instancias inyectables para simplificar pruebas unitarias mediante mocks.

---

## 🔐 1. FirebaseAuthService

Ubicación: [firebase_auth_service.dart](file:///d:/Projects/Flutter/koralis/packages/core/lib/src/firebase/firebase_auth_service.dart)

Gestiona la autenticación de usuarios. Soporta correo y contraseña, y deja preparado el soporte para Google Sign-In.

### Métodos Principales

| Método | Descripción | Retorno |
|---|---|---|
| `signInWithEmailAndPassword` | Inicia sesión con correo y contraseña. | `Future<UserCredential>` |
| `createUserWithEmailAndPassword` | Registra una nueva cuenta de usuario. | `Future<UserCredential>` |
| `sendPasswordResetEmail` | Envía el enlace de recuperación de contraseña. | `Future<void>` |
| `sendEmailVerification` | Envía correo de confirmación de cuenta. | `Future<void>` |
| `signOut` | Cierra la sesión activa en Firebase y en Google si aplica. | `Future<void>` |
| `reloadCurrentUser` | Refresca la información del usuario en sesión. | `Future<void>` |
| `deleteAccount` | Elimina permanentemente la cuenta autenticada. | `Future<void>` |

### Propiedades Reactivas y Getters
- `currentUser`: Instancia del `User` autenticado o `null`.
- `currentUid`: String con el UID único o `null`.
- `isAuthenticated`: Booleano que indica si hay sesión activa.
- `authStateChanges`: Stream reactivo que emite cambios de autenticación en tiempo real.

---

## 🗄 2. FirestoreService

Ubicación: [firestore_service.dart](file:///d:/Projects/Flutter/koralis/packages/core/lib/src/firebase/firestore_service.dart)

Provee una API unificada y simplificada para operaciones CRUD, transacciones y consultas sobre Cloud Firestore.

### Operaciones CRUD

```dart
final firestore = FirestoreService();

// 1. Generar ID único previo
final nuevoId = firestore.newDocumentId('users/123/instruments');

// 2. Crear o sobrescribir con merge
await firestore.setDocument(
  collectionPath: 'users/123/instruments',
  docId: nuevoId,
  data: {'nombre': 'Plazo Fijo', 'tasa': 11.5},
  merge: true,
);

// 3. Actualizar campos específicos
await firestore.updateDocument(
  collectionPath: 'users/123/instruments',
  docId: nuevoId,
  data: {'estado': 'Activo'},
);

// 4. Obtener documento único
final doc = await firestore.getDocument(
  collectionPath: 'users/123/instruments',
  docId: nuevoId,
);

// 5. Eliminar documento
await firestore.deleteDocument(
  collectionPath: 'users/123/instruments',
  docId: nuevoId,
);
```

### Consultas Reactivas en Tiempo Real
- `streamCollection({required String collectionPath, Query Function(Query)? queryBuilder})`: Retorna un `Stream<List<Map<String, dynamic>>>` con los datos sincronizados y el `id` inyectado automáticamente.
- `streamDocument({required String collectionPath, required String docId})`: Retorna un `Stream<Map<String, dynamic>?>` que notifica cambios instantáneos sobre un registro específico.

---

## 📁 3. FirebaseStorageService

Ubicación: [firebase_storage_service.dart](file:///d:/Projects/Flutter/koralis/packages/core/lib/src/firebase/firebase_storage_service.dart)

Administra la carga y recuperación de archivos multimedia (comprobantes de pago, avatares, contratos).

### Métodos Disponibles
- `uploadFile({required String storagePath, required File file, SettableMetadata? metadata})`: Sube un archivo del sistema de archivos local y retorna la URL pública de descarga.
- `uploadData({required String storagePath, required Uint8List bytes, SettableMetadata? metadata})`: Sube bytes binarios en memoria (ideal para soporte web o imágenes comprimidas).
- `getDownloadUrl(String storagePath)`: Consulta la URL de un recurso existente.
- `deleteFile(String storagePath)`: Elimina el recurso en la nube.

---

## 🛑 4. Control y Traducción de Excepciones: FirebaseErrors

Ubicación: [firebase_errors.dart](file:///d:/Projects/Flutter/koralis/packages/core/lib/src/firebase/firebase_errors.dart)

Mapea códigos alfanuméricos técnicos del SDK de Firebase a mensajes claros y en español:

| Código de Error Firebase | Mensaje en Español al Usuario |
|---|---|
| `user-not-found` | "No existe una cuenta registrada con este correo electrónico." |
| `wrong-password` | "La contraseña ingresada es incorrecta." |
| `email-already-in-use` | "Ya existe una cuenta con este correo electrónico." |
| `invalid-email` | "El formato del correo electrónico no es válido." |
| `weak-password` | "La contraseña proporcionada es demasiado débil." |
| `permission-denied` | "No tienes los permisos necesarios para realizar esta operación." |
| `network-request-failed` | "Error de conexión. Verifica tu acceso a internet." |
| `too-many-requests` | "Demasiados intentos fallidos. Inténtalo más tarde." |
