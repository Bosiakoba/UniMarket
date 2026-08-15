class ListingReview {
  const ListingReview({
    required this.id,
    required this.authorName,
    required this.rating,
    required this.body,
    required this.dateLabel,
  });

  final String id;
  final String authorName;
  final double rating;
  final String body;
  final String dateLabel;

  String get authorInitial =>
      authorName.isNotEmpty ? authorName[0].toUpperCase() : '?';
}
