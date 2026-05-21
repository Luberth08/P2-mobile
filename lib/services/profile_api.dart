import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ProfileApi {
  static String get baseUrl => kApiBaseUrl;

  static Future<Map<String, dynamic>> getProfile(String token) async {
    final url = Uri.parse('${baseUrl}perfil/me');
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
    throw Exception('getProfile failed: ${res.statusCode} ${res.body}');
  }

  static Future<Map<String, dynamic>> updateProfile(String token, Map<String, dynamic> data) async {
    final url = Uri.parse('${baseUrl}perfil/me');
    final res = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('updateProfile failed: ${res.statusCode} ${res.body}');
  }

  static Future<Map<String, dynamic>> createUsuario(String token, String username, String password) async {
    final url = Uri.parse('${baseUrl}perfil/create-usuario');
    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );
    if (res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('createUsuario failed: ${res.statusCode} ${res.body}');
  }

  static Future<void> requestPasswordChange(String email) async {
    final url = Uri.parse('${baseUrl}perfil/request-password-change');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (res.statusCode == 200) return;
    throw Exception('requestPasswordChange failed: ${res.statusCode} ${res.body}');
  }

  static Future<void> changePassword(String email, String code, String newPassword) async {
    final url = Uri.parse('${baseUrl}perfil/change-password');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'code': code,
        'new_password': newPassword,
      }),
    );
    if (res.statusCode == 200) return;
    throw Exception('changePassword failed: ${res.statusCode} ${res.body}');
  }

  static Future<String> uploadPhoto(String token, List<int> imageBytes, String filename) async {
    final url = Uri.parse('${baseUrl}perfil/upload-photo');
    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: filename,
      ),
    );
    
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      return data['photo_url'] as String;
    }
    throw Exception('uploadPhoto failed: ${response.statusCode} $responseBody');
  }

  static Future<void> deletePhoto(String token) async {
    final url = Uri.parse('${baseUrl}perfil/photo');
    final res = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 204) return;
    throw Exception('deletePhoto failed: ${res.statusCode} ${res.body}');
  }
}