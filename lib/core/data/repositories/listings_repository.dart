import '../../models/listing_item.dart';
import '../../models/post_listing_draft.dart';
import '../../models/seller_listing_record.dart';
import '../stores/seller_store.dart';

/// Listing catalog + seller inventory contract.
/// Replace [SellerStoreListingsRepository] with an API-backed implementation.
abstract class ListingsRepository {
  List<ListingItem> get allListings;
  List<SellerListingRecord> get listingRecords;
  List<ListingItem> get myListings;

  SellerListingRecord? recordFor(String listingId);
  bool ownsListing(String listingId);
  PostListingDraft? draftForListing(String listingId);

  ListingItem publish(PostListingDraft draft);
  void updateListing(String listingId, PostListingDraft draft);
  void markAsSold(String listingId);
  void markAsActive(String listingId);
  void deleteListing(String listingId);
}

class SellerStoreListingsRepository implements ListingsRepository {
  SellerStoreListingsRepository(this._store);

  final SellerStore _store;

  @override
  List<ListingItem> get allListings => _store.allListings;

  @override
  List<SellerListingRecord> get listingRecords => _store.listingRecords;

  @override
  List<ListingItem> get myListings => _store.myListings;

  @override
  SellerListingRecord? recordFor(String listingId) =>
      _store.recordFor(listingId);

  @override
  bool ownsListing(String listingId) => _store.ownsListing(listingId);

  @override
  PostListingDraft? draftForListing(String listingId) =>
      _store.draftForListing(listingId);

  @override
  ListingItem publish(PostListingDraft draft) => _store.publish(draft);

  @override
  void updateListing(String listingId, PostListingDraft draft) =>
      _store.updateListing(listingId, draft);

  @override
  void markAsSold(String listingId) => _store.markAsSold(listingId);

  @override
  void markAsActive(String listingId) => _store.markAsActive(listingId);

  @override
  void deleteListing(String listingId) => _store.deleteListing(listingId);
}
