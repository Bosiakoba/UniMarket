import '../constants/category_posting_schemas.dart';
import 'category_field.dart';
import 'listing_availability.dart';

class PostListingDraft {
  PostListingDraft({
    List<String>? photoAssets,
    this.title = '',
    this.description = '',
    this.category = 'Electronics & Gadgets',
    List<String>? tags,
    Map<String, String>? attributes,
    this.condition = 'Like new',
    this.price = '',
    this.meetupLocation = 'Main Campus',
    this.enableDiscount = false,
    this.discountPercent = 15,
    this.discountValidDays = 7,
    ListingAvailabilityType? availabilityType,
    this.stockQuantity = 1,
  })  : photoAssets = photoAssets ?? [],
        tags = tags ?? [],
        attributes = attributes ?? {},
        availabilityType =
            availabilityType ?? ListingAvailabilityType.unique;

  static const discountPercentOptions = [10, 15, 20, 25, 30];
  static const discountValidDayOptions = [3, 7, 14, 30];
  static const stockQuantityOptions = [2, 3, 5, 10, 20, 50];

  final List<String> photoAssets;
  String title;
  String description;
  String category;
  List<String> tags;
  Map<String, String> attributes;
  String condition;
  String price;
  String meetupLocation;
  bool enableDiscount;
  int discountPercent;
  int discountValidDays;
  ListingAvailabilityType availabilityType;
  int stockQuantity;

  CategoryPostingSchema get schema =>
      CategoryPostingSchemas.forCategory(category);

  bool get hasPhotos => photoAssets.isNotEmpty;

  bool get categoryFieldsValid => schema.validateAttributes(attributes);

  bool get isDetailsValid =>
      title.trim().length >= 3 &&
      description.trim().length >= 10 &&
      tags.isNotEmpty &&
      categoryFieldsValid;

  bool get isPricingValid {
    final value = double.tryParse(price.trim());
    return value != null && value > 0;
  }

  bool get isDiscountValid {
    if (!enableDiscount) return true;
    return discountPercentOptions.contains(discountPercent) &&
        discountValidDayOptions.contains(discountValidDays);
  }

  bool get isReadyToPublish =>
      hasPhotos && isDetailsValid && isPricingValid && isDiscountValid;

  double? get listPrice => double.tryParse(price.trim());

  double? get salePrice {
    final base = listPrice;
    if (base == null || !enableDiscount) return base;
    return base * (1 - discountPercent / 100);
  }

  bool get canChooseStock =>
      ListingAvailabilityRules.supportsStock(schema.kind);

  bool get isOngoingListing =>
      availabilityType == ListingAvailabilityType.ongoing;

  bool get usesStockQuantity =>
      availabilityType == ListingAvailabilityType.stock;

  void applyDefaultsForCategory(String nextCategory) {
    category = nextCategory;
    final nextSchema = CategoryPostingSchemas.forCategory(nextCategory);
    availabilityType = ListingAvailabilityRules.defaultForKind(nextSchema.kind);
    stockQuantity = 2;
  }

  int? get resolvedQuantityAvailable {
    if (availabilityType == ListingAvailabilityType.stock) {
      return stockQuantity.clamp(2, 999);
    }
    return null;
  }
}
