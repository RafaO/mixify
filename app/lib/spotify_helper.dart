import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mixify/api_service.dart';
import 'package:mixify/entities/spotify_playlist.dart';
import 'package:mixify/entities/spotify_song.dart';
import 'package:mixify/entities/time_range.dart';

class SpotifyHelper {
  final APIService _apiService;

  SpotifyHelper({required APIService apiService}) : _apiService = apiService;

  void playMix(
    List<SpotifyPlaylist> playlists,
    TimeRange timeRange,
    void Function() onError,
  ) async {
    String deviceId = await _apiService.getActiveDevice();

    if (deviceId.isEmpty) {
      onError();
      return;
    }

    final listOfSongs = await _apiService.fetchAndMixAllSongsFromPlaylists(
      playlists.map((playlist) => playlist.id).toList(),
      timeRange,
    );

    bool isFirstSong = true;

    for (SpotifySong song in listOfSongs) {
      await _apiService.addSongToQueue(song.id, deviceId);

      if (isFirstSong) {
        debugPrint("first song is: ${song.name}");

        isFirstSong = false;
        try {
          await _apiService.pause(deviceId);
        } on DioError catch (e) {
          if (e.response?.statusCode == 403) {
            // do nothing, the player is already paused
          }
        }
        SpotifySong? currentTrack;
        while (
            (currentTrack = await _apiService.currentTrack())?.id != song.id) {
          debugPrint("skipping to next song");
          debugPrint(
              "the song ${currentTrack?.name} is different from ${song.name}");
          await _apiService.skipToNextSong(deviceId);
        }
        _apiService.play(deviceId);
      }
    }
  }
}
