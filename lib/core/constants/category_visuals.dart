import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_colors.dart';

/// Visual identity for marketplace categories.
///
/// 3D icons are Microsoft Fluent Emoji (MIT) PNGs bundled under
/// [assets/category_icons/]. They render as realistic illustrated objects,
/// similar to modern e-commerce category grids.
abstract final class CategoryVisuals {
  static String assetFor(String category) {
    final slug = switch (category) {
      'All' => 'all',
      'Electronics & Gadgets' => 'electronics',
      'Phones & Tablets' => 'phones',
      'Computers & Accessories' => 'computers',
      'Fashion & Clothing' => 'fashion',
      'Shoes & Bags' => 'shoes',
      'Beauty & Personal Care' => 'beauty',
      'Books & Stationery' => 'books',
      'Courses & Notes' => 'courses',
      'Food & Snacks' => 'food',
      'Hostel & Room Essentials' => 'hostel',
      'Furniture' => 'furniture',
      'Sports & Fitness' => 'sports',
      'Services & Gigs' => 'services',
      'Tickets & Events' => 'tickets',
      'Transportation' => 'transport',
      'Health & Wellness' => 'health',
      'Art & Crafts' => 'art',
      'Baby & Kids' => 'baby',
      'Pets & Supplies' => 'pets',
      'Jobs & Internships' => 'jobs',
      'Other' => 'other',
      'Active' => 'active',
      'Sold' => 'sold',
      _ => 'other',
    };
    return 'assets/category_icons/$slug.png';
  }

  static IconData iconFor(String category) {
    return switch (category) {
      'All' => LucideIcons.layoutGrid,
      'Electronics & Gadgets' => LucideIcons.cpu,
      'Phones & Tablets' => LucideIcons.smartphone,
      'Computers & Accessories' => LucideIcons.laptop,
      'Fashion & Clothing' => LucideIcons.shirt,
      'Shoes & Bags' => LucideIcons.shoppingBag,
      'Beauty & Personal Care' => LucideIcons.sparkles,
      'Books & Stationery' => LucideIcons.bookOpen,
      'Courses & Notes' => LucideIcons.fileText,
      'Food & Snacks' => LucideIcons.utensils,
      'Hostel & Room Essentials' => LucideIcons.home,
      'Furniture' => LucideIcons.armchair,
      'Sports & Fitness' => LucideIcons.dumbbell,
      'Services & Gigs' => LucideIcons.briefcase,
      'Tickets & Events' => LucideIcons.ticket,
      'Transportation' => LucideIcons.car,
      'Health & Wellness' => LucideIcons.heartPulse,
      'Art & Crafts' => LucideIcons.palette,
      'Baby & Kids' => LucideIcons.baby,
      'Pets & Supplies' => LucideIcons.cat,
      'Jobs & Internships' => LucideIcons.graduationCap,
      'Other' => LucideIcons.moreHorizontal,
      'Active' => LucideIcons.tag,
      'Sold' => LucideIcons.checkCircle,
      _ => LucideIcons.layoutGrid,
    };
  }

  static Color colorFor(String category) {
    return switch (category) {
      'All' => const Color(0xFF5C6BC0),
      'Electronics & Gadgets' => const Color(0xFF1E88E5),
      'Phones & Tablets' => const Color(0xFF5E35B1),
      'Computers & Accessories' => const Color(0xFF00897B),
      'Fashion & Clothing' => const Color(0xFFE91E63),
      'Shoes & Bags' => const Color(0xFFEF6C00),
      'Beauty & Personal Care' => const Color(0xFFD81B60),
      'Books & Stationery' => const Color(0xFF8D6E63),
      'Courses & Notes' => const Color(0xFF3949AB),
      'Food & Snacks' => const Color(0xFFF4511E),
      'Hostel & Room Essentials' => const Color(0xFF43A047),
      'Furniture' => const Color(0xFF6D4C41),
      'Sports & Fitness' => const Color(0xFFE53935),
      'Services & Gigs' => const Color(0xFF7B1FA2),
      'Tickets & Events' => const Color(0xFF8E24AA),
      'Transportation' => const Color(0xFF1565C0),
      'Health & Wellness' => const Color(0xFF00ACC1),
      'Art & Crafts' => const Color(0xFFFF7043),
      'Baby & Kids' => const Color(0xFFEC407A),
      'Pets & Supplies' => const Color(0xFF26A69A),
      'Jobs & Internships' => AppColors.forestGreen,
      'Other' => const Color(0xFF78909C),
      'Active' => const Color(0xFF2E7D32),
      'Sold' => const Color(0xFF546E7A),
      _ => const Color(0xFF78909C),
    };
  }
}

class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 40,
    this.onDark = false,
  });

  final String category;
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final color = CategoryVisuals.colorFor(category);
    final assetPath = CategoryVisuals.assetFor(category);
    final imageSize = (size * 0.68).round();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: 0.14)
            : color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Image.asset(
        assetPath,
        width: imageSize.toDouble(),
        height: imageSize.toDouble(),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        cacheWidth: imageSize * 2,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            CategoryVisuals.iconFor(category),
            size: size * 0.45,
            color: onDark ? Colors.white : color,
          );
        },
      ),
    );
  }
}
