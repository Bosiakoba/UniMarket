import '../../constants/app_assets.dart';
import '../../models/listing_item.dart';

abstract final class MockProfile {
  static const name = 'Alex Morgan';
  static const email = 'alex.morgan@university.edu';
  static const university = 'State University';
  static const campus = 'Main Campus';
  static const isVerified = true;
  static const rating = 4.9;
  static const reviewCount = 38;
  static const activeCount = 3;
  static const soldCount = 5;
  static const memberSince = 'Sep 2025';

  static const recentListings = [
    ListingItem(
      id: 'p1',
      title: 'Calculus textbook — 3rd edition',
      price: 45,
      imageAsset: AppAssets.ob1Collage3,
      sellerName: name,
      isVerified: true,
      distanceKm: 0,
      category: 'Books',
    ),
    ListingItem(
      id: 'p2',
      title: 'USB-C hub for MacBook',
      price: 65,
      imageAsset: AppAssets.ob1Collage9,
      sellerName: name,
      isVerified: true,
      distanceKm: 0,
      category: 'Electronics',
    ),
    ListingItem(
      id: 'p3',
      title: 'Logo design — campus clubs',
      price: 80,
      imageAsset: AppAssets.ob1Collage7,
      sellerName: name,
      isVerified: true,
      distanceKm: 0,
      category: 'Services',
    ),
  ];
}
