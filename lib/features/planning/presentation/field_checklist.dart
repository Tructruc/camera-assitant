import 'package:flutter/material.dart';

class FieldChecklist extends StatefulWidget {
  const FieldChecklist({
    required this.items,
    required this.onChanged,
    super.key,
  });

  final Map<String, bool> items;
  final ValueChanged<Map<String, bool>> onChanged;

  @override
  State<FieldChecklist> createState() => _FieldChecklistState();
}

class _FieldChecklistState extends State<FieldChecklist> {
  final _customItem = TextEditingController();

  @override
  void dispose() {
    _customItem.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Field checklist',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final entry in widget.items.entries)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(entry.key),
              value: entry.value,
              onChanged: (value) => widget.onChanged({
                ...widget.items,
                entry.key: value ?? false,
              }),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customItem,
                  decoration: const InputDecoration(
                    labelText: 'Add field task',
                  ),
                  onSubmitted: (_) => _add(),
                ),
              ),
              IconButton(
                tooltip: 'Add checklist task',
                onPressed: _add,
                icon: const Icon(Icons.add_task),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  void _add() {
    final text = _customItem.text.trim();
    if (text.isEmpty || widget.items.containsKey(text)) return;
    widget.onChanged({...widget.items, text: false});
    _customItem.clear();
  }
}
