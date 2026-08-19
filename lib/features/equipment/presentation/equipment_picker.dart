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

class EquipmentOverrideControl extends StatefulWidget {
  const EquipmentOverrideControl({
    required this.label,
    required this.equipmentValue,
    required this.onOverrideChanged,
    super.key,
  });

  final String label;
  final String equipmentValue;
  final ValueChanged<String?> onOverrideChanged;

  @override
  State<EquipmentOverrideControl> createState() =>
      _EquipmentOverrideControlState();
}

class _EquipmentOverrideControlState extends State<EquipmentOverrideControl> {
  var _override = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('From saved equipment: ${widget.equipmentValue}'),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Use a one-off ${widget.label} override'),
          value: _override,
          onChanged: (value) {
            setState(() => _override = value ?? false);
            if (!_override) {
              widget.onOverrideChanged(null);
            }
          },
        ),
        if (_override)
          TextFormField(
            decoration: InputDecoration(labelText: '${widget.label} override'),
            onChanged: widget.onOverrideChanged,
          ),
      ],
    );
  }
}
