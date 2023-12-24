import 'package:flutter/material.dart';
import 'package:mixify/api_service.dart';

class PlaylistSelector extends StatefulWidget {
  final Function(dynamic) onPlaylistAdded;
  final APIService apiService;

  const PlaylistSelector({
    Key? key,
    required this.apiService,
    required this.onPlaylistAdded,
  }) : super(key: key);

  @override
  State<PlaylistSelector> createState() => _PlaylistSelectorState();
}

class _PlaylistSelectorState extends State<PlaylistSelector> {
  List<Map<String, dynamic>> playlists = [];

  @override
  void initState() {
    super.initState();
    widget.apiService
        .fetchPlaylists()
        .then((value) => setState(() => playlists = value));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spotify Playlists'),
      ),
      body: playlists.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                return ListTile(
                  title: Text(playlist['name']),
                  subtitle: Text(playlist['description'] ?? 'No description'),
                  onTap: () {
                    widget.onPlaylistAdded(playlist);
                    Navigator.pop(context);
                  },
                );
              },
            ),
    );
  }
}
