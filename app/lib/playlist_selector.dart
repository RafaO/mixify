import 'package:flutter/material.dart';
import 'package:mixafy/api_service.dart';
import 'package:mixafy/entities/artist.dart';
import 'package:mixafy/entities/spotify_playlist.dart';

class PlaylistSelector extends StatefulWidget {
  final APIService apiService;
  final Function(List<SpotifyPlaylist>) onSelectedPlaylists;
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

class _PlaylistSelectorState extends State<PlaylistSelector>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<SpotifyPlaylist> playlists;
  late List<SpotifyPlaylist> filteredPlaylists;
  late List<Artist> artists;
  late List<Artist> filteredArtists;
  late List<SpotifyPlaylist> selectedPlaylists;
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    playlists = [];
    filteredPlaylists = [];
    artists = [];
    filteredArtists = [];
    selectedPlaylists = List.from(widget.alreadySelectedPlaylists);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _clearSearch();
      }
    });
    _fetchData();
  }

  Future<void> _fetchData() async {
    final fetchedPlaylists = await widget.apiService.fetchPlaylists();
    final fetchedArtists = await widget.apiService.getUserSavedArtists();
    setState(() {
      playlists = fetchedPlaylists;
      filteredPlaylists = fetchedPlaylists;
      artists = fetchedArtists;
      filteredArtists = fetchedArtists;
      isLoading = false;
    });
  }

  void _filterItems(String query) {
    setState(() {
      if (_tabController.index == 0) { // If Playlists tab is selected
        filteredPlaylists = playlists
            .where((playlist) =>
            playlist.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      } else { // If Artists tab is selected
        filteredArtists = artists
            .where((artist) =>
            artist.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _clearSearch() {
    searchController.clear();
    _filterItems(''); // Reset the filter
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
        title: const Text('Select items'),
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
              onChanged: _filterItems,
              decoration: InputDecoration(
                labelText: 'Search',
                hintText: 'Start typing to filter',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.cancel_outlined),
                  onPressed: _clearSearch, // Clear the search
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Playlists'),
              Tab(text: 'Artists'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPlaylistList(),
                _buildArtistList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistList() {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
      itemCount: filteredPlaylists.length,
      itemBuilder: (context, index) {
        final playlist = filteredPlaylists[index];
        final isSelected = selectedPlaylists.contains(playlist);
        return ListTile(
          leading: playlist.imageUrl != null
              ? CircleAvatar(
              backgroundImage: NetworkImage(playlist.imageUrl!))
              : const Icon(Icons.music_note),
          title: Text(playlist.name),
          trailing: isSelected
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.circle_outlined),
          onTap: () => _togglePlaylistSelection(playlist),
        );
      },
    );
  }

  Widget _buildArtistList() {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
      itemCount: filteredArtists.length,
      itemBuilder: (context, index) {
        final artist = filteredArtists[index];
        return ListTile(
          title: Text(artist.name),
        );
      },
    );
  }
}
