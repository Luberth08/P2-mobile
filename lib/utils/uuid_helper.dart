import 'dart:math';

class UuidHelper {
  static final Random _random = Random();

  /// Generates a unique ID for sync operations
  /// Format: timestamp-randomString
  static String generateSyncId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomBytes = List.generate(8, (_) => _random.nextInt(256));
    final randomString = randomBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '$timestamp-$randomString';
  }

  /// Generates a shorter unique ID
  static String generateShortId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch % 1000000;
    final random = _random.nextInt(10000);
    return '$timestamp-$random';
  }
}
