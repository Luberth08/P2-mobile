import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class VehicleApi {
  static String get baseUrl => kApiBaseUrl;

  static Future<Map<String, dynamic>> getVehicles(String token, {int skip = 0, int limit = 10}) async {
    final url = Uri.parse('${baseUrl}vehiculos/?skip=$skip&limit=$limit');
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
    throw Exception('getVehicles failed: ${res.statusCode} ${res.body}');
  }

  static Future<Map<String, dynamic>> getVehicle(String token, int vehicleId) async {
    final url = Uri.parse('${baseUrl}vehiculos/$vehicleId');
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
    throw Exception('getVehicle failed: ${res.statusCode} ${res.body}');
  }

  static Future<Map<String, dynamic>> createVehicle(String token, Map<String, dynamic> vehicleData) async {
    final url = Uri.parse('${baseUrl}vehiculos/');
    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(vehicleData),
    );
    if (res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('createVehicle failed: ${res.statusCode} ${res.body}');
  }

  static Future<Map<String, dynamic>> updateVehicle(String token, int vehicleId, Map<String, dynamic> vehicleData) async {
    final url = Uri.parse('${baseUrl}vehiculos/$vehicleId');
    final res = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(vehicleData),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('updateVehicle failed: ${res.statusCode} ${res.body}');
  }

  static Future<void> deleteVehicle(String token, int vehicleId) async {
    final url = Uri.parse('${baseUrl}vehiculos/$vehicleId');
    final res = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 204) return;
    throw Exception('deleteVehicle failed: ${res.statusCode} ${res.body}');
  }
}