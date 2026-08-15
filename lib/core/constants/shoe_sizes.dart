/// Structured shoe sizing for campus footwear listings.
abstract final class ShoeSizes {
  static const category = 'Shoes & Bags';

  static const shoeItemTypes = [
    'Sneakers',
    'Formal shoes',
    'Sandals',
  ];

  static const bagItemTypes = [
    'Backpack',
    'Handbag',
    'Other bag',
  ];

  static const systems = ['UK', 'US', 'EU'];

  static const genders = ["Men's", "Women's", 'Unisex'];

  static bool isShoeCategory(String? category) => category == ShoeSizes.category;

  static bool isShoeItemType(String? itemType) =>
      itemType != null && shoeItemTypes.contains(itemType);

  static bool isBagItemType(String? itemType) =>
      itemType != null && bagItemTypes.contains(itemType);

  static List<String> sizesFor({
    required String system,
    required String gender,
  }) {
    return switch (system) {
      'UK' => switch (gender) {
          "Women's" => _ukWomen,
          _ => _ukMen,
        },
      'US' => switch (gender) {
          "Women's" => _usWomen,
          _ => _usMen,
        },
      'EU' => switch (gender) {
          "Women's" => _euWomen,
          _ => _euMen,
        },
      _ => _ukMen,
    };
  }

  static String? firstMissingShoeField(Map<String, String> attributes) {
    if (!isShoeItemType(attributes['item_type'])) return null;
    if ((attributes['size_gender'] ?? '').trim().isEmpty) {
      return 'Size fit';
    }
    if ((attributes['size_system'] ?? '').trim().isEmpty) {
      return 'Size system';
    }
    if ((attributes['size_value'] ?? '').trim().isEmpty) {
      return 'Shoe size';
    }
    return null;
  }

  static String formatPrimary(Map<String, String> attributes) {
    final system = attributes['size_system']?.trim();
    final value = attributes['size_value']?.trim();
    if (system == null || system.isEmpty || value == null || value.isEmpty) {
      return attributes['size']?.trim() ?? '';
    }
    return '$system $value';
  }

  static String formatDetailed(Map<String, String> attributes) {
    final primary = formatPrimary(attributes);
    if (primary.isEmpty) return '';

    final gender = attributes['size_gender']?.trim();
    final euHint = equivalentLabel(attributes);

    final parts = <String>[primary];
    if (gender != null && gender.isNotEmpty) parts.add(gender);
    if (euHint != null && !primary.startsWith('EU ')) parts.add(euHint);

    return parts.join(' · ');
  }

  static String? equivalentLabel(Map<String, String> attributes) {
    final system = attributes['size_system']?.trim();
    final value = attributes['size_value']?.trim();
    final gender = attributes['size_gender']?.trim() ?? 'Unisex';
    if (system == null || value == null) return null;

    final eu = toEu(system: system, value: value, gender: gender);
    if (eu == null) return null;
    if (system == 'EU' && value == eu) return null;
    return 'EU $eu';
  }

  static String? toEu({
    required String system,
    required String value,
    required String gender,
  }) {
    final normalizedGender = genders.contains(gender) ? gender : 'Unisex';
    final index = sizesFor(system: system, gender: normalizedGender).indexOf(value);
    if (index < 0) return null;
    final euSizes = sizesFor(system: 'EU', gender: normalizedGender);
    if (index >= euSizes.length) return null;
    return euSizes[index];
  }

  static String labelForAttributeKey(String key) {
    return switch (key) {
      'item_type' => 'Type',
      'size_gender' => 'Fit',
      'size_system' => 'Size system',
      'size_value' => 'Size',
      'size' => 'Size',
      'brand' => 'Brand',
      'model' => 'Model',
      'bag_capacity' => 'Capacity',
      _ => key
          .split('_')
          .map(
            (part) => part.isEmpty
                ? part
                : '${part[0].toUpperCase()}${part.substring(1)}',
          )
          .join(' '),
    };
  }

  static bool shouldHideAttributeKey(String key) =>
      key == 'size_system' || key == 'size_value' || key == 'size_gender';

  static const _ukMen = [
    '3',
    '3.5',
    '4',
    '4.5',
    '5',
    '5.5',
    '6',
    '6.5',
    '7',
    '7.5',
    '8',
    '8.5',
    '9',
    '9.5',
    '10',
    '10.5',
    '11',
    '11.5',
    '12',
    '13',
  ];

  static const _ukWomen = [
    '2',
    '2.5',
    '3',
    '3.5',
    '4',
    '4.5',
    '5',
    '5.5',
    '6',
    '6.5',
    '7',
    '7.5',
    '8',
    '8.5',
    '9',
  ];

  static const _usMen = [
    '4',
    '4.5',
    '5',
    '5.5',
    '6',
    '6.5',
    '7',
    '7.5',
    '8',
    '8.5',
    '9',
    '9.5',
    '10',
    '10.5',
    '11',
    '11.5',
    '12',
    '13',
    '14',
  ];

  static const _usWomen = [
    '4',
    '4.5',
    '5',
    '5.5',
    '6',
    '6.5',
    '7',
    '7.5',
    '8',
    '8.5',
    '9',
    '10',
    '11',
  ];

  static const _euMen = [
    '36',
    '37',
    '38',
    '39',
    '40',
    '41',
    '42',
    '43',
    '44',
    '45',
    '46',
    '47',
    '48',
    '49',
  ];

  static const _euWomen = [
    '35',
    '36',
    '37',
    '38',
    '39',
    '40',
    '41',
    '42',
    '43',
    '44',
  ];
}
