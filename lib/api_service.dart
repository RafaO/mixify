import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:mixify/token_manager.dart';

class APIService {
  static const String baseUrl = 'https://api.spotify.com';
  final TokenManager tokenManager;
  final VoidCallback onUnauthorised;

  late final Dio _dio;

  APIService({
    required this.onUnauthorised,
    required this.tokenManager,
  }) {
    _dio = Dio(BaseOptions(baseUrl: baseUrl));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.baseUrl == baseUrl) {
          options.headers['Authorization'] =
              'Bearer ${tokenManager.spotifyToken}';
        }
        return handler.next(options);
      },
      onError: (DioError error, handler) {
        if (error.response?.statusCode == 401) {
          debugPrint('Token expired. Please re-login.');
          tokenManager.expired();
          onUnauthorised();
        }
        return handler.next(error);
      },
    ));
  }

  Future<void> play(String deviceId) async {
    _dio.put('/v1/me/player/play?device_id=$deviceId');
  }

  Future<void> pause(String deviceId) async {
    await _dio.put("/v1/me/player/pause?device_id=$deviceId");
  }

  Future<void> addSongToQueue(String songId, String deviceId) async {
    await _dio.post(
        'https://api.spotify.com/v1/me/player/queue?uri=$songId&device_id=$deviceId');
  }

  Future<void> skipToNextSong(String deviceId) async {
    await _dio.post('/v1/me/player/next?device_id=$deviceId');
  }

  Future<String> currentTrack() async {
    final response = await _dio.get('/v1/me/player/currently-playing');

    if (response.statusCode != 200) {
      return '';
    }

    return response.data['item']['uri'];
  }

  Future<List<Map<String, dynamic>>> fetchPlaylists() async {
    const url = '/v1/me/playlists?limit=50&offset=0';

    final response = await _dio.get(url);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(response.data['items']);
    } else {
      debugPrint('Failed to load playlists: ${response.statusCode}');
      return List.empty();
    }
  }

  Future<String> getActiveDevice() async {
    final response = await _dio.get('/v1/me/player/devices');

    String deviceId = '';
    if (response.data['devices'] != null &&
        response.data['devices'].length > 0) {
      // get the first one that is active
      deviceId = response.data['devices'].first['id'];

      // use this if we want to get the active device only
      // final activeDevice = data['devices'].firstWhere(
      //     (device) => device['is_active'] == true,
      //     orElse: () => null);
      // if (activeDevice != null) {
      //   deviceId = activeDevice['id'];
      // }
    } else {
      return '';
    }
    return deviceId;
  }

  Future<List<SpotifySong>> fetchAllSongsFromPlaylists(
    List<String> playlistIds,
  ) async {
    List<SpotifySong> allSongs = [];

    for (String playlistId in playlistIds) {
      final playlistSongs = await _fetchSongsFromPlaylist(playlistId);
      allSongs.addAll(playlistSongs);
    }

    allSongs.shuffle();

    return allSongs;
  }

  Future<List<SpotifySong>> _fetchSongsFromPlaylist(
    String playlistId,
  ) async {
    final url = '/v1/playlists/$playlistId/tracks';

    final response = await _dio.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = response.data;
      final List<dynamic> items = data['items'];

      List<SpotifySong> playlistSongs = [];

      for (var item in items) {
        final track = item['track'];
        final songName = track['name'];
        final artists = track['artists'] as List<dynamic>;
        final artistNames = artists.map((artist) => artist['name']).join(', ');

        final spotifySong = SpotifySong(
          track['uri'],
          name: songName,
          artist: artistNames,
        );
        playlistSongs.add(spotifySong);
      }

      return playlistSongs;
    } else {
      throw Exception('Failed to load playlist songs: ${response.statusCode}');
    }
  }
}

class SpotifySong {
  final String name;
  final String artist;
  final String id;

  SpotifySong(this.id, {required this.name, required this.artist});
}
