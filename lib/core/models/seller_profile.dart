class SellerProfile {
  const SellerProfile({
    required this.name,
    required this.university,
    required this.campus,
    required this.isVerified,
    required this.rating,
    required this.reviewCount,
    required this.activeListings,
    required this.soldCount,
    required this.memberSince,
    required this.phone,
    required this.bio,
    this.responseTime = 'Usually replies within 1h',
  });

  final String name;
  final String university;
  final String campus;
  final bool isVerified;
  final double rating;
  final int reviewCount;
  final int activeListings;
  final int soldCount;
  final String memberSince;
  final String phone;
  final String bio;
  final String responseTime;

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';
}
