import 'package:mixafy/entities/spotify_song.dart';

class PlaylistSongs {
  final List<SpotifySong> playlistSongs;
  final List<SpotifySong> fallbackSongs;

  PlaylistSongs({
    required this.playlistSongs,
    required this.fallbackSongs,
  });
}
