import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ServiceRequestApi {
  static String get baseUrl => kApiBaseUrl;

  /// Genera solicitudes automáticas para talleres sugeridos
  static Future<Map<String, dynamic>> generarSolicitudesAutomaticas(
    String token,
    int diagnosticoId,
  ) async {
    final url = Uri.parse('${baseUrl}servicios/$diagnosticoId/generar-solicitudes');
    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('generarSolicitudesAutomaticas failed: ${res.statusCode} ${res.body}');
  }

  /// Lista talleres sugeridos y otros talleres cercanos
  static Future<List<Map<String, dynamic>>> listarTalleresSugeridos(
    String token,
    int diagnosticoId,
  ) async {
    final url = Uri.parse('${baseUrl}servicios/$diagnosticoId/talleres-sugeridos');
    final res = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
    throw Exception('listarTalleresSugeridos failed: ${res.statusCode} ${res.body}');
  }

  /// Solicita servicio a un taller específico (manual)
  static Future<Map<String, dynamic>> solicitarServicioTaller(
    String token,
    int diagnosticoId,
    int idTaller, {
    String? comentario,
  }) async {
    final url = Uri.parse('${baseUrl}servicios/$diagnosticoId/solicitar-taller');
    final res = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'id_taller': idTaller.toString(),
        if (comentario != null && comentario.isNotEmpty) 'comentario': comentario,
      },
    );

    if (res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('solicitarServicioTaller failed: ${res.statusCode} ${res.body}');
  }

  /// Lista todas las solicitudes de servicio para un diagnóstico
  static Future<List<Map<String, dynamic>>> listarSolicitudesServicio(
    String token,
    int diagnosticoId,
  ) async {
    final url = Uri.parse('${baseUrl}servicios/$diagnosticoId/solicitudes');
    final res = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
    throw Exception('listarSolicitudesServicio failed: ${res.statusCode} ${res.body}');
  }

  /// Cancela una solicitud de servicio
  static Future<void> cancelarSolicitudServicio(
    String token,
    int solicitudId,
  ) async {
    final url = Uri.parse('${baseUrl}servicios/$solicitudId');
    final res = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 204) return;
    throw Exception('cancelarSolicitudServicio failed: ${res.statusCode} ${res.body}');
  }

  /// Actualiza el comentario de una solicitud existente
  static Future<Map<String, dynamic>> actualizarComentario(
    String token,
    int solicitudId,
    String comentario,
  ) async {
    final url = Uri.parse('${baseUrl}servicios/$solicitudId/comentario');
    final res = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'comentario': comentario,
      },
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('actualizarComentario failed: ${res.statusCode} ${res.body}');
  }

  /// Obtiene la ubicación de un taller
  static Future<Map<String, dynamic>> obtenerUbicacionTaller(
    String token,
    int tallerId,
  ) async {
    final url = Uri.parse('${baseUrl}servicios/taller/$tallerId/ubicacion');
    final res = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('obtenerUbicacionTaller failed: ${res.statusCode} ${res.body}');
  }
}
