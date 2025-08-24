import 'dart:async';

import 'package:mixafy/entities/mix.dart';
import 'package:mixafy/entities/spotify_playlist.dart';
import 'package:mixafy/entities/time_range.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = await getDatabasesPath();
    final dbPath = join(path, 'mixafy.db');

    return await openDatabase(
      dbPath,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
  CREATE TABLE mixes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    mixName TEXT UNIQUE,
    userId TEXT,
    timeRange TEXT,
    includeSavedTracks INTEGER DEFAULT 0
  )
''');

        await db.execute('''
  CREATE TABLE playlists (
    id TEXT PRIMARY KEY,
    name TEXT,
    description TEXT,
    imageUrl TEXT
  )
''');

        await db.execute('''
  CREATE TABLE mix_playlists (
    mixId INTEGER,
    playlistId TEXT,
    FOREIGN KEY (mixId) REFERENCES mixes(id) ON DELETE CASCADE,
    FOREIGN KEY (playlistId) REFERENCES playlists(id) ON DELETE CASCADE,
    PRIMARY KEY (mixId, playlistId)
  )
''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE mixes ADD COLUMN includeSavedTracks INTEGER DEFAULT 0');
        }
      },
    );
  }

  Future<void> saveMix(Mix mix) async {
    final db = await database;
    final mixId = await db.insert(
      'mixes',
      {
        'mixName': mix.mixName,
        'userId': mix.userId,
        'timeRange': mix.timeRange.toJson(),
        'includeSavedTracks': mix.includeSavedTracks ? 1 : 0
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    for (var playlist in mix.items) {
      await db.insert(
        'playlists',
        {
          'id': playlist.id,
          'name': playlist.name,
          'description': playlist.description,
          'imageUrl': playlist.imageUrl
        },
        conflictAlgorithm:
            ConflictAlgorithm.ignore, // Prevent duplicate inserts
      );

      await db.insert(
        'mix_playlists',
        {'mixId': mixId, 'playlistId': playlist.id},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<List<Mix>> loadAllMixes() async {
    final db = await database;
    final List<Map<String, dynamic>> mixRows = await db.query('mixes');
    List<Mix> mixes = [];

    for (var mixRow in mixRows) {
      final mixId = mixRow['id'];
      final playlistRows = await db.rawQuery('''
      SELECT p.* FROM playlists p
      JOIN mix_playlists mp ON p.id = mp.playlistId
      WHERE mp.mixId = ?
    ''', [mixId]);

      final playlists =
          playlistRows.map((row) => SpotifyPlaylist.fromJson(row)).toList();

      mixes.add(Mix(
        mixName: mixRow['mixName'],
        userId: mixRow['userId'],
        timeRange: TimeRange.fromJson(mixRow['timeRange']),
        items: playlists,
        includeSavedTracks: (mixRow['includeSavedTracks'] ?? 0) == 1,
      ));
    }

    return mixes;
  }

  Future<bool> deleteMix(String mixName) async {
    final db = await database;
    final deleted =
        await db.delete('mixes', where: 'mixName = ?', whereArgs: [mixName]);
    return deleted == 1;
  }
}
