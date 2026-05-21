import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class AuthApi {
  // Usar la configuración centralizada
  static String get baseUrl => kApiBaseUrl;

  static Future<Map<String, dynamic>> checkEmail(String email) async {
    final url = Uri.parse('${baseUrl}auth/mobile/check-email');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('checkEmail failed: ${res.statusCode} ${res.body}');
  }

  static Future<void> requestOtp(String email) async {
    final url = Uri.parse('${baseUrl}auth/mobile/request-otp');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (res.statusCode == 200) return;
    throw Exception('requestOtp failed: ${res.statusCode} ${res.body}');
  }

  static Future<void> register(String email) async {
    final url = Uri.parse('${baseUrl}auth/mobile/register');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (res.statusCode == 200) return;
    throw Exception('register failed: ${res.statusCode} ${res.body}');
  }

  static Future<String> verifyOtp(String email, String code, {String? fcmToken}) async {
    final url = Uri.parse('${baseUrl}auth/mobile/verify-otp');
    final body = {'email': email, 'code': code};
    if (fcmToken != null) body['fcm_token'] = fcmToken;
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['access_token'] as String;
    }
    throw Exception('verifyOtp failed: ${res.statusCode} ${res.body}');
  }

  static Future<String> login(String email, String password, {String? fcmToken}) async {
    final url = Uri.parse('${baseUrl}auth/mobile/login');
    final body = {'email': email, 'password': password};
    if (fcmToken != null) body['fcm_token'] = fcmToken;
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['access_token'] as String;
    }
    throw Exception('login failed: ${res.statusCode} ${res.body}');
  }

  static Future<void> logout(String token) async {
    final url = Uri.parse('${baseUrl}auth/mobile/logout');
    final res = await http.post(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 204 || res.statusCode == 200) return;
    throw Exception('logout failed: ${res.statusCode} ${res.body}');
  }
}
