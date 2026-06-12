import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/app_assets.dart';
import '../models/app_user.dart';
import '../models/app_notification.dart';
import '../models/chat_message.dart';
import '../models/listing_availability.dart';
import '../models/listing_item.dart';
import '../models/record_sale_result.dart';
import '../models/listing_review.dart';
import '../config/api_config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final String baseUrl;
  String? devUserId;
  String? idToken;

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (idToken != null) 'Authorization': 'Bearer $idToken',
    if (idToken == null && devUserId != null) 'X-Dev-User-Id': devUserId!,
  };

  Map<String, String> get _authHeaders => {
    'Accept': 'application/json',
    if (idToken != null) 'Authorization': 'Bearer $idToken',
    if (idToken == null && devUserId != null) 'X-Dev-User-Id': devUserId!,
  };

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<Map<String, dynamic>> bootstrapSession({
    String? firebaseIdToken,
    String? devUserId,
  }) async {
    if (firebaseIdToken != null) {
      idToken = firebaseIdToken;
      this.devUserId = null;
    } else if (devUserId != null) {
      this.devUserId = devUserId;
      idToken = null;
    }

    final body = firebaseIdToken != null
        ? {'firebaseIdToken': firebaseIdToken}
        : {'devUserId': devUserId};

    final response = await http.post(
      _uri('/api/auth/session'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _decodeObject(response, errorLabel: 'Session failed');
  }

  Future<AppUser> updateProfile({
    String? fullName,
    String? university,
    String? campus,
    String? phone,
    bool? markProfileComplete,
    List<String>? interestCategories,
  }) async {
    final response = await http.put(
      _uri('/api/users/me'),
      headers: _headers,
      body: jsonEncode({
        'fullName': ?fullName,
        'university': ?university,
        'campus': ?campus,
        'phone': ?phone,
        'markProfileComplete': ?markProfileComplete,
        'interestCategories': ?interestCategories,
      }),
    );
    final json = _decodeObject(
      response,
      errorLabel: 'Could not update profile',
    );
    return ListingMapper.userFromJson(json);
  }

  Future<AppUser> fetchMe() async {
    final response = await http.get(_uri('/api/users/me'), headers: _headers);
    final json = _decodeObject(response, errorLabel: 'Could not load profile');
    return ListingMapper.userFromJson(json);
  }

  Future<void> submitSellerApplication({
    required String storeName,
    String? idDocumentUrl,
  }) async {
    final response = await http.post(
      _uri('/api/users/seller-application'),
      headers: _headers,
      body: jsonEncode({
        'storeName': storeName,
        'idDocumentUrl': ?idDocumentUrl,
      }),
    );
    if (response.statusCode >= 400) {
      throw ApiException(
        _errorMessage(response, fallback: 'Seller application failed'),
        statusCode: response.statusCode,
      );
    }
  }

  Future<AppUser> applyVerifyBadge() async {
    final response = await http.post(
      _uri('/api/users/verify-badge'),
      headers: _headers,
    );
    if (response.statusCode >= 400) {
      throw ApiException(
        _errorMessage(
          response,
          fallback: 'Could not apply for verification badge',
        ),
        statusCode: response.statusCode,
      );
    }
    return fetchMe();
  }

  Future<void> deleteListing(String listingId) async {
    final response = await http.delete(
      _uri('/api/listings/$listingId'),
      headers: _headers,
    );
    if (response.statusCode >= 400) {
      throw ApiException(
        'Could not delete listing',
        statusCode: response.statusCode,
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchMyReports() async {
    final response = await http.get(
      _uri('/api/reports/mine'),
      headers: _headers,
    );
    final list = _decodeList(response, errorLabel: 'Could not load reports');
    return list.cast<Map<String, dynamic>>();
  }

  Future<String> uploadListingPhoto(String filePath) async {
    final request = http.MultipartRequest(
      'POST',
      _uri('/api/uploads/listing-photos'),
    );
    request.headers.addAll(_authHeaders);
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final json = _decodeObject(response, errorLabel: 'Photo upload failed');
    final url = json['url'] as String?;
    if (url == null || url.isEmpty) {
      throw ApiException('Photo upload failed: missing URL');
    }
    return url;
  }

  Future<String> uploadSellerDocument(String filePath) async {
    final request = http.MultipartRequest(
      'POST',
      _uri('/api/uploads/seller-documents'),
    );
    request.headers.addAll(_authHeaders);
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final json = _decodeObject(
      response,
      errorLabel: 'Student ID upload failed',
    );
    final url = json['url'] as String?;
    if (url == null || url.isEmpty) {
      throw ApiException('Student ID upload failed: missing URL');
    }
    return url;
  }

  Future<ListingItem> createListing({
    required String title,
    required String description,
    required double price,
    required String category,
    required String? condition,
    required String? meetupLocation,
    required List<String> tags,
    required Map<String, String> attributes,
    required List<String> photoUrls,
    double? originalPrice,
    DateTime? discountEndsAt,
    int? discountDurationDays,
    required String availabilityType,
    int? quantityAvailable,
  }) async {
    final response = await http.post(
      _uri('/api/listings'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'description': description,
        'price': price,
        'category': category,
        'condition': condition,
        'meetupLocation': meetupLocation,
        'tags': tags,
        'attributes': attributes,
        'photoUrls': photoUrls,
        'originalPrice': originalPrice,
        'discountEndsAt': discountEndsAt?.toUtc().toIso8601String(),
        'discountDurationDays': discountDurationDays,
        'availabilityType': availabilityType,
        'quantityAvailable': quantityAvailable,
      }),
    );
    final json = _decodeObject(
      response,
      errorLabel: 'Could not publish listing',
    );
    return ListingMapper.fromJson(json);
  }

  Future<ListingItem> updateListing({
    required String listingId,
    required String title,
    required String description,
    required double price,
    required String category,
    required String? condition,
    required String? meetupLocation,
    required List<String> tags,
    required Map<String, String> attributes,
    required List<String> photoUrls,
    double? originalPrice,
    DateTime? discountEndsAt,
    int? discountDurationDays,
    required String availabilityType,
    int? quantityAvailable,
  }) async {
    final response = await http.put(
      _uri('/api/listings/$listingId'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'description': description,
        'price': price,
        'category': category,
        'condition': condition,
        'meetupLocation': meetupLocation,
        'tags': tags,
        'attributes': attributes,
        'photoUrls': photoUrls,
        'originalPrice': originalPrice,
        'discountEndsAt': discountEndsAt?.toUtc().toIso8601String(),
        'discountDurationDays': discountDurationDays,
        'availabilityType': availabilityType,
        'quantityAvailable': quantityAvailable,
      }),
    );
    final json = _decodeObject(
      response,
      errorLabel: 'Could not update listing',
    );
    return ListingMapper.fromJson(json);
  }

  Future<List<ListingItem>> fetchListings({
    String? query,
    String sort = 'verified',
  }) async {
    final response = await http.get(
      _uri('/api/listings', {
        if (query != null && query.isNotEmpty) 'q': query,
        'sort': sort,
      }),
      headers: _headers,
    );
    final list = _decodeList(response, errorLabel: 'Listings failed');
    return list
        .map((item) => ListingMapper.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ListingItem>> fetchWishlist() async {
    final response = await http.get(_uri('/api/wishlist'), headers: _headers);
    final list = _decodeList(response, errorLabel: 'Wishlist failed');
    return list
        .map((item) => ListingMapper.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> addWishlist(String listingId) async {
    final response = await http.post(
      _uri('/api/wishlist/$listingId'),
      headers: _headers,
    );
    if (response.statusCode >= 400) {
      throw ApiException(
        'Could not save listing',
        statusCode: response.statusCode,
      );
    }
  }

  Future<void> removeWishlist(String listingId) async {
    final response = await http.delete(
      _uri('/api/wishlist/$listingId'),
      headers: _headers,
    );
    if (response.statusCode >= 400 && response.statusCode != 404) {
      throw ApiException(
        'Could not remove listing',
        statusCode: response.statusCode,
      );
    }
  }

  Future<List<ListingReview>> fetchReviews(String listingId) async {
    final response = await http.get(
      _uri('/api/listings/$listingId/reviews'),
      headers: _headers,
    );
    final list = _decodeList(response, errorLabel: 'Reviews failed');
    return list
        .map(
          (item) => ListingMapper.reviewFromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> postReview({
    required String listingId,
    required int score,
    required String comment,
  }) async {
    final response = await http.post(
      _uri('/api/listings/$listingId/reviews'),
      headers: _headers,
      body: jsonEncode({'score': score, 'comment': comment}),
    );
    if (response.statusCode >= 400) {
      throw ApiException('Review failed', statusCode: response.statusCode);
    }
  }

  Future<void> reportListing({
    required String listingId,
    required String reason,
    String? comment,
  }) async {
    final response = await http.post(
      _uri('/api/reports/listings/$listingId'),
      headers: _headers,
      body: jsonEncode({'reason': reason, 'comment': comment}),
    );
    if (response.statusCode >= 400) {
      throw ApiException('Report failed', statusCode: response.statusCode);
    }
  }

  Future<RecordSaleResult> recordSale({
    required String listingId,
    required int units,
    String? buyerUserId,
  }) async {
    final response = await http.post(
      _uri('/api/listings/$listingId/sales'),
      headers: _headers,
      body: jsonEncode({'units': units, 'buyerUserId': ?buyerUserId}),
    );
    final saleJson = _decodeObject(
      response,
      errorLabel: 'Could not record sale',
    );
    final listingResponse = await http.get(
      _uri('/api/listings/$listingId'),
      headers: _headers,
    );
    final listingJson = _decodeObject(
      listingResponse,
      errorLabel: 'Could not refresh listing',
    );
    return RecordSaleResult(
      saleId: saleJson['id'] as String,
      listing: ListingMapper.fromJson(listingJson),
    );
  }

  Future<List<Map<String, dynamic>>> fetchChats() async {
    final response = await http.get(_uri('/api/chats'), headers: _headers);
    final list = _decodeList(response, errorLabel: 'Could not load chats');
    return list.cast<Map<String, dynamic>>();
  }

  Future<String> openChat({required String listingId}) async {
    final response = await http.post(
      _uri('/api/chats', {'listingId': listingId}),
      headers: _headers,
    );
    final json = _decodeObject(response, errorLabel: 'Could not open chat');
    return json['id'] as String;
  }

  Future<List<Map<String, dynamic>>> fetchChatMessages(String chatId) async {
    final response = await http.get(
      _uri('/api/chats/$chatId/messages'),
      headers: _headers,
    );
    final list = _decodeList(response, errorLabel: 'Could not load messages');
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> respondToSale({
    required String saleId,
    required bool confirmed,
  }) async {
    final response = await http.post(
      _uri('/api/sales/$saleId/respond'),
      headers: _headers,
      body: jsonEncode({'confirmed': confirmed}),
    );
    if (response.statusCode >= 400) {
      throw ApiException(
        'Could not respond to sale',
        statusCode: response.statusCode,
      );
    }
  }

  Future<void> confirmSale(String saleId) async {
    await respondToSale(saleId: saleId, confirmed: true);
  }

  Future<void> sendChatMessage({
    required String chatId,
    required String content,
  }) async {
    final response = await http.post(
      _uri('/api/chats/$chatId/messages'),
      headers: _headers,
      body: jsonEncode({'content': content}),
    );
    if (response.statusCode >= 400) {
      throw ApiException(
        'Could not send message',
        statusCode: response.statusCode,
      );
    }
  }

  Future<List<AppNotification>> fetchNotifications() async {
    final response = await http.get(
      _uri('/api/notifications'),
      headers: _headers,
    );
    final list = _decodeList(
      response,
      errorLabel: 'Could not load notifications',
    );
    return list
        .map(
          (item) =>
              ListingMapper.notificationFromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> markNotificationRead(String id) async {
    final response = await http.post(
      _uri('/api/notifications/$id/read'),
      headers: _headers,
    );
    if (response.statusCode >= 400) {
      throw ApiException(
        'Could not update notification',
        statusCode: response.statusCode,
      );
    }
  }

  Future<void> markAllNotificationsRead() async {
    final response = await http.post(
      _uri('/api/notifications/read-all'),
      headers: _headers,
    );
    if (response.statusCode >= 400) {
      throw ApiException(
        'Could not update notifications',
        statusCode: response.statusCode,
      );
    }
  }

  Future<void> registerFcmToken({
    required String token,
    required String platform,
  }) async {
    final response = await http.post(
      _uri('/api/notifications/fcm-token'),
      headers: _headers,
      body: jsonEncode({'token': token, 'platform': platform}),
    );
    if (response.statusCode >= 400) {
      throw ApiException(
        'Could not register notifications',
        statusCode: response.statusCode,
      );
    }
  }

  Future<ListingItem> restockListing({
    required String listingId,
    required int quantity,
  }) async {
    final response = await http.post(
      _uri('/api/listings/$listingId/restock'),
      headers: _headers,
      body: jsonEncode({'quantity': quantity}),
    );
    final json = _decodeObject(
      response,
      errorLabel: 'Could not restock listing',
    );
    return ListingMapper.fromJson(json);
  }

  Future<ListingItem> relistListing({required String listingId}) async {
    final response = await http.post(
      _uri('/api/listings/$listingId/relist'),
      headers: _headers,
    );
    final json = _decodeObject(
      response,
      errorLabel: 'Could not relist listing',
    );
    return ListingMapper.fromJson(json);
  }

  static ChatMessage messageFromJson(
    Map<String, dynamic> json, {
    required String currentUserId,
  }) {
    final senderId = json['senderId'] as String? ?? '';
    final messageType = json['messageType'] as String? ?? 'text';
    final isSystem = senderId == 'unimarket-system';

    ChatMessageKind kind = ChatMessageKind.text;
    if (messageType == 'sale_confirmation') {
      kind = ChatMessageKind.saleConfirmation;
    } else if (messageType == 'system_text' || isSystem) {
      kind = ChatMessageKind.systemText;
    }

    return ChatMessage(
      id: json['id'] as String,
      text: json['content'] as String? ?? '',
      isMine:
          !isSystem &&
          senderId == currentUserId &&
          kind == ChatMessageKind.text,
      timeLabel: json['timeLabel'] as String? ?? 'Recently',
      kind: kind,
      saleId: json['saleId'] as String?,
      confirmationStatus: json['confirmationStatus'] as String?,
      requiresMyResponse: json['canRespond'] as bool? ?? false,
    );
  }

  List<dynamic> _decodeList(
    http.Response response, {
    required String errorLabel,
  }) {
    if (response.statusCode >= 400) {
      throw ApiException(errorLabel, statusCode: response.statusCode);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw ApiException('$errorLabel: unexpected response');
    }
    return decoded;
  }

  Map<String, dynamic> _decodeObject(
    http.Response response, {
    required String errorLabel,
  }) {
    if (response.statusCode >= 400) {
      throw ApiException(
        _errorMessage(response, fallback: errorLabel),
        statusCode: response.statusCode,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('$errorLabel: unexpected response');
    }
    return decoded;
  }

  String _errorMessage(http.Response response, {required String fallback}) {
    if (response.body.isEmpty) return fallback;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] is String) {
        return decoded['message'] as String;
      }
      if (decoded is String && decoded.isNotEmpty) return decoded;
    } catch (_) {
      if (response.body.isNotEmpty) return response.body;
    }
    return fallback;
  }
}

abstract final class ListingMapper {
  static ListingItem fromJson(Map<String, dynamic> json) {
    final photos =
        (json['photoUrls'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    final image = photos.isNotEmpty ? photos.first : AppAssets.ob1Collage3;

    return ListingItem(
      id: json['id'] as String,
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      imageAsset: image,
      photoUrls: photos,
      sellerName: json['sellerName'] as String? ?? 'Campus seller',
      sellerUserId: json['sellerUserId'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? false,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String? ?? 'Other',
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const [],
      attributes:
          (json['attributes'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value.toString()),
          ) ??
          const {},
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      discountEndsAt: json['discountEndsAt'] != null
          ? DateTime.tryParse(json['discountEndsAt'] as String)
          : null,
      discountDurationDays: json['discountDurationDays'] as int?,
      availabilityType: ListingAvailabilityRules.typeFromApi(
        json['availabilityType'] as String?,
      ),
      quantityAvailable: json['quantityAvailable'] as int?,
      unitsSold: json['unitsSold'] as int? ?? 0,
      lifecycleStatus: ListingAvailabilityRules.lifecycleFromApi(
        json['status'] as String?,
      ),
    );
  }

  static ListingReview reviewFromJson(Map<String, dynamic> json) {
    return ListingReview(
      id: json['id'] as String,
      authorName: json['authorName'] as String,
      rating: (json['rating'] as num).toDouble(),
      body: json['body'] as String,
      dateLabel: json['dateLabel'] as String? ?? 'Recently',
    );
  }

  static AppUser userFromJson(Map<String, dynamic> json) {
    final categories =
        (json['interestCategories'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toSet() ??
        const <String>{};

    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
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
      firebaseUid: json['firebaseUid'] as String?,
      isSeller: json['isSeller'] as bool? ?? false,
      isVerified: json['isVerified'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  static AppNotification notificationFromJson(Map<String, dynamic> json) {
    final type = switch (json['type'] as String? ?? 'system') {
      'verification' => NotificationType.verification,
      'listing' => NotificationType.listing,
      'message' => NotificationType.message,
      'wishlist' => NotificationType.wishlist,
      'sellerApplication' => NotificationType.sellerApplication,
      _ => NotificationType.system,
    };

    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'UniMarket',
      body: json['body'] as String? ?? '',
      timeLabel: json['timeLabel'] as String? ?? 'Recently',
      section: _notificationSection(json['createdAt'] as String?),
      isRead: json['isRead'] as bool? ?? false,
      type: type,
      targetId: json['targetId'] as String?,
      actionLabel: json['actionLabel'] as String?,
    );
  }

  static String _notificationSection(String? createdAt) {
    final parsed = createdAt == null ? null : DateTime.tryParse(createdAt);
    if (parsed == null) return 'Earlier';
    final now = DateTime.now();
    final local = parsed.toLocal();
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (local.year == yesterday.year &&
        local.month == yesterday.month &&
        local.day == yesterday.day) {
      return 'Yesterday';
    }
    return 'Earlier';
  }
}
