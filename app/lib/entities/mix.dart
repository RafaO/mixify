import 'package:mixafy/database_helper.dart';
import 'package:mixafy/entities/time_range.dart';
import 'package:mixafy/playlist_selector.dart';

class Mix {
  final String mixName;
  final String userId;
  final List<SelectableItem> playlists;
  final TimeRange timeRange;

  Mix({
    required this.mixName,
    required this.userId,
    required this.playlists,
    required this.timeRange,
  });

  Future<bool> save() async {
    final db = DatabaseHelper();
    await db.saveMix(this);
    return true;
  }

  static Future<List<Mix>> loadAllMixes() async {
    final db = DatabaseHelper();
    return await db.loadAllMixes();
  }
}
