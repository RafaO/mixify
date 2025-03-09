import 'dart:math';
import 'package:mixafy/entities/spotify_song.dart';

class SongsMixer {
  final double fallbackPercentage;

  SongsMixer({this.fallbackPercentage = 0.2});

  List<SpotifySong> mix(
      Map<String, List<SpotifySong>> songsByPlaylist,
      Map<String, double> playlistPercentages,
      Map<String, List<SpotifySong>> fallbackSongsByPlaylist,
      ) {
    // Step 1: Find the largest required contribution and scale the mix accordingly
    int largestPlaylistSize = songsByPlaylist.values.fold(0, (maxSize, songs) => max(maxSize, songs.length));
    int totalSongsNeeded = (largestPlaylistSize / playlistPercentages.values.reduce(max)).round();

    // Step 2: Determine how many songs each playlist should contribute
    Map<String, int> songsAllocation = {};
    for (var entry in playlistPercentages.entries) {
      songsAllocation[entry.key] = (entry.value * totalSongsNeeded).round();
    }

    // Step 3: Fill the mix with primary and fallback songs
    List<SpotifySong> mixedSongs = [];

    for (var entry in songsAllocation.entries) {
      String playlistId = entry.key;
      int allocatedSongs = entry.value;

      List<SpotifySong> mainSongs = songsByPlaylist[playlistId] ?? [];
      List<SpotifySong> fallbackSongs = fallbackSongsByPlaylist[playlistId] ?? [];

      // Take songs from the main list
      int mainCount = min(allocatedSongs, mainSongs.length);
      mixedSongs.addAll(mainSongs.take(mainCount));

      // If not enough, take from the fallback
      int missing = allocatedSongs - mainCount;
      if (missing > 0) {
        mixedSongs.addAll(fallbackSongs.take(missing));
      }
    }
    return mixedSongs;
  }
}
