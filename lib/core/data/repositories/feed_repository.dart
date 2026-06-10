import '../../models/home_feed_section.dart';
import '../../models/listing_item.dart';
import '../services/home_feed_service.dart';

/// Home feed sections contract.
/// Replace with API-backed [FeedRepository] when backend is ready.
abstract class FeedRepository {
  List<HomeFeedSection> buildFeed(List<ListingItem> catalog);
  HomeFeedSection sectionForId(String id, List<ListingItem> catalog);
  List<ListingItem> allListingsForSection(String id, List<ListingItem> catalog);
}

class HomeFeedRepository implements FeedRepository {
  const HomeFeedRepository();

  @override
  List<HomeFeedSection> buildFeed(List<ListingItem> catalog) =>
      HomeFeedService.buildFeed(catalog);

  @override
  HomeFeedSection sectionForId(String id, List<ListingItem> catalog) =>
      HomeFeedService.sectionForId(id, catalog);

  @override
  List<ListingItem> allListingsForSection(
    String id,
    List<ListingItem> catalog,
  ) =>
      HomeFeedService.allListingsForSection(id, catalog);
}
