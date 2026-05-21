import 'dart:convert';
import 'package:http/http.dart' as http;

class ClienteApi {
  static const String baseUrl = 'https://backend-repo-2ncr.onrender.com/api/v1';

  /// Obtiene el servicio actual en proceso del cliente con seguimiento completo
  static Future<ServicioSeguimientoCliente?> obtenerServicioActual(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cliente/servicio-actual'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data == null) return null;
        return ServicioSeguimientoCliente.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Error al obtener servicio actual: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en obtenerServicioActual: $e');
      rethrow;
    }
  }

  /// Obtiene la ruta optimizada desde un técnico hasta el cliente
  static Future<RutaTecnicoCliente> obtenerRutaTecnico(
    String token,
    int servicioId,
    int empleadoId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cliente/servicio/$servicioId/tecnico/$empleadoId/ruta'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return RutaTecnicoCliente.fromJson(data);
      } else {
        throw Exception('Error al obtener ruta: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en obtenerRutaTecnico: $e');
      rethrow;
    }
  }

  /// Valora un servicio finalizado
  static Future<void> valorarServicio(
    String token,
    int servicioId,
    int puntos,
    String? comentario,
  ) async {
    try {
      final body = {
        'puntos': puntos,
        if (comentario != null && comentario.isNotEmpty) 'comentario': comentario,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/cliente/servicio/$servicioId/valorar'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode != 201) {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['detail'] ?? 'Error al valorar servicio');
      }
    } catch (e) {
      print('Error en valorarServicio: $e');
      rethrow;
    }
  }

  /// Obtiene la valoración de un servicio
  static Future<Valoracion?> obtenerValoracion(
    String token,
    int servicioId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cliente/servicio/$servicioId/valoracion'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data == null) return null;
        return Valoracion.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Error al obtener valoración: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en obtenerValoracion: $e');
      rethrow;
    }
  }

  /// Actualiza la valoración de un servicio
  static Future<void> actualizarValoracion(
    String token,
    int servicioId,
    int puntos,
    String? comentario,
  ) async {
    try {
      final body = {
        'puntos': puntos,
        if (comentario != null && comentario.isNotEmpty) 'comentario': comentario,
      };

      final response = await http.put(
        Uri.parse('$baseUrl/cliente/servicio/$servicioId/valoracion'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode != 200) {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['detail'] ?? 'Error al actualizar valoración');
      }
    } catch (e) {
      print('Error en actualizarValoracion: $e');
      rethrow;
    }
  }
}

// ============================================================
// MODELOS
// ============================================================

class ServicioSeguimientoCliente {
  final int id;
  final DateTime fecha;
  final String estado;
  final String estadoDescripcion;
  final TallerInfo taller;
  final List<TecnicoUbicacion> tecnicos;
  final List<EstadoHistorial> historialEstados;
  final String? ubicacionCliente; // "lat,lon"
  final String? diagnosticoDescripcion;

  ServicioSeguimientoCliente({
    required this.id,
    required this.fecha,
    required this.estado,
    required this.estadoDescripcion,
    required this.taller,
    required this.tecnicos,
    required this.historialEstados,
    this.ubicacionCliente,
    this.diagnosticoDescripcion,
  });

  factory ServicioSeguimientoCliente.fromJson(Map<String, dynamic> json) {
    return ServicioSeguimientoCliente(
      id: json['id'],
      fecha: DateTime.parse(json['fecha']),
      estado: json['estado'],
      estadoDescripcion: json['estado_descripcion'],
      taller: TallerInfo.fromJson(json['taller']),
      tecnicos: (json['tecnicos'] as List)
          .map((t) => TecnicoUbicacion.fromJson(t))
          .toList(),
      historialEstados: (json['historial_estados'] as List)
          .map((h) => EstadoHistorial.fromJson(h))
          .toList(),
      ubicacionCliente: json['ubicacion_cliente'],
      diagnosticoDescripcion: json['diagnostico_descripcion'],
    );
  }
}

class TallerInfo {
  final int id;
  final String nombre;
  final String? telefono;
  final String? email;
  final String? direccion;
  final String? ubicacion; // "lat,lon"
  final double puntos;

  TallerInfo({
    required this.id,
    required this.nombre,
    this.telefono,
    this.email,
    this.direccion,
    this.ubicacion,
    required this.puntos,
  });

  factory TallerInfo.fromJson(Map<String, dynamic> json) {
    return TallerInfo(
      id: json['id'],
      nombre: json['nombre'],
      telefono: json['telefono'],
      email: json['email'],
      direccion: json['direccion'],
      ubicacion: json['ubicacion'],
      puntos: (json['puntos'] as num).toDouble(),
    );
  }
}

class TecnicoUbicacion {
  final int idEmpleado;
  final String nombreCompleto;
  final double? latitud;
  final double? longitud;
  final DateTime? timestamp;
  final bool tieneUbicacion;

  TecnicoUbicacion({
    required this.idEmpleado,
    required this.nombreCompleto,
    this.latitud,
    this.longitud,
    this.timestamp,
    required this.tieneUbicacion,
  });

  factory TecnicoUbicacion.fromJson(Map<String, dynamic> json) {
    return TecnicoUbicacion(
      idEmpleado: json['id_empleado'],
      nombreCompleto: json['nombre_completo'],
      latitud: json['latitud']?.toDouble(),
      longitud: json['longitud']?.toDouble(),
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
      tieneUbicacion: json['tiene_ubicacion'],
    );
  }
}

class EstadoHistorial {
  final String estado;
  final String estadoDescripcion;
  final DateTime tiempo;

  EstadoHistorial({
    required this.estado,
    required this.estadoDescripcion,
    required this.tiempo,
  });

  factory EstadoHistorial.fromJson(Map<String, dynamic> json) {
    return EstadoHistorial(
      estado: json['estado'],
      estadoDescripcion: json['estado_descripcion'],
      tiempo: DateTime.parse(json['tiempo']),
    );
  }
}

class RutaTecnicoCliente {
  final List<List<double>> ruta; // [[lon, lat], [lon, lat], ...]
  final double? distanciaMetros;
  final double? duracionSegundos;
  final UbicacionPunto ubicacionTecnico;
  final UbicacionPunto ubicacionCliente;
  final bool? fallback;

  RutaTecnicoCliente({
    required this.ruta,
    this.distanciaMetros,
    this.duracionSegundos,
    required this.ubicacionTecnico,
    required this.ubicacionCliente,
    this.fallback,
  });

  factory RutaTecnicoCliente.fromJson(Map<String, dynamic> json) {
    return RutaTecnicoCliente(
      ruta: (json['ruta'] as List)
          .map((punto) => (punto as List).map((coord) => (coord as num).toDouble()).toList())
          .toList(),
      distanciaMetros: json['distancia_metros']?.toDouble(),
      duracionSegundos: json['duracion_segundos']?.toDouble(),
      ubicacionTecnico: UbicacionPunto.fromJson(json['ubicacion_tecnico']),
      ubicacionCliente: UbicacionPunto.fromJson(json['ubicacion_cliente']),
      fallback: json['fallback'],
    );
  }
}

class UbicacionPunto {
  final double latitud;
  final double longitud;

  UbicacionPunto({
    required this.latitud,
    required this.longitud,
  });

  factory UbicacionPunto.fromJson(Map<String, dynamic> json) {
    return UbicacionPunto(
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
    );
  }
}

// Modelo de Valoración
class Valoracion {
  final int id;
  final int puntos;
  final String? comentario;
  final int idServicio;

  Valoracion({
    required this.id,
    required this.puntos,
    this.comentario,
    required this.idServicio,
  });

  factory Valoracion.fromJson(Map<String, dynamic> json) {
    return Valoracion(
      id: json['id'],
      puntos: json['puntos'],
      comentario: json['comentario'],
      idServicio: json['id_servicio'],
    );
  }
}
