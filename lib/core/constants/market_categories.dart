abstract final class MarketCategories {
  static const listingCategories = [
    'Electronics & Gadgets',
    'Phones & Tablets',
    'Computers & Accessories',
    'Fashion & Clothing',
    'Shoes & Bags',
    'Beauty & Personal Care',
    'Books & Stationery',
    'Courses & Notes',
    'Food & Snacks',
    'Hostel & Room Essentials',
    'Furniture',
    'Sports & Fitness',
    'Services & Gigs',
    'Tickets & Events',
    'Transportation',
    'Health & Wellness',
    'Art & Crafts',
    'Baby & Kids',
    'Pets & Supplies',
    'Jobs & Internships',
    'Other',
  ];

  static const feedCategories = ['All', ...listingCategories];

  static const suggestedTags = {
    'Electronics & Gadgets': [
      'laptop',
      'charger',
      'headphones',
      'gaming',
      'accessories',
    ],
    'Phones & Tablets': ['iphone', 'android', 'samsung', 'ipad', 'used'],
    'Computers & Accessories': [
      'macbook',
      'keyboard',
      'monitor',
      'usb-c',
      'ssd',
    ],
    'Fashion & Clothing': [
      'streetwear',
      'vintage',
      'campus',
      'hoodie',
      'dress',
    ],
    'Shoes & Bags': ['sneakers', 'backpack', 'handbag', 'nike', 'adidas'],
    'Beauty & Personal Care': [
      'skincare',
      'perfume',
      'makeup',
      'haircare',
    ],
    'Books & Stationery': [
      'textbook',
      'novel',
      'calculus',
      'engineering',
      'notes',
    ],
    'Courses & Notes': [
      'lecture notes',
      'past questions',
      'slides',
      'tutorial',
    ],
    'Food & Snacks': ['homemade', 'bulk', 'snacks', 'meal prep'],
    'Hostel & Room Essentials': [
      'bedding',
      'fan',
      'storage',
      'kitchen',
      'decor',
    ],
    'Furniture': ['desk', 'chair', 'shelf', 'mattress', 'lamp'],
    'Sports & Fitness': ['gym', 'football', 'yoga', 'bike', 'equipment'],
    'Services & Gigs': [
      'design',
      'tutoring',
      'photography',
      'coding',
      'editing',
    ],
    'Tickets & Events': ['concert', 'party', 'sports', 'festival'],
    'Transportation': ['bike', 'scooter', 'carpool', 'parking'],
    'Health & Wellness': ['supplements', 'fitness', 'first aid'],
    'Art & Crafts': ['painting', 'handmade', 'prints', 'supplies'],
    'Baby & Kids': ['toys', 'clothes', 'stroller', 'books'],
    'Pets & Supplies': ['food', 'aquarium', 'accessories'],
    'Jobs & Internships': ['part-time', 'remote', 'campus job'],
    'Other': ['bundle', 'negotiable', 'urgent', 'pickup'],
  };

  static List<String> tagsForCategory(String category) =>
      suggestedTags[category] ?? suggestedTags['Other']!;
}
