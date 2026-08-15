import '../../models/home_feed_section.dart';
import '../../models/listing_item.dart';
import '../../models/app_user.dart';
import '../services/home_feed_service.dart';

/// Home feed sections contract.
/// Replace with API-backed [FeedRepository] when backend is ready.
abstract class FeedRepository {
  List<HomeFeedSection> buildFeed(List<ListingItem> catalog, {AppUser? user});
  HomeFeedSection sectionForId(String id, List<ListingItem> catalog, {AppUser? user});
  List<ListingItem> allListingsForSection(String id, List<ListingItem> catalog, {AppUser? user});
}

class HomeFeedRepository implements FeedRepository {
  const HomeFeedRepository();

  @override
  List<HomeFeedSection> buildFeed(List<ListingItem> catalog, {AppUser? user}) =>
      HomeFeedService.buildFeed(catalog, user: user);

  @override
  HomeFeedSection sectionForId(String id, List<ListingItem> catalog, {AppUser? user}) =>
      HomeFeedService.sectionForId(id, catalog, user: user);

  @override
  List<ListingItem> allListingsForSection(
    String id,
    List<ListingItem> catalog, {
    AppUser? user,
  }) =>
      HomeFeedService.allListingsForSection(id, catalog, user: user);
}
