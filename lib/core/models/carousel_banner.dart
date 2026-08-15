class CarouselBanner {
  const CarouselBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.routePath,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String routePath;
  final DateTime createdAt;

  factory CarouselBanner.fromJson(Map<String, dynamic> json) {
    return CarouselBanner(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      routePath: json['routePath'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'routePath': routePath,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
