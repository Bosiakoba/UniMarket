import 'package:flutter/material.dart';

import '../../../core/constants/category_visuals.dart';
import '../../../core/constants/market_categories.dart';
import '../../../core/widgets/uni_option_sheet.dart';

abstract final class CategoryPickerSheet {
  static Future<String?> show(
    BuildContext context, {
    required String selected,
  }) {
    return showUniOptionSheet<String>(
      context: context,
      title: 'Choose category',
      subtitle: 'Pick the best fit so buyers see the right fields and tips.',
      options: MarketCategories.listingCategories,
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
