import '../models/listing_item.dart';

class RecordSaleResult {
  const RecordSaleResult({
    required this.listing,
    required this.saleId,
  });

  final ListingItem listing;
  final String saleId;
}
