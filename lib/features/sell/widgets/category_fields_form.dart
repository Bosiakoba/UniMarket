import 'package:flutter/material.dart';

import '../../../core/models/category_field.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/uni_option_sheet.dart';
import '../../../core/widgets/uni_text_field.dart';
import 'shoe_size_selector.dart';

class CategoryFieldsForm extends StatefulWidget {
  const CategoryFieldsForm({
    super.key,
    required this.schema,
    required this.values,
    required this.onChanged,
  });

  final CategoryPostingSchema schema;
  final Map<String, String> values;
  final void Function(String key, String value) onChanged;

  @override
  State<CategoryFieldsForm> createState() => _CategoryFieldsFormState();
}

class _CategoryFieldsFormState extends State<CategoryFieldsForm> {
  final _controllers = <String, TextEditingController>{};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(CategoryField field) {
    return _controllers.putIfAbsent(
      field.key,
      () => TextEditingController(text: widget.values[field.key] ?? ''),
    );
  }

  @override
  void didUpdateWidget(covariant CategoryFieldsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.schema.category != widget.schema.category) {
      for (final controller in _controllers.values) {
        controller.dispose();
      }
      _controllers.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.schema.fields.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${widget.schema.category} details', style: AppTypography.bodyBold()),
        const SizedBox(height: 6),
        Text(
          'These fields help buyers trust your listing and improve search.',
          style: AppTypography.caption(),
        ),
        const SizedBox(height: 12),
        ...widget.schema.visibleFields(widget.values).map((field) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _FieldInput(
              field: field,
              values: widget.values,
              controller: field.type == CategoryFieldType.dropdown ||
                      field.type == CategoryFieldType.shoeSize
                  ? null
                  : _controllerFor(field),
              value: widget.values[field.key] ?? '',
              onChanged: (key, value) => widget.onChanged(key, value),
            ),
          );
        }),
      ],
    );
  }
}

class _FieldInput extends StatelessWidget {
  const _FieldInput({
    required this.field,
    required this.values,
    required this.controller,
    required this.value,
    required this.onChanged,
  });

  final CategoryField field;
  final Map<String, String> values;
  final TextEditingController? controller;
  final String value;
  final void Function(String key, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    if (field.type == CategoryFieldType.shoeSize) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(field.label, style: AppTypography.bodyBold()),
              if (field.required) ...[
                const SizedBox(width: 4),
                Text('*', style: AppTypography.bodyBold(color: Colors.red)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          ShoeSizeSelector(
            values: values,
            onChanged: onChanged,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(field.label, style: AppTypography.bodyBold()),
            if (field.required) ...[
              const SizedBox(width: 4),
              Text('*', style: AppTypography.bodyBold(color: Colors.red)),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (field.type == CategoryFieldType.dropdown)
          PickerFieldTile(
            value: value.isEmpty ? null : value,
            hint: field.hint,
            onTap: () async {
              final picked = await showUniOptionSheet<String>(
                context: context,
                title: field.label,
                subtitle: field.hint,
                options: field.options,
                labelFor: (option) => option,
                selected: value.isEmpty ? null : value,
              );
              if (picked != null) onChanged(field.key, picked);
            },
          )
        else
          UniTextField(
            hint: field.hint,
            controller: controller!,
            onChanged: (value) => onChanged(field.key, value),
            keyboardType: field.type == CategoryFieldType.number
                ? TextInputType.number
                : TextInputType.text,
          ),
      ],
    );
  }
}
