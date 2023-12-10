import 'dart:convert';

import 'package:http/http.dart' as http;

class SpotifySong {
  final String name;
  final String artist;
  final String id;

  SpotifySong(this.id, {required this.name, required this.artist});
}

Future<List<SpotifySong>> fetchAllSongsFromPlaylists(
  List<String> playlistIds,
  String accessToken,
) async {
  List<SpotifySong> allSongs = [];

  for (String playlistId in playlistIds) {
    final playlistSongs =
        await _fetchSongsFromPlaylist(playlistId, accessToken);
    allSongs.addAll(playlistSongs);
  }

  allSongs.shuffle();

  return allSongs;
}

Future<List<SpotifySong>> _fetchSongsFromPlaylist(
  String playlistId,
  String accessToken,
) async {
  final url = 'https://api.spotify.com/v1/playlists/$playlistId/tracks';

  final response = await http.get(
    Uri.parse(url),
    headers: {
      'Authorization': 'Bearer $accessToken',
    },
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = jsonDecode(response.body);
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
