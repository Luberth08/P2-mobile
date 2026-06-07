import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../models/cotizacion.dart';
import '../config.dart';
import 'dart:io';

class CotizacionApi {
  static String get baseUrl => kApiBaseUrl;

  /// Obtiene la lista de tipos de servicios disponibles
  static Future<List<Map<String, dynamic>>> getTiposServicio(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cotizaciones/tipos-servicio'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return List<Map<String, dynamic>>.from(data);
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['detail'] ?? 'Error al obtener tipos de servicio');
      }
    } catch (e) {
      print('Error en getTiposServicio: $e');
      rethrow;
    }
  }

  /// Obtiene la lista de talleres disponibles
  static Future<List<Map<String, dynamic>>> getTalleres(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cotizaciones/talleres'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return List<Map<String, dynamic>>.from(data);
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['detail'] ?? 'Error al obtener talleres');
      }
    } catch (e) {
      print('Error en getTalleres: $e');
      rethrow;
    }
  }

  /// Crea una solicitud de cotización
  static Future<QuoteRequest> crearSolicitudCotizacion(
    String token,
    QuoteRequestCreate request,
  ) async {
    try {
      http.Response response;

      if (request.fotos != null && request.fotos!.isNotEmpty) {
        // Enviar con multipart/form-data si hay fotos
        var requestMultipart = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/cotizaciones/solicitudes-con-fotos'),
        );
        
        requestMultipart.headers['Authorization'] = 'Bearer $token';
        
        // Agregar campos de texto
        requestMultipart.fields['id_vehiculo'] = request.idVehiculo.toString();
        requestMultipart.fields['id_servicio'] = request.idServicio.toString();
        if (request.ubicacionLat != null) {
          requestMultipart.fields['ubicacion_lat'] = request.ubicacionLat.toString();
        }
        if (request.ubicacionLon != null) {
          requestMultipart.fields['ubicacion_lon'] = request.ubicacionLon.toString();
        }
        if (request.comentario != null && request.comentario!.isNotEmpty) {
          requestMultipart.fields['comentario'] = request.comentario!;
        }
        requestMultipart.fields['ids_talleres'] = json.encode(request.idsTalleres);
        
        // Agregar fotos
        for (var i = 0; i < request.fotos!.length; i++) {
          var xfile = request.fotos![i];
          var bytes = await xfile.readAsBytes();
          var stream = http.ByteStream.fromBytes(bytes);
          var multipartFile = http.MultipartFile(
            'fotos',
            stream,
            bytes.length,
            filename: 'foto_$i.jpg',
            contentType: MediaType('image', 'jpeg'),
          );
          requestMultipart.files.add(multipartFile);
        }
        
        var streamedResponse = await requestMultipart.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        // Enviar con JSON si no hay fotos
        response = await http.post(
          Uri.parse('$baseUrl/cotizaciones/solicitudes'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(request.toJson()),
        );
      }

      if (response.statusCode == 201) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return QuoteRequest.fromJson(data);
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['detail'] ?? 'Error al crear solicitud de cotización');
      }
    } catch (e) {
      print('Error en crearSolicitudCotizacion: $e');
      rethrow;
    }
  }

  /// Obtiene las cotizaciones del cliente
  static Future<List<QuoteRequest>> obtenerMisCotizaciones(
    String token, {
    int skip = 0,
    int limit = 10,
    String? estado,
  }) async {
    try {
      String url = '$baseUrl/cotizaciones/solicitudes/mis-cotizaciones?skip=$skip&limit=$limit';
      if (estado != null) {
        url += '&estado=$estado';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return (data['items'] as List)
            .map((item) => QuoteRequest.fromJson(item))
            .toList();
      } else {
        throw Exception('Error al obtener cotizaciones: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en obtenerMisCotizaciones: $e');
      rethrow;
    }
  }

  /// Obtiene el detalle de una solicitud de cotización
  static Future<QuoteRequest> obtenerDetalleCotizacion(
    String token,
    int requestId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cotizaciones/solicitudes/$requestId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return QuoteRequest.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Solicitud de cotización no encontrada');
      } else {
        throw Exception('Error al obtener detalle: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en obtenerDetalleCotizacion: $e');
      rethrow;
    }
  }

  /// Acepta una cotización específica
  static Future<QuoteRequest> aceptarCotizacion(
    String token,
    int requestId,
    QuoteAcceptRequest request,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cotizaciones/solicitudes/$requestId/aceptar'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return QuoteRequest.fromJson(data);
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['detail'] ?? 'Error al aceptar cotización');
      }
    } catch (e) {
      print('Error en aceptarCotizacion: $e');
      rethrow;
    }
  }
}
