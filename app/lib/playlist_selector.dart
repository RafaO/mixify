import 'package:flutter/material.dart';
import 'package:mixafy/api_service.dart';
import 'package:mixafy/entities/spotify_playlist.dart';

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
  bool isLoading = true;

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
      isLoading = false;
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
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final hintTextColor =
        onSurfaceColor.withOpacity(0.6); // Slightly faded for hint text

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/Spotify_Icon_CMYK_Black.png',
              width: 24.0,
              height: 24.0,
            ),
            const SizedBox(width: 10),
            const Text('Spotify Playlists'),
          ],
        ),
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
              decoration: InputDecoration(
                filled: true,
                // Use surface color for the background
                labelText: 'Search Playlists',
                labelStyle: TextStyle(color: onSurfaceColor),
                // Label text color
                hintText: 'Enter playlist name...',
                hintStyle: TextStyle(color: hintTextColor),
                // Faded hint text
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.cancel_outlined),
                        onPressed: () {
                          searchController.text = "";
                          _filterPlaylists("");
                        },
                      )
                    : null,
                border: UnderlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                  child: filteredPlaylists.isEmpty
                      ? const Center(
                          child: Text("No playlists found"),
                        )
                      : ListView.builder(
                          itemCount: filteredPlaylists.length,
                          itemBuilder: (context, index) {
                            final playlist = filteredPlaylists[index];
                            final isSelected =
                                selectedPlaylists.contains(playlist);
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              elevation: 4.0,
                              child: SizedBox(
                                // height: 80.0, // Fixed height for each row
                                child: ListTile(
                                  leading: playlist.imageUrl != null
                                      ? CircleAvatar(
                                          backgroundImage:
                                              NetworkImage(playlist.imageUrl!),
                                        )
                                      : const CircleAvatar(
                                          backgroundColor: Colors.grey,
                                          child: Icon(Icons.music_note),
                                        ),
                                  title: Text(
                                    playlist.name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  onTap: () {
                                    _togglePlaylistSelection(playlist);
                                  },
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        )
                                      : const Icon(Icons.circle_outlined),
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ],
      ),
    );
  }
}
