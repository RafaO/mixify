import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  final storageKey = "spotifyToken";

  final storage = const FlutterSecureStorage();
  String? spotifyToken;

  Future<String?> getTokenFromStorage() async {
    spotifyToken = await storage.read(key: storageKey);
    return spotifyToken;
  }

  Future<void> saveTokenToStorage(String token) async {
    await storage.write(key: storageKey, value: token);
  }

  void tokenReceived(String token) {
    spotifyToken = token;
    saveTokenToStorage(token);
  }

  bool isTokenValid() => spotifyToken?.isNotEmpty ?? false;

  void expired() {
    spotifyToken = null;
    storage.delete(key: storageKey);
  }
}
