import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/app_assets.dart';
import '../models/app_user.dart';
import '../models/listing_availability.dart';
import '../models/listing_item.dart';
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

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (devUserId != null) 'X-Dev-User-Id': devUserId!,
      };

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<Map<String, dynamic>> bootstrapSession({required String devUserId}) async {
    this.devUserId = devUserId;
    final response = await http.post(
      _uri('/api/auth/session'),
      headers: _headers,
      body: jsonEncode({'devUserId': devUserId}),
    );
    return _decodeObject(response, errorLabel: 'Session failed');
  }

  Future<List<ListingItem>> fetchListings({String? query, String sort = 'verified'}) async {
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
      throw ApiException('Could not save listing', statusCode: response.statusCode);
    }
  }

  Future<void> removeWishlist(String listingId) async {
    final response = await http.delete(
      _uri('/api/wishlist/$listingId'),
      headers: _headers,
    );
    if (response.statusCode >= 400 && response.statusCode != 404) {
      throw ApiException('Could not remove listing', statusCode: response.statusCode);
    }
  }

  Future<List<ListingReview>> fetchReviews(String listingId) async {
    final response = await http.get(
      _uri('/api/listings/$listingId/reviews'),
      headers: _headers,
    );
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

  Future<ListingItem> recordSale({
    required String listingId,
    required int units,
    String? buyerUserId,
  }) async {
    final response = await http.post(
      _uri('/api/listings/$listingId/sales'),
      headers: _headers,
      body: jsonEncode({
        'units': units,
        if (buyerUserId != null) 'buyerUserId': buyerUserId,
      }),
    );
    _decodeObject(response, errorLabel: 'Could not record sale');
    final listingResponse = await http.get(
      _uri('/api/listings/$listingId'),
      headers: _headers,
    );
    final listingJson =
        _decodeObject(listingResponse, errorLabel: 'Could not refresh listing');
    return ListingMapper.fromJson(listingJson);
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
    final json = _decodeObject(response, errorLabel: 'Could not restock listing');
    return ListingMapper.fromJson(json);
  }

  Future<ListingItem> relistListing({required String listingId}) async {
    final response = await http.post(
      _uri('/api/listings/$listingId/relist'),
      headers: _headers,
    );
    final json = _decodeObject(response, errorLabel: 'Could not relist listing');
    return ListingMapper.fromJson(json);
  }

  Future<void> confirmSale(String saleId) async {
    final response = await http.post(
      _uri('/api/sales/$saleId/confirm'),
      headers: _headers,
    );
    if (response.statusCode >= 400) {
      throw ApiException('Could not confirm sale', statusCode: response.statusCode);
    }
  }

  List<dynamic> _decodeList(http.Response response, {required String errorLabel}) {
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
      throw ApiException(errorLabel, statusCode: response.statusCode);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('$errorLabel: unexpected response');
    }
    return decoded;
  }
}

abstract final class ListingMapper {
  static ListingItem fromJson(Map<String, dynamic> json) {
    final photos = (json['photoUrls'] as List<dynamic>?)
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
      isVerified: json['isVerified'] as bool? ?? false,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String? ?? 'Other',
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      attributes: (json['attributes'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value.toString()),
          ) ??
          const {},
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
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
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      university: json['university'] as String? ?? 'State University',
      campus: json['campus'] as String? ?? 'Main Campus',
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      firebaseUid: json['firebaseUid'] as String?,
      isSeller: json['isSeller'] as bool? ?? false,
      isVerified: json['isVerified'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}
