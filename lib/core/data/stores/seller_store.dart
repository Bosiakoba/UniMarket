import 'package:flutter/foundation.dart';

import '../../api/api_client.dart';
import '../../api/session_mode.dart';
import '../../services/firebase_auth_service.dart';
import '../../models/app_user.dart';
import '../../constants/app_assets.dart';
import '../../constants/verification_criteria.dart';
import '../../models/listing_availability.dart';
import '../../models/record_sale_result.dart';
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
        availabilityType: ListingAvailabilityType.stock,
        quantityAvailable: 10,
        unitsSold: 2,
      ),
      views: 84,
      messages: 4,
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
        availabilityType: ListingAvailabilityType.ongoing,
        unitsSold: 5,
      ),
      views: 56,
      messages: 7,
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
        lifecycleStatus: ListingLifecycleStatus.sold,
        unitsSold: 1,
      ),
      views: 210,
      messages: 14,
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
        lifecycleStatus: ListingLifecycleStatus.sold,
        unitsSold: 1,
      ),
      views: 97,
      messages: 6,
      postedLabel: 'Sold · 1 month ago',
    ),
  ];

  SellerApplicationStatus sellerApplicationStatus =
      SellerApplicationStatus.none;
  VerificationStatus verificationStatus = VerificationStatus.none;
  SellerApplication? sellerApplication;
  final List<SellerListingRecord> _records = [];
  List<ListingItem> _remoteCatalog = [];
  bool useRemoteCatalog = false;
  bool isSyncingCatalog = false;
  String? catalogSyncError;

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

  List<ListingItem> get activeListings =>
      _records.where((r) => r.isActive).map((r) => r.listing).toList();

  List<ListingItem> get allListings {
    if (useRemoteCatalog) {
      final ownedIds = _records.map((r) => r.listing.id).toSet();
      final remoteOnly = _remoteCatalog.where(
        (l) => !ownedIds.contains(l.canonicalId),
      );
      return [...activeListings, ...remoteOnly];
    }
    return [...activeListings, ...MockListings.items];
  }

  List<ListingItem> listingsForSeller(String sellerName) {
    final merged = <String, ListingItem>{};

    void put(ListingItem listing) {
      if (listing.sellerName != sellerName) return;
      merged[listing.canonicalId] = listing;
    }

    for (final record in _records) {
      put(record.listing);
    }
    for (final listing in _remoteCatalog) {
      put(listing);
    }
    if (!useRemoteCatalog) {
      for (final listing in MockListings.items) {
        put(listing);
      }
    }

    final items = merged.values.toList()
      ..sort((a, b) {
        final activeCompare =
            (a.isBrowseable ? 0 : 1).compareTo(b.isBrowseable ? 0 : 1);
        if (activeCompare != 0) return activeCompare;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    return items;
  }

  SellerListingRecord? recordFor(String listingId) {
    for (final record in _records) {
      if (record.listing.id == listingId) return record;
    }
    return null;
  }

  bool ownsListing(String listingId) => recordFor(listingId) != null;

  int get activeCount => _records.where((r) => r.isActive).length;

  int get soldCount =>
      _records.fold<int>(0, (sum, record) => sum + record.listing.unitsSold);

  int get totalListings => _records.length;

  int get totalViews => _records.fold<int>(0, (sum, r) => sum + r.views);

  int get totalMessages => _records.fold<int>(0, (sum, r) => sum + r.messages);

  int get sellerReviewCount =>
      _records.fold<int>(0, (sum, r) => sum + r.listing.reviewCount);

  double get sellerRating {
    final rated = _records.where((r) => r.listing.reviewCount > 0).toList();
    if (rated.isEmpty) return 0;

    final totalScore = rated.fold<double>(
      0,
      (sum, r) => sum + (r.listing.rating * r.listing.reviewCount),
    );
    final totalReviews = rated.fold<int>(
      0,
      (sum, r) => sum + r.listing.reviewCount,
    );
    if (totalReviews == 0) return 0;
    return totalScore / totalReviews;
  }

  int get daysAsSeller {
    final appliedAt = sellerApplication?.appliedAt;
    if (appliedAt == null) return 0;
    return DateTime.now().difference(appliedAt).inDays;
  }

  String get storeName => sellerApplication?.storeName ?? MockProfile.name;

  bool get hasStudentIdOnFile => sellerApplication?.studentIdUploaded ?? false;

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
  }

  Future<String?> submitSellerApplicationRemote({
    required SellerApplication data,
    required ApiClient client,
    String? idDocumentUrl,
  }) async {
    sellerApplication = data;
    sellerApplicationStatus = SellerApplicationStatus.pending;
    notifyListeners();

    if (!isLiveSession(client)) {
      _simulateSellerApprovalReview();
      return null;
    }

    try {
      await client.submitSellerApplication(
        storeName: data.storeName,
        studentEmail: data.studentEmail,
        idDocumentUrl: idDocumentUrl,
      );
      final user = await client.fetchMe();
      applyUserProfile(user);
      notifyListeners();
      return null;
    } catch (error) {
      final message = error.toString();
      if (message.contains('already under review')) {
        try {
          final user = await client.fetchMe();
          applyUserProfile(user);
          notifyListeners();
          return null;
        } catch (_) {
          // fall through to reset below
        }
      }

      sellerApplicationStatus = SellerApplicationStatus.none;
      sellerApplication = null;
      notifyListeners();
      return message;
    }
  }

  void _simulateSellerApprovalReview() {
    Future.delayed(const Duration(seconds: 4), () {
      if (sellerApplicationStatus == SellerApplicationStatus.pending) {
        sellerApplicationStatus = SellerApplicationStatus.approved;
        notifyListeners();
      }
    });
  }

  Future<String?> submitVerificationApplication({ApiClient? client}) async {
    if (!canApplyForVerification) {
      return 'Complete the seller requirements first.';
    }

    verificationStatus = VerificationStatus.pending;
    notifyListeners();

    if (client == null || !isLiveSession(client)) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        verificationStatus = VerificationStatus.verified;
        _refreshListingVerificationFlags();
        notifyListeners();
      });
      return null;
    }

    try {
      final user = await client.applyVerifyBadge();
      applyUserProfile(user);
      notifyListeners();
      return null;
    } catch (error) {
      verificationStatus = VerificationStatus.none;
      notifyListeners();
      return error.toString();
    }
  }

  @Deprecated('Use submitVerificationApplication')
  void submitVerificationApplicationLocal() {
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
      draft.discountPercent =
          listing.discountPercent ??
          PostListingDraft.discountPercentOptions.first;
      draft.discountValidDays =
          listing.discountDurationDays ?? listing.discountDaysRemaining;
      draft.price = listing.originalPrice!.toStringAsFixed(0);
    } else {
      draft.price = listing.price.toStringAsFixed(0);
    }

    draft.availabilityType = listing.availabilityType;
    draft.stockQuantity = listing.quantityAvailable ?? draft.stockQuantity;

    return draft;
  }

  Future<String?> publishListing({
    required PostListingDraft draft,
    ApiClient? client,
  }) async {
    final authError = await _prepareListingPublish(draft, client);
    if (authError != null) return authError;

    try {
      final photoUrls = await _resolvePhotoUrls(draft, client!);
      if (photoUrls.isEmpty) {
        return 'Add at least one photo from your gallery or camera.';
      }

      final listPrice = double.parse(draft.price.trim());
      final pricing = _resolveDiscountPricing(draft, listPrice);
      final listing = await client.createListing(
        title: draft.title.trim(),
        description: draft.description.trim(),
        price: pricing.salePrice,
        category: draft.category,
        condition: draft.condition,
        meetupLocation: draft.meetupLocation,
        tags: draft.tags,
        attributes: draft.attributes,
        photoUrls: photoUrls,
        originalPrice: pricing.originalPrice,
        discountEndsAt: pricing.discountEndsAt,
        discountDurationDays: pricing.discountDurationDays,
        availabilityType: draft.availabilityType.name,
        quantityAvailable: draft.resolvedQuantityAvailable,
      );
      _upsertOwnedListing(_listingWithUploadedPhotos(listing, photoUrls));
      notifyListeners();
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> updateListingRemote({
    required String listingId,
    required PostListingDraft draft,
    ApiClient? client,
  }) async {
    final authError = await _prepareListingPublish(draft, client);
    if (authError != null) return authError;

    try {
      final photoUrls = await _resolvePhotoUrls(draft, client!);
      if (photoUrls.isEmpty) {
        return 'Add at least one photo from your gallery or camera.';
      }

      final listPrice = double.parse(draft.price.trim());
      final pricing = _resolveDiscountPricing(draft, listPrice);
      final listing = await client.updateListing(
        listingId: listingId,
        title: draft.title.trim(),
        description: draft.description.trim(),
        price: pricing.salePrice,
        category: draft.category,
        condition: draft.condition,
        meetupLocation: draft.meetupLocation,
        tags: draft.tags,
        attributes: draft.attributes,
        photoUrls: photoUrls,
        originalPrice: pricing.originalPrice,
        discountEndsAt: pricing.discountEndsAt,
        discountDurationDays: pricing.discountDurationDays,
        availabilityType: draft.availabilityType.name,
        quantityAvailable: draft.resolvedQuantityAvailable,
      );
      _upsertOwnedListing(_listingWithUploadedPhotos(listing, photoUrls));
      notifyListeners();
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> _prepareListingPublish(
    PostListingDraft draft,
    ApiClient? client,
  ) async {
    final hasDevicePhotos = draft.photoAssets.any(PostListingDraft.isLocalFile);
    final hasBundledPhotos = draft.photoAssets.any(PostListingDraft.isBundledAsset);

    if (client == null) {
      if (hasDevicePhotos) {
        return 'Sign in to publish photos from your gallery or camera.';
      }
      if (hasBundledPhotos) {
        publish(draft);
        return null;
      }
      return 'Add at least one photo.';
    }

    if (client.idToken == null) {
      final token = await FirebaseAuthService.getIdToken();
      if (token != null) {
        client.idToken = token;
      }
    }

    if (client.idToken == null) {
      if (hasDevicePhotos) {
        return 'Sign in to publish photos from your gallery or camera.';
      }
      if (hasBundledPhotos) {
        publish(draft);
        return null;
      }
      return 'Add at least one photo.';
    }

    return null;
  }

  Future<List<String>> _resolvePhotoUrls(
    PostListingDraft draft,
    ApiClient client,
  ) async {
    final urls = <String>[];
    for (final photo in draft.photoAssets) {
      if (PostListingDraft.isRemotePhoto(photo)) {
        urls.add(photo);
      } else if (PostListingDraft.isLocalFile(photo)) {
        urls.add(await client.uploadListingPhoto(photo));
      }
    }

    if (draft.photoAssets.isNotEmpty && urls.isEmpty) {
      throw ApiException(
        'Could not prepare your listing photos. Try re-adding them.',
      );
    }

    return urls;
  }

  ListingItem _listingWithUploadedPhotos(
    ListingItem listing,
    List<String> uploadedUrls,
  ) {
    final remotePhotos = listing.photoUrls
        .where((url) => url.trim().isNotEmpty)
        .toList();
    if (remotePhotos.isNotEmpty) return listing;

    final photos = uploadedUrls.where((url) => url.trim().isNotEmpty).toList();
    if (photos.isEmpty) return listing;

    return listing.copyWith(
      photoUrls: photos,
      imageAsset: photos.first,
    );
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

    final photos = draft.photoAssets
        .where(
          (photo) =>
              PostListingDraft.isRemotePhoto(photo) ||
              PostListingDraft.isLocalFile(photo),
        )
        .toList();

    return ListingItem(
      id: id,
      title: draft.title.trim(),
      price: pricing.salePrice,
      imageAsset: photos.isNotEmpty ? photos.first : '',
      photoUrls: photos,
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
      availabilityType: draft.availabilityType,
      quantityAvailable: draft.resolvedQuantityAvailable,
      unitsSold: preserveFrom?.unitsSold ?? 0,
      lifecycleStatus:
          preserveFrom?.lifecycleStatus ?? ListingLifecycleStatus.active,
    );
  }

  ({
    double salePrice,
    double? originalPrice,
    DateTime? discountEndsAt,
    int? discountDurationDays,
  })
  _resolveDiscountPricing(PostListingDraft draft, double listPrice) {
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
      discountEndsAt: DateTime.now().add(
        Duration(days: draft.discountValidDays),
      ),
      discountDurationDays: draft.discountValidDays,
    );
  }

  Future<({String? error, String? saleId})> recordSale({
    required String listingId,
    required int units,
    ApiClient? client,
  }) async {
    final index = _records.indexWhere((r) => r.listing.id == listingId);
    if (index == -1) return (error: 'Listing not found.', saleId: null);

    if (client != null && isLiveSession(client)) {
      try {
        final result = await client.recordSale(
          listingId: listingId,
          units: units,
        );
        _applySaleResult(index, result);
        notifyListeners();
        return (error: null, saleId: result.saleId);
      } catch (error) {
        return (error: error.toString(), saleId: null);
      }
    }

    final error = _applyLocalSale(index, units);
    if (error != null) return (error: error, saleId: null);
    notifyListeners();
    return (
      error: null,
      saleId: 'local-${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<String?> restockListing({
    required String listingId,
    required int quantity,
    ApiClient? client,
  }) async {
    final index = _records.indexWhere((r) => r.listing.id == listingId);
    if (index == -1) return 'Listing not found.';

    if (client != null && isLiveSession(client)) {
      try {
        final updated = await client.restockListing(
          listingId: listingId,
          quantity: quantity,
        );
        _records[index] = _records[index].copyWithListing(updated);
        notifyListeners();
        return null;
      } catch (error) {
        return error.toString();
      }
    }

    final listing = _records[index].listing;
    if (listing.availabilityType != ListingAvailabilityType.stock) {
      return 'Only stock listings can be restocked.';
    }

    _records[index] = _records[index].copyWithListing(
      listing.copyWith(
        quantityAvailable: (listing.quantityAvailable ?? 0) + quantity,
        lifecycleStatus: ListingLifecycleStatus.active,
      ),
    );
    notifyListeners();
    return null;
  }

  Future<String?> relistListing({
    required String listingId,
    ApiClient? client,
  }) async {
    final index = _records.indexWhere((r) => r.listing.id == listingId);
    if (index == -1) return 'Listing not found.';

    if (client != null && isLiveSession(client)) {
      try {
        final updated = await client.relistListing(listingId: listingId);
        _records[index] = _records[index].copyWithListing(updated);
        notifyListeners();
        return null;
      } catch (error) {
        return error.toString();
      }
    }

    final listing = _records[index].listing;
    if (listing.availabilityType != ListingAvailabilityType.unique) {
      return 'Only one-of-a-kind listings can be relisted this way.';
    }

    _records[index] = _records[index].copyWithListing(
      listing.copyWith(lifecycleStatus: ListingLifecycleStatus.active),
    );
    notifyListeners();
    return null;
  }

  @Deprecated('Use recordSale instead')
  void markAsSold(String listingId) {
    _applyLocalSale(_records.indexWhere((r) => r.listing.id == listingId), 1);
    notifyListeners();
  }

  void markAsActive(String listingId) {
    final index = _records.indexWhere((r) => r.listing.id == listingId);
    if (index == -1) return;

    _records[index] = _records[index].copyWithListing(
      _records[index].listing.copyWith(
        lifecycleStatus: ListingLifecycleStatus.active,
        unitsSold:
            _records[index].listing.availabilityType ==
                ListingAvailabilityType.unique
            ? 0
            : _records[index].listing.unitsSold,
      ),
    );
    notifyListeners();
  }

  String? _applyLocalSale(int index, int units) {
    if (index == -1) return 'Listing not found.';

    final record = _records[index];
    final listing = record.listing;
    final normalizedUnits = units.clamp(1, 999);

    ListingItem updated;
    switch (listing.availabilityType) {
      case ListingAvailabilityType.ongoing:
        updated = listing.copyWith(
          unitsSold: listing.unitsSold + normalizedUnits,
          lifecycleStatus: ListingLifecycleStatus.active,
        );
      case ListingAvailabilityType.stock:
        final remaining = listing.quantityAvailable ?? 0;
        if (remaining <= 0) {
          return 'Listing is sold out. Restock before recording another sale.';
        }
        if (normalizedUnits > remaining) {
          return 'Only $remaining unit(s) remain in stock.';
        }
        final nextRemaining = remaining - normalizedUnits;
        updated = listing.copyWith(
          quantityAvailable: nextRemaining,
          unitsSold: listing.unitsSold + normalizedUnits,
          lifecycleStatus: nextRemaining <= 0
              ? ListingLifecycleStatus.soldOut
              : ListingLifecycleStatus.active,
        );
      case ListingAvailabilityType.unique:
        if (normalizedUnits != 1) {
          return 'Unique listings can only record one sale at a time.';
        }
        updated = listing.copyWith(
          unitsSold: 1,
          lifecycleStatus: ListingLifecycleStatus.sold,
        );
    }

    _records[index] = record
        .copyWithListing(updated)
        .copyWith(
          postedLabel:
              listing.availabilityType == ListingAvailabilityType.ongoing
              ? '${updated.unitsSold} completed'
              : updated.lifecycleStatus == ListingLifecycleStatus.active
              ? record.postedLabel
              : 'Sold · just now',
        );
    return null;
  }

  void _applySaleResult(int index, RecordSaleResult result) {
    final record = _records[index];
    final updatedListing = result.listing;
    _records[index] = record
        .copyWithListing(updatedListing)
        .copyWith(
          postedLabel:
              updatedListing.availabilityType == ListingAvailabilityType.ongoing
              ? '${updatedListing.unitsSold} completed'
              : updatedListing.isBrowseable
              ? record.postedLabel
              : 'Sold · just now',
        );
  }

  Future<String?> deleteListingRemote({
    required String listingId,
    ApiClient? client,
  }) async {
    if (client != null && isLiveSession(client)) {
      try {
        await client.deleteListing(listingId);
      } catch (error) {
        return error.toString();
      }
    }

    deleteListing(listingId);
    return null;
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
    _remoteCatalog = [];
    useRemoteCatalog = false;
    isSyncingCatalog = false;
    catalogSyncError = null;
    sellerApplication = null;
    sellerApplicationStatus = SellerApplicationStatus.none;
    verificationStatus = VerificationStatus.none;
    notifyListeners();
  }

  Future<void> syncFromApi(ApiClient client, {required AppUser user}) async {
    isSyncingCatalog = true;
    catalogSyncError = null;
    notifyListeners();

    try {
      if (!isLiveSession(client)) {
        client.devUserId = user.id;
      }
      final items = await client.fetchListings();
      _remoteCatalog = items;
      useRemoteCatalog = true;
      if (isLiveSession(client)) {
        _records.clear();
      }
      applyUserProfile(user);

      for (final item in items.where(_isOwnedByUser(user))) {
        _upsertOwnedListing(item);
      }
    } catch (error) {
      catalogSyncError = error.toString();
      if (!isLiveSession(client)) {
        if (user.email.toLowerCase() == MockProfile.email.toLowerCase()) {
          loadDemoSellerState(displayName: user.fullName, email: user.email);
        }
      } else {
        _records.clear();
        _remoteCatalog = [];
        useRemoteCatalog = true;
      }
    } finally {
      isSyncingCatalog = false;
      notifyListeners();
    }
  }

  void applyUserProfile(AppUser user) {
    sellerApplicationStatus = _mapSellerApplicationStatus(
      user.sellerApplicationStatus,
      user.isSeller,
    );
    verificationStatus = _mapVerificationStatus(
      user.verificationBadgeStatus,
      user.isVerified,
    );

    if (sellerApplicationStatus == SellerApplicationStatus.approved ||
        sellerApplicationStatus == SellerApplicationStatus.pending ||
        sellerApplicationStatus == SellerApplicationStatus.rejected) {
      sellerApplication = SellerApplication(
        fullName: user.fullName,
        studentEmail: user.email,
        storeName: user.storeName ??
            sellerApplication?.storeName ??
            user.fullName,
        studentIdUploaded: true,
        appliedAt: sellerApplication?.appliedAt ?? DateTime.now(),
      );
    } else if (sellerApplicationStatus == SellerApplicationStatus.none) {
      sellerApplication = null;
    }

    if (verificationStatus == VerificationStatus.verified) {
      _refreshListingVerificationFlags();
    }
  }

  SellerApplicationStatus _mapSellerApplicationStatus(
    String status,
    bool isSeller,
  ) {
    return switch (status.toLowerCase()) {
      'pending' => SellerApplicationStatus.pending,
      'rejected' => SellerApplicationStatus.rejected,
      'approved' => SellerApplicationStatus.approved,
      _ =>
        isSeller
            ? SellerApplicationStatus.approved
            : SellerApplicationStatus.none,
    };
  }

  VerificationStatus _mapVerificationStatus(String status, bool isVerified) {
    return switch (status.toLowerCase()) {
      'pending' => VerificationStatus.pending,
      'rejected' => VerificationStatus.none,
      'approved' => VerificationStatus.verified,
      _ => isVerified ? VerificationStatus.verified : VerificationStatus.none,
    };
  }

  Future<void> refreshApplicationStatus({
    required ApiClient client,
    required void Function(AppUser user) onUserUpdated,
  }) async {
    if (!isLiveSession(client)) return;

    final user = await client.fetchMe();
    onUserUpdated(user);
    applyUserProfile(user);
    notifyListeners();
  }

  void _upsertOwnedListing(ListingItem listing) {
    final index = _records.indexWhere((r) => r.listing.id == listing.id);
    var resolved = listing;

    if (resolved.photoUrls.isEmpty && index >= 0) {
      final existing = _records[index].listing;
      if (existing.photoUrls.isNotEmpty) {
        resolved = resolved.copyWith(
          photoUrls: existing.photoUrls,
          imageAsset: existing.primaryPhotoSource,
        );
      }
    }

    if (index >= 0) {
      _records[index] = _records[index].copyWithListing(resolved);
      return;
    }

    _records.add(
      SellerListingRecord(
        listing: resolved,
        views: 0,
        messages: 0,
        postedLabel: 'From server',
        description: resolved.title,
        photoAssets: resolved.displayPhotos,
      ),
    );
  }

  bool Function(ListingItem listing) _isOwnedByUser(AppUser user) {
    return (listing) {
      if (listing.sellerUserId.isNotEmpty) {
        return listing.sellerUserId == user.id;
      }
      return listing.sellerName == user.fullName;
    };
  }
}
