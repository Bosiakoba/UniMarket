import 'package:flutter/material.dart';

import '../../../core/constants/category_visuals.dart';
import '../../../core/constants/market_categories.dart';
import '../../../core/widgets/uni_option_sheet.dart';

abstract final class FeedCategoryPickerSheet {
  static Future<String?> show(
    BuildContext context, {
    required String selected,
  }) {
    return showUniOptionSheet<String>(
      context: context,
      title: 'Browse by category',
      subtitle: 'Filter listings to one campus category.',
      options: MarketCategories.feedCategories,
      labelFor: (category) => category,
      selected: selected,
      leadingFor: (category) => CategoryIcon(
        category: category,
        size: 52,
      ),
      searchable: true,
      searchHint: 'Search categories...',
    );
  }
}
