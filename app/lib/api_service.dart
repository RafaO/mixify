import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:mixafy/entities/artist.dart';
import 'package:mixafy/entities/spotify_playlist.dart';
import 'package:mixafy/entities/spotify_song.dart';
import 'package:mixafy/entities/time_range.dart';
import 'package:mixafy/songs_mixer.dart';
import 'package:mixafy/token_manager.dart';

import 'entities/playlist_songs.dart';
import 'entities/selectable_item.dart';

class APIService {
  static const String baseUrl = 'https://api.spotify.com';
  final TokenManager tokenManager;
  final VoidCallback onUnauthorised;
  final SongsMixer songsMixer;

  late final Dio _dio;

  APIService({
    required this.onUnauthorised,
    required this.tokenManager,
    required this.songsMixer,
  }) {
    _dio = Dio(BaseOptions(baseUrl: baseUrl));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        debugPrint(
            "Calling ${options.uri} with token ${tokenManager.spotifyToken}");
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
      return items
          .map((item) => SpotifyPlaylist(
                id: item['id'],
                name: item['name'],
                description: item['description'],
                imageUrl: item['images']?[0]['url'],
                spotifyUrl: item['external_urls']['spotify'],
              ))
          .toList();
    } else {
      debugPrint('Failed to load playlists: ${response.statusCode}');
      return [];
    }
  }

  Future<List<SpotifySong>> fetchAndMixAllSongsFromItems(
    bool includeSavedTracks,
    List<SelectableItem> items,
    Map<String, double> itemsPercentage,
    TimeRange timeRange,
  ) async {
    if (itemsPercentage.isEmpty) {
      return [];
    }

    Map<String, List<SpotifySong>> songsByItem = {};
    Map<String, List<SpotifySong>> fallbackSongsByItem = {};

    for (int i = 0; i < itemsPercentage.length && i < items.length; i++) {
      final itemId = itemsPercentage.keys.elementAt(i);
      final item = items[i];
      if (item is SpotifyPlaylist) {
        final playlistSongs = await _fetchSongsFromPlaylist(itemId, timeRange);
        songsByItem[itemId] = playlistSongs.playlistSongs;
        fallbackSongsByItem[itemId] = playlistSongs.fallbackSongs;
      } else if (item is Artist) {
        final popularTracks = await getPopularTracks(item.id);
        songsByItem[itemId] = popularTracks;
        fallbackSongsByItem[itemId] = []; // TODO
      }
    }

    if (includeSavedTracks) {
      final savedTracks = await _fetchSavedTracks(timeRange);
      songsByItem['saved_tracks'] = savedTracks.playlistSongs;
      fallbackSongsByItem['saved_tracks'] = savedTracks.fallbackSongs;
    }

    // Use SongsMixer to mix the songs based on the percentages
    return songsMixer.mix(songsByItem, itemsPercentage, fallbackSongsByItem);
  }

  Future<String> getActiveDevice() async {
    try {
      final response = await _dio.get('/v1/me/player/devices');
      if (response.statusCode == 200) {
        List<dynamic> devices = response.data['devices'];
        final activeDevice = devices.firstWhere(
          (device) => device['is_active'] == true,
          orElse: () => null,
        );
        return activeDevice?['id'] ?? '';
      }
    } catch (e) {
      debugPrint("Error fetching active device: ${e.toString()}");
    }
    return '';
  }

  Future<PlaylistSongs> _fetchSongsFromPlaylist(
      String playlistId, TimeRange timeRange) async {
    return _fetchSongs('/v1/playlists/$playlistId/tracks', timeRange);
  }

  Future<PlaylistSongs> _fetchSavedTracks(TimeRange timeRange) async {
    return _fetchSongs('/v1/me/tracks', timeRange, limit: 50);
  }

  Future<PlaylistSongs> _fetchSongs(
    String url,
    TimeRange timeRange, {
    int limit = 100,
  }) async {
    List<SpotifySong> playlistSongs = [];
    List<SpotifySong> fallbackSongs = [];
    int offset = 0;

    final DateTime filterStartDate = timeRange.getStartDate();

    while (true) {
      final response = await _dio.get(
        url,
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> items = response.data['items'];

        for (var item in items) {
          final track = item['track'];
          final songName = track['name'];
          final addedAt = item['added_at'];
          DateTime dateTime = DateTime.parse(addedAt);

          final spotifySong = SpotifySong(
            track['uri'],
            name: songName,
            addedAt: dateTime,
          );

          if (dateTime.isAfter(filterStartDate)) {
            playlistSongs.add(spotifySong);
          } else {
            fallbackSongs.add(spotifySong);
          }
        }

        if (items.length < limit) {
          break;
        }
        offset += limit;
      } else {
        throw Exception(
            'Failed to load playlist songs: ${response.statusCode}');
      }
    }

    fallbackSongs.sort((a, b) {
      if (a.addedAt == null || b.addedAt == null) {
        return 0;
      }
      return a.addedAt!.isBefore(b.addedAt!) ? 1 : -1;
    });
    return PlaylistSongs(
      playlistSongs: playlistSongs,
      fallbackSongs: fallbackSongs,
    );
  }

  Future<List<Artist>> getUserSavedArtists() async {
    final response = await _dio.get('/v1/me/following?type=artist');
    if (response.statusCode == 200) {
      return response.data['artists']['items']
          .map<Artist>((artist) => Artist(
                artist['id'],
                name: artist['name'],
                imageUrl: artist['images']?[0]['url'],
                spotifyUrl: artist['external_urls']['spotify'],
              ))
          .toList();
    }
    return [];
  }

  Future<List<SpotifySong>> getPopularTracks(String artistId) async {
    final response = await _dio.get('/v1/artists/$artistId/top-tracks');
    if (response.statusCode == 200) {
      return response.data['tracks']
          .map<SpotifySong>(
              (track) => SpotifySong(track['uri'], name: track['name']))
          .toList();
    }
    return [];
  }
}
