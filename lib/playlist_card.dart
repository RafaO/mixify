import 'package:flutter/material.dart';
import 'package:mixify/entities/SpotifyPlaylist.dart';

class PlaylistCard extends StatelessWidget {
  final SpotifyPlaylist playlist;
  final Function(dynamic) onRemove;

  const PlaylistCard({
    super.key,
    required this.playlist,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      child: Stack(
        children: [
          if (playlist.imageUrl != null)
            Image.network(
              playlist.imageUrl!!,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.topRight,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: IconButton(
              icon: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
              onPressed: () {
                onRemove(playlist); // Call the function to remove the playlist
              },
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                playlist.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
