# Flujo del Sistema de Diagnóstico

## Descripción General
El sistema de diagnóstico permite a los usuarios solicitar un análisis de problemas vehiculares mediante IA, proporcionando descripción, ubicación, fotos y audio.

## Componentes Implementados

### Frontend (Flutter)

#### 1. CreateDiagnosticScreen
**Ubicación**: `lib/screens/create_diagnostic_screen.dart`

**Funcionalidad**:
- Selector de vehículo (dropdown con vehículos registrados)
- Captura de ubicación GPS con opción de actualizar
- Campo de descripción del problema (mínimo 5 caracteres)
- Subida de hasta 3 fotos (cámara o galería)
- Sección de audio (placeholder - en desarrollo)
- Botón "Generar Diagnóstico"

**Validaciones**:
- Vehículo seleccionado requerido
- Ubicación GPS requerida
- Descripción mínima de 5 caracteres
- Máximo 3 fotos

**Flujo**:
1. Usuario selecciona vehículo
2. Sistema obtiene ubicación GPS automáticamente
3. Usuario describe el problema
4. Usuario agrega fotos (opcional)
5. Al presionar "Generar Diagnóstico", navega a DiagnosticResultScreen

#### 2. DiagnosticResultScreen
**Ubicación**: `lib/screens/diagnostic_result_screen.dart`

**Funcionalidad**:
- Muestra estado de la solicitud (pendiente, procesando, completada, cancelada)
- Polling cada 3 segundos hasta que el diagnóstico esté listo
- Muestra nivel de confianza del diagnóstico
- Lista de incidentes detectados por IA
- Botón para asociar tipos de incidentes adicionales
- Botón para descartar incidentes sugeridos
- Botón "Solicitar Servicio" (muestra diálogo "En Construcción")

**Estados de Solicitud**:
- **Pendiente**: Esperando procesamiento
- **Procesando**: IA analizando datos
- **Completada**: Diagnóstico listo
- **Cancelada**: Solicitud cancelada por usuario

#### 3. SolicitudesTab
**Ubicación**: `lib/screens/solicitudes_tab.dart`

**Funcionalidad**:
- Lista todas las solicitudes de diagnóstico del usuario
- Muestra estado, descripción, fecha y vehículo
- Indica si el diagnóstico está disponible
- Pull-to-refresh para actualizar lista
- Al tocar una solicitud, navega a DiagnosticResultScreen

**Formato de Fecha**:
- Menos de 1 hora: "Hace Xm"
- Menos de 1 día: "Hace Xh"
- Menos de 7 días: "Hace Xd"
- Más de 7 días: "DD/MM/YYYY"

#### 4. HomeScreen (Actualizado)
**Ubicación**: `lib/screens/home_screen.dart`

**Tabs**:
1. **Mi Perfil**: Gestión de perfil y vehículos
2. **Diagnóstico**: CreateDiagnosticScreen
3. **Solicitudes**: SolicitudesTab

### Backend (FastAPI)

#### Endpoints Implementados

##### POST /api/v1/diagnosticos/
Crea una nueva solicitud de diagnóstico.

**Parámetros**:
- `descripcion` (Form, requerido): Descripción del problema
- `ubicacion` (Form, requerido): Coordenadas "lat,lon"
- `matricula` (Form, opcional): Matrícula del vehículo
- `marca`, `modelo`, `anio`, `color`, `tipo_vehiculo` (Form, opcionales)
- `foto1`, `foto2`, `foto3` (File, opcionales): Hasta 3 fotos
- `audio` (File, opcional): Audio del problema

**Respuesta**: `SolicitudDiagnosticoResponse` (201)

##### GET /api/v1/diagnosticos/mis-solicitudes
Lista todas las solicitudes del usuario autenticado.

**Respuesta**: `List[SolicitudDiagnosticoResponse]` (200)

##### GET /api/v1/diagnosticos/{solicitud_id}
Obtiene una solicitud específica.

**Respuesta**: `SolicitudDiagnosticoResponse` (200)

##### POST /api/v1/diagnosticos/{solicitud_id}/asociar-tipo
Asocia un tipo de incidente existente al diagnóstico.

**Parámetros**:
- `id_tipo_incidente` (Form, requerido): ID del tipo de incidente

**Respuesta**: `{"message": "Tipo de incidente asociado correctamente"}` (201)

##### DELETE /api/v1/diagnosticos/{solicitud_id}/incidentes/{incidente_id}
Descarta un incidente del diagnóstico.

**Respuesta**: 204 No Content

##### GET /api/v1/diagnosticos/tipos-incidentes
Lista todos los tipos de incidentes disponibles (público).

**Respuesta**: `List[{"id": int, "concepto": str, "prioridad": int}]` (200)

##### POST /api/v1/diagnosticos/{solicitud_id}/cancel
Cancela una solicitud en estado pendiente.

**Respuesta**: 204 No Content

##### POST /api/v1/diagnosticos/{solicitud_id}/reintentar
Reintenta el procesamiento de una solicitud.

**Respuesta**: Resultado del procesamiento (200)

### Servicios API (Flutter)

#### DiagnosticApi
**Ubicación**: `lib/services/diagnostic_api.dart`

**Métodos**:
- `createDiagnostic()`: Crea solicitud con multipart/form-data
- `getMySolicitudes()`: Obtiene lista de solicitudes
- `getSolicitud()`: Obtiene solicitud específica
- `getTiposIncidentes()`: Lista tipos de incidentes
- `asociarTipoIncidente()`: Asocia tipo de incidente
- `descartarIncidente()`: Descarta incidente
- `cancelarSolicitud()`: Cancela solicitud
- `reintentarProcesamiento()`: Reintenta procesamiento

## Flujo Completo del Usuario

### 1. Crear Solicitud de Diagnóstico
```
Usuario → Tab "Diagnóstico" → CreateDiagnosticScreen
  ↓
Selecciona vehículo
  ↓
Sistema obtiene ubicación GPS
  ↓
Usuario describe problema
  ↓
Usuario agrega fotos (opcional)
  ↓
Presiona "Generar Diagnóstico"
  ↓
POST /api/v1/diagnosticos/
  ↓
Navega a DiagnosticResultScreen
```

### 2. Ver Resultado del Diagnóstico
```
DiagnosticResultScreen
  ↓
Polling cada 3 segundos: GET /api/v1/diagnosticos/{id}
  ↓
Estado "pendiente" o "procesando" → Muestra "Procesando..."
  ↓
Estado "completada" → Muestra diagnóstico e incidentes
  ↓
Usuario puede:
  - Asociar tipos de incidentes adicionales
  - Descartar incidentes sugeridos
  - Solicitar servicio (en construcción)
```

### 3. Ver Historial de Solicitudes
```
Usuario → Tab "Solicitudes" → SolicitudesTab
  ↓
GET /api/v1/diagnosticos/mis-solicitudes
  ↓
Muestra lista de solicitudes
  ↓
Usuario toca una solicitud
  ↓
Navega a DiagnosticResultScreen
```

## Permisos Requeridos (Android)

### AndroidManifest.xml
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

## Dependencias Flutter

### pubspec.yaml
```yaml
dependencies:
  geolocator: ^10.1.0
  image_picker: ^1.0.4
  http: ^1.1.0
```

## Próximas Funcionalidades

### En Desarrollo
- **Grabación de audio**: Implementar funcionalidad de grabación de audio
- **Solicitar servicio**: Conectar con sistema de talleres y servicios

### Mejoras Futuras
- Caché de ubicación para uso offline
- Compresión de imágenes antes de subir
- Indicador de progreso de subida
- Notificaciones push cuando el diagnóstico esté listo
- Filtros y búsqueda en historial de solicitudes
- Exportar diagnóstico como PDF

## Notas Técnicas

### Formato de Ubicación
- Backend espera: `"lat,lon"` (ej: "-17.783333,-63.182222")
- Flutter Geolocator proporciona: `Position` con `latitude` y `longitude`
- Conversión: `'${position.latitude},${position.longitude}'`

### Manejo de Imágenes
- Máximo 3 fotos por solicitud
- Compresión automática: maxWidth=1920, maxHeight=1920, quality=85
- Formatos soportados: JPEG, PNG

### Polling del Diagnóstico
- Intervalo: 3 segundos
- Se detiene cuando: `diagnostico != null`
- Evita sobrecarga del servidor

### Estados de Incidente
- **sugerido_por**: "ia" o "conductor"
- **nivel_confianza**: 0.0 a 1.0 (0% a 100%)
- Incidentes sugeridos por conductor tienen confianza 1.0

## Testing

### Probar el Flujo Completo
1. Registrar un vehículo en "Mi Perfil"
2. Ir a tab "Diagnóstico"
3. Seleccionar vehículo
4. Verificar que se obtenga ubicación GPS
5. Escribir descripción del problema
6. Agregar 1-3 fotos
7. Presionar "Generar Diagnóstico"
8. Verificar que aparezca pantalla de resultado
9. Esperar a que el diagnóstico se procese
10. Verificar incidentes detectados
11. Probar asociar/descartar incidentes
12. Volver a tab "Solicitudes"
13. Verificar que aparezca la solicitud creada
