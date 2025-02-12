import 'package:flutter/material.dart';
import 'package:mixafy/database_helper.dart';
import 'package:mixafy/entities/mix.dart';

class MixListScreen extends StatefulWidget {
  final List<Mix> mixes;
  final Function(Mix) onMixSelected;

  const MixListScreen(
      {Key? key, required this.mixes, required this.onMixSelected})
      : super(key: key);

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
        title: const Text('Delete Mix'),
        content: const Text(
            'Are you sure you want to delete this mix? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
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
            const SnackBar(content: Text('Failed to delete mix')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Mixes')),
      body: mixes.isEmpty
          ? const Center(child: Text('No saved mixes yet!'))
          : ListView.builder(
              itemCount: mixes.length,
              itemBuilder: (context, index) {
                final mix = mixes[index];

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ExpansionTile(
                    title: Text(mix.mixName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Songs added in the last: ${mix.timeRange}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
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
                          icon: const Icon(Icons.delete, color: Colors.white),
                          onPressed: () => _deleteMix(mix),
                        ),
                      ],
                    ),
                    children: [
                      Column(
                        children: mix.playlists.map((playlist) {
                          return Card(
                            child: ListTile(
                              leading: playlist.imageUrl != null
                                  ? Image.network(
                                      playlist.imageUrl!,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.music_note),
                              title: Text(playlist.name),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
