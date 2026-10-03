# 🛡 Aislamiento Multiusuario y Modelo de Datos (`architecture/aislamiento_multiusuario`)

La arquitectura de **Koralis** está diseñada bajo un principio estricto de **aislamiento multi-inquilino a nivel de usuario (User-Level Multi-Tenancy)** en Cloud Firestore. Esto asegura que la información financiera de cada usuario permanezca completamente segregada, privada e inaccesible para otros usuarios del sistema.

---

## 🏛 1. Jerarquía Canónica de Colecciones

Firestore organiza los datos en un árbol jerárquico dividido entre recursos globales y espacios de datos privados:

```text
/ (Raíz de Firestore)
│
├── banks/{bankId}                                  [CATÁLOGO GLOBAL]
│   └── (Documentos maestros de bancos: Bancolombia, Davivienda, etc.)
│
├── profiles/{userId}                               [PERFIL PRIVADO]
│   └── (Datos personales, nombre, foto, configuración del usuario)
│
└── users/{userId}/                                 [ESPACIO PRIVADO MULTIUSUARIO]
    │
    ├── clients/{clientId}                          [SUBCOLECCIÓN DE CLIENTES]
    │   ├── nombre, documento, correo, telefono, ...
    │   └── transacciones: [                        [SUBOBJETO EMBEBIDO]
    │           { id, tipo: 'recarga', monto, ... },
    │           { id, tipo: 'inversion', monto, ... }
    │       ]
    │
    └── instruments/{instrumentId}                  [SUBCOLECCIÓN DE INSTRUMENTOS]
        └── numero, entidad, valorInvertido, tasaIea, estado, ...
```

---

## 🧩 2. Centralización de Rutas en `FirebaseFirestoreConfig`

Ubicación: [firebase_firestore_config.dart](file:///d:/Projects/Flutter/koralis/lib/app/firebase_firestore_config.dart)

Para evitar la concatenación manual y errática de rutas en la capa de datos, se centralizan helpers estáticos:

```dart
// Retorna: 'users/{userId}/clients'
static String coleccionClientes(String userId) {
  final uidLimpio = userId.trim();
  if (uidLimpio.isEmpty) return colClientes;
  return '$colUsuarios/$uidLimpio/$subcolClientes';
}

// Retorna: 'users/{userId}/instruments'
static String coleccionInstrumentos(String userId) {
  final uidLimpio = userId.trim();
  if (uidLimpio.isEmpty) return colInstrumentos;
  return '$colUsuarios/$uidLimpio/$subcolInstrumentos';
}
```

---

## 🔒 3. Garantías de Privacidad y Rendimiento

1. **Partición Física Lógica:**
   - Al segmentar las subcolecciones dentro del documento `/users/{userId}`, las consultas (`getDocuments` o `streamCollection`) operan únicamente sobre el subárbol del usuario activo.
   - Es técnicamente imposible que un usuario descargue por accidente registros de otro cliente o instrumento.
2. **Consultas Atómicas de Clientes y Transacciones:**
   - Las transacciones financieras residen en el campo `transacciones` de cada cliente como una lista embebida de mapas.
   - Con **1 sola lectura** de Firestore se obtienen los datos del cliente, todo su historial de movimientos y se recalcula reactivamente su saldo disponible en memoria.
3. **Escalabilidad y Cuotas:**
   - La partición por usuario distribuye las escrituras entre múltiples nodos de Firestore, evitando cuellos de botella por contención de concurrencia en colecciones masivas.

---

## 🧪 4. Validación Automatizada de Aislamiento

El comportamiento multiusuario se encuentra validado en la suite de pruebas automatizadas [multi_user_isolation_test.dart](file:///d:/Projects/Flutter/koralis/test/features/multi_user_isolation_test.dart), verificando que:
- Operaciones del `Usuario A` en su subcolección de clientes no impactan ni son visibles para el `Usuario B`.
- Los instrumentos del `Usuario A` no colisionan ni comparten identificadores con el `Usuario B`.
- El catálogo global `/banks` responde a todos los usuarios autenticados sin requerir duplicación de datos.
