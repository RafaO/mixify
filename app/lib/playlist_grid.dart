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
  TimeRange selectedTimeRange = TimeRange.oneMonth();

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
    final theme = Theme.of(context);

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
            : Column(
                children: [
                  const Text(
                    'Mixing songs added to the lists in the last...',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTimeBubble(
                            '1 Month', TimeRange.oneMonth(), theme),
                        _buildTimeBubble(
                            '3 Months', TimeRange.threeMonths(), theme),
                        _buildTimeBubble('1 Year', TimeRange.oneYear(), theme),
                        _buildTimeBubble('Anytime', TimeRange.forever(), theme),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: playlists.isEmpty
                        ? _buildEmptyState(context, theme)
                        : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
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
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: playlists.isEmpty
            ? Colors.grey.shade400
            : theme.colorScheme.primary,
        onPressed: playlists.isEmpty
            ? null
            : () async {
                _showProgressDialog(context);

                try {
                  await SpotifyHelper(apiService: widget.apiService).playMix(
                    playlists,
                    selectedTimeRange,
                    () {
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      _showAlertDialog(context);
                    },
                  );
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                } catch (e) {
                  Navigator.of(context).pop(); // Close progress dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('An error occurred.'),
                    ),
                  );
                }
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
            color: playlists.isEmpty ? Colors.grey.shade700 : Colors.black,
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
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note,
            size: 80.0,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16.0),
          Text(
            'No playlists added yet!',
            style: TextStyle(
              fontSize: 18.0,
              color: theme.colorScheme.onSurfaceVariant,
            ),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text(
              'Add a Playlist',
              style: TextStyle(fontSize: 16.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBubble(String label, TimeRange timeRange, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTimeRange = timeRange;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          color: selectedTimeRange == timeRange
              ? theme.colorScheme.secondary
              : Colors.transparent,
          border: Border.all(color: theme.colorScheme.secondary),
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selectedTimeRange == timeRange
                ? Colors.black
                : theme.colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showProgressDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: const Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text(
                  'We are preparing your mix and sending it over to Spotify...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.0),
                ),
              ],
            ),
          ),
        );
      },
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
