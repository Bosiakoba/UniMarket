import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/shoe_sizes.dart';
import '../../core/models/category_field.dart';
import '../../core/models/listing_availability.dart';
import '../../core/models/post_listing_draft.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/api/session_mode.dart';
import '../../core/widgets/api_client_scope.dart';
import '../../core/widgets/seller_store_scope.dart';
import '../../core/widgets/uni_button.dart';
import '../../core/widgets/uni_option_sheet.dart';
import '../../core/widgets/uni_text_field.dart';
import '../../core/widgets/user_session_scope.dart';
import 'widgets/listing_photo_picker.dart';
import 'widgets/category_fields_form.dart';
import 'widgets/category_picker_sheet.dart';
import 'widgets/description_guide_card.dart';
import 'widgets/tag_input_field.dart';

class PostListingScreen extends StatefulWidget {
  const PostListingScreen({super.key, this.editingListingId});

  final String? editingListingId;

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PostListingScreen(),
      ),
    );
  }

  @override
  State<PostListingScreen> createState() => _PostListingScreenState();
}

class _PostListingScreenState extends State<PostListingScreen> {
  static const _photoOptions = [
    AppAssets.ob1Collage6,
    AppAssets.ob1Collage9,
    AppAssets.ob2Produce,
    AppAssets.ob2Perfume,
    AppAssets.ob1Collage3,
    AppAssets.ob1Collage7,
  ];

  late PostListingDraft _draft;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  int _step = 0;
  bool _draftReady = false;
  bool _isPublishing = false;

  bool get _isEditing => widget.editingListingId != null;

  void _fillMissingDraftFields(PostListingDraft draft) {
    for (final field in draft.schema.fields) {
      final value = draft.attributes[field.key]?.trim();
      if (value != null && value.isNotEmpty) continue;
      if (field.options.isNotEmpty) {
        draft.attributes[field.key] = field.options.first;
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_draftReady) return;
    _draftReady = true;

    if (_isEditing) {
      _draft = SellerStoreScope.of(context)
              .draftForListing(widget.editingListingId!) ??
          PostListingDraft();
      _fillMissingDraftFields(_draft);
      if (_draft.meetupLocation.trim().isEmpty) {
        final campus =
            UserSessionScope.of(context).currentUser?.campus ?? '';
        _draft.meetupLocation =
            PostListingDraft.defaultMeetupLocationFor(campus);
      }
    } else {
      final campus =
          UserSessionScope.of(context).currentUser?.campus ?? '';
      _draft = PostListingDraft(
        meetupLocation: PostListingDraft.defaultMeetupLocationFor(campus),
      );
    }

    _titleController.text = _draft.title;
    _descriptionController.text = _draft.description;
    _priceController.text = _draft.price;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0 && !_draft.hasPhotos) {
      _showSnack('Add at least one photo.');
      return;
    }
    if (_step == 1) {
      _draft.title = _titleController.text;
      _draft.description = _descriptionController.text;
      if (!_draft.isDetailsValid) {
        final missing = _draft.schema.firstMissingAttribute(_draft.attributes);
        if (missing != null) {
          _showSnack('Fill in required field: $missing.');
        } else if (_draft.tags.isEmpty) {
          _showSnack('Add at least one tag.');
        } else {
          _showSnack('Add a title and description (10+ characters).');
        }
        return;
      }
    }
    if (_step == 2) {
      _draft.price = _priceController.text;
      if (!_draft.isPricingValid) {
        _showSnack('Enter a valid price.');
        return;
      }
      if (!_draft.isDiscountValid) {
        _showSnack('Choose a discount and validity period.');
        return;
      }
    }
    if (_step < 3) {
      setState(() => _step++);
      return;
    }
    _save();
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _step--);
  }

  void _syncDraftFromControllers() {
    _draft.title = _titleController.text;
    _draft.description = _descriptionController.text;
    _draft.price = _priceController.text;
  }

  Future<void> _save() async {
    _syncDraftFromControllers();
    if (!_draft.isReadyToPublish || _isPublishing) return;

    final store = SellerStoreScope.of(context);
    final client = ApiClientScope.of(context);
    setState(() => _isPublishing = true);

    final error = _isEditing
        ? await store.updateListingRemote(
            listingId: widget.editingListingId!,
            draft: _draft,
            client: client,
          )
        : await store.publishListing(
            draft: _draft,
            client: client,
          );

    if (!mounted) return;
    setState(() => _isPublishing = false);

    if (error != null) {
      _showSnack(error);
      return;
    }

    Navigator.of(context).pop();
    _showSnack(
      _isEditing
          ? 'Listing updated.'
          : _draft.enableDiscount
              ? 'Listing published — it will appear in Hot deals.'
              : 'Listing published to campus feed.',
    );
  }

  void _setPhotos(List<String> photos) {
    setState(() {
      _draft.photoAssets
        ..clear()
        ..addAll(photos);
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _draft.attributes.clear();
      _draft.applyDefaultsForCategory(category);
      final schema = _draft.schema;
      if (schema.showCondition && schema.conditionOptions.isNotEmpty) {
        _draft.condition = schema.conditionOptions.first;
      }
    });
  }

  void _onAttributeChanged(String key, String value) {
    setState(() {
      _draft.attributes[key] = value;
      if (key == 'item_type') {
        if (ShoeSizes.isShoeItemType(value)) {
          _draft.attributes.putIfAbsent('size_gender', () => ShoeSizes.genders.first);
          _draft.attributes.putIfAbsent('size_system', () => 'UK');
        } else {
          _draft.attributes
            ..remove('size_gender')
            ..remove('size_system')
            ..remove('size_value');
        }
      }
    });
  }

  List<String> _meetupLocations() {
    final campus = UserSessionScope.of(context).currentUser?.campus ?? '';
    final options = PostListingDraft.meetupLocationsFor(campus);
    final current = _draft.meetupLocation.trim();
    if (current.isNotEmpty && !options.contains(current)) {
      return [current, ...options];
    }
    return options;
  }

  @override
  Widget build(BuildContext context) {
    if (!_draftReady) {
      return const Scaffold(
        backgroundColor: AppColors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bottom = MediaQuery.paddingOf(context).bottom;
    const stepLabels = ['Photos', 'Details', 'Pricing', 'Review'];
    final useMockPhotos = !isLiveSession(ApiClientScope.of(context));

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: _back,
          icon: Icon(_step == 0 ? LucideIcons.x : LucideIcons.arrowLeft),
        ),
        title: Text(
          _isEditing ? 'Edit listing' : 'Post listing',
          style: AppTypography.h3(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: List.generate(stepLabels.length, (index) {
                final active = index == _step;
                final done = index < _step;
                return Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              height: 4,
                              decoration: BoxDecoration(
                                color: done || active
                                    ? AppColors.forestGreen
                                    : AppColors.border,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              stepLabels[index],
                              style: AppTypography.caption(
                                color: active
                                    ? AppColors.forestGreen
                                    : AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index < stepLabels.length - 1)
                        const SizedBox(width: 6),
                    ],
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: switch (_step) {
                0 => _PhotosStep(
                    schema: _draft.schema,
                    photos: _draft.photoAssets,
                    useMockPhotos: useMockPhotos,
                    mockAssetOptions: _photoOptions,
                    onPhotosChanged: _setPhotos,
                  ),
                1 => _DetailsStep(
                    schema: _draft.schema,
                    titleController: _titleController,
                    descriptionController: _descriptionController,
                    category: _draft.category,
                    attributes: _draft.attributes,
                    tags: _draft.tags,
                    onCategoryChanged: _onCategoryChanged,
                    onAttributeChanged: _onAttributeChanged,
                    onTagsChanged: (tags) =>
                        setState(() => _draft.tags..clear()..addAll(tags)),
                  ),
                2 => _PricingStep(
                    schema: _draft.schema,
                    draft: _draft,
                    priceController: _priceController,
                    condition: _draft.condition,
                    location: _draft.meetupLocation,
                    locations: _meetupLocations(),
                    onConditionChanged: (c) =>
                        setState(() => _draft.condition = c),
                    onLocationChanged: (l) =>
                        setState(() => _draft.meetupLocation = l),
                    onDiscountChanged: () => setState(() {}),
                    onAvailabilityChanged: () => setState(() {}),
                  ),
                _ => _ReviewStep(draft: _draft),
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 16),
            child: UniButton(
              label: _step == 3
                  ? (_isEditing ? 'Save changes' : 'Publish listing')
                  : 'Continue',
              variant: UniButtonVariant.green,
              isLoading: _isPublishing,
              onPressed: _isPublishing ? null : _next,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotosStep extends StatelessWidget {
  const _PhotosStep({
    required this.schema,
    required this.photos,
    required this.useMockPhotos,
    required this.mockAssetOptions,
    required this.onPhotosChanged,
  });

  final CategoryPostingSchema schema;
  final List<String> photos;
  final bool useMockPhotos;
  final List<String> mockAssetOptions;
  final ValueChanged<List<String>> onPhotosChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add photos', style: AppTypography.h2()),
        const SizedBox(height: 6),
        Text(
          useMockPhotos
              ? 'Pick up to 4 demo photos for offline mode.'
              : 'Pick up to 4 photos from your phone. The first photo is the cover.',
          style: AppTypography.body(),
        ),
        const SizedBox(height: 10),
        DescriptionGuideCard(
          schema: schema,
          title: 'Photo tips for ${schema.category}',
          items: schema.photoTips,
        ),
        const SizedBox(height: 16),
        ListingPhotoPicker(
          photos: photos,
          onChanged: onPhotosChanged,
          useMockAssets: useMockPhotos,
          mockAssetOptions: mockAssetOptions,
        ),
      ],
    );
  }
}

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.schema,
    required this.titleController,
    required this.descriptionController,
    required this.category,
    required this.attributes,
    required this.tags,
    required this.onCategoryChanged,
    required this.onAttributeChanged,
    required this.onTagsChanged,
  });

  final CategoryPostingSchema schema;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final String category;
  final Map<String, String> attributes;
  final List<String> tags;
  final ValueChanged<String> onCategoryChanged;
  final void Function(String key, String value) onAttributeChanged;
  final ValueChanged<List<String>> onTagsChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Listing details', style: AppTypography.h2()),
        const SizedBox(height: 16),
        PickerField(
          label: 'Category',
          required: true,
          value: category,
          hint: 'Select a category',
          category: category,
          onTap: () async {
            final picked = await CategoryPickerSheet.show(
              context,
              selected: category,
            );
            if (picked != null) onCategoryChanged(picked);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        DescriptionGuideCard(schema: schema),
        const SizedBox(height: AppSpacing.md),
        Text('Title', style: AppTypography.bodyBold()),
        const SizedBox(height: 8),
        UniTextField(
          hint: schema.titleHint,
          controller: titleController,
        ),
        const SizedBox(height: AppSpacing.md),
        CategoryFieldsForm(
          schema: schema,
          values: attributes,
          onChanged: onAttributeChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Description', style: AppTypography.bodyBold()),
        const SizedBox(height: 8),
        TextField(
          controller: descriptionController,
          maxLines: 5,
          style: AppTypography.body(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: schema.descriptionHint,
            hintStyle: AppTypography.body(color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.all(18),
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
        ),
        const SizedBox(height: AppSpacing.md),
        TagInputField(
          tags: tags,
          category: category,
          onChanged: onTagsChanged,
        ),
      ],
    );
  }
}

class _PricingStep extends StatelessWidget {
  const _PricingStep({
    required this.schema,
    required this.draft,
    required this.priceController,
    required this.condition,
    required this.location,
    required this.locations,
    required this.onConditionChanged,
    required this.onLocationChanged,
    required this.onDiscountChanged,
    required this.onAvailabilityChanged,
  });

  final CategoryPostingSchema schema;
  final PostListingDraft draft;
  final TextEditingController priceController;
  final String condition;
  final String location;
  final List<String> locations;
  final ValueChanged<String> onConditionChanged;
  final ValueChanged<String> onLocationChanged;
  final VoidCallback onDiscountChanged;
  final VoidCallback onAvailabilityChanged;

  @override
  Widget build(BuildContext context) {
    final salePrice = draft.salePrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Price & meetup', style: AppTypography.h2()),
        const SizedBox(height: 16),
        Text(schema.priceLabel, style: AppTypography.bodyBold()),
        const SizedBox(height: 8),
        UniTextField(
          hint: schema.priceHint,
          controller: priceController,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.payments_outlined,
          onChanged: (_) => onDiscountChanged(),
        ),
        const SizedBox(height: AppSpacing.md),
        _AvailabilitySection(
          draft: draft,
          onChanged: onAvailabilityChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: draft.enableDiscount
                  ? AppColors.forestGreen
                  : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Campus discount', style: AppTypography.bodyBold()),
                        const SizedBox(height: 4),
                        Text(
                          'Discounted listings appear in Hot deals while active.',
                          style: AppTypography.caption(),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: draft.enableDiscount,
                    activeThumbColor: AppColors.white,
                    activeTrackColor: AppColors.forestGreen,
                    onChanged: (value) {
                      draft.enableDiscount = value;
                      onDiscountChanged();
                    },
                  ),
                ],
              ),
              if (draft.enableDiscount) ...[
                const SizedBox(height: 14),
                Text('Discount', style: AppTypography.caption()),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: PostListingDraft.discountPercentOptions.map((pct) {
                    final selected = draft.discountPercent == pct;
                    return ChoiceChip(
                      label: Text('$pct% off'),
                      selected: selected,
                      onSelected: (_) {
                        draft.discountPercent = pct;
                        onDiscountChanged();
                      },
                      selectedColor: AppColors.forestGreen,
                      labelStyle: AppTypography.caption(
                        color: selected ? AppColors.white : AppColors.textPrimary,
                      ),
                      backgroundColor: AppColors.white,
                      side: BorderSide.none,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Text('Valid for', style: AppTypography.caption()),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: PostListingDraft.discountValidDayOptions.map((days) {
                    final selected = draft.discountValidDays == days;
                    return ChoiceChip(
                      label: Text('$days days'),
                      selected: selected,
                      onSelected: (_) {
                        draft.discountValidDays = days;
                        onDiscountChanged();
                      },
                      selectedColor: AppColors.black,
                      labelStyle: AppTypography.caption(
                        color: selected ? AppColors.white : AppColors.textPrimary,
                      ),
                      backgroundColor: AppColors.white,
                      side: BorderSide.none,
                    );
                  }).toList(),
                ),
                if (salePrice != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Buyers pay GHS ${salePrice.round()} for ${draft.discountValidDays} days',
                    style: AppTypography.bodyBold(color: AppColors.forestGreen),
                  ),
                ],
              ],
            ],
          ),
        ),
        if (schema.showCondition) ...[
          const SizedBox(height: AppSpacing.md),
          PickerField(
            label: 'Condition',
            required: true,
            value: condition,
            hint: 'Select condition',
            onTap: () async {
              final picked = await showUniOptionSheet<String>(
                context: context,
                title: 'Condition',
                subtitle: 'Be honest — buyers trust accurate condition notes.',
                options: schema.conditionOptions,
                labelFor: (option) => option,
                selected: condition,
              );
              if (picked != null) onConditionChanged(picked);
            },
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        PickerField(
          label: 'Meetup location',
          required: true,
          value: location,
          hint: 'Where will you meet the buyer?',
          icon: LucideIcons.mapPin,
          onTap: () async {
            final picked = await showUniOptionSheet<String>(
              context: context,
              title: 'Meetup location',
              subtitle: 'Choose a safe, public campus spot.',
              options: locations,
              labelFor: (option) => option,
              selected: location,
              iconFor: (_) => LucideIcons.mapPin,
            );
            if (picked != null) onLocationChanged(picked);
          },
        ),
      ],
    );
  }
}

class _AvailabilitySection extends StatelessWidget {
  const _AvailabilitySection({
    required this.draft,
    required this.onChanged,
  });

  final PostListingDraft draft;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    if (draft.isOngoingListing) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Service availability', style: AppTypography.bodyBold()),
            const SizedBox(height: 6),
            Text(
              'Services and gigs stay listed after each completed job. '
              'Use “Record completed job” when you finish work for a buyer.',
              style: AppTypography.caption(),
            ),
          ],
        ),
      );
    }

    if (!draft.canChooseStock) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How many do you have?', style: AppTypography.bodyBold()),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Just one'),
                selected: draft.availabilityType == ListingAvailabilityType.unique,
                onSelected: (_) {
                  draft.availabilityType = ListingAvailabilityType.unique;
                  onChanged();
                },
              ),
              ChoiceChip(
                label: const Text('Multiple in stock'),
                selected: draft.availabilityType == ListingAvailabilityType.stock,
                onSelected: (_) {
                  draft.availabilityType = ListingAvailabilityType.stock;
                  onChanged();
                },
              ),
            ],
          ),
          if (draft.usesStockQuantity) ...[
            const SizedBox(height: 14),
            Text('Starting quantity', style: AppTypography.caption()),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PostListingDraft.stockQuantityOptions.map((qty) {
                final selected = draft.stockQuantity == qty;
                return ChoiceChip(
                  label: Text('$qty units'),
                  selected: selected,
                  onSelected: (_) {
                    draft.stockQuantity = qty;
                    onChanged();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              'Each sale reduces stock. Listing hides only when quantity reaches zero.',
              style: AppTypography.caption(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.draft});

  final PostListingDraft draft;

  @override
  Widget build(BuildContext context) {
    final store = SellerStoreScope.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review & publish', style: AppTypography.h2()),
        const SizedBox(height: 6),
        Text(
          'Buyers will contact you directly to arrange campus pickup.',
          style: AppTypography.body(),
        ),
        const SizedBox(height: 16),
        if (draft.photoAssets.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: DraftPhotoPreview(source: draft.photoAssets.first),
          ),
        const SizedBox(height: 14),
        Text(draft.title, style: AppTypography.h3()),
        const SizedBox(height: 4),
        if (draft.enableDiscount && draft.salePrice != null) ...[
          Text(
            'GHS ${draft.salePrice!.round()}',
            style: AppTypography.price(color: AppColors.forestGreen),
          ),
          const SizedBox(height: 2),
          Text(
            'Was GHS ${draft.price} · ${draft.discountPercent}% off for ${draft.discountValidDays} days',
            style: AppTypography.caption(color: AppColors.textSecondary),
          ),
        ] else
          Text(
            'GHS ${draft.price}',
            style: AppTypography.price(),
          ),
        const SizedBox(height: 12),
        _ReviewRow(label: 'Category', value: draft.category),
        _ReviewRow(
          label: 'Availability',
          value: draft.isOngoingListing
              ? 'Ongoing service'
              : draft.usesStockQuantity
                  ? '${draft.stockQuantity} in stock'
                  : 'One item',
        ),
        ...draft.schema.visibleFields(draft.attributes).where((f) {
          if (f.type == CategoryFieldType.shoeSize) return false;
          final value = draft.attributes[f.key];
          return value != null && value.trim().isNotEmpty;
        }).map(
          (field) => _ReviewRow(
            label: field.label,
            value: draft.attributes[field.key]!,
          ),
        ),
        if (ShoeSizes.isShoeItemType(draft.attributes['item_type']))
          _ReviewRow(
            label: 'Shoe size',
            value: ShoeSizes.formatDetailed(draft.attributes),
          ),
        if (draft.schema.showCondition)
          _ReviewRow(label: 'Condition', value: draft.condition),
        _ReviewRow(label: 'Meetup', value: draft.meetupLocation),
        _ReviewRow(label: 'Seller', value: store.storeName),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: draft.tags
              .map(
                (tag) => Chip(
                  label: Text(tag, style: AppTypography.caption()),
                  backgroundColor:
                      AppColors.forestGreen.withValues(alpha: 0.1),
                  side: BorderSide.none,
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        Text(draft.description, style: AppTypography.body()),
        if (store.isVerified) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                LucideIcons.shieldCheck,
                size: 16,
                color: AppColors.forestGreen,
              ),
              const SizedBox(width: 6),
              Text(
                'Verified campus seller',
                style: AppTypography.caption(color: AppColors.forestGreen),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label · ', style: AppTypography.caption()),
          Text(value, style: AppTypography.bodyBold()),
        ],
      ),
    );
  }
}
