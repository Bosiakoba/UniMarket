import 'package:flutter/foundation.dart';

import '../../models/listing_report.dart';

class ReportStore extends ChangeNotifier {
  final List<ListingReport> _reports = [];

  List<ListingReport> get reports => List.unmodifiable(_reports);

  void submit({
    required String listingId,
    required String listingTitle,
    required String reason,
    String? comment,
  }) {
    _reports.insert(
      0,
      ListingReport(
        id: 'report-${DateTime.now().millisecondsSinceEpoch}',
        listingId: listingId,
        listingTitle: listingTitle,
        reason: reason,
        comment: comment?.trim().isEmpty ?? true ? null : comment?.trim(),
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void clear() {
    _reports.clear();
    notifyListeners();
  }
}
