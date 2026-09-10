/// Reusable saved-equipment selection and one-off override controls.
library;

import 'package:flutter/material.dart';

class EquipmentPicker<T> extends StatelessWidget {
  const EquipmentPicker({
    required this.label,
    required this.items,
    required this.itemLabel,
    required this.onSelected,
    this.value,
    super.key,
  });

  final String label;
  final List<T> items;
  final String Function(T item) itemLabel;
  final ValueChanged<T?> onSelected;
  final T? value;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      initialValue: value,
      items: items
          .map(
            (item) =>
                DropdownMenuItem<T>(value: item, child: Text(itemLabel(item))),
          )
          .toList(growable: false),
      onChanged: onSelected,
    );
  }
}
