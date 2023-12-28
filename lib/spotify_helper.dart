import 'package:flutter/material.dart';
import 'package:mixify/api_service.dart';

class SpotifyHelper {
  final APIService _apiService;

  SpotifyHelper({required APIService apiService}) : _apiService = apiService;

  void playMix(
    List<Map<String, dynamic>> playlists,
    void Function() onError,
  ) async {
    String deviceId = await _apiService.getActiveDevice();

    if (deviceId.isEmpty) {
      onError();
      return;
    }

    final listOfSongs = await _apiService.fetchAllSongsFromPlaylists(
      playlists.map((playlist) => playlist['id'] as String).toList(),
    );

    bool isFirstSong = true;

    for (SpotifySong song in listOfSongs) {
      await _apiService.addSongToQueue(song.id, deviceId);

      if (isFirstSong) {
        debugPrint("first song is: ${song.name}");

        isFirstSong = false;
        await _apiService.pause(deviceId);
        while (await _apiService.currentTrack() != song.id) {
          await _apiService.skipToNextSong(deviceId);
        }
        _apiService.play(deviceId);
      }
    }
  }
}
