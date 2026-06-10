enum CategoryFieldType { text, dropdown, number }

enum ListingKind { product, service, ticket, job, food, other }

class CategoryField {
  const CategoryField({
    required this.key,
    required this.label,
    required this.hint,
    this.required = false,
    this.type = CategoryFieldType.text,
    this.options = const [],
  });

  final String key;
  final String label;
  final String hint;
  final bool required;
  final CategoryFieldType type;
  final List<String> options;
}

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

  bool validateAttributes(Map<String, String> attributes) {
    for (final field in requiredFields) {
      if ((attributes[field.key] ?? '').trim().isEmpty) return false;
    }
    return true;
  }

  String? firstMissingAttribute(Map<String, String> attributes) {
    for (final field in requiredFields) {
      if ((attributes[field.key] ?? '').trim().isEmpty) return field.label;
    }
    return null;
  }
}
