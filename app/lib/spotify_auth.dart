import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:url_launcher/url_launcher.dart';

final String clientId = dotenv.env['spotify_client_id'] ?? '';
final String clientSecret = dotenv.env['spotify_client_secret'] ?? '';
const redirectUri = 'mixafy://callback';
final String scopes = [
  "playlist-read-private",
  "user-modify-playback-state",
  "user-read-playback-state",
  "user-read-currently-playing",
  "user-follow-read",
  "user-library-read",
  "app-remote-control"
].join(' ');

Future<Map<String, dynamic>> fetchSpotifyToken(String code) async {
  if (clientId.isEmpty || clientSecret.isEmpty) {
    throw Exception('Spotify client credentials are not set in .env');
  }

  final credentials = base64Encode(utf8.encode('$clientId:$clientSecret'));

  try {
    final response = await Dio().post<Map<String, dynamic>>(
      'https://accounts.spotify.com/api/token',
      data: {
        'code': code,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
      },
      options: Options(
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic $credentials',
        },
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    return response.data ?? {};
  } on DioException catch (e) {
    if (e.response != null) {
      throw Exception(
        'Spotify token request failed: '
        '${e.response?.statusCode} - ${e.response?.data}',
      );
    } else {
      throw Exception('Spotify token request error: ${e.message}');
    }
  }
}

Future<void> authenticateWithSpotifyApp(Function(String) onTokenReceived,
    Function(Exception, StackTrace) onException) async {
  if (clientId.isEmpty) {
    FirebaseCrashlytics.instance.recordError(
      Exception("clientID is empty"),
      null,
    );
    return;
  }

  try {
    // If installed, use Spotify SDK authentication
    var accessToken = await SpotifySdk.getAccessToken(
      clientId: clientId,
      redirectUrl: redirectUri,
      scope: scopes,
    );
    onTokenReceived(accessToken);
  } on Exception catch (e, s) {
    onException(e, s);
  }
}
