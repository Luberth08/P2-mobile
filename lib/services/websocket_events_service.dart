import 'dart:async';
import 'websocket_service.dart';

/// Evento de solicitud creada
class SolicitudCreadaEvent {
  final int solicitudId;
  final int idTaller;
  final int idDiagnostico;
  final double? distanciaKm;
  final String timestamp;

  SolicitudCreadaEvent({
    required this.solicitudId,
    required this.idTaller,
    required this.idDiagnostico,
    this.distanciaKm,
    required this.timestamp,
  });

  factory SolicitudCreadaEvent.fromJson(Map<String, dynamic> json) {
    return SolicitudCreadaEvent(
      solicitudId: json['solicitud_id'] as int,
      idTaller: json['id_taller'] as int,
      idDiagnostico: json['id_diagnostico'] as int,
      distanciaKm: json['distancia_km'] != null ? (json['distancia_km'] as num).toDouble() : null,
      timestamp: json['timestamp'] as String,
    );
  }
}

/// Evento de solicitud aceptada
class SolicitudAceptadaEvent {
  final int solicitudId;
  final int servicioId;
  final int idTaller;
  final String timestamp;

  SolicitudAceptadaEvent({
    required this.solicitudId,
    required this.servicioId,
    required this.idTaller,
    required this.timestamp,
  });

  factory SolicitudAceptadaEvent.fromJson(Map<String, dynamic> json) {
    return SolicitudAceptadaEvent(
      solicitudId: json['solicitud_id'] as int,
      servicioId: json['servicio_id'] as int,
      idTaller: json['id_taller'] as int,
      timestamp: json['timestamp'] as String,
    );
  }
}

/// Evento de solicitud rechazada
class SolicitudRechazadaEvent {
  final int solicitudId;
  final int idTaller;
  final String timestamp;

  SolicitudRechazadaEvent({
    required this.solicitudId,
    required this.idTaller,
    required this.timestamp,
  });

  factory SolicitudRechazadaEvent.fromJson(Map<String, dynamic> json) {
    return SolicitudRechazadaEvent(
      solicitudId: json['solicitud_id'] as int,
      idTaller: json['id_taller'] as int,
      timestamp: json['timestamp'] as String,
    );
  }
}

/// Evento de cambio de estado de servicio
class ServicioEstadoCambiadoEvent {
  final int servicioId;
  final String estadoAnterior;
  final String estadoNuevo;
  final String timestamp;

  ServicioEstadoCambiadoEvent({
    required this.servicioId,
    required this.estadoAnterior,
    required this.estadoNuevo,
    required this.timestamp,
  });

  factory ServicioEstadoCambiadoEvent.fromJson(Map<String, dynamic> json) {
    return ServicioEstadoCambiadoEvent(
      servicioId: json['servicio_id'] as int,
      estadoAnterior: json['estado_anterior'] as String,
      estadoNuevo: json['estado_nuevo'] as String,
      timestamp: json['timestamp'] as String,
    );
  }
}

/// Evento de actualización de ubicación de técnico
class TecnicoUbicacionActualizadaEvent {
  final int servicioId;
  final int empleadoId;
  final double latitud;
  final double longitud;
  final String timestamp;

  TecnicoUbicacionActualizadaEvent({
    required this.servicioId,
    required this.empleadoId,
    required this.latitud,
    required this.longitud,
    required this.timestamp,
  });

  factory TecnicoUbicacionActualizadaEvent.fromJson(Map<String, dynamic> json) {
    return TecnicoUbicacionActualizadaEvent(
      servicioId: json['servicio_id'] as int,
      empleadoId: json['empleado_id'] as int,
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      timestamp: json['timestamp'] as String,
    );
  }
}

/// Evento de servicio finalizado
class ServicioFinalizadoEvent {
  final int servicioId;
  final String timestamp;

  ServicioFinalizadoEvent({
    required this.servicioId,
    required this.timestamp,
  });

  factory ServicioFinalizadoEvent.fromJson(Map<String, dynamic> json) {
    return ServicioFinalizadoEvent(
      servicioId: json['servicio_id'] as int,
      timestamp: json['timestamp'] as String,
    );
  }
}

/// Servicio para gestionar eventos específicos del negocio vía WebSocket
class WebSocketEventsService {
  static final WebSocketEventsService _instance = WebSocketEventsService._internal();
  factory WebSocketEventsService() => _instance;
  WebSocketEventsService._internal() {
    _setupEventListeners();
  }

  final _wsService = WebSocketService();

  // Streams para eventos específicos
  final _solicitudCreadaController = StreamController<SolicitudCreadaEvent>.broadcast();
  final _solicitudAceptadaController = StreamController<SolicitudAceptadaEvent>.broadcast();
  final _solicitudRechazadaController = StreamController<SolicitudRechazadaEvent>.broadcast();
  final _servicioEstadoCambiadoController = StreamController<ServicioEstadoCambiadoEvent>.broadcast();
  final _tecnicoUbicacionActualizadaController = StreamController<TecnicoUbicacionActualizadaEvent>.broadcast();
  final _servicioFinalizadoController = StreamController<ServicioFinalizadoEvent>.broadcast();

  // Streams públicos
  Stream<SolicitudCreadaEvent> get solicitudCreada => _solicitudCreadaController.stream;
  Stream<SolicitudAceptadaEvent> get solicitudAceptada => _solicitudAceptadaController.stream;
  Stream<SolicitudRechazadaEvent> get solicitudRechazada => _solicitudRechazadaController.stream;
  Stream<ServicioEstadoCambiadoEvent> get servicioEstadoCambiado => _servicioEstadoCambiadoController.stream;
  Stream<TecnicoUbicacionActualizadaEvent> get tecnicoUbicacionActualizada => _tecnicoUbicacionActualizadaController.stream;
  Stream<ServicioFinalizadoEvent> get servicioFinalizado => _servicioFinalizadoController.stream;

  void _setupEventListeners() {
    // Escuchar todos los mensajes del WebSocket
    _wsService.messages.listen((message) {
      _handleMessage(message);
    });
  }

  void _handleMessage(Map<String, dynamic> message) {
    if (!message.containsKey('type')) {
      print('Mensaje WebSocket sin tipo: $message');
      return;
    }

    final type = message['type'] as String;
    final data = message['data'] as Map<String, dynamic>?;

    if (data == null) {
      print('Mensaje WebSocket sin data: $message');
      return;
    }

    switch (type) {
      case 'solicitud_creada':
        _handleSolicitudCreada(data);
        break;
      case 'solicitud_aceptada':
        _handleSolicitudAceptada(data);
        break;
      case 'solicitud_rechazada':
        _handleSolicitudRechazada(data);
        break;
      case 'servicio_estado_cambiado':
        _handleServicioEstadoCambiado(data);
        break;
      case 'tecnico_ubicacion_actualizada':
        _handleTecnicoUbicacionActualizada(data);
        break;
      case 'servicio_finalizado':
        _handleServicioFinalizado(data);
        break;
      case 'connected':
        print('WebSocket conectado: $data');
        break;
      case 'joined_service':
        print('Unido a sala de servicio: $data');
        break;
      case 'left_service':
        print('Salió de sala de servicio: $data');
        break;
      case 'pong':
        // Respuesta a ping, no hacer nada
        break;
      case 'error':
        print('Error WebSocket: $data');
        break;
      default:
        print('Tipo de evento WebSocket no manejado: $type');
    }
  }

  void _handleSolicitudCreada(Map<String, dynamic> data) {
    print('Solicitud creada: $data');
    try {
      final event = SolicitudCreadaEvent.fromJson(data);
      _solicitudCreadaController.add(event);
    } catch (e) {
      print('Error parsing SolicitudCreadaEvent: $e');
    }
  }

  void _handleSolicitudAceptada(Map<String, dynamic> data) {
    print('Solicitud aceptada: $data');
    try {
      final event = SolicitudAceptadaEvent.fromJson(data);
      _solicitudAceptadaController.add(event);
    } catch (e) {
      print('Error parsing SolicitudAceptadaEvent: $e');
    }
  }

  void _handleSolicitudRechazada(Map<String, dynamic> data) {
    print('Solicitud rechazada: $data');
    try {
      final event = SolicitudRechazadaEvent.fromJson(data);
      _solicitudRechazadaController.add(event);
    } catch (e) {
      print('Error parsing SolicitudRechazadaEvent: $e');
    }
  }

  void _handleServicioEstadoCambiado(Map<String, dynamic> data) {
    print('Estado de servicio cambiado: $data');
    try {
      final event = ServicioEstadoCambiadoEvent.fromJson(data);
      _servicioEstadoCambiadoController.add(event);
    } catch (e) {
      print('Error parsing ServicioEstadoCambiadoEvent: $e');
    }
  }

  void _handleTecnicoUbicacionActualizada(Map<String, dynamic> data) {
    print('Ubicación de técnico actualizada: $data');
    try {
      final event = TecnicoUbicacionActualizadaEvent.fromJson(data);
      _tecnicoUbicacionActualizadaController.add(event);
    } catch (e) {
      print('Error parsing TecnicoUbicacionActualizadaEvent: $e');
    }
  }

  void _handleServicioFinalizado(Map<String, dynamic> data) {
    print('Servicio finalizado: $data');
    try {
      final event = ServicioFinalizadoEvent.fromJson(data);
      _servicioFinalizadoController.add(event);
    } catch (e) {
      print('Error parsing ServicioFinalizadoEvent: $e');
    }
  }

  /// Obtiene un stream filtrado para un servicio específico (estado)
  Stream<ServicioEstadoCambiadoEvent> onServicioEstadoCambiado(int servicioId) {
    return servicioEstadoCambiado.where((event) => event.servicioId == servicioId);
  }

  /// Obtiene un stream filtrado para un servicio específico (ubicación)
  Stream<TecnicoUbicacionActualizadaEvent> onTecnicoUbicacionActualizada(int servicioId) {
    return tecnicoUbicacionActualizada.where((event) => event.servicioId == servicioId);
  }

  /// Limpia recursos
  void dispose() {
    _solicitudCreadaController.close();
    _solicitudAceptadaController.close();
    _solicitudRechazadaController.close();
    _servicioEstadoCambiadoController.close();
    _tecnicoUbicacionActualizadaController.close();
    _servicioFinalizadoController.close();
  }
}
