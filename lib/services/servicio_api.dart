import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/servicio.dart';

class ServicioApi {
  static const String baseUrl = 'https://backend-repo-2ncr.onrender.com/api/v1';

  /// TEMPORAL: Debug - obtiene todos los servicios del cliente
  static Future<Map<String, dynamic>> debugTodosLosServicios(String token) async {
    try {
      print('🔍 DEBUG: Consultando todos los servicios...');
      final response = await http.get(
        Uri.parse('$baseUrl/servicios/debug/mis-servicios-todos'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 DEBUG Status code: ${response.statusCode}');
      print('📦 DEBUG Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data;
      } else {
        throw Exception('Error en debug: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en debug: $e');
      rethrow;
    }
  }

  /// Obtiene el servicio actual (activo) del cliente
  static Future<ServicioCliente?> obtenerServicioActual(String token) async {
    try {
      print('🔍 Consultando servicio actual...');
      final response = await http.get(
        Uri.parse('$baseUrl/servicios/mis-servicios/actual'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Status code: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ Data recibida: $data');
        if (data == null) {
          print('⚠️ No hay servicio actual');
          return null;
        }
        return ServicioCliente.fromJson(data);
      } else if (response.statusCode == 404) {
        print('⚠️ 404 - No hay servicio actual');
        return null;
      } else {
        print('❌ Error: ${response.statusCode}');
        throw Exception('Error al obtener servicio actual: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en obtenerServicioActual: $e');
      rethrow;
    }
  }

  /// Obtiene el historial de servicios completados/cancelados
  static Future<List<ServicioHistorial>> obtenerHistorialServicios(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/servicios/mis-servicios/historial'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => ServicioHistorial.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener historial: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en obtenerHistorialServicios: $e');
      rethrow;
    }
  }

  /// Obtiene el detalle completo de un servicio específico
  static Future<ServicioCliente> obtenerDetalleServicio(String token, int servicioId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/servicios/mis-servicios/$servicioId/detalle'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return ServicioCliente.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Servicio no encontrado');
      } else if (response.statusCode == 403) {
        throw Exception('No autorizado');
      } else {
        throw Exception('Error al obtener detalle del servicio: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en obtenerDetalleServicio: $e');
      rethrow;
    }
  }
}
