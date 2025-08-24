import 'package:mixafy/database_helper.dart';
import 'package:mixafy/entities/selectable_item.dart';
import 'package:mixafy/entities/time_range.dart';

class Mix {
  final String mixName;
  final String userId;
  final List<SelectableItem> items;
  final bool includeSavedTracks;
  final TimeRange timeRange;

  Mix({
    required this.mixName,
    required this.userId,
    required this.items,
    required this.includeSavedTracks,
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
