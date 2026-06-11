import '../../constants/app_assets.dart';
import '../../constants/market_categories.dart';
import '../../models/listing_item.dart';

abstract final class MockListings {
  static const categories = MarketCategories.feedCategories;

  static const items = [
    ListingItem(
      id: '1',
      title: 'Chunky Campus Sneakers — barely worn',
      price: 280,
      imageAsset: AppAssets.ob1Collage6,
      sellerName: 'Ama K.',
      isVerified: true,
      distanceKm: 0.4,
      category: 'Shoes & Bags',
      tags: ['sneakers', 'nike', 'campus', 'streetwear'],
      attributes: {
        'item_type': 'Sneakers',
        'brand': 'Nike',
        'model': 'Air Max 90',
        'size_gender': "Men's",
        'size_system': 'UK',
        'size_value': '9',
      },
    ),
    ListingItem(
      id: '2',
      title: 'MacBook Pro 13" — CS major upgrade',
      price: 4200,
      imageAsset: AppAssets.ob1Collage9,
      sellerName: 'Kwesi M.',
      isVerified: true,
      distanceKm: 0.8,
      category: 'Computers & Accessories',
      tags: ['macbook', 'laptop', 'apple', 'cs major'],
    ),
    ListingItem(
      id: '3',
      title: 'Fresh produce bundle — hostel friendly',
      price: 35,
      imageAsset: AppAssets.ob2Produce,
      sellerName: 'Efua A.',
      isVerified: false,
      distanceKm: 1.2,
      category: 'Food & Snacks',
      tags: ['homemade', 'bulk', 'snacks'],
    ),
    ListingItem(
      id: '4',
      title: 'Designer perfume set — 80% full',
      price: 150,
      imageAsset: AppAssets.ob2Perfume,
      sellerName: 'Nana O.',
      isVerified: true,
      distanceKm: 0.6,
      category: 'Beauty & Personal Care',
      tags: ['perfume', 'skincare', 'bundle'],
    ),
    ListingItem(
      id: '5',
      title: 'Textbooks bundle — Level 200',
      price: 120,
      imageAsset: AppAssets.ob1Collage3,
      sellerName: 'Kojo B.',
      isVerified: false,
      distanceKm: 1.5,
      category: 'Books & Stationery',
      tags: ['textbook', 'engineering', 'level 200'],
    ),
    ListingItem(
      id: '6',
      title: 'Graphic design gigs — logos & flyers',
      price: 80,
      imageAsset: AppAssets.ob1Collage7,
      sellerName: 'Yaa S.',
      isVerified: true,
      distanceKm: 0.3,
      category: 'Services & Gigs',
      tags: ['design', 'logo', 'flyers', 'freelance'],
    ),
  ];
}
