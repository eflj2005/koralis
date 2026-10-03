# 📦 Catálogo de Widgets Reutilizables (Core)

El paquete [packages/core](file:///d:/Projects/Flutter/koralis/packages/core) provee una biblioteca modular de componentes visuales desacoplados de la lógica de negocio. Todos los widgets están centralizados y exportados a través de [widgets.dart](file:///d:/Projects/Flutter/koralis/packages/core/lib/src/widgets.dart).

---

## 📑 Clasificación de Componentes

1. [Botones y Acciones Interactivas](#1-botones-y-acciones-interactivas)
2. [Entradas de Formulario y Selección](#2-entradas-de-formulario-y-selección)
3. [Navegación Lateral y Solapas Archivador](#3-navegación-lateral-y-solapas-archivador)
4. [Tarjetas, Bloques de Lista y Encabezados](#4-tarjetas-bloques-de-lista-y-encabezados)
5. [Indicadores de Estado, Carga y Vacío](#5-indicadores-de-estado-carga-y-vacío)
6. [Ventanas Modales y Diálogos](#6-ventanas-modales-y-diálogos)
7. [Mensajería y Notificaciones en Pantalla](#7-mensajería-y-notificaciones-en-pantalla)

---

## 1. Botones y Acciones Interactivas

Ubicación: [app_buttons.dart](file:///d:/Projects/Flutter/koralis/packages/core/lib/src/widgets/app_buttons.dart)

### `AppButton`
Botón principal que encapsula un `ElevatedButton` estilizado con soporte opcional para ícono a la izquierda.

```dart
AppButton(
  texto: 'Guardar Instrumento',
  icono: Icons.save_rounded,
  onPressed: () => _guardar(),
)
```

### `AppMenuButton`
Botón rectangular con borde sutil, icono destacado y chevron derecho, diseñado para accesos directos y menús de paneles.

```dart
AppMenuButton(
  title: 'Gestión de Clientes',
  icon: Icons.people_outline,
  onTap: () => Navigator.pushNamed(context, '/clients'),
)
```

### `AppFloatingActionButton`
Botón circular flotante (`FloatingActionButton`) con bordes redondeados (16px), diseñado para el registro de nuevos elementos en listas.

```dart
AppFloatingActionButton(
  icono: Icons.add_rounded,
  mensajeTooltip: 'Nuevo Registro',
  onPressed: () => _abrirFormulario(),
)
```

---

## 2. Entradas de Formulario y Selección

Ubicación: [app_inputs.dart](file:///d:/Projects/Flutter/koralis/packages/core/lib/src/widgets/app_inputs.dart)

### `AppTextField`
Campo de texto con label flotante, icono de prefijo, soporte de validación y control de contraseña con botón de visibilidad integrado.

```dart
AppTextField(
  label: 'Monto de Inversión',
  hint: '0.00',
  icono: Icons.attach_money_rounded,
  tipoTeclado: const TextInputType.numberWithOptions(decimal: true),
  controller: _montoController,
  validator: (v) => v!.isEmpty ? 'Ingrese un monto válido' : null,
)
```

### `AppDropdownField<T>`
Lista desplegable estandarizada con el mismo estilo visual de `AppTextField` y soporte para indicador de carga asíncrona (`isLoading`).

```dart
AppDropdownField<String>(
  label: 'Entidad Financiera',
  hint: 'Seleccione un banco',
  icono: Icons.account_balance_rounded,
  value: _bancoSeleccionado,
  items: bancos.map((b) => DropdownMenuItem(value: b.id, child: Text(b.nombre))).toList(),
  onChanged: (nuevo) => setState(() => _bancoSeleccionado = nuevo),
)
```

---

## 3. Navegación Lateral y Solapas Archivador

Ubicación: [app_navigation.dart](file:///d:/Projects/Flutter/koralis/packages/core/lib/src/widgets/app_navigation.dart)

Inspirado en archivadores físicos con pestañas de colores escalonadas que se leen en orientación vertical.

### `AppSidebarNavigation`
Barra lateral anclada a la izquierda que contiene la insignia del perfil de usuario, lista de solapas scrollables y pie de acciones (cerrar sesión).

### `AppFolderTab` y `AppFolderTabsColumn`
Solapa individual y contenedor en columna. Utiliza un `RotatedBox` con texto e íconos girados a 270° (lectura vertical de abajo hacia arriba), esquina derecha redondeada y soporte táctil accesible.

```dart
AppSidebarNavigation(
  anchoBarra: 58.0,
  insigniaFlotante: AppFloatingProfileBadge(
    avatarUrl: usuario.avatarUrl,
    iniciales: 'JS',
    onTap: () => Navigator.pushNamed(context, '/profile'),
  ),
  seccionPestanas: AppFolderTabsColumn(
    indiceActivo: _indiceTabSeleccionado,
    items: [
      AppFolderTabItem(
        indice: 0,
        titulo: 'Clientes',
        icono: Icons.people_alt_rounded,
        colorAcento: const Color(0xFF6B4EFF),
        onTap: () => _seleccionarTab(0),
      ),
      AppFolderTabItem(
        indice: 1,
        titulo: 'Instrumentos',
        icono: Icons.trending_up_rounded,
        colorAcento: const Color(0xFF00A389),
        onTap: () => _seleccionarTab(1),
      ),
    ],
  ),
)
```

---

## 4. Tarjetas, Bloques de Lista y Encabezados

Ubicación: [app_cards.dart](file:///d:/Projects/Flutter/koralis/packages/core/lib/src/widgets/app_cards.dart)

### `AppHeaderTitle`
Encabezado tipográfico sin sombras que se integra con el fondo de la pantalla. Muestra un título principal de gran contraste y subtítulo explicativo.

### `AppListCard`
Bloque rectangular apilable optimizado para listas densas.
- **Avatar:** Iniciales o ícono con color cromático distintivo.
- **Jerarquía:** Soporta fusión inteligente de subtítulo en segunda línea (`fusionarSubtituloSiMultilinea`) para pantallas estrechas.
- **Insignia:** Espacio reservado para badges de estado (`AppBadge`).

```dart
AppListCard(
  titulo: 'Carlos Mendoza',
  subtitulo: 'DNI: 09283748 • Persona Natural',
  detalle: 'cmendoza@empresa.com',
  textoAvatar: 'C',
  colorAcento: Colors.blueAccent,
  badge: const AppBadge(texto: 'Activo', color: Colors.green),
  onTap: () => _verDetalleCliente(cliente.id),
)
```

### `AppBadge`
Píldora compacta de estado con fondo suave translúcido y borde cromático para visualizar estados de instrumentos ("Activo", "En Negociación", "Cerrado").

---

## 5. Indicadores de Estado, Carga y Vacío

Ubicación: [app_indicators.dart](file:///d:/Projects/Flutter/koralis/packages/core/lib/src/widgets/app_indicators.dart)

### `AppSpinner`
Indicador circular compuesto por un `CircularProgressIndicator` perimetral y el GIF/imagen configurada en `CoreThemeExtension` en el núcleo central.

### `LoadingWidget`
Capa de bloqueo modal translúcida a pantalla completa con spinner y leyenda informativa ("Cargando...").

### `EmptyWidget`
Vista estándar para colecciones vacías o búsquedas sin coincidencias, compuesta por un ícono neutral ampliado, título en negrita y sugerencia descriptiva.

```dart
if (lista.isEmpty) {
  return const EmptyWidget(
    icono: Icons.inbox_outlined,
    titulo: 'No hay transacciones registradas',
    descripcion: 'Presiona el botón + para registrar la primera operación.',
  );
}
```

---

## 6. Ventanas Modales y Diálogos

Ubicación: [app_modals.dart](file:///d:/Projects/Flutter/koralis/packages/core/lib/src/widgets/app_modals.dart)

### `AppModalBottomSheet`
Contenedor base para bottom sheets con borde superior redondeado de 24px, barra de arrastre y ajuste automático contra el teclado virtual (`viewInsets`).

### `showUnderConstructionDialog`
Diálogo rápido reutilizable para funcionalidades en proceso de implementación.

---

## 7. Mensajería y Notificaciones en Pantalla

Ubicación: [app_messenger.dart](file:///d:/Projects/Flutter/koralis/packages/core/lib/src/widgets/app_messenger.dart)

### `AppMessenger`
Helper estático que abstrae el `ScaffoldMessenger`:
- `AppMessenger.showSnackBar(context, mensaje: '...')`: Notificación estándar.
- `AppMessenger.showError(context, error: '...')`: Notificación de error con color semántico de alerta.
- `AppMessenger.showSuccess(context, mensaje: '...')`: Notificación de éxito con icono de confirmación.
