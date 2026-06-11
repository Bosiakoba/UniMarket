class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.university,
    required this.campus,
    this.phone,
    this.avatarUrl,
    this.interestCategories = const {},
    this.createdAt,
    this.firebaseUid,
  });

  final String id;
  final String email;
  final String fullName;
  final String university;
  final String campus;
  final String? phone;
  final String? avatarUrl;
  final Set<String> interestCategories;
  final DateTime? createdAt;
  /// Placeholder until Firebase Auth is wired.
  final String? firebaseUid;

  String get displayInitial =>
      fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

  AppUser copyWith({
    String? fullName,
    String? university,
    String? campus,
    String? phone,
    String? avatarUrl,
    Set<String>? interestCategories,
  }) {
    return AppUser(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      university: university ?? this.university,
      campus: campus ?? this.campus,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      interestCategories: interestCategories ?? this.interestCategories,
      createdAt: createdAt,
      firebaseUid: firebaseUid,
    );
  }
}
