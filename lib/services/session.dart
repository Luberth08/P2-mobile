import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Session {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _keyToken = 'access_token';

  static Future<void> saveToken(String token) => _storage.write(key: _keyToken, value: token);
  static Future<String?> getToken() => _storage.read(key: _keyToken);
  static Future<void> clearToken() => _storage.delete(key: _keyToken);
}
