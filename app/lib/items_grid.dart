import 'package:flutter/material.dart';
import 'package:mixafy/api_service.dart';
import 'package:mixafy/entities/mix.dart';
import 'package:mixafy/entities/selectable_item.dart';
import 'package:mixafy/entities/time_range.dart';
import 'package:mixafy/items_selector.dart';
import 'package:mixafy/mix_list_screen.dart';
import 'package:mixafy/item_card.dart';
import 'package:mixafy/save_mix.dart';
import 'package:mixafy/spotify_helper.dart';
import 'package:mixafy/theme.dart';
import 'package:mixafy/utils.dart';

class ItemsGrid extends StatefulWidget {
  final APIService apiService;

  const ItemsGrid({Key? key, required this.apiService}) : super(key: key);

  @override
  State<ItemsGrid> createState() => _ItemsGridState();
}

class _ItemsGridState extends State<ItemsGrid> {
  List<SelectableItem> items = [];
  bool isLoading = false;
  TimeRange selectedTimeRange = TimeRange.oneMonth();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mixafy'),
        backgroundColor: greenColor,
        actions: [
          IconButton(
            onPressed: items.isEmpty
                ? null // TODO display a message to the user
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SaveMixScreen(
                          items: items,
                          onSave: saveMix,
                        ),
                      ),
                    );
                  },
            icon: const Icon(Icons.save),
          ),
          IconButton(
            onPressed: () async {
              final savedMixes = await Mix.loadAllMixes();
              // Navigate to the saved mixes list screen
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MixListScreen(
                      mixes: savedMixes,
                      onMixSelected: (Mix mix) {
                        setState(() {
                          items = mix.playlists;
                          selectedTimeRange = mix.timeRange;
                        });
                      },
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.list), // List icon to show saved mixes
          )
        ],
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
                        _buildTimeBubble(TimeRange.oneMonth(), theme),
                        _buildTimeBubble(TimeRange.threeMonths(), theme),
                        _buildTimeBubble(TimeRange.oneYear(), theme),
                        _buildTimeBubble(TimeRange.forever(), theme),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: items.isEmpty
                        ? _buildEmptyState(context, theme)
                        : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16.0,
                              mainAxisSpacing: 16.0,
                            ),
                            itemCount: items.length + 1,
                            itemBuilder: (context, index) {
                              if (index < items.length) {
                                final playlist = items[index];
                                return PlaylistCard(
                                  playlist: playlist,
                                  onRemove: (playlistToRemove) {
                                    setState(() {
                                      items.remove(playlistToRemove);
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
        backgroundColor: items.isEmpty || isLoading
            ? Colors.grey.shade400
            : theme.colorScheme.primary,
        onPressed: items.isEmpty || isLoading
            ? null
            : () async {
                setState(() => isLoading = true);
                _showProgressDialog(context);
                try {
                  Result playing =
                      await SpotifyHelper(apiService: widget.apiService)
                          .playMix(items, selectedTimeRange);

                  if (!context.mounted) return;
                  Navigator.of(context).pop();

                  if (playing.isSuccess) {
                    showMixafyDialog(
                      context: context,
                      title: 'Started!',
                      message: 'Spotify should now be playing your mix! Enjoy!',
                    );
                  } else {
                    showMixafyDialog(
                      context: context,
                      title: 'Could not start',
                      message: playing.error ??
                          'There was a problem playing your mix',
                    );
                  }
                } catch (e) {
                  debugPrint("Error playing mix: \n${e.toString()}");
                  if (context.mounted) Navigator.of(context).pop();
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (!context.mounted) return;
                  showMixafyDialog(
                    context: context,
                    title: 'Could not start',
                    message: 'There was a problem playing your mix',
                  );
                } finally {
                  if (context.mounted) setState(() => isLoading = false);
                }
              },
        icon: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.black), // Customize color
                ),
              )
            : Image.asset(
                'assets/Spotify_Icon_CMYK_Black.png',
                width: 24.0,
                height: 24.0,
                color: items.isEmpty ? Colors.grey.shade700 : null,
              ),
        label: isLoading
            ? const Text("Loading...", style: TextStyle(color: Colors.black))
            : Text(
                "Play on Spotify",
                style: TextStyle(
                  color: items.isEmpty ? Colors.grey.shade700 : Colors.black,
                ),
              ),
      ),
    );
  }

  saveMix(String mixName) async {
    // display loading icon
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing while saving
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text("Saving mix..."),
          ],
        ),
      ),
    );

    final mix = Mix(
      mixName: mixName,
      userId: "me", // TODO
      playlists: items,
      timeRange: selectedTimeRange,
    );

    bool result = await mix.save();

    // Close the loading dialog
    if (mounted) {
      Navigator.pop(context);
    }

    // Show result dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(result ? "Success" : "Error"),
          content:
              Text(result ? "Mix saved successfully!" : "Failed to save mix."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildAddButton(BuildContext context) {
    return Card(
      elevation: 6.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ItemsSelector(
              apiService: widget.apiService,
              onSelectionChanged: (selectedItems) {
                setState(() {
                  items.clear();
                  items.addAll(selectedItems);
                });
              },
              alreadySelectedItems: items,
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
            'Your mix is empty!',
            style: TextStyle(
              fontSize: 18.0,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ItemsSelector(
                  apiService: widget.apiService,
                  onSelectionChanged: (selectedItems) {
                    setState(() {
                      items.clear();
                      items.addAll(selectedItems);
                    });
                  },
                  alreadySelectedItems: items,
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
              'Add something to your mix',
              style: TextStyle(fontSize: 16.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBubble(TimeRange timeRange, ThemeData theme) {
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
          timeRange.toString(),
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
}
