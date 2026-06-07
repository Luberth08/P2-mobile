// Modelos para Cotizaciones
import 'dart:io';
import 'package:image_picker/image_picker.dart';

// Función auxiliar para convertir dinámicamente a double
double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

class QuoteItem {
  final int id;
  final String titulo;
  final double precio;

  QuoteItem({
    required this.id,
    required this.titulo,
    required this.precio,
  });

  factory QuoteItem.fromJson(Map<String, dynamic> json) {
    return QuoteItem(
      id: json['id'],
      titulo: json['titulo'],
      precio: _toDouble(json['precio']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'precio': precio,
    };
  }
}

class QuoteResponse {
  final int id;
  final DateTime fechaCreacion;
  final DateTime? fechaRespuesta;
  final String estado;
  final double? total;
  final int idQuoteRequest;
  final int idTaller;
  final List<QuoteItem> items;

  QuoteResponse({
    required this.id,
    required this.fechaCreacion,
    this.fechaRespuesta,
    required this.estado,
    this.total,
    required this.idQuoteRequest,
    required this.idTaller,
    required this.items,
  });

  factory QuoteResponse.fromJson(Map<String, dynamic> json) {
    return QuoteResponse(
      id: json['id'],
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      fechaRespuesta: json['fecha_respuesta'] != null
          ? DateTime.parse(json['fecha_respuesta'])
          : null,
      estado: json['estado'],
      total: json['total'] != null ? _toDouble(json['total']) : null,
      idQuoteRequest: json['id_quote_request'],
      idTaller: json['id_taller'],
      items: (json['items'] as List)
          .map((i) => QuoteItem.fromJson(i))
          .toList(),
    );
  }

  String get estadoTexto {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'respondida':
        return 'Respondida';
      case 'rechazada':
        return 'Rechazada';
      case 'expirada':
        return 'Expirada';
      default:
        return estado;
    }
  }

  String get estadoColor {
    switch (estado) {
      case 'pendiente':
        return '#F59E0B'; // Amarillo
      case 'respondida':
        return '#10B981'; // Verde
      case 'rechazada':
        return '#EF4444'; // Rojo
      case 'expirada':
        return '#6B7280'; // Gris
      default:
        return '#6B7280';
    }
  }
}

class VehiculoInfo {
  final int id;
  final String placa;
  final String marca;
  final String modelo;

  VehiculoInfo({
    required this.id,
    required this.placa,
    required this.marca,
    required this.modelo,
  });

  factory VehiculoInfo.fromJson(Map<String, dynamic> json) {
    return VehiculoInfo(
      id: json['id'],
      placa: json['placa'],
      marca: json['marca'],
      modelo: json['modelo'],
    );
  }
}

class ServicioInfo {
  final int id;
  final String nombre;
  final String? descripcion;

  ServicioInfo({
    required this.id,
    required this.nombre,
    this.descripcion,
  });

  factory ServicioInfo.fromJson(Map<String, dynamic> json) {
    return ServicioInfo(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
    );
  }
}

class QuoteRequest {
  final int id;
  final String? ubicacion;
  final DateTime fechaCreacion;
  final DateTime? fechaExpiracion;
  final String? comentario;
  final String estado;
  final DateTime? fechaAceptada;
  final int idVehiculo;
  final int idServicio;
  final int idCliente;
  final VehiculoInfo? vehiculo;
  final ServicioInfo? servicio;
  final List<QuoteResponse> responses;
  final List<String>? fotos;  // URLs de las fotos

  QuoteRequest({
    required this.id,
    this.ubicacion,
    required this.fechaCreacion,
    this.fechaExpiracion,
    this.comentario,
    required this.estado,
    this.fechaAceptada,
    required this.idVehiculo,
    required this.idServicio,
    required this.idCliente,
    this.vehiculo,
    this.servicio,
    required this.responses,
    this.fotos,
  });

  factory QuoteRequest.fromJson(Map<String, dynamic> json) {
    return QuoteRequest(
      id: json['id'],
      ubicacion: json['ubicacion'],
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      fechaExpiracion: json['fecha_expiracion'] != null
          ? DateTime.parse(json['fecha_expiracion'])
          : null,
      comentario: json['comentario'],
      estado: json['estado'],
      fechaAceptada: json['fecha_aceptada'] != null
          ? DateTime.parse(json['fecha_aceptada'])
          : null,
      idVehiculo: json['id_vehiculo'],
      idServicio: json['id_servicio'],
      idCliente: json['id_cliente'],
      vehiculo: json['vehiculo'] != null
          ? VehiculoInfo.fromJson(json['vehiculo'])
          : null,
      servicio: json['servicio'] != null
          ? ServicioInfo.fromJson(json['servicio'])
          : null,
      responses: (json['responses'] as List)
          .map((r) => QuoteResponse.fromJson(r))
          .toList(),
      fotos: json['fotos'] != null
          ? List<String>.from(json['fotos'])
          : null,
    );
  }

  String get estadoTexto {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'con_respuesta':
        return 'Con Respuesta';
      case 'aceptada':
        return 'Aceptada';
      case 'rechazada':
        return 'Rechazada';
      case 'expirada':
        return 'Expirada';
      default:
        return estado;
    }
  }

  String get estadoColor {
    switch (estado) {
      case 'pendiente':
        return '#F59E0B'; // Amarillo
      case 'con_respuesta':
        return '#3B82F6'; // Azul
      case 'aceptada':
        return '#10B981'; // Verde
      case 'rechazada':
        return '#EF4444'; // Rojo
      case 'expirada':
        return '#6B7280'; // Gris
      default:
        return '#6B7280';
    }
  }

  bool get tieneRespuestas => responses.isNotEmpty;
  
  List<QuoteResponse> get respuestasRespondidas => 
      responses.where((r) => r.estado == 'respondida').toList();
}

class QuoteRequestCreate {
  final int idVehiculo;
  final int idServicio;
  final double? ubicacionLat;
  final double? ubicacionLon;
  final String? comentario;
  final List<int> idsTalleres;
  final List<XFile>? fotos;

  QuoteRequestCreate({
    required this.idVehiculo,
    required this.idServicio,
    this.ubicacionLat,
    this.ubicacionLon,
    this.comentario,
    required this.idsTalleres,
    this.fotos,
  });

  Map<String, dynamic> toJson() {
    return {
      'id_vehiculo': idVehiculo,
      'id_servicio': idServicio,
      if (ubicacionLat != null) 'ubicacion_lat': ubicacionLat,
      if (ubicacionLon != null) 'ubicacion_lon': ubicacionLon,
      if (comentario != null && comentario!.isNotEmpty) 'comentario': comentario,
      'ids_talleres': idsTalleres,
    };
  }
}

class QuoteAcceptRequest {
  final int idQuoteResponse;

  QuoteAcceptRequest({
    required this.idQuoteResponse,
  });

  Map<String, dynamic> toJson() {
    return {
      'id_quote_response': idQuoteResponse,
    };
  }
}
