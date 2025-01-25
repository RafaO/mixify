import 'package:flutter/material.dart';
import 'package:mixify/api_service.dart';
import 'package:mixify/entities/spotify_playlist.dart';
import 'package:mixify/entities/time_range.dart';
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
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() {
      isLoading = true;
    });

    // Simulate loading process (replace with actual API call if needed)
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      isLoading = false;
      // Initialize playlists here if you have a default set
      playlists = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mixify',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : playlists.isEmpty
            ? _buildEmptyState(context)
            : GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
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
              return _buildAddButton(context);
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: playlists.isEmpty ? Colors.grey.shade400 : Colors.green,
        onPressed: playlists.isEmpty
            ? null
            : () async {
          SpotifyHelper(apiService: widget.apiService).playMix(
            playlists,
            TimeRange.oneMonth(),
                () {
              if (!context.mounted) return;
              _showAlertDialog(context);
            },
          );
        },
        icon: Image.asset(
          'assets/Spotify_Icon_CMYK_Black.png',
          width: 24.0,
          height: 24.0,
          color: playlists.isEmpty ? Colors.grey.shade700 : null,
        ),
        label: Text(
          "Play on Spotify",
          style: TextStyle(
            color: playlists.isEmpty ? Colors.grey.shade700 : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Card(
      elevation: 6.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => PlaylistSelector(
              apiService: widget.apiService,
              onSelectedPlaylists: (selectedPlaylists) {
                setState(() {
                  playlists.clear();
                  playlists.addAll(selectedPlaylists);
                });
              },
              alreadySelectedPlaylists: playlists,
            ),
          ));
        },
        child: const Center(
          child: Icon(
            Icons.add,
            size: 40.0,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note,
            size: 80.0,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16.0),
          const Text(
            'No playlists added yet!',
            style: TextStyle(fontSize: 18.0, color: Colors.grey),
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => PlaylistSelector(
                  apiService: widget.apiService,
                  onSelectedPlaylists: (selectedPlaylists) {
                    setState(() {
                      playlists.addAll(selectedPlaylists);
                    });
                  },
                  alreadySelectedPlaylists: playlists,
                ),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text(
              'Add a Playlist',
              style: TextStyle(fontSize: 16.0, color: Colors.white),
            ),
          ),
        ],
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
              'Please start your Spotify app on any device and try again.'),
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
