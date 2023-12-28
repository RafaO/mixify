import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mixify/api_service.dart';
import 'package:mixify/entities/SpotifyPlaylist.dart';
import 'package:mixify/entities/SpotifySong.dart';

class SpotifyHelper {
  final APIService _apiService;

  SpotifyHelper({required APIService apiService}) : _apiService = apiService;

  void playMix(
    List<SpotifyPlaylist> playlists,
    void Function() onError,
  ) async {
    String deviceId = await _apiService.getActiveDevice();

    if (deviceId.isEmpty) {
      onError();
      return;
    }

    final listOfSongs = await _apiService.fetchAllSongsFromPlaylists(
      playlists.map((playlist) => playlist.id).toList(),
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
        while (await _apiService.currentTrack() != song.id) {
          await _apiService.skipToNextSong(deviceId);
        }
        _apiService.play(deviceId);
      }
    }
  }
}
