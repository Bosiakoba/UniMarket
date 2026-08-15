import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl, LaunchMode;
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/config/api_config.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/api_client_scope.dart';
import '../../../core/widgets/seller_store_scope.dart';
import '../../../core/navigation/listing_navigation.dart';
import '../../../core/models/carousel_banner.dart';
import '../../sell/seller_verification_benefits_screen.dart';

class VaultPromoBanner extends StatefulWidget {
  const VaultPromoBanner({super.key});

  @override
  State<VaultPromoBanner> createState() => _VaultPromoBannerState();
}

class _VaultPromoBannerState extends State<VaultPromoBanner> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;
  List<CarouselBanner> _banners = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchBanners();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchBanners() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final client = ApiClientScope.of(context);
      final list = await client.getCarouselBanners();
      if (mounted) {
        setState(() {
          _banners = list;
        });
      }
      // Preload all banner images in background so they load instantly on first view
      _preloadImages(list);
    } catch (_) {
      // Graceful fallback to default banner
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || !_pageController.hasClients) return;
      final totalSlides = _banners.isEmpty ? 1 : _banners.length;
      final next = (_currentPage + 1) % totalSlides;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _handleBannerTap(String routePath) {
    final trimmed = routePath.trim();
    if (trimmed.isEmpty) return;

    // External URLs — open in device browser
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      _openExternalUrl(trimmed);
      return;
    }

    // Internal app routes
    if (trimmed == '/benefits' || trimmed == '/verification-benefits') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const SellerVerificationBenefitsScreen(),
        ),
      );
    } else if (trimmed.startsWith('/listings/')) {
      final listingId = trimmed.substring('/listings/'.length);
      final catalog = SellerStoreScope.of(context);
      try {
        final listing = catalog.allListings.firstWhere((l) => l.id == listingId);
        ListingNavigation.openDetail(context, listing: listing, catalog: catalog);
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This listing is no longer available.')),
        );
      }
    } else if (trimmed.startsWith('/')) {
      // Try named route navigation for internal paths
      try {
        Navigator.of(context).pushNamed(trimmed);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Route not found: $trimmed')),
          );
        }
      }
    } else {
      // Fallback: treat as external URL if it looks like one
      if (trimmed.contains('.') || trimmed.contains('://')) {
        _openExternalUrl(trimmed.startsWith('http') ? trimmed : 'https://$trimmed');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot navigate to: $trimmed')),
        );
      }
    }
  }

  /// Wraps an image URL through the backend's image proxy for resized delivery.
  /// Falls back to the original URL if proxy construction fails.
  String _proxiedImageUrl(String imageUrl, {int width = 400}) {
    final trimmed = imageUrl.trim();
    if (trimmed.isEmpty) return trimmed;
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return trimmed;
    }
    final encoded = Uri.encodeComponent(trimmed);
    return '${ApiConfig.baseUrl}/api/image-proxy?url=$encoded&w=$width';
  }

  Future<void> _preloadImages(List<CarouselBanner> banners) async {
    for (final banner in banners) {
      if (banner.imageUrl.isNotEmpty) {
        try {
          final proxied = _proxiedImageUrl(banner.imageUrl, width: 400);
          await precacheImage(
            CachedNetworkImageProvider(proxied),
            context,
          );
        } catch (_) {
          // Silently skip images that fail to preload
        }
      }
    }
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid URL: $url')),
        );
      }
      return;
    }
    try {
      // Skip canLaunchUrl for http/https — a browser is always available
      // canLaunchUrl returns false on Android 11+ without explicit <queries> manifest entries
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open: $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        child: Container(
          height: 130,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final hasCustomBanners = _banners.isNotEmpty;
    final totalSlides = hasCustomBanners ? _banners.length : 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Column(
        children: [
          Container(
            height: 130,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemCount: totalSlides,
                itemBuilder: (context, index) {
                  if (!hasCustomBanners) {
                    return _buildDefaultSlide();
                  }
                  final banner = _banners[index];
                  return _buildCustomSlide(banner);
                },
              ),
            ),
          ),
          if (totalSlides > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalSlides, (index) {
                final isSelected = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 6,
                  width: isSelected ? 18 : 6,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.forestGreen
                        : AppColors.forestGreen.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDefaultSlide() {
    return GestureDetector(
      onTap: () => _handleBannerTap('/benefits'),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verified sellers get\npriority in search',
                    style: AppTypography.bodyBold().copyWith(height: 1.35),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        'Learn more',
                        style: AppTypography.caption(
                          color: AppColors.textPrimary,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        LucideIcons.arrowRight,
                        size: 14,
                        color: AppColors.textPrimary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                AppAssets.ob1Collage6,
                width: 88,
                height: 94,
                fit: BoxFit.cover,
                cacheWidth: 200,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomSlide(CarouselBanner banner) {
    return GestureDetector(
      onTap: () => _handleBannerTap(banner.routePath),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyBold().copyWith(height: 1.35),
                  ),
                  const SizedBox(height: 4),
                  if (banner.subtitle.isNotEmpty)
                    Expanded(
                      child: Text(
                        banner.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption(color: AppColors.textSecondary),
                      ),
                    ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        'Learn more',
                        style: AppTypography.caption(
                          color: AppColors.textPrimary,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        LucideIcons.arrowRight,
                        size: 14,
                        color: AppColors.textPrimary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (banner.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: _proxiedImageUrl(banner.imageUrl, width: 400),
                  width: 88,
                  height: 94,
                  fit: BoxFit.cover,
                  maxWidthDiskCache: 200,
                  maxHeightDiskCache: 214,
                  memCacheWidth: 200,
                  memCacheHeight: 214,
                  fadeInDuration: const Duration(milliseconds: 300),
                  fadeInCurve: Curves.easeIn,
                  placeholder: (_, _) => Container(
                    width: 88,
                    height: 94,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.image,
                        size: 24,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  errorWidget: (_, _, _) => Container(
                    width: 88,
                    height: 94,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.imageOff,
                        size: 24,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
