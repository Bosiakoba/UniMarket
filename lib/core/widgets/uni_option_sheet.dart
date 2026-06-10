import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../constants/category_visuals.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

typedef OptionLabelBuilder<T> = String Function(T option);
typedef OptionIconBuilder<T> = IconData? Function(T option);
typedef OptionLeadingBuilder<T> = Widget? Function(T option);

Future<T?> showUniOptionSheet<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  required List<T> options,
  required OptionLabelBuilder<T> labelFor,
  T? selected,
  OptionIconBuilder<T>? iconFor,
  OptionLeadingBuilder<T>? leadingFor,
  bool searchable = false,
  String searchHint = 'Search...',
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _UniOptionSheet<T>(
      title: title,
      subtitle: subtitle,
      options: options,
      labelFor: labelFor,
      selected: selected,
      iconFor: iconFor,
      leadingFor: leadingFor,
      searchable: searchable,
      searchHint: searchHint,
    ),
  );
}

class _UniOptionSheet<T> extends StatefulWidget {
  const _UniOptionSheet({
    required this.title,
    this.subtitle,
    required this.options,
    required this.labelFor,
    this.selected,
    this.iconFor,
    this.leadingFor,
    required this.searchable,
    required this.searchHint,
  });

  final String title;
  final String? subtitle;
  final List<T> options;
  final OptionLabelBuilder<T> labelFor;
  final T? selected;
  final OptionIconBuilder<T>? iconFor;
  final OptionLeadingBuilder<T>? leadingFor;
  final bool searchable;
  final String searchHint;

  @override
  State<_UniOptionSheet<T>> createState() => _UniOptionSheetState<T>();
}

class _UniOptionSheetState<T> extends State<_UniOptionSheet<T>> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<T> get _filtered {
    if (_query.trim().isEmpty) return widget.options;
    final q = _query.trim().toLowerCase();
    return widget.options
        .where((o) => widget.labelFor(o).toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(widget.title, style: AppTypography.h3()),
            ),
            if (widget.subtitle != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: Text(widget.subtitle!, style: AppTypography.body()),
              ),
            ],
            if (widget.searchable) ...[
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  style: AppTypography.body(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    hintStyle: AppTypography.body(color: AppColors.textTertiary),
                    prefixIcon: const Icon(
                      LucideIcons.search,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceMuted,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Flexible(
              child: _filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No matches found.',
                        textAlign: TextAlign.center,
                        style: AppTypography.body(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 16),
                      itemCount: _filtered.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final option = _filtered[index];
                        final isSelected = option == widget.selected;
                        final leading = widget.leadingFor?.call(option);
                        final icon = leading == null
                            ? widget.iconFor?.call(option)
                            : null;

                        return Material(
                          color: isSelected
                              ? AppColors.forestGreen.withValues(alpha: 0.08)
                              : AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(option),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.forestGreen
                                      : AppColors.border,
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (leading != null) ...[
                                    leading,
                                    const SizedBox(width: 10),
                                  ] else if (icon != null) ...[
                                    Icon(
                                      icon,
                                      size: 18,
                                      color: isSelected
                                          ? AppColors.forestGreen
                                          : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                  Expanded(
                                    child: Text(
                                      widget.labelFor(option),
                                      style: AppTypography.body(),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      LucideIcons.check,
                                      size: 16,
                                      color: AppColors.forestGreen,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    this.label,
    required this.value,
    required this.hint,
    required this.onTap,
    this.required = false,
    this.icon,
    this.category,
    this.showLabel = true,
  });

  final String? label;
  final String? value;
  final String hint;
  final VoidCallback onTap;
  final bool required;
  final IconData? icon;
  final String? category;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel && label != null) ...[
          Row(
            children: [
              Text(label!, style: AppTypography.bodyBold()),
              if (required) ...[
                const SizedBox(width: 4),
                Text('*', style: AppTypography.bodyBold(color: Colors.red)),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
        PickerFieldTile(
          value: value,
          hint: hint,
          onTap: onTap,
          icon: icon,
          category: category,
        ),
      ],
    );
  }
}

class PickerFieldTile extends StatelessWidget {
  const PickerFieldTile({
    super.key,
    required this.value,
    required this.hint,
    required this.onTap,
    this.icon,
    this.category,
  });

  final String? value;
  final String hint;
  final VoidCallback onTap;
  final IconData? icon;
  final String? category;

  bool get _hasValue => value != null && value!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              if (category != null) ...[
                CategoryIcon(category: category!, size: 36),
                const SizedBox(width: 10),
              ] else if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  _hasValue ? value! : hint,
                  style: AppTypography.body(
                    color: _hasValue
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                ),
              ),
              const Icon(
                LucideIcons.chevronDown,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
