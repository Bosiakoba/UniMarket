enum ListingReportStatus { pending, reviewed, dismissed }

class ListingReport {
  const ListingReport({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.reason,
    required this.createdAt,
    this.comment,
    this.status = ListingReportStatus.pending,
  });

  final String id;
  final String listingId;
  final String listingTitle;
  final String reason;
  final String? comment;
  final DateTime createdAt;
  final ListingReportStatus status;

  String get statusLabel => switch (status) {
        ListingReportStatus.pending => 'Pending review',
        ListingReportStatus.reviewed => 'Reviewed',
        ListingReportStatus.dismissed => 'Dismissed',
      };
}
