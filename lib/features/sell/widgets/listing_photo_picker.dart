import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/models/post_listing_draft.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/listing_image.dart';

class ListingPhotoPicker extends StatelessWidget {
  const ListingPhotoPicker({
    super.key,
    required this.photos,
    required this.onChanged,
    this.useMockAssets = false,
    this.mockAssetOptions = const [],
  });

  final List<String> photos;
  final ValueChanged<List<String>> onChanged;
  final bool useMockAssets;
  final List<String> mockAssetOptions;

  static final _picker = ImagePicker();

  Future<void> _pickFromGallery(BuildContext context) async {
    final remaining = PostListingDraft.maxPhotos - photos.length;
    if (remaining <= 0) return;

    final files = await _picker.pickMultiImage(
      imageQuality: 82,
      limit: remaining,
    );
    if (files.isEmpty) return;

    final next = [...photos, ...files.map((file) => file.path)];
    onChanged(next.take(PostListingDraft.maxPhotos).toList());
  }

  Future<void> _pickFromCamera(BuildContext context) async {
    if (photos.length >= PostListingDraft.maxPhotos) return;

    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 82,
    );
    if (file == null) return;

    onChanged([...photos, file.path]);
  }

  Future<void> _showSourceSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Add photos', style: AppTypography.h3()),
                const SizedBox(height: 4),
                Text(
                  'Choose from your gallery or take a new photo.',
                  style: AppTypography.body(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(LucideIcons.imagePlus),
                  title: const Text('Photo library'),
                  subtitle: const Text('Select up to 4 photos'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromGallery(context);
                  },
                ),
                const SizedBox(height: 4),
                ListTile(
                  leading: Icon(LucideIcons.camera),
                  title: const Text('Camera'),
                  subtitle: const Text('Take a photo now'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromCamera(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _removeAt(int index) {
    final next = [...photos]..removeAt(index);
    onChanged(next);
  }

  void _setCover(int index) {
    if (index <= 0 || index >= photos.length) return;
    final next = [...photos];
    final photo = next.removeAt(index);
    next.insert(0, photo);
    onChanged(next);
  }

  void _toggleMockAsset(String asset) {
    final next = [...photos];
    if (next.contains(asset)) {
      next.remove(asset);
    } else if (next.length < PostListingDraft.maxPhotos) {
      next.add(asset);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (photos.isNotEmpty) ...[
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final photo = photos[index];
                return _SelectedPhotoTile(
                  source: photo,
                  isCover: index == 0,
                  onRemove: () => _removeAt(index),
                  onMakeCover: index == 0 ? null : () => _setCover(index),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (photos.length < PostListingDraft.maxPhotos && !useMockAssets)
          Material(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => _showSourceSheet(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.forestGreen.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.imagePlus,
                      size: 28,
                      color: AppColors.forestGreen,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      photos.isEmpty ? 'Add photos' : 'Add more photos',
                      style: AppTypography.bodyBold(
                        color: AppColors.forestGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${photos.length} of ${PostListingDraft.maxPhotos} selected',
                      style: AppTypography.caption(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (useMockAssets && mockAssetOptions.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Demo photos (offline mode)',
            style: AppTypography.caption(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: mockAssetOptions.length,
            itemBuilder: (context, index) {
              final asset = mockAssetOptions[index];
              final isSelected = photos.contains(asset);
              final order = photos.indexOf(asset);

              return InkWell(
                onTap: () => _toggleMockAsset(asset),
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.forestGreen
                          : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.asset(asset, fit: BoxFit.cover),
                      ),
                      if (isSelected)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color:
                                AppColors.forestGreen.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                      if (isSelected)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.forestGreen,
                            child: Text(
                              '${order + 1}',
                              style: AppTypography.caption(
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _SelectedPhotoTile extends StatelessWidget {
  const _SelectedPhotoTile({
    required this.source,
    required this.isCover,
    required this.onRemove,
    this.onMakeCover,
  });

  final String source;
  final bool isCover;
  final VoidCallback onRemove;
  final VoidCallback? onMakeCover;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _PhotoPreview(source: source),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (isCover)
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.forestGreen,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Cover',
                        style: AppTypography.caption(color: AppColors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (onMakeCover != null) ...[
            const SizedBox(height: 6),
            TextButton(
              onPressed: onMakeCover,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Make cover',
                style: AppTypography.caption(color: AppColors.forestGreen),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    if (PostListingDraft.isLocalFile(source)) {
      return Image.file(
        File(source),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return ListingImage(
      source: source,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}

class DraftPhotoPreview extends StatelessWidget {
  const DraftPhotoPreview({
    super.key,
    required this.source,
    this.aspectRatio = 1.4,
  });

  final String source;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: _PhotoPreview(source: source),
    );
  }
}
