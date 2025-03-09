class SpotifySong {
  final String name;
  final String id;
  final DateTime? addedAt;

  SpotifySong(
    this.id, {
    required this.name,
    this.addedAt,
  });
}
