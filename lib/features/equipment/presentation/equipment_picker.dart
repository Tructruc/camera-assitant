/// Reusable saved-equipment selection control.
///
/// The picker only *fills* values in: it never selects an item on its own and
/// never rewrites what the photographer typed. Every value it applies stays
/// editable in the calculator's own field.
library;

import 'package:flutter/material.dart';

import '../../../app/theme/design_tokens.dart';

class EquipmentPicker<T> extends StatelessWidget {
  const EquipmentPicker({
    required this.label,
    required this.items,
    required this.itemLabel,
    required this.onSelected,
    this.value,
    this.itemDetail,
    super.key,
  });

  final String label;
  final List<T> items;
  final String Function(T item) itemLabel;
  final ValueChanged<T?> onSelected;
  final T? value;

  /// Optional one-line specification for a saved item (a sensor size, a focal
  /// range), shown quietly under its name in the opened menu. Callers that do
  /// not supply it see the plain name, exactly as before.
  final String Function(T item)? itemDetail;

  @override
  Widget build(BuildContext context) {
    // A picker with nothing to pick is noise: an optional control disappears
    // entirely rather than rendering an empty dropdown on every screen.
    if (items.isEmpty) return const SizedBox.shrink();
    final detail = itemDetail;
    // The stored selection is only shown while the kit still contains it;
    // otherwise the field reads as unset instead of tripping a framework
    // assertion over a value that is not in the list.
    final selection = items.contains(value) ? value : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppGap.md),
      child: DropdownButtonFormField<T>(
        isExpanded: true,
        // An item that carries a specification is two lines tall; the default
        // kMinInteractiveDimension item height clips it, so the menu measures
        // each entry instead.
        itemHeight: null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.inventory_2_outlined, size: 18),
        ),
        initialValue: selection,
        // The closed field is one line tall, so it shows the name alone: the
        // specification belongs to the opened menu, where an entry has room for
        // both lines. Rendering the two-line entry in the closed field
        // overflows the decorator's content box.
        selectedItemBuilder: (BuildContext context) => <Widget>[
          for (final item in items)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                itemLabel(item),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        items: items
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: _PickerEntry(
                  label: itemLabel(item),
                  detail: detail?.call(item),
                ),
              ),
            )
            .toList(growable: false),
        onChanged: onSelected,
      ),
    );
  }
}

/// One row of the opened menu: the saved item's name, and its specification
/// when the caller supplies one.
class _PickerEntry extends StatelessWidget {
  const _PickerEntry({required this.label, this.detail});

  final String label;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final text = detail;
    if (text == null || text.isEmpty) return Text(label);
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
