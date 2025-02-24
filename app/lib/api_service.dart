import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:mixafy/entities/artist.dart';
import 'package:mixafy/entities/spotify_playlist.dart';
import 'package:mixafy/entities/spotify_song.dart';
import 'package:mixafy/entities/time_range.dart';
import 'package:mixafy/token_manager.dart';

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
        debugPrint(
            "calling ${options.uri} with token ${tokenManager.spotifyToken}");
        if (options.baseUrl == baseUrl) {
          options.headers['Authorization'] =
              'Bearer ${tokenManager.spotifyToken}';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) {
        if (error.response?.statusCode == 401) {
          debugPrint('Token expired. Please re-login.');
          tokenManager.expired();
          onUnauthorised();
        }
        return handler.next(error);
      },
    ));
  }

  Future<void> play(String deviceId, {List<SpotifySong>? songs}) async {
    Object? data;
    if (songs != null) {
      data = {
        "uris": songs.map((song) => song.id).toList(),
      };
    }

    await _dio.put('/v1/me/player/play?device_id=$deviceId', data: data);
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
    if (data == null || data['item'] == null) {
      return null;
    }
    return SpotifySong(
      data['item']['uri'],
      name: data['item']['name'],
    );
  }

  Future<List<SpotifyPlaylist>> fetchPlaylists() async {
    const url = '/v1/me/playlists';

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

      final activeDevice = response.data['devices'].firstWhere(
          (device) => device['is_active'] == true,
          orElse: () => null);
      if (activeDevice != null) {
        deviceId = activeDevice['id'];
      }
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
    TimeRange timeRange,
  ) async {
    if (playlistIds.isEmpty) {
      return [];
    }
    List<List<SpotifySong>> songsLists = [];

    for (String playlistId in playlistIds) {
      final playlistSongs = await _fetchSongsFromPlaylist(
        playlistId,
        timeRange,
      );
      songsLists.add(playlistSongs);
    }

    final result = mixAndAppendMultipleListsRecursive(songsLists);

    return result;
  }

  Future<List<SpotifySong>> _fetchSongsFromPlaylist(
    String playlistId,
    TimeRange timeRange,
  ) async =>
      _fetchSongs('/v1/playlists/$playlistId/tracks', timeRange);

  Future<List<SpotifySong>> _fetchSavedTracks(TimeRange timeRange) async =>
      _fetchSongs('/v1/me/tracks', timeRange);

  Future<List<SpotifySong>> _fetchSongs(
    String url,
    TimeRange timeRange,
  ) async {
    List<SpotifySong> playlistSongs = [];
    int offset = 0;
    const int limit = 100; // Spotify's max limit per page

    final DateTime filterStartDate = timeRange.getStartDate();

    while (true) {
      // Construct the request URL with pagination parameters
      final response = await _dio.get(
        url,
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        final List<dynamic> items = data['items'];

        for (var item in items) {
          final track = item['track'];
          final songName = track['name'];
          final addedAt = item['added_at'];
          DateTime dateTime = DateTime.parse(addedAt);

          final spotifySong = SpotifySong(
            track['uri'],
            name: songName,
          );

          // Filter by the time range
          if (dateTime.isAfter(filterStartDate)) {
            playlistSongs.add(spotifySong);
          }
        }

        // Check if there are more pages
        if (items.length < limit) {
          break; // No more pages
        }
        offset += limit; // Move to the next page
      } else {
        throw Exception(
            'Failed to load playlist songs: ${response.statusCode}');
      }
    }

    return playlistSongs;
  }

  Future<List<Artist>> getUserSavedArtists() async {
    final response = await _dio.get('/v1/me/following?type=artist');
    if (response.statusCode == 200) {
      List<dynamic> items = response.data['artists']['items'];
      return items
          .map((artist) => Artist(
                artist['id'],
                name: artist['name'],
                imageUrl: artist['images']?[0]['url'],
              ))
          .toList();
    }
    return [];
  }

  Future<List<SpotifySong>> getPopularTracks(String artistId) async {
    final response = await _dio.get('/v1/artists/$artistId/top-tracks');
    if (response.statusCode == 200) {
      List<dynamic> tracks = response.data['tracks'];
      return tracks
          .map((track) => SpotifySong(track['uri'], name: track['name']))
          .toList();
    }
    return [];
  }
}
