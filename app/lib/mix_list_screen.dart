import 'package:flutter/material.dart';
import 'package:mixafy/database_helper.dart';
import 'package:mixafy/entities/mix.dart';

class MixListScreen extends StatefulWidget {
  final List<Mix> mixes;
  final Function(Mix) onMixSelected;

  const MixListScreen({
    super.key,
    required this.mixes,
    required this.onMixSelected,
  });

  @override
  MixListScreenState createState() => MixListScreenState();
}

class MixListScreenState extends State<MixListScreen> {
  List<Mix> mixes = [];

  @override
  void initState() {
    super.initState();
    mixes = List.from(widget.mixes);
  }

  Future<void> _deleteMix(Mix mix) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 10),
            Text('Delete Mix'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this mix? This action cannot be undone.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = DatabaseHelper();
      final success = await db.deleteMix(mix.mixName);
      if (success) {
        setState(() {
          mixes.remove(mix);
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete mix'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Mixes'),
      ),
      body: mixes.isEmpty
          ? const Center(
              child: Text(
                'No saved mixes yet!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            )
          : ListView.builder(
              itemCount: mixes.length,
              padding: const EdgeInsets.all(10),
              itemBuilder: (context, index) {
                final mix = mixes[index];

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    childrenPadding: const EdgeInsets.only(bottom: 10),
                    title: Text(
                      mix.mixName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Text(
                      'Songs added in the last: ${mix.timeRange}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    trailing: Wrap(
                      spacing: 5,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.play_arrow, color: Colors.green),
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onMixSelected(mix);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteMix(mix),
                        ),
                      ],
                    ),
                    children: [
                      if (mix.includeSavedTracks)
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 5),
                          leading: SizedBox(
                            width: 50,
                            height: 50,
                            child: Icon(
                              Icons.favorite,
                              color: Colors.green,
                              size: 40,
                            ),
                          ),
                          title: const Text(
                            'Your Liked Songs',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ...mix.items.map((playlist) {
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 5),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: playlist.imageUrl != null
                                ? Image.network(
                                    playlist.imageUrl!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.music_note,
                                    size: 40, color: Colors.grey),
                          ),
                          title: Text(
                            playlist.name,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
