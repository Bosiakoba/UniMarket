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
    this.profileComplete = false,
    this.sellerApplicationStatus = 'none',
    this.verificationBadgeStatus = 'none',
    this.storeName,
    this.storeDescription,
    this.hasPhysicalStore = false,
    this.storeAddress,
    this.createdAt,
    this.firebaseUid,
    this.isSeller = false,
    this.isVerified = false,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isFollowing = false,
  });

  final String id;
  final String email;
  final String fullName;
  final String university;
  final String campus;
  final String? phone;
  final String? avatarUrl;
  final Set<String> interestCategories;
  final bool profileComplete;
  final String sellerApplicationStatus;
  final String verificationBadgeStatus;
  final String? storeName;
  final String? storeDescription;
  final bool hasPhysicalStore;
  final String? storeAddress;
  final DateTime? createdAt;
  /// Placeholder until Firebase Auth is wired.
  final String? firebaseUid;
  final bool isSeller;
  final bool isVerified;
  final int followersCount;
  final int followingCount;
  final bool isFollowing;

  String get displayInitial =>
      fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final categories =
        (json['interestCategories'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toSet() ??
        const <String>{};

    return AppUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      university: json['university'] as String? ?? 'State University',
      campus: json['campus'] as String? ?? 'Main Campus',
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      interestCategories: categories,
      profileComplete: json['profileComplete'] as bool? ?? false,
      sellerApplicationStatus:
          json['sellerApplicationStatus'] as String? ?? 'none',
      verificationBadgeStatus:
          json['verificationBadgeStatus'] as String? ?? 'none',
      storeName: json['storeName'] as String?,
      storeDescription: json['storeDescription'] as String?,
      hasPhysicalStore: json['hasPhysicalStore'] as bool? ?? false,
      storeAddress: json['storeAddress'] as String?,
      firebaseUid: json['firebaseUid'] as String?,
      isSeller: json['isSeller'] as bool? ?? false,
      isVerified: json['isVerified'] as bool? ?? false,
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      isFollowing: json['isFollowing'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'university': university,
      'campus': campus,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'interestCategories': interestCategories.toList(),
      'profileComplete': profileComplete,
      'sellerApplicationStatus': sellerApplicationStatus,
      'verificationBadgeStatus': verificationBadgeStatus,
      'storeName': storeName,
      'storeDescription': storeDescription,
      'hasPhysicalStore': hasPhysicalStore,
      'storeAddress': storeAddress,
      'createdAt': createdAt?.toIso8601String(),
      'firebaseUid': firebaseUid,
      'isSeller': isSeller,
      'isVerified': isVerified,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'isFollowing': isFollowing,
    };
  }

  AppUser copyWith({
    String? fullName,
    String? university,
    String? campus,
    String? phone,
    String? avatarUrl,
    Set<String>? interestCategories,
    bool? profileComplete,
    String? sellerApplicationStatus,
    String? verificationBadgeStatus,
    String? storeName,
    String? storeDescription,
    bool? hasPhysicalStore,
    String? storeAddress,
    bool? isSeller,
    bool? isVerified,
    int? followersCount,
    int? followingCount,
    bool? isFollowing,
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
      profileComplete: profileComplete ?? this.profileComplete,
      sellerApplicationStatus:
          sellerApplicationStatus ?? this.sellerApplicationStatus,
      verificationBadgeStatus:
          verificationBadgeStatus ?? this.verificationBadgeStatus,
      storeName: storeName ?? this.storeName,
      storeDescription: storeDescription ?? this.storeDescription,
      hasPhysicalStore: hasPhysicalStore ?? this.hasPhysicalStore,
      storeAddress: storeAddress ?? this.storeAddress,
      createdAt: createdAt,
      firebaseUid: firebaseUid,
      isSeller: isSeller ?? this.isSeller,
      isVerified: isVerified ?? this.isVerified,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}
