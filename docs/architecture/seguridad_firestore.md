# 🔐 Reglas de Seguridad en Cloud Firestore (`architecture/seguridad_firestore`)

La seguridad del backend serverless en **Koralis** reside en [firestore.rules](file:///d:/Projects/Flutter/koralis/firestore.rules). Las reglas imponen autorización a nivel de petición en la nube, garantizando que ninguna solicitud no autorizada pueda violar el aislamiento de datos, aun si el cliente móvil es modificado o interceptado.

---

## 🛡 1. Funciones Auxiliares de Seguridad

Para asegurar legibilidad y evitar código repetitivo, se definen dos funciones evaluadoras:

```javascript
/// Verifica si la petición proviene de un usuario con sesión activa en Firebase Auth.
function estaAutenticado() {
  return request.auth != null;
}

/// Verifica si el usuario autenticado es el propietario del recurso.
function esPropietario(userId) {
  return estaAutenticado() && request.auth.uid == userId;
}
```

---

## 📊 2. Matriz de Control de Acceso (RBAC)

| Ruta de Firestore | Permiso de Lectura | Permiso de Escritura | Justificación de Seguridad |
|---|---|---|---|
| `/banks/{bankId}` | `estaAutenticado()` | `false` (Bloqueado) | Catálogo maestro de entidades financieras. Consultable por cualquier usuario autenticado; sólo modificable por administradores vía consola o scripts de backend con Service Account. |
| `/profiles/{userId}` | `esPropietario(userId)` | `esPropietario(userId)` | Protege datos personales del usuario. Nadie puede ver ni modificar un perfil que no corresponda a su `auth.uid`. |
| `/users/{userId}` | `esPropietario(userId)` | `esPropietario(userId)` | Raíz del espacio multiusuario del cliente. |
| `/users/{userId}/clients/{clientId}` | `esPropietario(userId)` | `esPropietario(userId)` | Cartera de clientes y sus transacciones financieras embebidas. |
| `/users/{userId}/instruments/{instrumentId}` | `esPropietario(userId)` | `esPropietario(userId)` | Instrumentos de inversión, tasas y montos colocados. |
| `/{document=**}` (Resto de la base de datos) | `false` | `false` | **Denegación por defecto** (*Deny by default*). |

---

## 🚫 3. Principio de Denegación por Defecto (Zero Trust)

Al final de [firestore.rules](file:///d:/Projects/Flutter/koralis/firestore.rules#L79), se implementa un interceptor comodín:

```javascript
match /{document=**} {
  allow read, write: if false;
}
```

**Beneficios:**
- Cualquier colección nueva o experimental que se cree accidentalmente queda **bloqueada por defecto** hasta que se defina una regla explícita.
- Previene fugas de datos derivadas de colecciones en desuso o temporales.

---

## 🔒 4. Integridad en Pruebas y Despliegue

1. **Tokens JWT:** Cada petición hacia Cloud Firestore viaja firmada con el token de Firebase Authentication, que contiene el `request.auth.uid` validado criptográficamente por los servidores de Google.
2. **Validación en Cliente + Servidor:** Aunque la aplicación Flutter aplica validaciones sincrónicas de interfaz ([app_inputs.dart](file:///d:/Projects/Flutter/koralis/packages/core/lib/src/widgets/app_inputs.dart)), las reglas de Firestore son la barrera de seguridad infranqueable final.
