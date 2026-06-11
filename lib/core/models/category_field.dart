import '../constants/shoe_sizes.dart';

enum CategoryFieldType { text, dropdown, number, shoeSize }
class CategoryField {
  const CategoryField({
    required this.key,
    required this.label,
    required this.hint,
    this.required = false,
    this.type = CategoryFieldType.text,
    this.options = const [],
    this.visibleWhenKey,
    this.visibleWhenValues = const [],
  });

  final String key;
  final String label;
  final String hint;
  final bool required;
  final CategoryFieldType type;
  final List<String> options;
  final String? visibleWhenKey;
  final List<String> visibleWhenValues;

  bool isVisibleFor(Map<String, String> attributes) {
    if (visibleWhenKey == null || visibleWhenValues.isEmpty) return true;
    final current = attributes[visibleWhenKey!]?.trim();
    return current != null && visibleWhenValues.contains(current);
  }
}

enum ListingKind { product, service, ticket, job, food, other }

class CategoryPostingSchema {
  const CategoryPostingSchema({
    required this.category,
    required this.kind,
    required this.titleHint,
    required this.descriptionHint,
    required this.descriptionChecklist,
    required this.photoTips,
    required this.fields,
    required this.priceLabel,
    required this.priceHint,
    this.showCondition = true,
    this.conditionOptions = const ['Like new', 'Good', 'Fair', 'For parts'],
  });

  final String category;
  final ListingKind kind;
  final String titleHint;
  final String descriptionHint;
  final List<String> descriptionChecklist;
  final List<String> photoTips;
  final List<CategoryField> fields;
  final String priceLabel;
  final String priceHint;
  final bool showCondition;
  final List<String> conditionOptions;

  List<CategoryField> get requiredFields =>
      fields.where((f) => f.required).toList();

  List<CategoryField> visibleFields(Map<String, String> attributes) =>
      fields.where((f) => f.isVisibleFor(attributes)).toList();

  bool validateAttributes(Map<String, String> attributes) =>
      firstMissingAttribute(attributes) == null;

  String? firstMissingAttribute(Map<String, String> attributes) {
    for (final field in fields) {
      if (!field.isVisibleFor(attributes)) continue;
      if (field.type == CategoryFieldType.shoeSize) continue;
      if (field.required && (attributes[field.key] ?? '').trim().isEmpty) {
        return field.label;
      }
    }

    final hasShoeField =
        fields.any((field) => field.type == CategoryFieldType.shoeSize);
    if (hasShoeField) {
      return ShoeSizes.firstMissingShoeField(attributes);
    }

    return null;
  }
}
