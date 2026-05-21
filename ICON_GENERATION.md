# Generación del Ícono de SmartAssist

Este documento explica cómo generar el ícono de la aplicación SmartAssist.

## Requisitos

```bash
pip install pillow
```

## Generar el Ícono

Ejecuta el script desde el directorio `mobile_repo`:

```bash
cd mobile_repo
python generate_icon.py
```

Esto generará:
- `app_icon_1024.png` - Ícono base en alta resolución
- Íconos para Android en `android/app/src/main/res/mipmap-*/`
- Íconos para iOS en `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

## Diseño del Ícono

El ícono de SmartAssist presenta:
- **Fondo circular** en color primario (#932D30)
- **Ícono de vehículo** estilizado en color de fondo (#F5F2EB)
- **Símbolo de herramienta** (llave inglesa) indicando asistencia
- **Ruedas** en color secundario (#52341A)

## Colores del Tema

- **Primario**: #932D30 (Rojo oscuro)
- **Secundario**: #52341A (Marrón)
- **Fondo**: #F5F2EB (Beige claro)

## Después de Generar

### Android
Los íconos se generan automáticamente en las carpetas correctas. No necesitas hacer nada más.

### iOS
Después de generar los íconos, es posible que necesites actualizar el archivo `Contents.json` en la carpeta `AppIcon.appiconset`.

## Personalización

Si deseas modificar el diseño del ícono, edita la función `create_app_icon()` en `generate_icon.py`.
