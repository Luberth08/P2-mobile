# mobile_repo

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
# MOBILE-repo

## Configurar backend (API)

La URL base del backend se define en `lib/config.dart`. Por defecto está en `http://localhost:8000`.

Puedes sobrescribirla al ejecutar la app (útil para emuladores o dispositivos físicos):

```
flutter run --dart-define=API_URL=http://192.168.1.5:8000
```

Notas:
- Android emulator (AVD): usar `http://10.0.2.2:8000`.
- iOS simulator: usar `http://localhost:8000`.
- Dispositivo físico: usar la IP del equipo en la misma red, p. ej. `http://192.168.1.5:8000`.
- Alternativa: exponer tu backend con `ngrok` y usar la URL pública de ngrok.
