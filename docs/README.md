# 📚 Documentación Técnica de Koralis

Bienvenido al centro de documentación técnica y arquitectónica de **Koralis**, aplicación móvil en Flutter orientada a la gestión y análisis de instrumentos financieros y finanzas multiusuario.

---

## 🗂 Estructura de la Documentación

La documentación se organiza de forma modular y por capas, reflejando el desacoplamiento arquitectónico del proyecto:

```text
docs/
├── README.md                    # Este índice maestro
├── core/                        # Paquete interno reutilizable 'core'
│   ├── sistema_de_diseno.md     # Tokens, paleta cromática, tipografía y temas
│   ├── catalogo_widgets.md      # Catálogo de componentes y widgets UI reutilizables
│   ├── servicios_firebase.md    # Servicios agnósticos de Firestore, Auth y Storage
│   └── utilidades_y_errores.md  # Validadores, formateadores y control centralizado de excepciones
├── features/                    # Módulos de negocio (Auth, Clientes, Instrumentos, Transacciones) [Fase 2]
├── architecture/                # Decisiones arquitectónicas, modelo multiusuario y seguridad [Fase 3]
└── Propuesta_Koralis.pdf        # Documento fundacional de requerimientos de negocio
```

---

## 🧭 Módulos Disponibles

### 1. Paquete Core (`packages/core`)
El paquete `core` es una librería agnóstica de negocio, diseñada para proveer la infraestructura gráfica, componentes interactivos y servicios de nube transversales:

- **[Sistema de Diseño](file:///d:/Projects/Flutter/koralis/docs/core/sistema_de_diseno.md):** Especificación de colores, tipografías, extensiones temáticas (`CoreThemeExtension`) y personalización de spinners.
- **[Catálogo de Widgets](file:///d:/Projects/Flutter/koralis/docs/core/catalogo_widgets.md):** Catálogo de componentes reutilizables: formularios, navegación lateral estilo archivador, tarjetas de métricas, modales y alertas.
- **[Servicios Firebase](file:///d:/Projects/Flutter/koralis/docs/core/servicios_firebase.md):** Wrappers desacoplados para Cloud Firestore, Firebase Authentication y Cloud Storage con traducción nativa de errores.
- **[Utilidades y Errores](file:///d:/Projects/Flutter/koralis/docs/core/utilidades_y_errores.md):** Validadores de entradas, formateadores de datos y manejador uniforme de excepciones `AppErrorHandler`.

### 2. Módulos de Negocio (`lib/features`)
Lógica de negocio, casos de uso, modelos y pantallas de la aplicación:

- **[Autenticación y Perfil](file:///d:/Projects/Flutter/koralis/docs/features/auth.md):** Inicio de sesión, registro, recuperación de contraseña y gestión de cuenta.
- **[Instrumentos Financieros](file:///d:/Projects/Flutter/koralis/docs/features/instruments.md):** CDTs, bonos, fórmulas de rendimientos, formulario reactivo de 3 tabs y bloqueo de aportes en estado Activo.
- **[Transacciones Financieras](file:///d:/Projects/Flutter/koralis/docs/features/transactions.md):** Flujo de fondos (recargas, inversiones, retornos, retiros), saldo disponible calculado y filtros.
- **[Clientes y Dashboard](file:///d:/Projects/Flutter/koralis/docs/features/clients_and_dashboard.md):** Cartera ordenada A-Z, ficha de cliente, navegación por solapas verticales tipo archivador y métricas consolidadas.

### 3. Arquitectura y Seguridad (`docs/architecture`)
Fundamentos estructurales, persistencia y directivas de control de acceso:

- **[Aislamiento Multiusuario](file:///d:/Projects/Flutter/koralis/docs/architecture/aislamiento_multiusuario.md):** Partición jerárquica de colecciones Firestore por usuario (`users/{userId}/...`), catálogo global y subobjeto de transacciones.
- **[Seguridad en Cloud Firestore](file:///d:/Projects/Flutter/koralis/docs/architecture/seguridad_firestore.md):** Desglose de `firestore.rules`, funciones evaluadoras, matriz RBAC y principio de denegación por defecto.
- **[Clean Architecture](file:///d:/Projects/Flutter/koralis/docs/architecture/clean_architecture.md):** Separación de capas (Domain, Data, Presentation), rol del paquete agnóstico `core` e inversión de dependencias.

---

## 🛠 Convenciones y Buenas Prácticas

- **Idioma:** Todo el código fuente, comentarios Dartdoc, mensajes de commit y documentos técnicos se redactan en **español**.
- **Clean Architecture:** Separación estricta de responsabilidades entre Capa de Dominio (entidades, casos de uso, contratos), Capa de Datos (modelos, datasources, implementaciones de repositorios) y Capa de Presentación (pantallas, widgets, controladores).
- **Desacoplamiento:** Ningún widget o servicio del paquete `core` debe importar ni acoplarse a lógica específica del dominio financiero de Koralis.
