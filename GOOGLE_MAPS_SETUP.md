# Configuración de Google Maps

## ⚠️ IMPORTANTE: API Key Requerida

Para que el mapa funcione correctamente, necesitas obtener una API Key de Google Maps.

---

## Pasos para Obtener la API Key

### 1. Ir a Google Cloud Console
Visita: https://console.cloud.google.com/

### 2. Crear un Proyecto (si no tienes uno)
1. Haz clic en el selector de proyectos (arriba a la izquierda)
2. Clic en "Nuevo Proyecto"
3. Nombre: "SmartAssist" (o el que prefieras)
4. Clic en "Crear"

### 3. Habilitar la API de Google Maps
1. En el menú lateral, ve a: **APIs y servicios** → **Biblioteca**
2. Busca: **"Maps SDK for Android"**
3. Haz clic en el resultado
4. Clic en **"HABILITAR"**

### 4. Crear Credenciales (API Key)
1. Ve a: **APIs y servicios** → **Credenciales**
2. Clic en **"+ CREAR CREDENCIALES"**
3. Selecciona **"Clave de API"**
4. Se creará tu API Key
5. **COPIA LA CLAVE** (algo como: `AIzaSyAbc123...`)

### 5. Restringir la API Key (Recomendado)
1. En la lista de credenciales, haz clic en tu API Key
2. En "Restricciones de aplicación":
   - Selecciona **"Aplicaciones de Android"**
   - Clic en **"+ Agregar un elemento"**
3. Necesitas el **SHA-1** de tu app:

#### Obtener SHA-1 (Debug):
```bash
cd mobile_repo/android
./gradlew signingReport
```

O en Windows:
```bash
cd mobile_repo\android
gradlew.bat signingReport
```

Busca en la salida algo como:
```
Variant: debug
Config: debug
Store: C:\Users\TuUsuario\.android\debug.keystore
Alias: AndroidDebugKey
MD5: XX:XX:XX:...
SHA1: AA:BB:CC:DD:EE:FF:11:22:33:44:55:66:77:88:99:00:AA:BB:CC:DD
SHA-256: ...
```

4. Copia el **SHA-1** y pégalo en Google Cloud Console
5. Nombre del paquete: `com.example.mobile_repo` (o el que uses)
6. Clic en **"Listo"** y luego **"GUARDAR"**

---

## Configurar la API Key en la App

### Opción 1: Directamente en AndroidManifest.xml

Abre: `mobile_repo/android/app/src/main/AndroidManifest.xml`

Busca esta línea:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyDummyKeyForDevelopment"/>
```

Reemplaza `AIzaSyDummyKeyForDevelopment` con tu API Key real:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="TU_API_KEY_AQUI"/>
```

### Opción 2: Usando Variables de Entorno (Más Seguro)

1. Crea un archivo `local.properties` en `mobile_repo/android/`:
```properties
MAPS_API_KEY=TU_API_KEY_AQUI
```

2. Modifica `android/app/build.gradle`:
```gradle
def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

android {
    defaultConfig {
        // ...
        manifestPlaceholders = [MAPS_API_KEY: localProperties.getProperty('MAPS_API_KEY', 'AIzaSyDummyKeyForDevelopment')]
    }
}
```

3. Modifica `AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${MAPS_API_KEY}"/>
```

4. Agrega `local.properties` a `.gitignore`:
```
android/local.properties
```

---

## Instalar Dependencias

Ejecuta en la terminal:

```bash
cd mobile_repo
flutter pub get
```

---

## Recompilar la App

Después de configurar la API Key, **debes recompilar completamente**:

```bash
# Detén la app si está corriendo (Ctrl+C)

# Limpia el build anterior
flutter clean

# Recompila e instala
flutter run
```

⚠️ **IMPORTANTE**: Hot reload (`r`) NO funcionará para cambios en AndroidManifest.xml. Debes hacer un rebuild completo.

---

## Verificar que Funciona

1. Abre la app
2. Ve al tab "Diagnóstico"
3. Espera a que se obtenga la ubicación
4. Presiona el botón **"Ver Mapa"** o el ícono de mapa (🗺️)
5. Deberías ver un mapa de Google con un marcador rojo en tu ubicación

---

## Solución de Problemas

### Problema: Mapa aparece gris/en blanco

**Causas posibles**:
1. API Key no configurada o incorrecta
2. API de Maps no habilitada en Google Cloud
3. SHA-1 no configurado correctamente
4. No recompilaste la app después de cambiar AndroidManifest

**Solución**:
1. Verifica que la API Key esté correcta en AndroidManifest.xml
2. Verifica que "Maps SDK for Android" esté habilitada en Google Cloud
3. Verifica el SHA-1 en las restricciones de la API Key
4. Ejecuta `flutter clean` y luego `flutter run`

### Problema: Error "API key not found"

**Solución**:
1. Verifica que el `<meta-data>` esté dentro de `<application>` en AndroidManifest.xml
2. Recompila completamente la app

### Problema: Error "This API project is not authorized"

**Solución**:
1. Ve a Google Cloud Console
2. Verifica que "Maps SDK for Android" esté habilitada
3. Verifica las restricciones de la API Key
4. Asegúrate de que el SHA-1 y nombre del paquete sean correctos

---

## Costos de Google Maps

### Nivel Gratuito
Google Maps ofrece **$200 USD de crédito mensual gratis**, que incluye:
- **28,000 cargas de mapa estático** por mes
- **28,500 cargas de mapa dinámico** por mes

Para una app en desarrollo, esto es **más que suficiente**.

### Habilitar Facturación
Aunque hay nivel gratuito, Google requiere que habilites la facturación:
1. Ve a Google Cloud Console
2. Menú → **Facturación**
3. Vincula una tarjeta de crédito/débito
4. No te cobrarán si te mantienes dentro del nivel gratuito

⚠️ **Recomendación**: Configura alertas de presupuesto para evitar cargos inesperados.

---

## Alternativa: Usar OpenStreetMap (Sin API Key)

Si no quieres usar Google Maps, puedes usar OpenStreetMap con el paquete `flutter_map`:

### 1. Cambiar dependencia en pubspec.yaml:
```yaml
dependencies:
  # google_maps_flutter: ^2.5.0  # Comentar esta línea
  flutter_map: ^6.0.0
  latlong2: ^0.9.0
```

### 2. No requiere API Key
### 3. Gratuito y sin límites
### 4. Requiere cambios en el código

---

## Estado Actual

- ✅ Dependencia `google_maps_flutter` agregada
- ✅ AndroidManifest.xml configurado (con API Key dummy)
- ✅ Código del mapa implementado
- ⚠️ **PENDIENTE**: Configurar API Key real de Google Maps

---

## Próximos Pasos

1. **Obtén tu API Key** siguiendo los pasos de arriba
2. **Configura la API Key** en AndroidManifest.xml
3. **Recompila la app**: `flutter clean && flutter run`
4. **Prueba el mapa** presionando "Ver Mapa"

---

## Recursos Útiles

- [Google Maps Platform](https://console.cloud.google.com/google/maps-apis)
- [Documentación Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)
- [Obtener SHA-1](https://developers.google.com/android/guides/client-auth)
- [Precios de Google Maps](https://mapsplatform.google.com/pricing/)

---

**Nota**: Si tienes problemas, revisa los logs de la app con `flutter run -v` para ver mensajes de error detallados.
