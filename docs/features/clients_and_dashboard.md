# 👥 Cartera de Clientes y Dashboard Principal (`features/clients` & `features/dashboard`)

Este documento cubre la gestión integral de clientes y el centro de control principal (**Dashboard**) de **Koralis**.

---

## 👥 1. Cartera de Clientes (`features/clients`)

Ubicación: [client.dart](file:///d:/Projects/Flutter/koralis/lib/features/clients/domain/entities/client.dart)

### Modelo de Datos del Cliente

| Campo | Tipo | Propósito |
|---|---|---|
| `id` | `String` | Identificador único en Cloud Firestore. |
| `nombre` | `String` | Nombre completo o razón social. |
| `documento`| `String` | Cédula, DNI, RUT o NIT fiscal. |
| `correo` | `String` | Correo electrónico de contacto y notificaciones. |
| `telefono` | `String` | Teléfono móvil para soporte y mensajería. |
| `observacion`| `String` | Notas internas de negociación o perfil de riesgo. |
| `estado` | `String` | Estado operativo (`'Activo'`, `'Inactivo'`). |
| `transacciones`| `List<Transaction>` | Historial transaccional embebido. |
| `saldoDisponible`| `double` (Calculado) | Sumatoria algebraica de ingresos y egresos. |

---

### Pantalla de Clientes: `ClientsScreen`
Ubicación: [clients_screen.dart](file:///d:/Projects/Flutter/koralis/lib/features/clients/presentation/clients_screen.dart)

- **Ordenamiento Canónico:** La lista de clientes se presenta ordenada alfabéticamente **A-Z** por nombre.
- **Visualización en Bloques:** Utiliza el widget `AppListCard` del Core con:
  - Avatar circular con la inicial del cliente en mayúscula (`textoAvatar`).
  - Nombre principal y documento de identificación en subtítulo.
  - Indicador numérico del saldo disponible actual en el pie de la tarjeta.
  - Insignia de estado (`AppBadge`) destacando clientes activos.
- **Ficha de Detalle:** Al pulsar una tarjeta se abre la hoja modal con el resumen del cliente, opciones de edición ([client_form_screen.dart](file:///d:/Projects/Flutter/koralis/lib/features/clients/presentation/client_form_screen.dart)) y botón de acceso rápido para registrarle una recarga o retiro.
- **Acción Rápida:** Botón flotante `AppFloatingActionButton` para añadir un nuevo cliente al portafolio.

---

## 📊 2. Dashboard Principal (`features/dashboard`)

Ubicación: [dashboard_screen.dart](file:///d:/Projects/Flutter/koralis/lib/features/dashboard/presentation/dashboard_screen.dart)

El Dashboard es el núcleo operativo de Koralis. Presenta una experiencia inmersiva a pantalla completa sin `AppBar` tradicional superior, estructurado en dos zonas visuales:

```text
+---------------------------------------------------------------+
| [Avatar] |                                                    |
| -------- |  PANEL CENTRAL DE RESUMEN Y MÉTRICAS              |
| [Pest 1] |                                                    |
| [Pest 2] |  - Tarjetas de capital total colocado              |
| [Pest 3] |  - Rendimientos netos acumulados                   |
| [Pest 4] |  - Accesos directos a Clientes e Instrumentos      |
| -------- |                                                    |
| [Salir]  |                                                    |
+---------------------------------------------------------------+
```

### Componentes de la Barra Lateral (`AppSidebarNavigation`)
1. **Insignia Flotante de Perfil (`AppFloatingProfileBadge`):**
   - Situada en el vértice superior izquierdo. Muestra la foto o iniciales del usuario autenticado.
   - Al presionarla despliega el modal de configuración de perfil, cambio de clave y preferencias.
2. **Solapas de Carpeta Verticales (`AppFolderTab`):**
   - Inspiradas en archivadores físicos con bordes redondeados y colores diferenciados.
   - Textos e iconos girados 90° para lectura vertical de abajo hacia arriba.
   - Opciones directas:
     - 📁 **Clientes** (`Color(0xFF6B4EFF)`) -> `/clients`
     - 📈 **Instrumentos** (`Color(0xFF00A389)`) -> `/instruments`
     - 💳 **Transacciones** (`Color(0xFFF59E0B)`) -> `/transactions`
     - 👤 **Mi Perfil** (`Color(0xFF4638A4)`) -> `/profile`
3. **Pie de Acciones:**
   - Botón de cierre de sesión anclado permanentemente en la parte inferior, protegido contra retrocesos involuntarios.

---

## 🛡 3. Aislamiento de Cartera y Multiusuario

Cada usuario autenticado administra su propio universo de clientes y métricas:
- Las consultas a Firestore se ejecutan exclusivamente en la ruta `users/{userId}/clients`.
- No existe posibilidad de colisión ni filtración de información financiera entre distintas cuentas.
