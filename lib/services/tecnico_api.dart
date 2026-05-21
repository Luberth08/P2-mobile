import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tecnico_servicio.dart';

class TecnicoApi {
  static const String baseUrl = 'https://backend-repo-2ncr.onrender.com/api/v1';

  /// Obtiene los talleres donde el técnico puede trabajar
  static Future<List<TallerTecnicoInfo>> obtenerTalleres(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tecnico/talleres'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => TallerTecnicoInfo.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener talleres: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en obtenerTalleres: $e');
      rethrow;
    }
  }

  /// Obtiene los servicios asignados al técnico en un taller
  static Future<List<ServicioTecnico>> obtenerServiciosAsignados(
    String token, 
    int tallerId
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tecnico/servicios/$tallerId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => ServicioTecnico.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener servicios: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en obtenerServiciosAsignados: $e');
      rethrow;
    }
  }

  /// Obtiene el historial de servicios finalizados/cancelados del técnico en un taller
  static Future<List<ServicioTecnico>> obtenerHistorialServicios(
    String token, 
    int tallerId
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tecnico/servicios/$tallerId/historial'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => ServicioTecnico.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener historial: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en obtenerHistorialServicios: $e');
      rethrow;
    }
  }

  /// Actualiza el estado de un servicio
  static Future<void> actualizarEstadoServicio(
    String token,
    int servicioId,
    EstadoServicioTecnico nuevoEstado, {
    double? latitud,
    double? longitud,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'nuevo_estado': nuevoEstado.value,
      };

      if (latitud != null && longitud != null) {
        body['ubicacion_tecnico'] = jsonEncode({
          'latitud': latitud,
          'longitud': longitud,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      final response = await http.post(
        Uri.parse('$baseUrl/tecnico/servicios/$servicioId/actualizar-estado'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al actualizar estado: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en actualizarEstadoServicio: $e');
      rethrow;
    }
  }

  /// Actualiza solo la ubicación del técnico
  static Future<void> actualizarUbicacionTecnico(
    String token,
    int servicioId,
    double latitud,
    double longitud,
  ) async {
    try {
      final body = {
        'latitud': latitud,
        'longitud': longitud,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/tecnico/servicios/$servicioId/actualizar-ubicacion'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al actualizar ubicación: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en actualizarUbicacionTecnico: $e');
      rethrow;
    }
  }
}