# Documentación: Solicitud de Servicio - Flutter

## Descripción General

Implementación completa del sistema de solicitud de servicio en Flutter, permitiendo al usuario:
1. Generar solicitudes automáticas a talleres sugeridos por el sistema
2. Ver talleres sugeridos vs otros talleres cercanos
3. Enviar solicitudes manuales a cualquier taller
4. Agregar comentarios opcionales a las solicitudes

## Archivos Creados

### 1. `lib/services/service_request_api.dart`
Servicio API con 5 métodos:
- `generarSolicitudesAutomaticas()` - Genera solicitudes automáticas
- `listarTalleresSugeridos()` - Lista talleres sugeridos y otros
- `solicitarServicioTaller()` - Envía solicitud manual
- `listarSolicitudesServicio()` - Lista solicitudes enviadas
- `cancelarSolicitudServicio()` - Cancela una solicitud

### 2. `lib/screens/service_request_screen.dart`
Pantalla principal con:
- Botón para generar solicitudes automáticas
- Sección de "Talleres Sugeridos" (con solicitud enviada)
- Sección de "Otros Talleres Cercanos" (sin solicitud)
- Diálogo para agregar comentario al enviar solicitud manual
- Indicadores de estado (enviado, cargando, etc.)

### 3. Actualización en `diagnostic_result_screen.dart`
- Botón "Solicitar Servicio" ahora navega a `ServiceRequestScreen`
- Import del nuevo screen

## Flujo de Usuario

### 1. Desde Resultado del Diagnóstico
```
DiagnosticResultScreen
    ↓ (presiona "Solicitar Servicio")
ServiceRequestScreen
```

### 2. En ServiceRequestScreen

#### Opción A: Generar Solicitudes Automáticas
1. Usuario ve botón grande "Generar Solicitudes Automáticas"
2. Presiona el botón
3. Sistema:
   - Identifica especialidades requeridas
   - Busca talleres cercanos con técnicos especializados
   - Crea solicitudes automáticas
4. Muestra resultado: "Se enviaron X solicitudes a talleres sugeridos"
5. Talleres aparecen en sección "Talleres Sugeridos" con badge "Enviado"

#### Opción B: Solicitud Manual
1. Usuario ve talleres en sección "Otros Talleres Cercanos"
2. Presiona "Enviar Solicitud" en un taller específico
3. Aparece diálogo con:
   - Información del taller
   - Campo de comentario opcional
4. Confirma y envía
5. Taller se mueve a "Talleres Sugeridos"

## Componentes de UI

### Card de Taller
Muestra:
- ✅ Nombre del taller
- 📍 Distancia en kilómetros
- ⭐ Puntuación (puntos)
- 📞 Teléfono
- 📧 Email
- 🔧 Especialidades disponibles (chips)
- ✓ Badge "Enviado" (si tiene solicitud)
- 📤 Botón "Enviar Solicitud" (si no tiene solicitud)

### Secciones

#### Talleres Sugeridos
- Color: Verde
- Icono: `recommend`
- Muestra talleres con solicitud enviada
- Badge verde "Enviado"

#### Otros Talleres Cercanos
- Color: Rojo (#932D30)
- Icono: `location_on`
- Muestra talleres sin solicitud
- Botón para enviar solicitud

### Botón de Generación Automática
- Aparece solo si no hay talleres sugeridos
- Color: Rojo (#932D30)
- Icono: `auto_awesome`
- Texto explicativo
- Estado de carga mientras genera

## Estados de la Pantalla

### 1. Cargando
```dart
Center(child: CircularProgressIndicator())
```

### 2. Error
- Icono de error
- Mensaje de error
- Botón "Reintentar"

### 3. Sin Talleres
- Icono `search_off`
- Mensaje: "No se encontraron talleres cercanos..."
- Botón "Actualizar"

### 4. Con Talleres
- Botón de generación automática (si aplica)
- Lista de talleres sugeridos
- Lista de otros talleres

## Diálogo de Solicitud Manual

```dart
AlertDialog(
  title: 'Solicitar servicio a [Nombre Taller]',
  content: Column(
    - Distancia
    - Especialidades
    - TextField para comentario (opcional, max 500 chars)
  ),
  actions: [
    'Cancelar',
    'Enviar Solicitud'
  ]
)
```

## Manejo de Estados

### Variables de Estado
```dart
List<Map<String, dynamic>> _talleres = [];
bool _loading = true;
bool _generando = false;  // Generando solicitudes automáticas
bool _enviando = false;   // Enviando solicitud manual
String? _errorMessage;
Map<String, dynamic>? _resultadoGeneracion;
```

### Prevención de Múltiples Clicks
- `_generando`: Deshabilita botón de generación automática
- `_enviando`: Deshabilita botones de envío manual

## Colores del Tema

```dart
Color(0xFFF5F2EB)  // Fondo
Color(0xFF932D30)  // Primario (rojo)
Color(0xFF2C2C2C)  // Texto oscuro
Color(0xFF52341A)  // Texto secundario
Colors.green       // Éxito/Sugeridos
```

## Ejemplo de Respuesta del Backend

### Talleres Sugeridos
```json
[
  {
    "taller": {
      "id": 1,
      "nombre": "Taller Mecánico ABC",
      "telefono": "12345678",
      "email": "abc@taller.com",
      "puntos": 4.5
    },
    "distancia_km": 2.5,
    "tiene_solicitud": true,
    "solicitud_id": 10,
    "especialidades_disponibles": ["Mecánica General", "Frenos"]
  }
]
```

### Resultado de Generación
```json
{
  "solicitudes_creadas": 3,
  "talleres_sugeridos": [
    {
      "id": 1,
      "nombre": "Taller ABC",
      "distancia_km": 2.5,
      "especialidades": ["Mecánica General"]
    }
  ],
  "especialidades_requeridas": ["Mecánica General", "Frenos"]
}
```

## Mejoras Futuras (Opcionales)

1. **Filtros**:
   - Por distancia
   - Por puntuación
   - Por especialidad

2. **Ordenamiento**:
   - Más cercanos primero
   - Mejor puntuados primero

3. **Mapa**:
   - Mostrar talleres en mapa
   - Ver ubicación del usuario

4. **Notificaciones**:
   - Cuando un taller acepta/rechaza
   - Cuando se recibe costo estimado

5. **Historial**:
   - Ver solicitudes anteriores
   - Estado de cada solicitud

## Testing

### Casos de Prueba

1. **Generar solicitudes automáticas**:
   - Con talleres disponibles
   - Sin talleres disponibles
   - Con error de red

2. **Enviar solicitud manual**:
   - Con comentario
   - Sin comentario
   - Cancelar diálogo

3. **Navegación**:
   - Desde resultado de diagnóstico
   - Volver atrás

4. **Estados**:
   - Cargando
   - Error
   - Sin talleres
   - Con talleres

## Notas Importantes

1. **Recarga Automática**: Después de generar solicitudes o enviar manual, se recargan los talleres automáticamente

2. **Validación**: El backend valida que no se envíen solicitudes duplicadas al mismo taller

3. **Comentario Opcional**: El campo de comentario es opcional y tiene límite de 500 caracteres

4. **Distancia**: Se muestra en kilómetros con 2 decimales

5. **Especialidades**: Se muestran como chips de colores para mejor visualización

## Integración con el Backend

Todos los endpoints están en `/api/v1/servicios/`:
- `POST /{diagnostico_id}/generar-solicitudes`
- `GET /{diagnostico_id}/talleres-sugeridos`
- `POST /{diagnostico_id}/solicitar-taller`
- `GET /{diagnostico_id}/solicitudes`
- `DELETE /{solicitud_id}`

Todos requieren autenticación con Bearer token.
