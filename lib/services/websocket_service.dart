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

  /// Conecta al servidor WebSocket
  Future<void> connect({int? servicioId}) async {
    if (_isConnected) {
      print('WebSocket ya está conectado');
      return;
    }

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
        },
        onDone: () {
          print('WebSocket cerrado');
          _isConnected = false;
          _connectionController.add(false);
          _channel = null;
        },
        cancelOnError: false,
      );

      _isConnected = true;
      _connectionController.add(true);
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
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _connectionController.add(false);
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
    disconnect();
    _messageController.close();
    _connectionController.close();
    _errorController.close();
  }
}
