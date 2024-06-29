import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:mixify/entities/spotify_playlist.dart';
import 'package:mixify/entities/spotify_song.dart';
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
    await _dio.post('/v1/me/player/queue?uri=$songId&device_id=$deviceId');
  }

  Future<void> skipToNextSong(String deviceId) async {
    await _dio.post('/v1/me/player/next?device_id=$deviceId');
  }

  Future<SpotifySong?> currentTrack() async {
    final response = await _dio.get('/v1/me/player/currently-playing');

    if (response.statusCode != 200) {
      return null;
    }

    final data = response.data;
    final artists = data['item']['artists'] as List<dynamic>;
    final artistNames = artists.map((artist) => artist['name']).join(', ');
    return SpotifySong(
      data['item']['uri'],
      name: data['item']['name'],
      artist: artistNames,
    );
  }

  Future<List<SpotifyPlaylist>> fetchPlaylists() async {
    const url = '/v1/me/playlists?limit=50&offset=0';

    final response = await _dio.get(url);

    if (response.statusCode == 200) {
      List<dynamic> items = response.data['items'];
      List<SpotifyPlaylist> playlists = [];

      for (var item in items) {
        playlists.add(SpotifyPlaylist(
            id: item['id'],
            name: item['name'],
            description: item['description'],
            imageUrl: item['images']?[0]['url']));
        // != null && playlist['images'].isNotEmpty ?
        //     if ()
        //   Image.network(
        //   playlist['images'][0]['url'],
        //   fit: BoxFit.cover,
        //   width: double.infinity,
        // ),
        // ));
      }

      return playlists;
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

  List<SpotifySong> mixAndAppendMultipleListsRecursive(
      List<List<SpotifySong>> lists) {
    List<SpotifySong> result = [];

    // Find the size of the shortest list
    int minLength = lists.map((list) => list.length).reduce(min);

    // Combine elements randomly up to the size of the shortest list
    List<int> indices =
        List.generate(minLength * lists.length, (index) => index);
    indices.shuffle();

    for (int i = 0; i < minLength * lists.length; i++) {
      int listIndex = indices[i] % lists.length;
      int elementIndex = indices[i] ~/ lists.length;
      result.add(lists[listIndex][elementIndex]);
    }

    // Create a list of remaining lists
    List<List<SpotifySong>> remainingLists = [];
    for (int j = 0; j < lists.length; j++) {
      if (lists[j].length > minLength) {
        remainingLists.add(lists[j].sublist(minLength));
      }
    }

    // Recursively mix and append the remaining lists
    if (remainingLists.length > 1) {
      result.addAll(mixAndAppendMultipleListsRecursive(remainingLists));
    } else if (remainingLists.length == 1) {
      // If there's only one list left, append its elements
      result.addAll(remainingLists[0]);
    }

    return result;
  }

  Future<List<SpotifySong>> fetchAndMixAllSongsFromPlaylists(
    List<String> playlistIds,
  ) async {
    List<List<SpotifySong>> songsLists = [];

    for (String playlistId in playlistIds) {
      final playlistSongs = await _fetchSongsFromPlaylist(playlistId);
      songsLists.add(playlistSongs);
    }

    final result = mixAndAppendMultipleListsRecursive(songsLists);

    return result;
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
