import 'package:flutter/material.dart';
import 'package:mixify/api_service.dart';
import 'package:mixify/entities/SpotifyPlaylist.dart';

class PlaylistSelector extends StatefulWidget {
  final Function(List<SpotifyPlaylist>) onSelectedPlaylists;
  final APIService apiService;
  final List<SpotifyPlaylist> alreadySelectedPlaylists;

  const PlaylistSelector({
    Key? key,
    required this.apiService,
    required this.onSelectedPlaylists,
    required this.alreadySelectedPlaylists,
  }) : super(key: key);

  @override
  State<PlaylistSelector> createState() => _PlaylistSelectorState();
}

class _PlaylistSelectorState extends State<PlaylistSelector> {
  late List<SpotifyPlaylist> playlists;
  late List<SpotifyPlaylist> filteredPlaylists;
  late List<SpotifyPlaylist> selectedPlaylists;

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    playlists = [];
    filteredPlaylists = [];
    _fetchPlaylists();
    selectedPlaylists = List.from(widget.alreadySelectedPlaylists);
  }

  Future<void> _fetchPlaylists() async {
    List<SpotifyPlaylist> fetchedPlaylists =
        await widget.apiService.fetchPlaylists();
    setState(() {
      playlists = fetchedPlaylists;
      filteredPlaylists = fetchedPlaylists;
      selectedPlaylists = List.from(widget.alreadySelectedPlaylists);
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

  void _togglePlaylistSelection(SpotifyPlaylist playlist) {
    setState(() {
      if (selectedPlaylists.contains(playlist)) {
        selectedPlaylists.remove(playlist);
      } else {
        selectedPlaylists.add(playlist);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spotify Playlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              widget.onSelectedPlaylists(selectedPlaylists);
              Navigator.pop(context);
            },
          ),
        ],
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
                      final isSelected = selectedPlaylists.contains(playlist);
                      return ListTile(
                        title: Text(playlist.name),
                        subtitle:
                            Text(playlist.description ?? 'No description'),
                        onTap: () {
                          _togglePlaylistSelection(playlist);
                        },
                        trailing: isSelected
                            ? IconButton(
                                icon: const Icon(Icons.check),
                                onPressed: () {
                                  _togglePlaylistSelection(playlist);
                                },
                              )
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
