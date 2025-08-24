import 'package:flutter/material.dart';
import 'package:mixafy/entities/selectable_item.dart';

class SaveMixScreen extends StatefulWidget {
  final List<SelectableItem> items;
  final Function(String mixName) onSave;

  const SaveMixScreen({
    super.key,
    required this.items,
    required this.onSave,
  });

  @override
  State<SaveMixScreen> createState() => _SaveMixScreenState();
}

class _SaveMixScreenState extends State<SaveMixScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Save Mix'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Mix Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Playlists in this mix:',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: widget.items.isEmpty
                  ? const Center(child: Text("No playlists selected"))
                  : ListView.builder(
                      itemCount: widget.items.length,
                      itemBuilder: (context, index) {
                        final playlist = widget.items[index];
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
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  final mixName = _nameController.text.trim();
                  if (mixName.isNotEmpty) {
                    widget.onSave(mixName);
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32.0, vertical: 12.0),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: const Text('Save Mix'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
