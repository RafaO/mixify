import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  final storageKey = "spotifyToken";
  final timestampKey = "spotifyTokenTimestamp";
  final storage = const FlutterSecureStorage();
  String? spotifyToken;

  TokenManager() {
    _loadToken();
  }

  Future<String?> _loadToken() async {
    spotifyToken = await storage.read(key: storageKey);
    return spotifyToken;
  }

  Future<void> saveTokenToStorage(String token) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    await storage.write(key: storageKey, value: token);
    await storage.write(key: timestampKey, value: timestamp);
    spotifyToken = token;
  }

  void tokenReceived(String token) {
    saveTokenToStorage(token);
  }

  Future<bool> isTokenValid() async {
    spotifyToken ??= await _loadToken();
    if (spotifyToken == null) return false;

    final timestampString = await storage.read(key: timestampKey);
    if (timestampString != null) {
      final timestamp = int.tryParse(timestampString);
      if (timestamp == null) return false;

      final expiryTime = DateTime.fromMillisecondsSinceEpoch(timestamp)
          .add(const Duration(minutes: 60));

      return DateTime.now().isBefore(expiryTime);
    }
    return true;
    return false;
  }

  Future<void> expired() async {
    spotifyToken = null;
    await storage.delete(key: storageKey);
    await storage.delete(key: timestampKey);
  }
}
