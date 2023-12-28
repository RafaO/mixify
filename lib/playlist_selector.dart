import 'package:flutter/material.dart';
import 'package:mixify/api_service.dart';
import 'package:mixify/entities/SpotifyPlaylist.dart';

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
  late List<SpotifyPlaylist> playlists;
  late List<SpotifyPlaylist> filteredPlaylists;

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    playlists = [];
    filteredPlaylists = [];
    _fetchPlaylists();
  }

  Future<void> _fetchPlaylists() async {
    List<SpotifyPlaylist> fetchedPlaylists =
        await widget.apiService.fetchPlaylists();
    setState(() {
      playlists = fetchedPlaylists;
      filteredPlaylists = fetchedPlaylists;
    });
  }

  void _filterPlaylists(String query) {
    List<SpotifyPlaylist> filtered = playlists
        .where((playlist) => playlist.name
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();
    setState(() {
      filteredPlaylists = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spotify Playlists'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                _filterPlaylists(value);
              },
              decoration: const InputDecoration(
                labelText: 'Search Playlists',
                hintText: 'Enter playlist name...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: filteredPlaylists.isEmpty
                ? const Center(
                    child: Text("No playlist found"),
                  )
                : ListView.builder(
                    itemCount: filteredPlaylists.length,
                    itemBuilder: (context, index) {
                      final playlist = filteredPlaylists[index];
                      return ListTile(
                        title: Text(playlist.name),
                        subtitle:
                            Text(playlist.description ?? 'No description'),
                        onTap: () {
                          widget.onPlaylistAdded(playlist);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
