// lib/config.dart
// API base URL configuration.
// Default: http://localhost:8000
// Can be overridden at build/run time:
//   flutter run --dart-define=API_URL=http://192.168.1.5:8000

const String kApiBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://backend-repo-2ncr.onrender.com/api/v1/',
);

// Helper note:
// - Android emulator (AVD) to host machine: use http://10.0.2.2:8000
// - iOS simulator: use http://localhost:8000
// - Physical device: use host machine LAN IP, e.g. http://192.168.1.5:8000
// - For production APK: use your deployed backend URL
