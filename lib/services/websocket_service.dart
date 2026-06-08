import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';

/// Servicio para gestionar la conexión WebSocket
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  final _storage = const FlutterSecureStorage();
  
  // Streams para eventos
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // Streams públicos
  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  Stream<bool> get connectionState => _connectionController.stream;
  Stream<String> get errors => _errorController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Reconexión automática
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  final int _reconnectDelay = 3000; // ms
  Timer? _reconnectTimer;
  int? _lastServiceId;

  /// Conecta al servidor WebSocket
  Future<void> connect({int? servicioId}) async {
    if (_isConnected) {
      print('WebSocket ya está conectado');
      return;
    }

    // Guardar servicioId para reconexión
    _lastServiceId = servicioId;

    final token = await _storage.read(key: 'token');
    if (token == null) {
      print('No hay token disponible para conectar WebSocket');
      return;
    }

    try {
      // Construir URL de WebSocket
      final protocol = kApiBaseUrl.startsWith('https') ? 'wss' : 'ws';
      final uri = Uri.parse(kApiBaseUrl).replace(
        scheme: protocol,
        path: '/ws/connect',
      );

      // Agregar parámetros
      final queryParams = <String, String>{
        'token': token,
      };
      if (servicioId != null) {
        queryParams['servicio_id'] = servicioId.toString();
      }

      final wsUrl = uri.replace(queryParameters: queryParams);
      print('Conectando a WebSocket: $wsUrl');

      _channel = WebSocketChannel.connect(wsUrl);

      // Escuchar mensajes
      _channel!.stream.listen(
        (message) {
          try {
            final data = json.decode(message as String) as Map<String, dynamic>;
            print('Mensaje WebSocket recibido: $data');
            _messageController.add(data);
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('Error WebSocket: $error');
          _errorController.add(error.toString());
          _scheduleReconnect();
        },
        onDone: () {
          print('WebSocket cerrado');
          _isConnected = false;
          _connectionController.add(false);
          _channel = null;
          // Intentar reconectar automáticamente
          _scheduleReconnect();
        },
        cancelOnError: false,
      );

      _isConnected = true;
      _connectionController.add(true);
      _reconnectAttempts = 0; // Reset intentos al conectar exitosamente
      print('WebSocket conectado exitosamente');
    } catch (e) {
      print('Error creando WebSocket: $e');
      _errorController.add(e.toString());
      _isConnected = false;
      _connectionController.add(false);
    }
  }

  /// Desconecta del servidor WebSocket
  void disconnect() {
    print('Desconectando WebSocket...');
    
    // Cancelar timer de reconexión si existe
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _connectionController.add(false);
  }

  /// Programa una reconexión automática con exponential backoff
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('❌ Máximo de intentos de reconexión alcanzado ($_maxReconnectAttempts)');
      return;
    }

    _reconnectAttempts++;
    final delay = _reconnectDelay * _reconnectAttempts; // Exponential backoff

    print('🔄 Intentando reconectar en ${delay}ms (intentos: $_reconnectAttempts/$_maxReconnectAttempts)');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: delay), () {
      print('⏰ Ejecutando reconexión automática...');
      connect(servicioId: _lastServiceId);
    });
  }

  /// Envía un mensaje al servidor WebSocket
  void send(Map<String, dynamic> message) {
    if (_channel != null && _isConnected) {
      try {
        _channel!.sink.add(json.encode(message));
        print('Mensaje WebSocket enviado: $message');
      } catch (e) {
        print('Error enviando mensaje WebSocket: $e');
      }
    } else {
      print('WebSocket no está conectado, no se puede enviar mensaje');
    }
  }

  /// Se une a una sala de servicio específica
  void joinServiceRoom(int servicioId) {
    send({
      'type': 'join_service',
      'data': {
        'servicio_id': servicioId,
      },
    });
  }

  /// Sale de una sala de servicio específica
  void leaveServiceRoom(int servicioId) {
    send({
      'type': 'leave_service',
      'data': {
        'servicio_id': servicioId,
      },
    });
  }

  /// Envía ping para mantener conexión viva
  void ping() {
    send({
      'type': 'ping',
      'data': {
        'timestamp': DateTime.now().toIso8601String(),
      },
    });
  }

  /// Limpia recursos
  void dispose() {
    _reconnectTimer?.cancel();
    disconnect();
    _messageController.close();
    _connectionController.close();
    _errorController.close();
  }
}
