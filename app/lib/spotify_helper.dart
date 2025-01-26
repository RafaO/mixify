import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mixify/api_service.dart';
import 'package:mixify/entities/spotify_playlist.dart';
import 'package:mixify/entities/spotify_song.dart';
import 'package:mixify/entities/time_range.dart';

class SpotifyHelper {
  final APIService _apiService;

  SpotifyHelper({required APIService apiService}) : _apiService = apiService;

  Future<void> playMix(
    List<SpotifyPlaylist> playlists,
    TimeRange timeRange,
    void Function() onError,
  ) async {
    try {
      // Step 1: Get the active device
      String deviceId = await _apiService.getActiveDevice();
      if (deviceId.isEmpty) {
        debugPrint("No active device found.");
        onError();
        return;
      }

      // Step 2: Fetch and mix songs from playlists
      final listOfSongs = await _apiService.fetchAndMixAllSongsFromPlaylists(
        playlists.map((playlist) => playlist.id).toList(),
        timeRange,
      );

      if (listOfSongs.isEmpty) {
        debugPrint("No songs found in the playlists.");
        onError();
        return;
      }

      // Step 3: Add songs to the queue and handle playback
      bool isFirstSong = true;

      for (SpotifySong song in listOfSongs) {
        await _apiService.addSongToQueue(song.id, deviceId);

        if (isFirstSong) {
          debugPrint("First song is: ${song.name}");
          isFirstSong = false;

          // Ensure the player is paused before starting
          try {
            await _apiService.pause(deviceId);
          } on DioError catch (e) {
            if (e.response?.statusCode == 403) {
              debugPrint("Player is already paused.");
            }
          }

          // Ensure the correct song starts playing
          SpotifySong? currentTrack;
          while ((currentTrack = await _apiService.currentTrack())?.id !=
              song.id) {
            debugPrint(
              "Skipping to next song. Current: ${currentTrack?.name}, Expected: ${song.name}",
            );
            await _apiService.skipToNextSong(deviceId);
          }

          // Play the song
          await _apiService.play(deviceId);
        }
      }

      debugPrint("Mix successfully played.");
    } catch (e) {
      debugPrint("An error occurred: $e");
      onError();
    }
  }
}
