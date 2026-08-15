import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/star_rating_input.dart';

class WriteReviewForm extends StatelessWidget {
  const WriteReviewForm({
    super.key,
    required this.rating,
    required this.controller,
    required this.onRatingChanged,
    required this.onSubmit,
    this.isSubmitting = false,
  });

  final int rating;
  final TextEditingController controller;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Write a review', style: AppTypography.bodyBold()),
          const SizedBox(height: 10),
          Text('Your rating', style: AppTypography.caption()),
          StarRatingInput(
            rating: rating,
            onChanged: onRatingChanged,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: 4,
            minLines: 3,
            style: AppTypography.body(),
            decoration: InputDecoration(
              hintText: 'Share your experience with this listing...',
              hintStyle: AppTypography.body(color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isSubmitting ? null : onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Post review',
                style: AppTypography.button(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
