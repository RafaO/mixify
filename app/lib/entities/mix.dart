import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mixafy/entities/spotify_playlist.dart';
import 'package:mixafy/entities/time_range.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Mix {
  final String mixName;
  final String userId;
  final List<SpotifyPlaylist> playlists;
  final TimeRange timeRange;

  Mix({
    required this.mixName,
    required this.userId,
    required this.playlists,
    required this.timeRange,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() => {
    'mixName': mixName,
    'userId': userId,
    'playlistIds': playlists.map((p) => p.id).toList(),
    'timeRange': timeRange.toJson(),
  };

  // Create from JSON (Needs a method to fetch SpotifyPlaylist from ID)
  factory Mix.fromJson(Map<String, dynamic> json, List<SpotifyPlaylist> allPlaylists) {
    List<String> playlistIds = List<String>.from(json['playlistIds']);

    return Mix(
      mixName: json['mixName'],
      userId: json['userId'],
      playlists: allPlaylists.where((p) => playlistIds.contains(p.id)).toList(),
      timeRange: TimeRange.fromJson(json['timeRange']),
    );
  }

  Future<bool> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final mixData = toJson();

      return await prefs.setString('mix_$mixName', jsonEncode(mixData));
    } catch (e) {
      debugPrint("Error saving mix: $e");
      return false;
    }
  }
}

Future<List<Mix>> loadAllMixes(List<SpotifyPlaylist> allPlaylists) async {
  final prefs = await SharedPreferences.getInstance();
  final mixes = <Mix>[];

  for (String key in prefs.getKeys()) {
    if (key.startsWith('mix_')) {
      final jsonString = prefs.getString(key);
      if (jsonString != null) {
        final jsonData = jsonDecode(jsonString);
        mixes.add(Mix.fromJson(jsonData, allPlaylists));
      }
    }
  }

  return mixes;
}
