import 'package:flutter/material.dart';

import '../../../core/constants/market_categories.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class TagInputField extends StatefulWidget {
  const TagInputField({
    super.key,
    required this.tags,
    required this.category,
    required this.onChanged,
    this.maxTags = 5,
  });

  final List<String> tags;
  final String category;
  final ValueChanged<List<String>> onChanged;
  final int maxTags;

  @override
  State<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<TagInputField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addTag(String raw) {
    final tag = raw.trim().toLowerCase();
    if (tag.isEmpty) return;
    if (widget.tags.contains(tag)) return;
    if (widget.tags.length >= widget.maxTags) return;
    widget.onChanged([...widget.tags, tag]);
    _controller.clear();
  }

  void _removeTag(String tag) {
    widget.onChanged(widget.tags.where((t) => t != tag).toList());
  }

  void _toggleSuggested(String tag) {
    if (widget.tags.contains(tag)) {
      _removeTag(tag);
    } else {
      _addTag(tag);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = MarketCategories.tagsForCategory(widget.category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tags', style: AppTypography.bodyBold()),
        const SizedBox(height: 6),
        Text(
          'Add up to ${widget.maxTags} tags so buyers find your listing faster.',
          style: AppTypography.caption(),
        ),
        const SizedBox(height: 10),
        if (widget.tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.tags.map((tag) {
              return InputChip(
                label: Text(tag, style: AppTypography.caption()),
                onDeleted: () => _removeTag(tag),
                deleteIconColor: AppColors.forestGreen,
                backgroundColor: AppColors.forestGreen.withValues(alpha: 0.1),
                side: BorderSide.none,
              );
            }).toList(),
          ),
        if (widget.tags.isNotEmpty) const SizedBox(height: 10),
        TextField(
          controller: _controller,
          style: AppTypography.body(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Type a tag and press enter',
            hintStyle: AppTypography.body(color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.forestGreen,
                width: 1.5,
              ),
            ),
          ),
          onSubmitted: _addTag,
        ),
        const SizedBox(height: 12),
        Text('Suggested', style: AppTypography.caption()),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((tag) {
            final selected = widget.tags.contains(tag);
            return ActionChip(
              label: Text(tag, style: AppTypography.caption()),
              backgroundColor: selected
                  ? AppColors.forestGreen
                  : AppColors.surfaceMuted,
              labelStyle: AppTypography.caption(
                color: selected ? AppColors.white : AppColors.textPrimary,
              ),
              side: BorderSide.none,
              onPressed: widget.tags.length >= widget.maxTags && !selected
                  ? null
                  : () => _toggleSuggested(tag),
            );
          }).toList(),
        ),
      ],
    );
  }
}
