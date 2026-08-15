import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'uni_text_field.dart';

class SearchableSelectionSheetItem {
  final String title;
  final String? subtitle;
  final dynamic value;

  SearchableSelectionSheetItem({
    required this.title,
    this.subtitle,
    required this.value,
  });
}

class SearchableSelectionSheet extends StatefulWidget {
  final String title;
  final String searchHint;
  final List<SearchableSelectionSheetItem> items;

  const SearchableSelectionSheet({
    super.key,
    required this.title,
    required this.searchHint,
    required this.items,
  });

  static Future<dynamic> show(
    BuildContext context, {
    required String title,
    required String searchHint,
    required List<SearchableSelectionSheetItem> items,
  }) {
    return showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SearchableSelectionSheet(
        title: title,
        searchHint: searchHint,
        items: items,
      ),
    );
  }

  @override
  State<SearchableSelectionSheet> createState() => _SearchableSelectionSheetState();
}

class _SearchableSelectionSheetState extends State<SearchableSelectionSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((item) {
      final q = _query.toLowerCase().trim();
      if (q.isEmpty) return true;
      final matchTitle = item.title.toLowerCase().contains(q);
      final matchSubtitle = item.subtitle?.toLowerCase().contains(q) ?? false;
      return matchTitle || matchSubtitle;
    }).toList();

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.75 + keyboardHeight,
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPadding + keyboardHeight + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.title,
            style: AppTypography.h3(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          UniTextField(
            controller: _searchController,
            hint: widget.searchHint,
            prefixIcon: Icons.search,
            onChanged: (val) => setState(() => _query = val),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'No matches found.',
                      style: AppTypography.body(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const Divider(
                      color: AppColors.border,
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 4,
                        ),
                        title: Text(
                          item.title,
                          style: AppTypography.bodyBold(color: AppColors.textPrimary),
                        ),
                        subtitle: item.subtitle != null
                            ? Text(
                                item.subtitle!,
                                style: AppTypography.caption(
                                  color: AppColors.textSecondary,
                                ),
                              )
                            : null,
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppColors.textTertiary,
                          size: 20,
                        ),
                        onTap: () {
                          Navigator.of(context).pop(item.value);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
