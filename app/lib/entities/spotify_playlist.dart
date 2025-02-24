import 'package:mixafy/items_selector.dart';

class SpotifyPlaylist implements SelectableItem {
  final String id;
  @override
  final String name;
  final String? description;
  @override
  final String? imageUrl;

  SpotifyPlaylist({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SpotifyPlaylist &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;

  // Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'imageUrl': imageUrl,
  };

  // Convert from JSON
  factory SpotifyPlaylist.fromJson(Map<String, dynamic> json) {
    return SpotifyPlaylist(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'],
    );
  }
}
