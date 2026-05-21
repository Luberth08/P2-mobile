import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  static const String baseUrl = 'https://backend-repo-2ncr.onrender.com/api/v1';

  /// Obtiene la información del usuario actual incluyendo su rol
  static Future<Map<String, dynamic>?> obtenerInfoUsuario(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/perfil/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data;
      } else {
        return null;
      }
    } catch (e) {
      print('Error obteniendo info usuario: $e');
      return null;
    }
  }

  /// Verifica si el usuario actual es técnico
  static Future<bool> esTecnico(String token) async {
    try {
      final info = await obtenerInfoUsuario(token);
      print('🔍 DEBUG - Info usuario completa: $info');
      
      if (info != null) {
        // Verificar si tiene rol de técnico o empleado en la lista de roles
        final roles = info['roles'];
        print('🔍 DEBUG - Roles obtenidos: $roles');
        
        if (roles is List) {
          // Convertir todos los roles a minúsculas y verificar
          final rolesLower = roles.map((r) => r.toString().toLowerCase()).toList();
          print('🔍 DEBUG - Roles en minúsculas: $rolesLower');
          
          final esTecnico = rolesLower.contains('tecnico') || rolesLower.contains('empleado');
          print('🔍 DEBUG - Es técnico: $esTecnico');
          
          return esTecnico;
        }
      }
      
      print('⚠️ DEBUG - Info es null o roles no es lista');
      return false;
    } catch (e) {
      print('❌ Error verificando si es técnico: $e');
      return false;
    }
  }
}