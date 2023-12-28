import 'package:flutter/material.dart';
import 'package:mixify/api_service.dart';
import 'package:mixify/entities/SpotifyPlaylist.dart';
import 'package:mixify/playlist_card.dart';
import 'package:mixify/playlist_selector.dart';
import 'package:mixify/spotify_helper.dart';

class PlaylistGrid extends StatefulWidget {
  final APIService apiService;

  const PlaylistGrid({Key? key, required this.apiService}) : super(key: key);

  @override
  State<PlaylistGrid> createState() => _PlaylistGridState();
}

class _PlaylistGridState extends State<PlaylistGrid> {
  List<SpotifyPlaylist> playlists = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mixify'),
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
            return PlaylistCard(
              playlist: playlist,
              onRemove: (playlistToRemove) {
                setState(() {
                  playlists.remove(playlistToRemove);
                });
              },
            );
          } else {
            return Card(
              elevation: 4.0,
              child: IconButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => PlaylistSelector(
                      apiService: widget.apiService,
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
        onPressed: playlists.isEmpty
            ? null
            : () async {
                SpotifyHelper(apiService: widget.apiService).playMix(playlists,
                    () {
                  // advice the user to open the spotify app in any device
                  // get user's devices (for now this only returns the active devices)
                  // https://community.spotify.com/t5/Spotify-for-Developers/v1-me-player-devices-returns-empty-array/m-p/5224904/thread-id/2752
                  if (!context.mounted) return;
                  _showAlertDialog(context);
                });
              },
        child: const Icon(Icons.play_arrow),
      ),
    );
  }

  void _showAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Could not start'),
          content: const Text(
              'Please start your Spotify app in any device and try again.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
