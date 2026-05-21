import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config.dart';

class DiagnosticApi {
  static String get baseUrl => kApiBaseUrl;

  /// Crea una solicitud de diagnóstico
  static Future<Map<String, dynamic>> createDiagnostic({
    required String token,
    required String descripcion,
    required String ubicacion, // "lat,lon"
    int? idVehiculo,
    String? matricula,
    String? marca,
    String? modelo,
    int? anio,
    String? color,
    String? tipoVehiculo,
    List<File>? fotos,
    File? audio,
  }) async {
    final url = Uri.parse('${baseUrl}diagnosticos/');
    final request = http.MultipartRequest('POST', url);
    
    request.headers['Authorization'] = 'Bearer $token';
    
    // Campos de texto
    request.fields['descripcion'] = descripcion;
    request.fields['ubicacion'] = ubicacion;
    
    if (matricula != null) request.fields['matricula'] = matricula;
    if (marca != null) request.fields['marca'] = marca;
    if (modelo != null) request.fields['modelo'] = modelo;
    if (anio != null) request.fields['anio'] = anio.toString();
    if (color != null) request.fields['color'] = color;
    if (tipoVehiculo != null) request.fields['tipo_vehiculo'] = tipoVehiculo;
    
    // Agregar fotos (máximo 3)
    if (fotos != null && fotos.isNotEmpty) {
      for (int i = 0; i < fotos.length && i < 3; i++) {
        final foto = fotos[i];
        request.files.add(await http.MultipartFile.fromPath(
          'foto${i + 1}',
          foto.path,
        ));
      }
    }
    
    // Agregar audio
    if (audio != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'audio',
        audio.path,
      ));
    }
    
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    
    if (response.statusCode == 201) {
      return jsonDecode(responseBody) as Map<String, dynamic>;
    }
    throw Exception('createDiagnostic failed: ${response.statusCode} $responseBody');
  }

  /// Obtiene las solicitudes de diagnóstico del usuario
  static Future<List<Map<String, dynamic>>> getMySolicitudes(String token) async {
    final url = Uri.parse('${baseUrl}diagnosticos/mis-solicitudes');
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
    throw Exception('getMySolicitudes failed: ${res.statusCode} ${res.body}');
  }

  /// Obtiene una solicitud específica
  static Future<Map<String, dynamic>> getSolicitud(String token, int solicitudId) async {
    final url = Uri.parse('${baseUrl}diagnosticos/$solicitudId');
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
    throw Exception('getSolicitud failed: ${res.statusCode} ${res.body}');
  }

  /// Lista todos los tipos de incidentes disponibles
  static Future<List<Map<String, dynamic>>> getTiposIncidentes(String token) async {
    final url = Uri.parse('${baseUrl}diagnosticos/tipos-incidentes');
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
    throw Exception('getTiposIncidentes failed: ${res.statusCode} ${res.body}');
  }

  /// Asocia un tipo de incidente al diagnóstico
  static Future<void> asociarTipoIncidente(
    String token,
    int solicitudId,
    int idTipoIncidente,
  ) async {
    final url = Uri.parse('${baseUrl}diagnosticos/$solicitudId/asociar-tipo');
    final res = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'id_tipo_incidente': idTipoIncidente.toString()},
    );
    
    if (res.statusCode == 201) return;
    throw Exception('asociarTipoIncidente failed: ${res.statusCode} ${res.body}');
  }

  /// Descarta un incidente del diagnóstico
  static Future<void> descartarIncidente(
    String token,
    int solicitudId,
    int idDiagnostico,
    int idTipoIncidente,
  ) async {
    final url = Uri.parse('${baseUrl}diagnosticos/$solicitudId/incidentes/$idDiagnostico/$idTipoIncidente');
    final res = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    
    if (res.statusCode == 204) return;
    throw Exception('descartarIncidente failed: ${res.statusCode} ${res.body}');
  }

  /// Cancela una solicitud
  static Future<void> cancelarSolicitud(String token, int solicitudId) async {
    final url = Uri.parse('${baseUrl}diagnosticos/$solicitudId/cancel');
    final res = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    
    if (res.statusCode == 204) return;
    throw Exception('cancelarSolicitud failed: ${res.statusCode} ${res.body}');
  }

  /// Reintenta el procesamiento de una solicitud
  static Future<Map<String, dynamic>> reintentarProcesamiento(
    String token,
    int solicitudId,
  ) async {
    final url = Uri.parse('${baseUrl}diagnosticos/$solicitudId/reintentar');
    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('reintentarProcesamiento failed: ${res.statusCode} ${res.body}');
  }
}
