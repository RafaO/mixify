import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  final storage = const FlutterSecureStorage();
  String? spotifyToken;

  Future<String?> getTokenFromStorage() async {
    spotifyToken = await storage.read(key: 'spotifyToken');
    return spotifyToken;
  }

  Future<void> saveTokenToStorage(String token) async {
    await storage.write(key: 'spotifyToken', value: token);
  }

  bool isTokenValid() => spotifyToken?.isNotEmpty ?? false;
}
