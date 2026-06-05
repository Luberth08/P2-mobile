import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'session.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static const String baseUrl = 'https://backend-repo-2ncr.onrender.com/api/v1';
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Inicializa Firebase y configura las notificaciones
  static Future<void> initialize() async {
    try {
      print('🔥 Inicializando Firebase...');
      
      // Inicializar Firebase
      await Firebase.initializeApp();
      print('✅ Firebase inicializado correctamente');

      // Inicializar notificaciones locales
      await _initializeLocalNotifications();

      // Solicitar permisos de notificación
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('📱 Permisos de notificación: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Obtener token FCM
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          print('🎯 Token FCM obtenido: ${token.substring(0, 50)}...');
          await _registerTokenWithBackend(token);
        } else {
          print('❌ No se pudo obtener token FCM');
        }

        // Configurar listeners
        _setupMessageHandlers();

        // Listener para cuando se actualiza el token
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          print('🔄 Token FCM actualizado: ${newToken.substring(0, 50)}...');
          _registerTokenWithBackend(newToken);
        });
      } else {
        print('❌ Permisos de notificación denegados: ${settings.authorizationStatus}');
      }
    } catch (e) {
      print('💥 Error inicializando Firebase: $e');
    }
  }

  /// Inicializa las notificaciones locales
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
    );

    print('✅ Notificaciones locales inicializadas');
  }

  /// Registra el token FCM en el backend
  static Future<void> _registerTokenWithBackend(String token) async {
    try {
      print('📤 Registrando token FCM en backend...');
      
      final sessionToken = await Session.getToken();
      if (sessionToken == null) {
        print('❌ No hay sesión activa, no se puede registrar token FCM');
        return;
      }

      print('🔑 Sesión encontrada, enviando request...');

      final response = await http.post(
        Uri.parse('$baseUrl/notifications/register-token'),
        headers: {
          'Authorization': 'Bearer $sessionToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'token_fcm': token}),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Token FCM registrado: ${data['message']}');
      } else {
        print('❌ Error registrando token FCM: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('💥 Error registrando token FCM: $e');
    }
  }

  /// Desregistra el token FCM del backend (al cerrar sesión)
  static Future<void> unregisterToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      final sessionToken = await Session.getToken();
      
      if (token == null || sessionToken == null) return;

      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/unregister-token'),
        headers: {
          'Authorization': 'Bearer $sessionToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'token_fcm': token}),
      );

      if (response.statusCode == 200) {
        print('Token FCM desregistrado exitosamente');
      }
    } catch (e) {
      print('Error desregistrando token FCM: $e');
    }
  }

  /// Configura los manejadores de mensajes
  static void _setupMessageHandlers() {
    // Mensaje recibido cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Mensaje recibido en primer plano: ${message.notification?.title}');
      _handleMessage(message);
    });

    // Mensaje tocado cuando la app está en segundo plano
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Mensaje tocado desde segundo plano: ${message.notification?.title}');
      _handleMessageTap(message);
    });

    // Verificar si la app se abrió desde una notificación
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('App abierta desde notificación: ${message.notification?.title}');
        _handleMessageTap(message);
      }
    });
  }

  /// Maneja mensajes recibidos en primer plano
  static void _handleMessage(RemoteMessage message) {
    if (message.notification != null) {
      final title = message.notification!.title ?? 'Nueva notificación';
      final body = message.notification!.body ?? '';
      
      print('📬 Mensaje en primer plano: $title - $body');
      
      // Mostrar notificación local
      _showLocalNotification(
        title,
        body,
        message.data,
      );
    }
  }

  /// Muestra una notificación local
  static Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic>? data,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'asistencia_vehicular_channel',
      'Asistencia Vehicular',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    final payload = data != null ? jsonEncode(data) : null;

    await _localNotifications.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  /// Maneja cuando el usuario toca una notificación
  static void _handleMessageTap(RemoteMessage message) {
    final data = message.data;
    final tipo = data['tipo'];
    final accion = data['accion'];

    print('Notificación tocada - Tipo: $tipo, Acción: $accion');

    // Navegar según el tipo de notificación
    switch (accion) {
      case 'abrir_solicitud_detalle':
        final solicitudId = data['solicitud_id'];
        if (solicitudId != null) {
          _navigateToServiceDetail(solicitudId);
        }
        break;
      case 'abrir_valoracion':
        final servicioId = data['servicio_id'];
        if (servicioId != null) {
          _navigateToRating(servicioId);
        }
        break;
      default:
        _navigateToHome();
    }
  }

  /// Maneja cuando el usuario toca una notificación local
  static void _handleNotificationTap(String? payload) {
    if (payload == null) {
      _navigateToHome();
      return;
    }

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final tipo = data['tipo'];
      final accion = data['accion'];

      print('Notificación local tocada - Tipo: $tipo, Acción: $accion');

      switch (accion) {
        case 'abrir_solicitud_detalle':
          final solicitudId = data['solicitud_id'];
          if (solicitudId != null) {
            _navigateToServiceDetail(solicitudId);
          }
          break;
        case 'abrir_valoracion':
          final servicioId = data['servicio_id'];
          if (servicioId != null) {
            _navigateToRating(servicioId);
          }
          break;
        default:
          _navigateToHome();
      }
    } catch (e) {
      print('Error parsing notification payload: $e');
      _navigateToHome();
    }
  }

  /// Navega al detalle del servicio
  static void _navigateToServiceDetail(String servicioId) {
    print('🧭 Navegando al servicio: $servicioId');
    navigatorKey.currentState?.pushNamed('/home');
  }

  /// Navega a la pantalla de valoración
  static void _navigateToRating(String servicioId) {
    print('🧭 Navegando a valoración del servicio: $servicioId');
    navigatorKey.currentState?.pushNamed('/home');
  }

  /// Navega a la pantalla principal
  static void _navigateToHome() {
    print('🧭 Navegando al home');
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/home',
      (route) => false,
    );
  }

  /// Envía una notificación de prueba
  static Future<void> sendTestNotification() async {
    try {
      final sessionToken = await Session.getToken();
      if (sessionToken == null) {
        print('No hay sesión activa');
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/notifications/test-notification'),
        headers: {
          'Authorization': 'Bearer $sessionToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Notificación de prueba enviada: ${data['message']}');
      } else {
        print('Error enviando notificación de prueba: ${response.statusCode}');
      }
    } catch (e) {
      print('Error enviando notificación de prueba: $e');
    }
  }

  /// Muestra una notificación local personalizada
  static void showLocalNotification(String title, String body) {
    // Implementar notificación local si es necesario
    print('Notificación local: $title - $body');
  }
}

/// Manejador de mensajes en segundo plano (debe ser función top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  
  print('📬 Mensaje en segundo plano: ${message.notification?.title}');
  
  // Inicializar notificaciones locales
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  await localNotifications.initialize(initializationSettings);

  // Mostrar notificación local
  if (message.notification != null) {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'asistencia_vehicular_channel',
      'Asistencia Vehicular',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    final title = message.notification!.title ?? 'Nueva notificación';
    final body = message.notification!.body ?? '';
    final payload = jsonEncode(message.data);

    await localNotifications.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }
}