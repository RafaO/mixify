import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mixify/playlist_selector.dart';
import 'package:mixify/spotify_helper.dart';

class PlaylistGrid extends StatefulWidget {
  final String accessToken;

  const PlaylistGrid({Key? key, required this.accessToken}) : super(key: key);

  @override
  State<PlaylistGrid> createState() => _PlaylistGridState();
}

class _PlaylistGridState extends State<PlaylistGrid> {
  List<Map<String, dynamic>> playlists = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spotify Playlists'),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Number of columns in the grid
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: playlists.length + 1,
        itemBuilder: (context, index) {
          if (index < playlists.length) {
            final playlist = playlists[index];
            return Card(
              elevation: 4.0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.library_music),
                  const SizedBox(height: 8.0),
                  Text(
                    playlist['name'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          } else {
            return Card(
              elevation: 4.0,
              child: IconButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => PlaylistSelector(
                      accessToken: widget.accessToken,
                      onPlaylistAdded: (playlist) {
                        setState(() {
                          playlists.add(playlist);
                        });
                      },
                    ),
                  ));
                },
                icon: const Icon(Icons.add),
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final response = await http.get(
            Uri.parse('https://api.spotify.com/v1/me/player/devices'),
            headers: {
              'Authorization': 'Bearer ${widget.accessToken}',
            },
          );

          final Map data = jsonDecode(response.body);
          String deviceId = '';
          if (data['devices'] != null && data['devices'].length > 0) {
            // get the first one that is active
            deviceId = data['devices'].first['id'];

            // use this if we want to get the active device only
            // final activeDevice = data['devices'].firstWhere(
            //     (device) => device['is_active'] == true,
            //     orElse: () => null);
            // if (activeDevice != null) {
            //   deviceId = activeDevice['id'];
            // }
          } else {
            // advice the user to open the spotify app in any device
            // get user's devices (for now this only returns the active devices)
            // https://community.spotify.com/t5/Spotify-for-Developers/v1-me-player-devices-returns-empty-array/m-p/5224904/thread-id/2752
          }

          if (deviceId.isNotEmpty) {
            final listOfSongs = await fetchAllSongsFromPlaylists(
              playlists.map((playlist) => playlist['id'] as String).toList(),
              widget.accessToken,
            );

            bool isFirstSong = true;

            for (SpotifySong song in listOfSongs) {
              // add song to queue
              final response = await http.post(
                Uri.parse(
                    'https://api.spotify.com/v1/me/player/queue?uri=${song.id}&device_id=$deviceId'),
                headers: {
                  'Authorization': 'Bearer ${widget.accessToken}',
                },
              );

              if (isFirstSong) {
                isFirstSong = false;
                while (await currentTrack() != song.id) {
                  await skipToNextSong(deviceId);
                }

                final response = await http.put(
                  Uri.parse(
                      'https://api.spotify.com/v1/me/player/play?device_id=$deviceId'),
                  headers: {
                    'Authorization': 'Bearer ${widget.accessToken}',
                  },
                );
                debugPrint("${response.statusCode} ${response.body}");
              }
              debugPrint("${response.statusCode} ${response.body}");
            }
          }
        },
        child: const Icon(Icons.play_arrow),
      ),
    );
  }

  Future<void> skipToNextSong(String deviceId) async {
    await http.post(
      Uri.parse(
          'https://api.spotify.com/v1/me/player/next?device_id=$deviceId'),
      headers: {
        'Authorization': 'Bearer ${widget.accessToken}',
      },
    );
  }

  Future<String> currentTrack() async {
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/me/player/currently-playing'),
      headers: {
        'Authorization': 'Bearer ${widget.accessToken}',
      },
    );

    if (response.statusCode != 200) {
      return '';
    }

    return jsonDecode(response.body)['item']['uri'];
  }
}
