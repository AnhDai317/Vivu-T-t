class SpringDestination {
  final String id;
  final String name;
  final String location;
  final String category;
  final String emoji;
  final String description;
  final double rating;
  final int checkins;
  final double lat;
  final double lng;
  final bool isHot;
  final String imagePath; // ← đổi từ imageUrl

  const SpringDestination({
    required this.id,
    required this.name,
    required this.location,
    required this.category,
    required this.emoji,
    required this.description,
    required this.rating,
    required this.checkins,
    required this.lat,
    required this.lng,
    this.isHot = false,
    this.imagePath = '', // ← đổi
  });
}