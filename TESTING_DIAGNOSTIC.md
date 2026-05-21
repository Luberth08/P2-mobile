# Guía de Pruebas - Sistema de Diagnóstico

## Pre-requisitos

### 1. Backend Funcionando
- Backend debe estar corriendo en Render o localmente
- Base de datos con tablas creadas (alembic migrations)
- API accesible desde el dispositivo móvil

### 2. Usuario Registrado
- Tener una cuenta creada
- Haber iniciado sesión en la app
- Tener al menos un vehículo registrado

### 3. Permisos del Dispositivo
- Ubicación (GPS) habilitado
- Permisos de cámara otorgados
- Permisos de almacenamiento otorgados

## Casos de Prueba

### Caso 1: Crear Solicitud de Diagnóstico Básica

**Objetivo**: Verificar que se puede crear una solicitud con datos mínimos.

**Pasos**:
1. Abrir la app y navegar al tab "Diagnóstico"
2. Verificar que aparezca el formulario de diagnóstico
3. Seleccionar un vehículo del dropdown
4. Esperar a que se obtenga la ubicación GPS (debe mostrar lat/lon)
5. Escribir en el campo descripción: "El motor hace ruido extraño"
6. Presionar "Generar Diagnóstico"

**Resultado Esperado**:
- La app navega a la pantalla de resultados
- Muestra estado "pendiente" o "procesando"
- Después de unos segundos, el estado cambia a "completada"
- Se muestran incidentes detectados por la IA

**Verificar**:
- ✅ Navegación exitosa
- ✅ Estado inicial correcto
- ✅ Polling funciona (actualiza cada 3 segundos)
- ✅ Diagnóstico aparece cuando está listo

---

### Caso 2: Crear Solicitud con Fotos

**Objetivo**: Verificar subida de múltiples fotos.

**Pasos**:
1. Navegar al tab "Diagnóstico"
2. Seleccionar vehículo
3. Escribir descripción: "Llanta desinflada y rayones en la puerta"
4. Presionar el botón "+" en la sección de fotos
5. Seleccionar "Galería" y elegir una foto
6. Repetir para agregar 2 fotos más (total 3)
7. Verificar que se muestren las 3 miniaturas
8. Presionar "Generar Diagnóstico"

**Resultado Esperado**:
- Las 3 fotos se suben correctamente
- El diagnóstico se procesa con las fotos
- Las fotos aparecen en la sección de evidencias

**Verificar**:
- ✅ Máximo 3 fotos permitidas
- ✅ Botón "+" desaparece después de 3 fotos
- ✅ Se pueden eliminar fotos antes de enviar
- ✅ Fotos se suben correctamente al backend

---

### Caso 3: Actualizar Ubicación GPS

**Objetivo**: Verificar que se puede actualizar la ubicación.

**Pasos**:
1. Navegar al tab "Diagnóstico"
2. Esperar a que se obtenga la ubicación inicial
3. Presionar el botón de "refresh" (🔄) en la sección de ubicación
4. Verificar que aparezca el indicador de carga
5. Esperar a que se actualice la ubicación

**Resultado Esperado**:
- La ubicación se actualiza
- Las coordenadas pueden cambiar si el dispositivo se movió
- El botón muestra feedback visual durante la carga

**Verificar**:
- ✅ Botón de refresh funciona
- ✅ Indicador de carga aparece
- ✅ Coordenadas se actualizan

---

### Caso 4: Validaciones del Formulario

**Objetivo**: Verificar que las validaciones funcionan correctamente.

**Pasos**:
1. Navegar al tab "Diagnóstico"
2. **Sin seleccionar vehículo**, presionar "Generar Diagnóstico"
   - Debe mostrar: "Selecciona un vehículo"
3. Seleccionar vehículo
4. Escribir solo "abc" en descripción (menos de 5 caracteres)
5. Presionar "Generar Diagnóstico"
   - Debe mostrar: "Describe el problema (mínimo 5 caracteres)"
6. Escribir descripción válida
7. Si la ubicación no está lista, presionar "Generar Diagnóstico"
   - Debe mostrar: "Esperando ubicación..."

**Resultado Esperado**:
- Todas las validaciones funcionan
- Mensajes de error claros
- No se permite enviar con datos inválidos

**Verificar**:
- ✅ Validación de vehículo
- ✅ Validación de descripción (mínimo 5 caracteres)
- ✅ Validación de ubicación

---

### Caso 5: Ver Historial de Solicitudes

**Objetivo**: Verificar que se muestra el historial correctamente.

**Pasos**:
1. Crear al menos 2 solicitudes de diagnóstico
2. Navegar al tab "Solicitudes"
3. Verificar que aparezcan las solicitudes creadas
4. Verificar que se muestren:
   - Estado (con color e icono)
   - Descripción (truncada si es larga)
   - Vehículo (matrícula, marca, modelo)
   - Fecha relativa (ej: "Hace 5m")
5. Tocar una solicitud

**Resultado Esperado**:
- Lista muestra todas las solicitudes del usuario
- Información clara y legible
- Al tocar, navega a la pantalla de resultados
- Pull-to-refresh actualiza la lista

**Verificar**:
- ✅ Lista se carga correctamente
- ✅ Información completa en cada card
- ✅ Navegación funciona
- ✅ Pull-to-refresh actualiza

---

### Caso 6: Asociar Tipo de Incidente

**Objetivo**: Verificar que se pueden asociar tipos de incidentes adicionales.

**Pasos**:
1. Crear una solicitud y esperar el diagnóstico
2. En la pantalla de resultados, presionar el botón "+" en la sección de incidentes
3. Seleccionar un tipo de incidente de la lista
4. Presionar "Aceptar"

**Resultado Esperado**:
- Aparece diálogo con lista de tipos de incidentes
- Al seleccionar, se asocia al diagnóstico
- Aparece mensaje: "Tipo de incidente asociado"
- El nuevo incidente aparece en la lista con icono de persona (👤)
- El incidente tiene confianza 100%

**Verificar**:
- ✅ Diálogo se abre correctamente
- ✅ Lista de tipos se carga
- ✅ Asociación exitosa
- ✅ Incidente aparece en la lista
- ✅ Icono correcto (persona vs IA)

---

### Caso 7: Descartar Incidente

**Objetivo**: Verificar que se pueden descartar incidentes sugeridos.

**Pasos**:
1. En la pantalla de resultados con diagnóstico
2. Presionar el botón "X" en un incidente
3. Confirmar en el diálogo "¿Descartar...?"
4. Presionar "Descartar"

**Resultado Esperado**:
- Aparece diálogo de confirmación
- Al confirmar, el incidente desaparece de la lista
- Aparece mensaje: "Incidente descartado"
- La lista se actualiza automáticamente

**Verificar**:
- ✅ Diálogo de confirmación aparece
- ✅ Incidente se elimina
- ✅ Mensaje de confirmación
- ✅ Lista se actualiza

---

### Caso 8: Botón "Solicitar Servicio"

**Objetivo**: Verificar que el botón muestra el mensaje "En Construcción".

**Pasos**:
1. En la pantalla de resultados con diagnóstico completado
2. Presionar el botón "Solicitar Servicio"

**Resultado Esperado**:
- Aparece diálogo con título "En Construcción"
- Mensaje: "La funcionalidad de solicitar servicio estará disponible próximamente."
- Botón "Aceptar" cierra el diálogo

**Verificar**:
- ✅ Diálogo aparece
- ✅ Mensaje correcto
- ✅ Botón cierra el diálogo

---

### Caso 9: Audio (Placeholder)

**Objetivo**: Verificar que el botón de audio muestra mensaje de desarrollo.

**Pasos**:
1. En el formulario de diagnóstico
2. Presionar el botón "Grabar Audio"

**Resultado Esperado**:
- Aparece SnackBar con mensaje: "Función de audio en desarrollo"

**Verificar**:
- ✅ SnackBar aparece
- ✅ Mensaje correcto

---

### Caso 10: Estados de Solicitud

**Objetivo**: Verificar que los diferentes estados se muestran correctamente.

**Estados a Verificar**:

| Estado | Color | Icono | Descripción |
|--------|-------|-------|-------------|
| pendiente | Naranja | ⏳ | Esperando procesamiento |
| procesando | Azul | 🔄 | IA analizando |
| completada | Verde | ✅ | Diagnóstico listo |
| cancelada | Rojo | ❌ | Solicitud cancelada |

**Pasos**:
1. Crear solicitud y observar estado inicial (pendiente/procesando)
2. Esperar a que cambie a "completada"
3. Verificar colores e iconos en ambas pantallas:
   - Pantalla de resultados
   - Lista de solicitudes

**Verificar**:
- ✅ Colores correctos para cada estado
- ✅ Iconos correctos para cada estado
- ✅ Texto en mayúsculas
- ✅ Consistencia entre pantallas

---

## Pruebas de Integración Backend

### Verificar Endpoints

#### 1. Crear Solicitud
```bash
curl -X POST "https://tu-backend.com/api/v1/diagnosticos/" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "descripcion=Motor hace ruido" \
  -F "ubicacion=-17.783333,-63.182222" \
  -F "matricula=ABC123" \
  -F "marca=Toyota" \
  -F "modelo=Corolla" \
  -F "anio=2020" \
  -F "color=Rojo" \
  -F "tipo_vehiculo=auto"
```

#### 2. Listar Solicitudes
```bash
curl -X GET "https://tu-backend.com/api/v1/diagnosticos/mis-solicitudes" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

#### 3. Obtener Solicitud
```bash
curl -X GET "https://tu-backend.com/api/v1/diagnosticos/1" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

#### 4. Tipos de Incidentes
```bash
curl -X GET "https://tu-backend.com/api/v1/diagnosticos/tipos-incidentes" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

#### 5. Asociar Tipo
```bash
curl -X POST "https://tu-backend.com/api/v1/diagnosticos/1/asociar-tipo" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "id_tipo_incidente=5"
```

#### 6. Descartar Incidente
```bash
curl -X DELETE "https://tu-backend.com/api/v1/diagnosticos/1/incidentes/10" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Problemas Comunes y Soluciones

### Problema: "Esperando ubicación..." no desaparece

**Causa**: Permisos de ubicación no otorgados o GPS deshabilitado

**Solución**:
1. Verificar que GPS esté habilitado en el dispositivo
2. Ir a Configuración → Apps → SmartAssist → Permisos
3. Otorgar permisos de ubicación "Permitir siempre" o "Solo mientras se usa"
4. Reiniciar la app

---

### Problema: No se pueden subir fotos

**Causa**: Permisos de cámara/almacenamiento no otorgados

**Solución**:
1. Ir a Configuración → Apps → SmartAssist → Permisos
2. Otorgar permisos de cámara y almacenamiento
3. Reiniciar la app

---

### Problema: "Error: Exception: createDiagnostic failed: 401"

**Causa**: Token de autenticación expirado o inválido

**Solución**:
1. Cerrar sesión
2. Volver a iniciar sesión
3. Intentar crear diagnóstico nuevamente

---

### Problema: Diagnóstico se queda en "procesando" indefinidamente

**Causa**: Error en el procesamiento de IA en el backend

**Solución**:
1. Verificar logs del backend en Render
2. Verificar que Groq API esté funcionando
3. Verificar que haya tipos de incidentes en la base de datos
4. Intentar con el botón "Reintentar" (si está implementado)

---

### Problema: Lista de solicitudes vacía

**Causa**: No hay solicitudes creadas o error de autenticación

**Solución**:
1. Crear al menos una solicitud
2. Pull-to-refresh en la lista
3. Verificar que el token sea válido
4. Verificar logs del backend

---

## Checklist de Pruebas Completas

- [ ] Crear solicitud con datos mínimos
- [ ] Crear solicitud con 1 foto
- [ ] Crear solicitud con 3 fotos
- [ ] Actualizar ubicación GPS
- [ ] Validación de vehículo requerido
- [ ] Validación de descripción mínima
- [ ] Ver historial de solicitudes
- [ ] Pull-to-refresh en historial
- [ ] Navegar a detalle desde historial
- [ ] Polling de diagnóstico funciona
- [ ] Asociar tipo de incidente
- [ ] Descartar incidente
- [ ] Botón "Solicitar Servicio" muestra diálogo
- [ ] Botón "Grabar Audio" muestra mensaje
- [ ] Estados se muestran correctamente
- [ ] Colores e iconos correctos
- [ ] Navegación entre tabs funciona
- [ ] Logout funciona correctamente

---

## Métricas de Éxito

### Performance
- ✅ Carga de lista de solicitudes: < 2 segundos
- ✅ Subida de diagnóstico con 3 fotos: < 10 segundos
- ✅ Obtención de ubicación GPS: < 5 segundos
- ✅ Polling no causa lag en la UI

### Usabilidad
- ✅ Formulario intuitivo y fácil de usar
- ✅ Mensajes de error claros
- ✅ Feedback visual en todas las acciones
- ✅ Navegación fluida entre pantallas

### Funcionalidad
- ✅ Todas las validaciones funcionan
- ✅ Datos se guardan correctamente
- ✅ Sincronización con backend exitosa
- ✅ Estados se actualizan en tiempo real

---

## Próximos Pasos

1. **Implementar grabación de audio**
   - Agregar dependencia `flutter_sound`
   - Implementar UI de grabación
   - Subir audio al backend

2. **Implementar "Solicitar Servicio"**
   - Conectar con sistema de talleres
   - Crear flujo de solicitud de servicio
   - Notificaciones de estado

3. **Mejoras de UX**
   - Caché de ubicación
   - Compresión de imágenes
   - Indicador de progreso de subida
   - Notificaciones push

4. **Testing Automatizado**
   - Unit tests para servicios API
   - Widget tests para pantallas
   - Integration tests para flujo completo
