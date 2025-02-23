import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mixafy/api_service.dart';
import 'package:mixafy/entities/spotify_playlist.dart';
import 'package:mixafy/entities/spotify_song.dart';
import 'package:mixafy/entities/time_range.dart';

class Result<T> {
  final T? data;
  final String? error;

  Result.success({this.data}) : error = null;

  Result.failure(this.error) : data = null;

  bool get isSuccess => error == null;
}

class SpotifyHelper {
  final APIService _apiService;

  SpotifyHelper({required APIService apiService}) : _apiService = apiService;

  Future<Result<void>> playMix(
    List<SpotifyPlaylist> playlists,
    TimeRange timeRange,
  ) async {
    // Step 1: Get the active device
    String deviceId = await _apiService.getActiveDevice();
    if (deviceId.isEmpty) {
      debugPrint("No active device found.");
      return Result.failure(
          "Please start your Spotify app on any device and try again.");
    }

    // Step 2: Fetch and mix songs from playlists
    final listOfSongs = await _apiService.fetchAndMixAllSongsFromPlaylists(
      playlists.map((playlist) => playlist.id).toList(),
      timeRange,
    );

    if (listOfSongs.isEmpty) {
      debugPrint("No songs found in the playlists.");
      return Result.failure(
          "It seems we couldn't find songs matching your criteria."
          " Please, review them and try again.");
    }

    bool useQueue = false;

    if (!useQueue) {
      await _apiService.play(deviceId, songs: listOfSongs);
    } else {
      // Step 3: Add songs to the queue and handle playback
      bool isFirstSong = true;

      for (SpotifySong song in listOfSongs) {
        debugPrint("adding song to queue");
        await _apiService.addSongToQueue(song.id, deviceId);

        if (isFirstSong) {
          debugPrint("First song is: ${song.name}");
          isFirstSong = false;

          // Ensure the player is paused before starting
          try {
            await _apiService.pause(deviceId);
          } on DioException catch (e) {
            if (e.response?.statusCode == 403) {
              debugPrint("Player is already paused.");
            }
          }

          // Ensure the correct song starts playing
          SpotifySong? currentTrack;
          while ((currentTrack = await _apiService.currentTrack()) != null &&
              currentTrack?.id != song.id) {
            debugPrint(
              "Skipping to next song. Current: ${currentTrack?.name}, Expected: ${song.name}",
            );
            await _apiService.skipToNextSong(deviceId);
          }

          // Play the song
          debugPrint("playing");
          await _apiService.play(deviceId);
        }
      }
    }
    debugPrint("Mix successfully played.");
    return Result.success();
  }
}
