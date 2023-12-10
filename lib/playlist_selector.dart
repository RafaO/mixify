import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PlaylistSelector extends StatefulWidget {
  final Function(dynamic) onPlaylistAdded;
  final String accessToken;

  const PlaylistSelector({
    Key? key,
    required this.accessToken,
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
    fetchPlaylists();
  }

  Future<void> fetchPlaylists() async {
    const url = 'https://api.spotify.com/v1/me/playlists';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${widget.accessToken}',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      setState(() {
        playlists = List<Map<String, dynamic>>.from(data['items']);
      });
    } else {
      print('Failed to load playlists: ${response.statusCode}');
    }
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
