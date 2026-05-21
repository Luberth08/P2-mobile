# Implementación de Servicios para Cliente Móvil

## Resumen
Se implementó la funcionalidad completa para que el cliente pueda ver sus servicios activos e historial desde la aplicación móvil Flutter.

## Archivos Creados

### 1. Modelos (`lib/models/servicio.dart`)
Modelos de datos para servicios:
- `TallerInfo`: Información del taller
- `TecnicoAsignado`: Técnico asignado al servicio
- `VehiculoAsignado`: Vehículo del taller asignado
- `DiagnosticoDetalle`: Información del diagnóstico
- `ServicioCliente`: Servicio completo con todos los detalles
- `ServicioHistorial`: Servicio resumido para historial

### 2. Servicio API (`lib/services/servicio_api.dart`)
Cliente HTTP para consumir los endpoints del backend:
- `obtenerServicioActual()`: Obtiene el servicio activo del cliente
- `obtenerHistorialServicios()`: Lista servicios completados/cancelados
- `obtenerDetalleServicio()`: Obtiene detalle completo de un servicio

### 3. Pantalla Principal (`lib/screens/servicios_tab.dart`)
Pantalla con 3 tabs que reemplaza a `solicitudes_tab.dart`:
- **Tab 1 - Solicitudes**: Solicitudes de diagnóstico pendientes
- **Tab 2 - Historial**: Servicios completados/cancelados
- **Tab 3 - Todos**: Vista combinada de solicitudes e historial

**Características**:
- Card destacado del servicio actual (si existe)
- Pull-to-refresh en todas las tabs
- Estados visuales con colores e iconos
- Navegación a detalle del servicio

### 4. Pantalla de Detalle (`lib/screens/servicio_detalle_screen.dart`)
Pantalla completa con información del servicio:
- Header con estado del servicio
- Información del taller (nombre, dirección, teléfono, rating)
- Técnicos asignados
- Vehículos del taller asignados
- Diagnóstico original
- Mapa con ubicación del cliente (placeholder)

**Funcionalidades**:
- Botón para llamar al taller
- Diseño responsive y atractivo
- Colores dinámicos según estado

## Archivos Modificados

### 1. Home Screen (`lib/screens/home_screen.dart`)
- Cambió import de `solicitudes_tab.dart` a `servicios_tab.dart`
- Renombró tab de "Solicitudes" a "Mis Servicios"
- Cambió icono de `Icons.history` a `Icons.build_circle`

## Flujo de Usuario

```
1. Cliente abre app → Ve tab "Mis Servicios"
2. Si hay servicio activo → Card destacado en la parte superior
3. Click en card → Pantalla de detalle completo
4. Tabs disponibles:
   - Solicitudes: Diagnósticos pendientes
   - Historial: Servicios completados
   - Todos: Vista combinada
```

## Estados de Servicio

| Estado | Color | Icono | Descripción |
|--------|-------|-------|-------------|
| `creado` | Azul (#3B82F6) | build | Servicio recién creado |
| `en_proceso` | Púrpura (#8B5CF6) | engineering | Servicio en progreso |
| `completado` | Verde (#10B981) | check_circle | Servicio finalizado |
| `cancelado` | Gris (#6B7280) | cancel | Servicio cancelado |

## Integración con Backend

### Endpoints Consumidos:
- `GET /api/v1/servicios/mis-servicios/actual`
- `GET /api/v1/servicios/mis-servicios/historial`
- `GET /api/v1/servicios/mis-servicios/{id}/detalle`

### Autenticación:
Todos los endpoints requieren token JWT en header:
```dart
headers: {
  'Authorization': 'Bearer $token',
  'Content-Type': 'application/json',
}
```

## Pendientes / Mejoras Futuras

### 1. Implementar Mapa Real
Actualmente hay un placeholder. Para implementar:

**Opción A: Google Maps**
```yaml
# pubspec.yaml
dependencies:
  google_maps_flutter: ^2.5.0
```

**Opción B: OpenStreetMap (Gratis)**
```yaml
# pubspec.yaml
dependencies:
  flutter_map: ^6.0.0
  latlong2: ^0.9.0
```

### 2. Notificaciones Push
Notificar al cliente cuando:
- Un taller acepta su solicitud
- El servicio cambia de estado
- El servicio se completa

### 3. Chat con el Taller
Permitir comunicación directa entre cliente y taller

### 4. Calificación del Servicio
Permitir al cliente calificar el servicio completado

### 5. Tracking en Tiempo Real
Mostrar ubicación del técnico en camino (si aplica)

## Dependencias Necesarias

Verificar que estén en `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  url_launcher: ^6.2.0  # Para llamar al taller
  
  # Opcional para mapa:
  # google_maps_flutter: ^2.5.0
  # O
  # flutter_map: ^6.0.0
  # latlong2: ^0.9.0
```

## Testing

### Casos de Prueba:
1. ✅ Cliente sin servicio activo → No muestra card destacado
2. ✅ Cliente con servicio activo → Muestra card con información
3. ✅ Click en servicio → Navega a detalle
4. ✅ Historial vacío → Muestra estado vacío
5. ✅ Pull to refresh → Recarga datos
6. ✅ Llamar al taller → Abre app de teléfono

### Datos de Prueba:
Para probar, necesitas:
1. Un cliente con diagnóstico creado
2. Un taller que haya aceptado la solicitud
3. Servicio en estado "creado" o "en_proceso"

## Notas de Implementación

### Manejo de Errores:
- Los errores de red se capturan y se imprimen en consola
- No se muestran SnackBars para evitar spam al usuario
- Los estados de carga se manejan con spinners

### Performance:
- Se cargan los 3 tabs en paralelo con `Future.wait()`
- Las imágenes y datos se cachean automáticamente por HTTP
- Pull-to-refresh solo recarga la tab activa

### Accesibilidad:
- Todos los botones tienen áreas táctiles de 48x48 mínimo
- Los colores tienen suficiente contraste
- Los textos son legibles en diferentes tamaños

## Migración desde Solicitudes Tab

Si ya tenías `solicitudes_tab.dart` en uso:

1. ✅ El nuevo `servicios_tab.dart` incluye toda la funcionalidad anterior
2. ✅ Las solicitudes pendientes siguen visibles en el primer tab
3. ✅ Se agregó funcionalidad de servicios sin romper lo existente
4. ⚠️ Puedes eliminar `solicitudes_tab.dart` si ya no lo necesitas

## Soporte

Para problemas o dudas:
1. Verificar que el backend esté corriendo
2. Verificar que el token JWT sea válido
3. Revisar logs de consola para errores de red
4. Verificar que los endpoints respondan correctamente
