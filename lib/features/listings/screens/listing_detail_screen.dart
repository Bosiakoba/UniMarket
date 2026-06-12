import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/auth/auth_gate.dart';
import '../../../core/constants/shoe_sizes.dart';
import '../../../core/data/stores/seller_store.dart';
import '../../../core/models/listing_item.dart';
import '../../../core/models/seller_listing_record.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/listing_image.dart';
import '../../../core/widgets/api_client_scope.dart';
import '../../../core/widgets/message_store_scope.dart';
import '../../../core/widgets/rating_row.dart';
import '../../../core/widgets/review_store_scope.dart';
import '../../../core/widgets/seller_store_scope.dart';
import '../../../core/widgets/user_session_scope.dart';
import '../../../core/widgets/verified_badge.dart';
import '../../seller/seller_profile_screen.dart';
import '../../../core/models/listing_availability.dart';
import '../widgets/listing_actions_sheet.dart';
import '../widgets/listing_attribute_chips.dart';
import '../widgets/listing_price_text.dart';
import '../widgets/record_sale_sheet.dart';
import '../widgets/reviews_section.dart';
import 'listing_reviews_screen.dart';

class ListingDetailScreen extends StatefulWidget {
  const ListingDetailScreen({super.key, required this.listing});

  final ListingItem listing;

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  String _condition = 'Like new';

  static const _conditions = ['Like new', 'Good', 'Fair'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final client = ApiClientScope.of(context);
      ReviewStoreScope.of(context)
          .loadFromApi(client, widget.listing.canonicalId);
    });
  }

  String get _sellerPhone => switch (widget.listing.sellerName) {
        'Ama K.' => '+233 24 111 2233',
        'Kwesi M.' => '+233 55 222 3344',
        'Efua A.' => '+233 20 333 4455',
        _ => '+233 50 000 1122',
      };

  String _description(SellerListingRecord? ownerRecord) {
    final custom = ownerRecord?.description.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    return '${widget.listing.category} item listed on campus. '
        'Contact the seller to agree on price and a meetup location.';
  }

  Future<void> _contactSeller() async {
    final allowed = await ensureRegisteredAccount(
      context,
      reason: 'Sign in to message this seller about ${widget.listing.title}.',
    );
    if (!allowed || !mounted) return;

    await MessageStoreScope.of(context).navigateToSellerChat(
      context,
      sellerName: widget.listing.sellerName,
      sellerUserId: widget.listing.sellerUserId,
      listing: widget.listing,
      client: ApiClientScope.of(context),
      currentUserId: UserSessionScope.of(context).currentUser?.id,
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openOwnerActions({
    required ListingItem listing,
    required SellerListingRecord record,
    required SellerStore sellerStore,
  }) async {
    await ListingActionsSheet.showOwner(
      context,
      listing: listing,
      record: record,
      onRecordSale: () => _handleRecordSale(listing, sellerStore),
      onRestock: () => _handleRestock(listing, sellerStore),
      onRelist: () => _handleRelist(listing, sellerStore),
      onDelete: () => _confirmDelete(),
    );
  }

  Future<void> _handleRecordSale(
    ListingItem listing,
    SellerStore sellerStore,
  ) async {
    final units = await RecordSaleSheet.show(context, listing);
    if (units == null || !mounted) return;

    final result = await sellerStore.recordSale(
      listingId: listing.id,
      units: units,
      client: ApiClientScope.of(context),
    );
    if (!mounted) return;

    if (result.error != null) {
      _showSnack(result.error!);
      return;
    }

    final updated = sellerStore.recordFor(listing.id)?.listing ?? listing;
    if (result.saleId != null) {
      await MessageStoreScope.of(context).afterSaleRecorded(
        listing: updated,
        saleId: result.saleId!,
        units: units,
        client: ApiClientScope.of(context),
        currentUserId: UserSessionScope.of(context).currentUser?.id,
      );
    }
    if (!mounted) return;

    _showSnack(
      ListingAvailabilityRules.recordSaleSuccessMessage(
        type: updated.availabilityType,
        units: units,
        quantityRemaining: updated.quantityAvailable,
        listingClosed: !updated.isBrowseable,
      ),
    );
  }

  Future<void> _handleRestock(
    ListingItem listing,
    SellerStore sellerStore,
  ) async {
    final quantity = await RestockSheet.show(context, listing);
    if (quantity == null || !mounted) return;

    final error = await sellerStore.restockListing(
      listingId: listing.id,
      quantity: quantity,
      client: ApiClientScope.of(context),
    );
    if (!mounted) return;

    if (error != null) {
      _showSnack(error);
      return;
    }

    _showSnack('Added $quantity units. Listing is live again.');
  }

  Future<void> _handleRelist(
    ListingItem listing,
    SellerStore sellerStore,
  ) async {
    final error = await sellerStore.relistListing(
      listingId: listing.id,
      client: ApiClientScope.of(context),
    );
    if (!mounted) return;

    if (error != null) {
      _showSnack(error);
      return;
    }

    _showSnack('Listing relisted on campus feed.');
  }

  void _openBuyerActions(ListingItem listing) {
    ListingActionsSheet.showBuyer(
      context,
      listing: listing,
      phone: _sellerPhone,
      onContact: _contactSeller,
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete listing?', style: AppTypography.h3()),
        content: Text(
          'This removes the listing from campus feed and your records.',
          style: AppTypography.body(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: AppTypography.bodyBold()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: AppTypography.bodyBold(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final client = ApiClientScope.of(context);
    final sellerStore = SellerStoreScope.of(context);
    final error = await sellerStore.deleteListingRemote(
      listingId: widget.listing.id,
      client: client,
    );
    if (!mounted) return;

    if (error != null) {
      _showSnack(error);
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    _showSnack('Listing deleted.');
  }

  @override
  Widget build(BuildContext context) {
    final sellerStore = SellerStoreScope.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return ListenableBuilder(
      listenable: sellerStore,
      builder: (context, _) {
        final resolved =
            widget.listing.resolveAgainst(sellerStore.allListings);
        final listing =
            sellerStore.recordFor(resolved.id)?.listing ?? resolved;
        final ownRecord = sellerStore.recordFor(resolved.id);
        final isOwner = ownRecord != null;
        final ownerRecord = ownRecord;

        return Scaffold(
          backgroundColor: AppColors.white,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(LucideIcons.arrowLeft),
                      ),
                      Expanded(
                        child: Text(
                          isOwner ? 'Your listing' : 'Product Details',
                          textAlign: TextAlign.center,
                          style: AppTypography.h3(),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (ownerRecord != null) {
                            _openOwnerActions(
                              listing: listing,
                              record: ownerRecord,
                              sellerStore: sellerStore,
                            );
                          } else {
                            _openBuyerActions(listing);
                          }
                        },
                        icon: const Icon(LucideIcons.moreVertical),
                        tooltip: isOwner ? 'Manage listing' : 'More options',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (ownerRecord != null) ...[
                          _OwnerStatusBanner(record: ownerRecord),
                          const SizedBox(height: 12),
                        ],
                        _ListingPhotoCarousel(
                          photos: resolved.displayPhotos,
                        ),
                        const SizedBox(height: 18),
                        Text(listing.title, style: AppTypography.h2()),
                        const SizedBox(height: 6),
                        ListingPriceText(
                          listing: listing,
                          style: AppTypography.h2(),
                        ),
                        if (listing.hasActiveDiscount) ...[
                          const SizedBox(height: 8),
                          ListingDiscountBadge(listing: listing),
                        ],
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ListingReviewsScreen(listing: listing),
                            ),
                          ),
                          child: RatingRow(
                            rating: listing.rating,
                            reviewCount: listing.reviewCount,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListingShoeSizeBadge(listing: listing),
                        if (ShoeSizes.formatDetailed(listing.attributes).isNotEmpty)
                          const SizedBox(height: 12),
                        Text(
                          _description(ownerRecord),
                          style: AppTypography.body(),
                        ),
                        if (ListingAttributeChips.hasVisibleEntries(listing)) ...[
                          const SizedBox(height: 12),
                          ListingAttributeChips(listing: listing),
                        ],
                        if (listing.tags.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: listing.tags
                                .map(
                                  (tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceMuted,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '#$tag',
                                      style: AppTypography.caption(),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        const SizedBox(height: 18),
                        if (ownerRecord != null)
                          _OwnerSellerSummary(
                            listing: listing,
                            record: ownerRecord,
                          )
                        else
                          _SellerCard(
                            listing: listing,
                            phone: _sellerPhone,
                            onContact: _contactSeller,
                          ),
                        if (!isOwner) ...[
                          const SizedBox(height: 20),
                          Text('Condition', style: AppTypography.bodyBold()),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _conditions.map((c) {
                              final selected = c == _condition;
                              return ChoiceChip(
                                label: Text(c),
                                selected: selected,
                                onSelected: (_) =>
                                    setState(() => _condition = c),
                                selectedColor: AppColors.black,
                                labelStyle: AppTypography.caption(
                                  color: selected
                                      ? AppColors.white
                                      : AppColors.textPrimary,
                                ),
                                backgroundColor: AppColors.surfaceMuted,
                                side: BorderSide.none,
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.mapPin,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Meet at Main Campus · ${listing.distanceLabel}',
                              style: AppTypography.body(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ReviewsSection(listing: listing),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 12),
                  child: _DetailBottomBar(
                    isOwner: ownerRecord != null,
                    onPressed: () {
                      if (ownerRecord != null) {
                        _openOwnerActions(
                          listing: listing,
                          record: ownerRecord,
                          sellerStore: sellerStore,
                        );
                      } else {
                        _openBuyerActions(listing);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OwnerStatusBanner extends StatelessWidget {
  const _OwnerStatusBanner({required this.record});

  final SellerListingRecord record;

  @override
  Widget build(BuildContext context) {
    final active = record.isActive;
    final listing = record.listing;
    final message = active
        ? switch (listing.availabilityType) {
            ListingAvailabilityType.ongoing =>
              'Service is live · ${listing.unitsSold} completed so far',
            ListingAvailabilityType.stock =>
              'Live on campus feed · ${listing.availabilityLabel}',
            ListingAvailabilityType.unique =>
              'One-of-a-kind item live on campus feed',
          }
        : switch (listing.lifecycleStatus) {
            ListingLifecycleStatus.soldOut => 'Sold out — restock to go live again',
            ListingLifecycleStatus.sold =>
              'Sold — relist if you have another identical item',
            _ => 'Not visible on campus feed',
          };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: active
            ? AppColors.forestGreen.withValues(alpha: 0.1)
            : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? AppColors.forestGreen : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            active ? LucideIcons.circleDot : LucideIcons.checkCircle2,
            size: 16,
            color: active ? AppColors.forestGreen : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyBold(),
            ),
          ),
          Text(record.postedLabel, style: AppTypography.caption()),
        ],
      ),
    );
  }
}

class _OwnerSellerSummary extends StatelessWidget {
  const _OwnerSellerSummary({
    required this.listing,
    required this.record,
  });

  final ListingItem listing;
  final SellerListingRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your listing stats', style: AppTypography.bodyBold()),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatChip(
                icon: LucideIcons.eye,
                label: '${record.views} views',
              ),
              const SizedBox(width: 10),
              _StatChip(
                icon: LucideIcons.messageCircle,
                label: '${record.messages} inquiries',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${listing.category} · ${record.statusLabel}',
            style: AppTypography.caption(),
          ),
          if (listing.hasActiveDiscount) ...[
            const SizedBox(height: 6),
            Text(
              'Hot deal · ${listing.discountDaysRemaining} days left',
              style: AppTypography.caption(color: AppColors.dealRed),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.caption()),
        ],
      ),
    );
  }
}

class _DetailBottomBar extends StatelessWidget {
  const _DetailBottomBar({
    required this.isOwner,
    required this.onPressed,
  });

  final bool isOwner;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.forestGreen,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            isOwner ? 'Manage listing' : 'Contact seller',
            style: AppTypography.button(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isOwner
              ? 'Edit, update status, or remove this listing.'
              : 'Message, call, or view the seller profile.',
          textAlign: TextAlign.center,
          style: AppTypography.caption(),
        ),
      ],
    );
  }
}

class _SellerCard extends StatelessWidget {
  const _SellerCard({
    required this.listing,
    required this.phone,
    required this.onContact,
  });

  final ListingItem listing;
  final String phone;
  final VoidCallback onContact;

  void _openSellerProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SellerProfileScreen(
          sellerName: listing.sellerName,
          highlightListing: listing,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openSellerProfile(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.white,
                          child: Text(
                            listing.sellerInitial,
                            style: AppTypography.bodyBold(
                              color: AppColors.forestGreen,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      listing.sellerName,
                                      style: AppTypography.bodyBold(),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (listing.isVerified) ...[
                                    const SizedBox(width: 6),
                                    const VerifiedBadge(compact: true),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Campus seller · View profile',
                                style: AppTypography.caption(
                                  color: AppColors.forestGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          LucideIcons.chevronRight,
                          size: 18,
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    RatingRow(
                      rating: listing.sellerRating,
                      reviewCount: listing.sellerReviewCount,
                      compact: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(phone, style: AppTypography.caption()),
                ),
                IconButton(
                  onPressed: onContact,
                  icon: const Icon(LucideIcons.messageCircle),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingPhotoCarousel extends StatefulWidget {
  const _ListingPhotoCarousel({required this.photos});

  final List<String> photos;

  @override
  State<_ListingPhotoCarousel> createState() => _ListingPhotoCarouselState();
}

class _ListingPhotoCarouselState extends State<_ListingPhotoCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 1,
            child: photos.length == 1
                ? ListingImage(
                    source: photos.first,
                    fit: BoxFit.cover,
                    cacheWidth: 600,
                  )
                : PageView.builder(
                    controller: _controller,
                    itemCount: photos.length,
                    onPageChanged: (value) => setState(() => _index = value),
                    itemBuilder: (context, index) => ListingImage(
                      source: photos[index],
                      fit: BoxFit.cover,
                      cacheWidth: 600,
                    ),
                  ),
          ),
        ),
        if (photos.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(photos.length, (index) {
              final active = index == _index;
              return Container(
                width: active ? 8 : 6,
                height: active ? 8 : 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.forestGreen
                      : AppColors.border,
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
