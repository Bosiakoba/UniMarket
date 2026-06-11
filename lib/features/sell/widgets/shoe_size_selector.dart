import 'package:flutter/material.dart';

import '../../../core/constants/shoe_sizes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class ShoeSizeSelector extends StatelessWidget {
  const ShoeSizeSelector({
    super.key,
    required this.values,
    required this.onChanged,
  });

  final Map<String, String> values;
  final void Function(String key, String value) onChanged;

  String get _gender => values['size_gender'] ?? ShoeSizes.genders.first;
  String get _system => values['size_system'] ?? 'UK';
  String get _size => values['size_value'] ?? '';

  @override
  Widget build(BuildContext context) {
    final sizes = ShoeSizes.sizesFor(system: _system, gender: _gender);
    final euHint = _size.isEmpty
        ? null
        : ShoeSizes.toEu(system: _system, value: _size, gender: _gender);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fit', style: AppTypography.bodyBold()),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ShoeSizes.genders.map((gender) {
            final selected = _gender == gender;
            return ChoiceChip(
              label: Text(gender),
              selected: selected,
              onSelected: (_) {
                onChanged('size_gender', gender);
                if (_size.isNotEmpty &&
                    !ShoeSizes.sizesFor(system: _system, gender: gender)
                        .contains(_size)) {
                  onChanged('size_value', '');
                }
              },
              selectedColor: AppColors.forestGreen,
              labelStyle: AppTypography.caption(
                color: selected ? AppColors.white : AppColors.textPrimary,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Text('Size system', style: AppTypography.bodyBold()),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ShoeSizes.systems.map((system) {
            final selected = _system == system;
            return ChoiceChip(
              label: Text(system),
              selected: selected,
              onSelected: (_) {
                onChanged('size_system', system);
                if (_size.isNotEmpty &&
                    !ShoeSizes.sizesFor(system: system, gender: _gender)
                        .contains(_size)) {
                  onChanged('size_value', '');
                }
              },
              selectedColor: AppColors.black,
              labelStyle: AppTypography.caption(
                color: selected ? AppColors.white : AppColors.textPrimary,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Text('Size', style: AppTypography.bodyBold()),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sizes.map((size) {
            final selected = _size == size;
            return ChoiceChip(
              label: Text(size),
              selected: selected,
              onSelected: (_) => onChanged('size_value', size),
              selectedColor: AppColors.forestGreen,
              labelStyle: AppTypography.caption(
                color: selected ? AppColors.white : AppColors.textPrimary,
              ),
            );
          }).toList(),
        ),
        if (euHint != null && _system != 'EU') ...[
          const SizedBox(height: 10),
          Text(
            'Equivalent: EU $euHint',
            style: AppTypography.caption(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}
