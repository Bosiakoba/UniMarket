import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/app_notification.dart';
import '../models/chat_message.dart';
import '../models/listing_availability.dart';
import '../models/listing_item.dart';
import '../models/record_sale_result.dart';
import '../models/listing_review.dart';
import '../models/carousel_banner.dart';
import '../config/api_config.dart';
import 'media_url.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  static final Map<String, String> _memoryCache = {};
  static SharedPreferences? _prefs;

  static Future<void> initCache() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      for (final key in _prefs!.getKeys()) {
        if (key.startsWith('apicache_')) {
          _memoryCache[key] = _prefs!.getString(key) ?? '';
        }
      }
    } catch (_) {}
  }

  String? getCached(String key) {
    return _memoryCache['apicache_$key'];
  }

  void setCached(String key, String value) {
    _memoryCache['apicache_$key'] = value;
    final prefs = _prefs;
    if (prefs != null) {
      try {
        prefs.setString('apicache_$key', value);
      } catch (_) {}
    }
  }

  void clearCache() {
    _memoryCache.clear();
    final prefs = _prefs;
    if (prefs != null) {
      for (final key in prefs.getKeys()) {
        if (key.startsWith('apicache_')) {
          try {
            prefs.remove(key);
          } catch (_) {}
        }
      }
    }
  }

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

  /// Wraps an HTTP call so that raw network exceptions (SocketException,
  /// ClientException, etc.) are converted to user-friendly ApiException
  /// messages that do NOT leak backend URLs or stack traces.
  Future<http.Response> _safe(Future<http.Response> Function() call) async {
    try {
      return await call();
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } catch (_) {
      throw ApiException('Unable to connect. Check your internet connection.');
    }
  }

  // ------------------------------------------------------------------
  //  Safe HTTP verb helpers — call site passes a string path.
  //  URL construction and headers are handled here.
  // ------------------------------------------------------------------

  Future<http.Response> _get(String path, [Map<String, String>? query]) =>
      _safe(() => http.get(_uri(path, query), headers: _headers));

  Future<http.Response> _post(
    String path, {
    Map<String, String>? query,
    Object? body,
  }) =>
      _safe(() => http.post(_uri(path, query), headers: _headers, body: body));

  Future<http.Response> _put(
    String path, {
    Map<String, String>? query,
    Object? body,
  }) =>
      _safe(() => http.put(_uri(path, query), headers: _headers, body: body));

  Future<http.Response> _delete(String path, [Map<String, String>? query]) =>
      _safe(() => http.delete(_uri(path, query), headers: _headers));

  /// Like [_safe] but for multipart uploads (stream-based).
  Future<http.Response> _safeUpload(
      http.MultipartRequest Function() buildRequest) async {
    return _safe(() async {
      final streamed = await buildRequest().send();
      return http.Response.fromStream(streamed);
    });
  }

  /// Like [_post] but with a configurable timeout (default 3 min).
  Future<http.Response> _postWithTimeout(
    String path, {
    Object? body,
    Duration timeout = const Duration(minutes: 3),
  }) =>
      _safe(
        () => http.post(_uri(path), headers: _headers, body: body).timeout(timeout),
      );

  // ==================================================================
  //  API METHODS
  // ==================================================================

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

    final response = await _post('/api/auth/session', body: jsonEncode(body));
    return _decodeObject(response, errorLabel: 'Session failed');
  }

  Future<AppUser> updateProfile({
    String? fullName,
    String? university,
    String? campus,
    String? phone,
    String? avatarUrl,
    bool? markProfileComplete,
    List<String>? interestCategories,
    String? storeName,
    String? storeDescription,
    bool? hasPhysicalStore,
    String? storeAddress,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (university != null) body['university'] = university;
    if (campus != null) body['campus'] = campus;
    if (phone != null) body['phone'] = phone;
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;
    if (markProfileComplete != null) body['markProfileComplete'] = markProfileComplete;
    if (interestCategories != null) body['interestCategories'] = interestCategories;
    if (storeName != null) body['storeName'] = storeName;
    if (storeDescription != null) body['storeDescription'] = storeDescription;
    if (hasPhysicalStore != null) body['hasPhysicalStore'] = hasPhysicalStore;
    if (storeAddress != null) body['storeAddress'] = storeAddress;

    final response = await _put('/api/users/me', body: jsonEncode(body));
    final json = _decodeObject(response, errorLabel: 'Could not update profile');
    return ListingMapper.userFromJson(json);
  }

  Future<AppUser> fetchMe() async {
    final response = await _get('/api/users/me');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return ListingMapper.userFromJson(data);
    }
    throw ApiException(
      _errorMessage(response, fallback: 'Could not fetch user profile'),
      statusCode: response.statusCode,
    );
  }

  Future<AppUser> getUser(String userId) async {
    final response = await _get('/api/users/$userId');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return ListingMapper.userFromJson(data);
    }
    throw ApiException(
      _errorMessage(response, fallback: 'Could not fetch user profile'),
      statusCode: response.statusCode,
    );
  }

  Future<List<AppUser>> getFollowers(String userId) async {
    final response = await _get('/api/users/$userId/followers');
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((e) => ListingMapper.userFromJson(e as Map<String, dynamic>)).toList();
    }
    throw ApiException('Failed to fetch followers');
  }

  Future<List<AppUser>> getFollowing(String userId) async {
    final response = await _get('/api/users/$userId/following');
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((e) => ListingMapper.userFromJson(e as Map<String, dynamic>)).toList();
    }
    throw ApiException('Failed to fetch following');
  }

  Future<void> sendSellerEmailOtp(String email) async {
    final response = await _post(
      '/api/users/seller-email/send-otp',
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode >= 400) {
      throw ApiException(
        _errorMessage(response, fallback: 'Could not send verification code'),
        statusCode: response.statusCode,
      );
    }
  }

  Future<void> verifySellerEmailOtp({
    required String email,
    required String code,
  }) async {
    final response = await _post(
      '/api/users/seller-email/verify-otp',
      body: jsonEncode({'email': email, 'code': code}),
    );
    if (response.statusCode >= 400) {
      throw ApiException(
        _errorMessage(response, fallback: 'Verification failed'),
        statusCode: response.statusCode,
      );
    }
  }

  Future<void> submitSellerApplication({
    required String storeName,
    required String studentEmail,
    String? idDocumentUrl,
  }) async {
    final response = await _postWithTimeout(
      '/api/users/seller-application',
      body: jsonEncode({
        'storeName': storeName,
        'studentEmail': studentEmail,
        'idDocumentUrl': idDocumentUrl,
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
    final response = await _postWithTimeout('/api/users/verify-badge');
    if (response.statusCode >= 400) {
      throw ApiException(
        _errorMessage(response, fallback: 'Could not apply for verification badge'),
        statusCode: response.statusCode,
      );
    }
    return fetchMe();
  }

  Future<void> deleteListing(String listingId) async {
    final response = await _delete('/api/listings/$listingId');
    if (response.statusCode >= 400) {
      throw ApiException('Could not delete listing', statusCode: response.statusCode);
    }
  }

  Future<List<Map<String, dynamic>>> fetchMyReports() async {
    final response = await _get('/api/reports/mine');
    final list = _decodeList(response, errorLabel: 'Could not load reports');
    return list.cast<Map<String, dynamic>>();
  }

  Future<String> uploadListingPhoto(
    String filePath, {
    String? mimeType,
  }) async {
    // Resolve file outside the safe wrapper so file errors aren't
    // caught by the network error handler.
    final file = await _multipartImageFile(filePath, mimeType: mimeType);
    final response = await _safeUpload(() {
      final request = http.MultipartRequest(
        'POST',
        _uri('/api/uploads/listing-photos'),
      );
      request.headers.addAll(_authHeaders);
      request.files.add(file);
      return request;
    });
    final json = _decodeObject(response, errorLabel: 'Photo upload failed');
    final url = _readUploadUrl(json);
    if (url == null || url.isEmpty) {
      throw ApiException('Photo upload failed: missing URL');
    }
    return url;
  }

  Future<String> uploadSellerDocument(
    String filePath, {
    String? mimeType,
  }) async {
    final file = await _multipartImageFile(filePath, mimeType: mimeType);
    final response = await _safeUpload(() {
      final request = http.MultipartRequest(
        'POST',
        _uri('/api/uploads/seller-documents'),
      );
      request.headers.addAll(_authHeaders);
      request.files.add(file);
      return request;
    });
    final json = _decodeObject(response, errorLabel: 'Student ID upload failed');
    final url = _readUploadUrl(json);
    if (url == null || url.isEmpty) {
      throw ApiException('Student ID upload failed: missing URL');
    }
    return url;
  }

  Future<String> uploadAvatar(
    String filePath, {
    String? mimeType,
  }) async {
    final file = await _multipartImageFile(filePath, mimeType: mimeType);
    final response = await _safeUpload(() {
      final request = http.MultipartRequest(
        'POST',
        _uri('/api/uploads/avatars'),
      );
      request.headers.addAll(_authHeaders);
      request.files.add(file);
      return request;
    });
    final json = _decodeObject(response, errorLabel: 'Avatar upload failed');
    final url = _readUploadUrl(json);
    if (url == null || url.isEmpty) {
      throw ApiException('Avatar upload failed: missing URL');
    }
    return url;
  }

  static String? _readUploadUrl(Map<String, dynamic> json) {
    for (final entry in json.entries) {
      if (entry.key.toLowerCase() == 'url' && entry.value is String) {
        return entry.value as String;
      }
    }
    return null;
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
    final response = await _post(
      '/api/listings',
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
    final json = _decodeObject(response, errorLabel: 'Could not publish listing');
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
    final response = await _put(
      '/api/listings/$listingId',
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
    final json = _decodeObject(response, errorLabel: 'Could not update listing');
    return ListingMapper.fromJson(json);
  }

  Future<List<ListingItem>> fetchListings({
    String? query,
    String sort = 'verified',
  }) async {
    final response = await _get('/api/listings', {
      if (query != null && query.isNotEmpty) 'q': query,
      'sort': sort,
    });
    if (response.statusCode == 200) {
      setCached('/api/listings?q=${query ?? ''}&sort=$sort', response.body);
    }
    final list = _decodeList(response, errorLabel: 'Listings failed');
    return list
        .map((item) => ListingMapper.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ListingItem>> fetchMyListings() async {
    final response = await _get('/api/listings/my');
    if (response.statusCode == 200) {
      setCached('/api/listings/my', response.body);
    }
    final list = _decodeList(response, errorLabel: 'Could not load your listings');
    return list
        .map((item) => ListingMapper.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> submitListingAppeal(String listingId, String appealReason) async {
    final response = await _post(
      '/api/listings/$listingId/appeal',
      body: jsonEncode({'appealReason': appealReason}),
    );
    if (response.statusCode >= 400) {
      throw ApiException('Could not submit appeal', statusCode: response.statusCode);
    }
  }

  Future<List<ListingItem>> fetchWishlist() async {
    final response = await _get('/api/wishlist');
    if (response.statusCode == 200) {
      setCached('/api/wishlist', response.body);
    }
    final list = _decodeList(response, errorLabel: 'Wishlist failed');
    return list
        .map((item) => ListingMapper.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> addWishlist(String listingId) async {
    final response = await _post('/api/wishlist/$listingId');
    if (response.statusCode >= 400) {
      throw ApiException('Could not save listing', statusCode: response.statusCode);
    }
  }

  Future<void> removeWishlist(String listingId) async {
    final response = await _delete('/api/wishlist/$listingId');
    if (response.statusCode >= 400 && response.statusCode != 404) {
      throw ApiException('Could not remove listing', statusCode: response.statusCode);
    }
  }

  Future<List<ListingReview>> fetchReviews(String listingId) async {
    final response = await _get('/api/listings/$listingId/reviews');
    final list = _decodeList(response, errorLabel: 'Reviews failed');
    return list
        .map((item) => ListingMapper.reviewFromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> postReview({
    required String listingId,
    required int score,
    required String comment,
  }) async {
    final response = await _post(
      '/api/listings/$listingId/reviews',
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
    final response = await _post(
      '/api/reports/listings/$listingId',
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
    final response = await _post(
      '/api/listings/$listingId/sales',
      body: jsonEncode({
        'units': units,
        // ignore: use_null_aware_elements
        if (buyerUserId != null) 'buyerUserId': buyerUserId,
      }),
    );
    final saleJson = _decodeObject(response, errorLabel: 'Could not record sale');
    final listingResponse = await _get('/api/listings/$listingId');
    final listingJson = _decodeObject(listingResponse, errorLabel: 'Could not refresh listing');
    return RecordSaleResult(
      saleId: saleJson['id'] as String,
      listing: ListingMapper.fromJson(listingJson),
    );
  }

  Future<List<Map<String, dynamic>>> fetchChats() async {
    final response = await _get('/api/chats');
    if (response.statusCode == 200) {
      setCached('/api/chats', response.body);
    }
    final list = _decodeList(response, errorLabel: 'Could not load chats');
    return list.cast<Map<String, dynamic>>();
  }

  Future<String> openChat({required String listingId}) async {
    final response = await _post(
      '/api/chats',
      query: {'listingId': listingId},
    );
    final json = _decodeObject(response, errorLabel: 'Could not open chat');
    return json['id'] as String;
  }

  Future<List<Map<String, dynamic>>> fetchChatMessages(String chatId) async {
    final response = await _get('/api/chats/$chatId/messages');
    if (response.statusCode == 200) {
      setCached('/api/chats/$chatId/messages', response.body);
    }
    final list = _decodeList(response, errorLabel: 'Could not load messages');
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> respondToSale({
    required String saleId,
    required bool confirmed,
  }) async {
    final response = await _post(
      '/api/sales/$saleId/respond',
      body: jsonEncode({'confirmed': confirmed}),
    );
    if (response.statusCode >= 400) {
      throw ApiException('Could not respond to sale', statusCode: response.statusCode);
    }
  }

  Future<void> confirmSale(String saleId) async {
    await respondToSale(saleId: saleId, confirmed: true);
  }

  Future<void> markChatRead({required String chatId}) async {
    final response = await _post('/api/chats/$chatId/read');
    if (response.statusCode >= 400) {
      throw ApiException('Could not mark chat as read', statusCode: response.statusCode);
    }
  }

  Future<Map<String, dynamic>?> sendChatMessage({
    required String chatId,
    required String content,
    String? listingId,
  }) async {
    final response = await _post(
      '/api/chats/$chatId/messages',
      body: jsonEncode({
        'content': content,
        'listingId': listingId,
      }),
    );
    if (response.statusCode >= 400) {
      throw ApiException('Could not send message', statusCode: response.statusCode);
    }
    if (response.body.isNotEmpty) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json;
      } catch (_) {}
    }
    return null;
  }

  Future<Map<String, dynamic>?> editChatMessage({
    required String chatId,
    required String messageId,
    required String content,
  }) async {
    final response = await _put(
      '/api/chats/$chatId/messages/$messageId',
      body: jsonEncode({'content': content}),
    );
    if (response.statusCode >= 400) {
      throw ApiException('Could not edit message', statusCode: response.statusCode);
    }
    if (response.body.isNotEmpty) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json;
      } catch (_) {}
    }
    return null;
  }

  Future<void> deleteChatMessage({
    required String chatId,
    required String messageId,
    bool forEveryone = false,
  }) async {
    final response = await _delete(
      '/api/chats/$chatId/messages/$messageId',
      {'forEveryone': forEveryone.toString()},
    );
    if (response.statusCode >= 400) {
      throw ApiException('Could not delete message', statusCode: response.statusCode);
    }
  }

  Future<void> viewListing(String listingId) async {
    try {
      await _post('/api/listings/$listingId/view');
    } catch (_) {}
  }

  Future<List<AppNotification>> fetchNotifications() async {
    final response = await _get('/api/notifications');
    if (response.statusCode == 200) {
      setCached('/api/notifications', response.body);
    }
    final list = _decodeList(response, errorLabel: 'Could not load notifications');
    return list
        .map((item) =>
            ListingMapper.notificationFromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> markNotificationRead(String id) async {
    final response = await _post('/api/notifications/$id/read');
    if (response.statusCode >= 400) {
      throw ApiException('Could not update notification', statusCode: response.statusCode);
    }
  }

  Future<void> markAllNotificationsRead() async {
    final response = await _post('/api/notifications/read-all');
    if (response.statusCode >= 400) {
      throw ApiException('Could not update notifications', statusCode: response.statusCode);
    }
  }

  Future<void> registerFcmToken({
    required String token,
    required String platform,
  }) async {
    final response = await _post(
      '/api/notifications/fcm-token',
      body: jsonEncode({'token': token, 'platform': platform}),
    );
    if (response.statusCode >= 400) {
      throw ApiException('Could not register notifications', statusCode: response.statusCode);
    }
  }

  Future<ListingItem> restockListing({
    required String listingId,
    required int quantity,
  }) async {
    final response = await _post(
      '/api/listings/$listingId/restock',
      body: jsonEncode({'quantity': quantity}),
    );
    final json = _decodeObject(response, errorLabel: 'Could not restock listing');
    return ListingMapper.fromJson(json);
  }

  Future<ListingItem> relistListing({required String listingId}) async {
    final response = await _post('/api/listings/$listingId/relist');
    final json = _decodeObject(response, errorLabel: 'Could not relist listing');
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

    ListingItem? listingAttachment;
    final inquiryListingId = json['listingId'] as String?;
    if (inquiryListingId != null && inquiryListingId.isNotEmpty) {
      final imageUrl = MediaUrlResolver.resolve(
        json['listingImageUrl'] as String?,
      );
      listingAttachment = ListingItem(
        id: inquiryListingId,
        title: json['listingTitle'] as String? ?? 'Listing',
        price: (json['listingPrice'] as num?)?.toDouble() ?? 0,
        imageAsset: imageUrl,
        photoUrls: imageUrl.isNotEmpty ? [imageUrl] : const [],
        sellerName: 'Seller',
        isVerified: false,
        distanceKm: 0,
        category: 'Listing',
      );
    }

    final isEdited = json['editedAt'] != null;
    final isDeletedForAll = json['isDeletedForMe'] as bool? ?? false;
    final sentAt = json['sentAt'] != null ? DateTime.tryParse(json['sentAt'] as String) : null;

    return ChatMessage(
      id: json['id'] as String,
      text: json['content'] as String? ?? '',
      isMine:
          !isSystem &&
          senderId == currentUserId &&
          (kind == ChatMessageKind.text ||
              messageType == 'listing_inquiry'),
      timeLabel: json['timeLabel'] as String? ?? 'Recently',
      kind: kind,
      listing: listingAttachment,
      saleId: json['saleId'] as String?,
      confirmationStatus: json['confirmationStatus'] as String?,
      requiresMyResponse: json['canRespond'] as bool? ?? false,
      isEdited: isEdited,
      isDeletedForAll: isDeletedForAll,
      sentAt: sentAt,
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

  Future<void> followUser(String userId) async {
    final response = await _post('/api/users/$userId/follow');
    if (response.statusCode >= 400) {
      throw ApiException('Could not follow user', statusCode: response.statusCode);
    }
  }

  Future<void> unfollowUser(String userId) async {
    final response = await _delete('/api/users/$userId/follow');
    if (response.statusCode >= 400) {
      throw ApiException('Could not unfollow user', statusCode: response.statusCode);
    }
  }

  Future<List<CarouselBanner>> getCarouselBanners() async {
    final response = await _get('/api/feed/carousel-banners');
    final List data = _decodeList(response, errorLabel: 'Get banners failed');
    return data.map((json) => CarouselBanner.fromJson(json)).toList();
  }
}

abstract final class ListingMapper {
  static List<String> photoUrlsFromJson(Map<String, dynamic> json) {
    for (final entry in json.entries) {
      if (entry.key.toLowerCase() != 'photourls' || entry.value is! List) {
        continue;
      }
      return (entry.value as List)
          .map((e) => e.toString().trim())
          .where((url) => url.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static ListingItem fromJson(Map<String, dynamic> json) {
    final photos = MediaUrlResolver.resolveAll(photoUrlsFromJson(json));
    final image = photos.isNotEmpty ? photos.first : '';

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
      location: json['meetupLocation'] as String? ?? json['location'] as String? ?? json['university'] as String? ?? '',
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
      sellerRating: (json['sellerRating'] as num?)?.toDouble() ?? 0,
      sellerReviewCount: json['sellerReviewCount'] as int? ?? 0,
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
      views: json['views'] as int? ?? 0,
      appealComment: json['appealComment'] as String?,
      sellerPhone: json['sellerPhone'] as String?,
      sellerAvatarUrl: json['sellerAvatarUrl'] as String?,
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
    return AppUser.fromJson(json);
  }

  static AppNotification notificationFromJson(Map<String, dynamic> json) {
    final type = switch (json['type'] as String? ?? 'system') {
      'verification' => NotificationType.verification,
      'listing' => NotificationType.listing,
      'message' => NotificationType.message,
      'wishlist' => NotificationType.wishlist,
      'sellerApplication' => NotificationType.sellerApplication,
      'listingSuspended' => NotificationType.listingSuspended,
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

String _resolveImageMimeType(String filePath, {String? mimeType}) {
  final reported = mimeType?.split(';').first.trim().toLowerCase();
  if (reported != null &&
      reported.isNotEmpty &&
      reported != 'application/octet-stream') {
    return reported;
  }

  final dot = filePath.lastIndexOf('.');
  final ext = dot >= 0 ? filePath.substring(dot + 1).toLowerCase() : '';
  return switch (ext) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' => 'image/heic',
    'heif' => 'image/heif',
    'jpg' || 'jpeg' => 'image/jpeg',
    _ => 'image/jpeg',
  };
}

Future<http.MultipartFile> _multipartImageFile(
  String filePath, {
  String? mimeType,
}) async {
  final resolved = _resolveImageMimeType(filePath, mimeType: mimeType);
  final slash = resolved.indexOf('/');
  final mediaType = slash > 0
      ? MediaType(resolved.substring(0, slash), resolved.substring(slash + 1))
      : MediaType('image', 'jpeg');

  return http.MultipartFile.fromPath(
    'file',
    filePath,
    contentType: mediaType,
  );
}
