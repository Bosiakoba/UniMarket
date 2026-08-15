import 'package:flutter/foundation.dart';

import '../../api/api_client.dart';
import '../../api/session_mode.dart';
import '../../models/listing_report.dart';

class ReportStore extends ChangeNotifier {
  final List<ListingReport> _reports = [];

  List<ListingReport> get reports => List.unmodifiable(_reports);

  Future<void> syncFromApi(ApiClient client) async {
    if (!isLiveSession(client)) return;

    try {
      final raw = await client.fetchMyReports();
      _reports
        ..clear()
        ..addAll(
          raw.map(
            (json) => ListingReport(
              id: json['id'] as String,
              listingId: json['listingId'] as String,
              listingTitle: json['listingId'] as String,
              reason: json['reason'] as String? ?? 'Reported',
              comment: json['comment'] as String?,
              createdAt: json['createdAt'] != null
                  ? DateTime.tryParse(json['createdAt'] as String) ??
                      DateTime.now()
                  : DateTime.now(),
              status: _statusFromApi(json['status'] as String?),
            ),
          ),
        );
      notifyListeners();
    } catch (_) {}
  }

  Future<String?> submit({
    required String listingId,
    required String listingTitle,
    required String reason,
    String? comment,
    ApiClient? client,
  }) async {
    if (client != null && isLiveSession(client)) {
      try {
        await client.reportListing(
          listingId: listingId,
          reason: reason,
          comment: comment,
        );
      } catch (error) {
        return error.toString();
      }
    }

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
    return null;
  }

  void clear() {
    _reports.clear();
    notifyListeners();
  }

  ListingReportStatus _statusFromApi(String? value) {
    return switch (value?.toLowerCase()) {
      'reviewed' => ListingReportStatus.reviewed,
      'dismissed' => ListingReportStatus.dismissed,
      _ => ListingReportStatus.pending,
    };
  }
}
