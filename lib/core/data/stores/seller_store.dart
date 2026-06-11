import 'package:flutter/foundation.dart';

import '../../constants/app_assets.dart';
import '../../constants/verification_criteria.dart';
import '../../models/listing_item.dart';
import '../../models/post_listing_draft.dart';
import '../../models/seller_application.dart';
import '../../models/seller_application_status.dart';
import '../../models/seller_listing_record.dart';
import '../../models/verification_status.dart';
import '../mock/mock_listings.dart';
import '../mock/mock_profile.dart';

class SellerStore extends ChangeNotifier {
  SellerStore();

  static final _seedRecords = [
    SellerListingRecord(
      listing: const ListingItem(
        id: 'p1',
        title: 'Calculus textbook — 3rd edition',
        price: 45,
        imageAsset: AppAssets.ob1Collage3,
        sellerName: MockProfile.name,
        isVerified: false,
        distanceKm: 0,
        category: 'Books & Stationery',
        tags: ['textbook', 'calculus', 'engineering'],
        rating: 4.8,
        reviewCount: 6,
      ),
      views: 128,
      messages: 9,
      status: ListingStatus.active,
      postedLabel: '2 weeks ago',
    ),
    SellerListingRecord(
      listing: ListingItem(
        id: 'p2',
        title: 'USB-C hub for MacBook',
        price: 52,
        originalPrice: 65,
        discountEndsAt: DateTime.now().add(const Duration(days: 5)),
        discountDurationDays: 7,
        imageAsset: AppAssets.ob1Collage9,
        sellerName: MockProfile.name,
        isVerified: false,
        distanceKm: 0,
        category: 'Computers & Accessories',
        tags: ['macbook', 'usb-c', 'accessories'],
        rating: 5.0,
        reviewCount: 3,
      ),
      views: 84,
      messages: 4,
      status: ListingStatus.active,
      postedLabel: '1 week ago',
      description:
          '7-in-1 USB-C hub with HDMI and SD card reader. Works great with MacBook Air and Pro.',
      condition: 'Like new',
      meetupLocation: 'Main Campus',
      photoAssets: [AppAssets.ob1Collage9],
    ),
    SellerListingRecord(
      listing: const ListingItem(
        id: 'p3',
        title: 'Logo design — campus clubs',
        price: 80,
        imageAsset: AppAssets.ob1Collage7,
        sellerName: MockProfile.name,
        isVerified: false,
        distanceKm: 0,
        category: 'Services & Gigs',
        tags: ['design', 'logo', 'freelance'],
        rating: 4.9,
        reviewCount: 11,
      ),
      views: 56,
      messages: 7,
      status: ListingStatus.active,
      postedLabel: '5 days ago',
    ),
    SellerListingRecord(
      listing: const ListingItem(
        id: 'p4',
        title: 'Economics notes bundle — Level 100',
        price: 30,
        imageAsset: AppAssets.ob1Collage3,
        sellerName: MockProfile.name,
        isVerified: false,
        distanceKm: 0,
        category: 'Courses & Notes',
        tags: ['notes', 'economics', 'level 100'],
        rating: 4.7,
        reviewCount: 2,
      ),
      views: 210,
      messages: 14,
      status: ListingStatus.sold,
      postedLabel: 'Sold · 3 weeks ago',
    ),
    SellerListingRecord(
      listing: const ListingItem(
        id: 'p5',
        title: 'Mini desk lamp — hostel',
        price: 25,
        imageAsset: AppAssets.ob1Collage5,
        sellerName: MockProfile.name,
        isVerified: false,
        distanceKm: 0,
        category: 'Hostel & Room Essentials',
        tags: ['lamp', 'hostel', 'desk'],
        rating: 4.6,
        reviewCount: 1,
      ),
      views: 97,
      messages: 6,
      status: ListingStatus.sold,
      postedLabel: 'Sold · 1 month ago',
    ),
  ];

  SellerApplicationStatus sellerApplicationStatus =
      SellerApplicationStatus.none;
  VerificationStatus verificationStatus = VerificationStatus.none;
  SellerApplication? sellerApplication;
  final List<SellerListingRecord> _records = [];

  bool get isSeller =>
      sellerApplicationStatus == SellerApplicationStatus.approved;

  bool get sellerApplicationPending =>
      sellerApplicationStatus == SellerApplicationStatus.pending;

  bool get sellerApplicationRejected =>
      sellerApplicationStatus == SellerApplicationStatus.rejected;

  bool get hasSellerApplication =>
      sellerApplicationStatus != SellerApplicationStatus.none;

  bool get isVerified => verificationStatus == VerificationStatus.verified;

  bool get verificationPending =>
      verificationStatus == VerificationStatus.pending;

  List<SellerListingRecord> get listingRecords =>
      List.unmodifiable(_records.reversed.toList());

  List<ListingItem> get myListings =>
      listingRecords.map((r) => r.listing).toList();

  List<ListingItem> get activeListings => _records
      .where((r) => r.isActive)
      .map((r) => r.listing)
      .toList();

  List<ListingItem> get allListings => [...activeListings, ...MockListings.items];

  SellerListingRecord? recordFor(String listingId) {
    for (final record in _records) {
      if (record.listing.id == listingId) return record;
    }
    return null;
  }

  bool ownsListing(String listingId) => recordFor(listingId) != null;

  int get activeCount => _records.where((r) => r.isActive).length;

  int get soldCount => _records.where((r) => !r.isActive).length;

  int get totalListings => _records.length;

  int get totalViews => _records.fold<int>(0, (sum, r) => sum + r.views);

  int get totalMessages => _records.fold<int>(0, (sum, r) => sum + r.messages);

  double get sellerRating => MockProfile.rating;

  int get daysAsSeller {
    final appliedAt = sellerApplication?.appliedAt;
    if (appliedAt == null) return 0;
    return DateTime.now().difference(appliedAt).inDays;
  }

  String get storeName =>
      sellerApplication?.storeName ?? MockProfile.name;

  bool get hasStudentIdOnFile =>
      sellerApplication?.studentIdUploaded ?? false;

  bool get meetsSalesCriteria =>
      soldCount >= VerificationCriteria.minCompletedSales;

  bool get meetsRatingCriteria =>
      sellerRating >= VerificationCriteria.minSellerRating;

  bool get meetsTenureCriteria =>
      daysAsSeller >= VerificationCriteria.minDaysAsSeller;

  bool get meetsListingsCriteria =>
      totalListings >= VerificationCriteria.minTotalListings;

  bool get canApplyForVerification =>
      isSeller &&
      !isVerified &&
      !verificationPending &&
      hasStudentIdOnFile &&
      meetsSalesCriteria &&
      meetsRatingCriteria &&
      meetsTenureCriteria &&
      meetsListingsCriteria;

  void submitSellerApplication(SellerApplication data) {
    sellerApplication = data;
    sellerApplicationStatus = SellerApplicationStatus.pending;
    notifyListeners();
    _simulateSellerApprovalReview();
  }

  void _simulateSellerApprovalReview() {
    Future.delayed(const Duration(seconds: 4), () {
      if (sellerApplicationStatus == SellerApplicationStatus.pending) {
        sellerApplicationStatus = SellerApplicationStatus.approved;
        notifyListeners();
      }
    });
  }

  void submitVerificationApplication() {
    if (!canApplyForVerification) return;
    verificationStatus = VerificationStatus.pending;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 1200), () {
      verificationStatus = VerificationStatus.verified;
      _refreshListingVerificationFlags();
      notifyListeners();
    });
  }

  PostListingDraft? draftForListing(String listingId) {
    final record = recordFor(listingId);
    if (record == null) return null;

    final listing = record.listing;
    final savedDescription = record.description.trim();
    final draft = PostListingDraft(
      photoAssets: List.of(record.allPhotoAssets),
      title: listing.title,
      description: savedDescription.isNotEmpty
          ? savedDescription
          : '${listing.title} — listed in ${listing.category} on campus.',
      category: listing.category,
      tags: List.of(listing.tags),
      attributes: Map.of(listing.attributes),
      condition: record.condition,
      meetupLocation: record.meetupLocation,
    );

    if (listing.hasActiveDiscount) {
      draft.enableDiscount = true;
      draft.discountPercent = listing.discountPercent ??
          PostListingDraft.discountPercentOptions.first;
      draft.discountValidDays = listing.discountDurationDays ??
          listing.discountDaysRemaining;
      draft.price = listing.originalPrice!.toStringAsFixed(0);
    } else {
      draft.price = listing.price.toStringAsFixed(0);
    }

    return draft;
  }

  ListingItem publish(PostListingDraft draft) {
    final listing = _listingFromDraft(
      draft,
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
    );
    _records.insert(
      0,
      SellerListingRecord(
        listing: listing,
        views: 0,
        messages: 0,
        status: ListingStatus.active,
        postedLabel: 'Just now',
        description: draft.description.trim(),
        condition: draft.condition,
        meetupLocation: draft.meetupLocation,
        photoAssets: List.of(draft.photoAssets),
      ),
    );
    notifyListeners();
    return listing;
  }

  void updateListing(String listingId, PostListingDraft draft) {
    final index = _records.indexWhere((r) => r.listing.id == listingId);
    if (index == -1) return;

    final existing = _records[index];
    final listing = _listingFromDraft(
      draft,
      id: listingId,
      preserveFrom: existing.listing,
    );

    _records[index] = existing
        .copyWith(
          description: draft.description.trim(),
          condition: draft.condition,
          meetupLocation: draft.meetupLocation,
          photoAssets: List.of(draft.photoAssets),
          postedLabel: 'Updated · just now',
        )
        .copyWithListing(listing);
    notifyListeners();
  }

  ListingItem _listingFromDraft(
    PostListingDraft draft, {
    required String id,
    ListingItem? preserveFrom,
  }) {
    final listPrice = double.parse(draft.price.trim());
    final pricing = _resolveDiscountPricing(draft, listPrice);

    return ListingItem(
      id: id,
      title: draft.title.trim(),
      price: pricing.salePrice,
      imageAsset: draft.photoAssets.first,
      sellerName: storeName,
      isVerified: isVerified,
      distanceKm: preserveFrom?.distanceKm ?? 0,
      category: draft.category,
      tags: List.of(draft.tags),
      attributes: Map.of(draft.attributes),
      rating: preserveFrom?.rating ?? 4.8,
      reviewCount: preserveFrom?.reviewCount ?? 0,
      sellerRating: preserveFrom?.sellerRating ?? sellerRating,
      sellerReviewCount:
          preserveFrom?.sellerReviewCount ?? MockProfile.reviewCount,
      originalPrice: pricing.originalPrice,
      discountEndsAt: pricing.discountEndsAt,
      discountDurationDays: pricing.discountDurationDays,
    );
  }

  ({
    double salePrice,
    double? originalPrice,
    DateTime? discountEndsAt,
    int? discountDurationDays,
  }) _resolveDiscountPricing(PostListingDraft draft, double listPrice) {
    if (!draft.enableDiscount) {
      return (
        salePrice: listPrice,
        originalPrice: null,
        discountEndsAt: null,
        discountDurationDays: null,
      );
    }

    final sale = listPrice * (1 - draft.discountPercent / 100);
    return (
      salePrice: sale.roundToDouble(),
      originalPrice: listPrice,
      discountEndsAt:
          DateTime.now().add(Duration(days: draft.discountValidDays)),
      discountDurationDays: draft.discountValidDays,
    );
  }

  void markAsSold(String listingId) {
    _updateRecord(
      listingId,
      (record) => record.copyWith(
        status: ListingStatus.sold,
        postedLabel: 'Sold · just now',
      ),
    );
  }

  void markAsActive(String listingId) {
    _updateRecord(
      listingId,
      (record) => record.copyWith(
        status: ListingStatus.active,
        postedLabel: 'Reposted · just now',
      ),
    );
  }

  void deleteListing(String listingId) {
    _records.removeWhere((record) => record.listing.id == listingId);
    notifyListeners();
  }

  void _refreshListingVerificationFlags() {
    for (var i = 0; i < _records.length; i++) {
      final record = _records[i];
      final listing = record.listing;
      _records[i] = record.copyWithListing(
        listing.copyWith(isVerified: isVerified),
      );
    }
  }

  void _updateRecord(
    String listingId,
    SellerListingRecord Function(SellerListingRecord record) transform,
  ) {
    final index = _records.indexWhere((r) => r.listing.id == listingId);
    if (index == -1) return;
    _records[index] = transform(_records[index]);
    notifyListeners();
  }

  void loadDemoSellerState({String? displayName, String? email}) {
    _records
      ..clear()
      ..addAll(_seedRecords);
    sellerApplication = SellerApplication(
      fullName: displayName ?? MockProfile.name,
      studentEmail: email ?? MockProfile.email,
      storeName: displayName ?? MockProfile.name,
      studentIdUploaded: true,
      appliedAt: DateTime.now().subtract(const Duration(days: 21)),
    );
    sellerApplicationStatus = SellerApplicationStatus.approved;
    verificationStatus = VerificationStatus.none;
    notifyListeners();
  }

  void resetForSignOut() {
    _records.clear();
    sellerApplication = null;
    sellerApplicationStatus = SellerApplicationStatus.none;
    verificationStatus = VerificationStatus.none;
    notifyListeners();
  }
}
