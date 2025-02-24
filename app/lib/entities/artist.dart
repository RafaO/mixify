import 'package:mixafy/entities/selectable_item.dart';

class Artist implements SelectableItem {
  @override
  final String id;
  @override
  final String name;
  @override
  final String? imageUrl;
  @override
  final String? description;

  Artist(this.id,
      {required this.name, required this.imageUrl, this.description});
}
