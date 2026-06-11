import 'package:flutter/material.dart';

import '../data/stores/report_store.dart';

class ReportStoreScope extends InheritedNotifier<ReportStore> {
  const ReportStoreScope({
    super.key,
    required ReportStore store,
    required super.child,
  }) : super(notifier: store);

  static ReportStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ReportStoreScope>();
    assert(scope != null, 'ReportStoreScope not found in widget tree');
    return scope!.notifier!;
  }
}
