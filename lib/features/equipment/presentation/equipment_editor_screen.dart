/// Validated camera, lens, and ND-filter editor with provenance fields.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/equipment.dart';
import 'equipment_controller.dart';

typedef EquipmentSave = Future<void> Function(EquipmentItem item);

class EquipmentEditorScreen extends ConsumerStatefulWidget {
  const EquipmentEditorScreen({
    required this.kind,
    this.item,
    this.duplicate = false,
    this.onSave,
    super.key,
  });

  final EquipmentKind kind;
  final EquipmentItem? item;
  final bool duplicate;
  final EquipmentSave? onSave;

  @override
  ConsumerState<EquipmentEditorScreen> createState() =>
      _EquipmentEditorScreenState();
}

class _EquipmentEditorScreenState extends ConsumerState<EquipmentEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _first = TextEditingController();
  final _second = TextEditingController();
  final _third = TextEditingController();
  final _fourth = TextEditingController();
  final _fifth = TextEditingController();
  final _sourceNote = TextEditingController();
  final _notes = TextEditingController();
  var _source = EquipmentSource.user;
  var _accessoryKind = OpticalAccessoryKind.extensionTube;
  var _saving = false;
  String? _nameError;

  bool get _isEditing => widget.item != null && !widget.duplicate;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item == null) return;
    _name.text = widget.duplicate ? '${item.name} copy' : item.name;
    _source = item.provenance.source;
    _sourceNote.text = item.provenance.note ?? '';
    switch (item) {
      case CameraBody():
        _first.text = '${item.sensorWidthMm}';
        _second.text = '${item.sensorHeightMm}';
        _third.text = item.defaultCircleOfConfusionMm?.toString() ?? '';
        _notes.text = item.notes ?? '';
      case Lens():
        _first.text = '${item.minimumFocalLengthMm}';
        _second.text = '${item.maximumFocalLengthMm}';
        _third.text = item.minimumAperture?.toString() ?? '';
        _fourth.text = item.maximumFocalLengthMinimumAperture?.toString() ?? '';
        _fifth.text = item.minimumFocusDistanceMm?.toString() ?? '';
        _notes.text = item.notes ?? '';
      case NdFilter():
        _first.text = '${item.strengthStops}';
        _second.text = item.opticalDensity?.toString() ?? '';
        _third.text = item.filterFactor?.toString() ?? '';
        _notes.text = item.notes ?? '';
      case OpticalAccessory():
        _accessoryKind = item.kind;
        _first.text = '${item.value}';
        _notes.text = item.notes ?? '';
    }
  }

  @override
  void dispose() {
    for (final controller in <TextEditingController>[
      _name,
      _first,
      _second,
      _third,
      _fourth,
      _fifth,
      _sourceNote,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _name,
              decoration: InputDecoration(
                labelText: '${_kindLabel()} name',
                errorText: _nameError,
              ),
              textInputAction: TextInputAction.next,
              validator: _required,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: 12),
            ..._kindFields(),
            const SizedBox(height: 12),
            DropdownButtonFormField<EquipmentSource>(
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Value source'),
              initialValue: _source,
              // No bundled equipment catalog ships yet, so "bundled" is not
              // offered as a new claim. A row that already carries it must stay
              // selectable, though: Flutter asserts that the current value has
              // exactly one matching item, and silently rewriting the source of
              // an existing row would corrupt its provenance.
              items:
                  <EquipmentSource>[
                        ..._selectableSources,
                        if (!_selectableSources.contains(_source)) _source,
                      ]
                      .map(
                        (source) => DropdownMenuItem<EquipmentSource>(
                          value: source,
                          child: Text(_sourceLabel(source)),
                        ),
                      )
                      .toList(growable: false),
              onChanged: (value) => setState(() => _source = value ?? _source),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sourceNote,
              decoration: const InputDecoration(labelText: 'Source note'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(
                _saving
                    ? 'Saving…'
                    : '${_isEditing ? 'Update' : 'Save'} ${_kindLabel().toLowerCase()}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _kindFields() => switch (widget.kind) {
    EquipmentKind.camera => <Widget>[
      _numberField(_first, 'Sensor width (mm)'),
      const SizedBox(height: 12),
      _numberField(_second, 'Sensor height (mm)'),
      const SizedBox(height: 12),
      _numberField(_third, 'Default circle of confusion (mm)', optional: true),
    ],
    EquipmentKind.lens => <Widget>[
      _numberField(_first, 'Minimum focal length (mm)'),
      const SizedBox(height: 12),
      _numberField(_second, 'Maximum focal length (mm)'),
      const SizedBox(height: 12),
      _numberField(_third, 'Maximum aperture (f-number)', optional: true),
      const SizedBox(height: 12),
      _numberField(
        _fourth,
        'Maximum focal length aperture (f-number)',
        optional: true,
      ),
      const SizedBox(height: 12),
      _numberField(_fifth, 'Minimum focus distance (mm)', optional: true),
    ],
    EquipmentKind.filter => <Widget>[
      _numberField(_first, 'Filter strength (stops)', allowZero: true),
      const SizedBox(height: 12),
      _numberField(_second, 'Optical density', optional: true, allowZero: true),
      const SizedBox(height: 12),
      _numberField(_third, 'Filter factor', optional: true),
    ],
    EquipmentKind.accessory => <Widget>[
      DropdownButtonFormField<OpticalAccessoryKind>(
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Accessory type'),
        initialValue: _accessoryKind,
        items: const [
          DropdownMenuItem(
            value: OpticalAccessoryKind.extensionTube,
            child: Text('Extension tube'),
          ),
          DropdownMenuItem(
            value: OpticalAccessoryKind.teleconverter,
            child: Text('Teleconverter'),
          ),
        ],
        onChanged: (value) =>
            setState(() => _accessoryKind = value ?? _accessoryKind),
      ),
      const SizedBox(height: 12),
      _numberField(
        _first,
        _accessoryKind == OpticalAccessoryKind.extensionTube
            ? 'Extension length (mm)'
            : 'Magnification factor (×)',
      ),
    ],
  };

  TextFormField _numberField(
    TextEditingController controller,
    String label, {
    bool optional = false,
    bool allowZero = false,
  }) => TextFormField(
    controller: controller,
    decoration: InputDecoration(labelText: label),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    validator: (value) =>
        _positiveNumber(value, optional: optional, allowZero: allowZero),
  );

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    // Active names must be unique per kind. Checking here names the field
    // instead of letting the database constraint surface as a generic failure;
    // the constraint stays as the backstop for a race or another kind.
    // Use the domain's own normalization, so a name that differs only by
    // repeated spaces still matches the stored uniqueness key.
    final wanted = normalizeEquipmentName(_name.text);
    // Fail open: if the inventory is not reachable this convenience check is
    // skipped and the database constraint decides, which the catch below turns
    // into the generic recovery message. Isolated widget tests render the
    // editor without a provider scope, and a missing list must not block a save.
    var clash = false;
    try {
      clash = ref
          .read(equipmentControllerProvider)
          .items
          .any(
            (entry) =>
                entry.item.normalizedName == wanted &&
                // Only active items hold the name: the unique index is partial
                // (WHERE archived_at IS NULL), so an archived item must not
                // block a replacement.
                !entry.item.isArchived &&
                entry.item.id != widget.item?.id,
          );
    } on Object {
      clash = false;
    }
    if (clash) {
      setState(
        () => _nameError = 'Another active item already uses this name.',
      );
      return;
    }
    setState(() {
      _nameError = null;
      _saving = true;
    });
    try {
      final now = DateTime.now().toUtc();
      final provenance = EquipmentProvenance(
        source: _source,
        note: _nullableText(_sourceNote.text),
      );
      final original = widget.item;
      final id = _isEditing
          ? original!.id
          : 'equipment-${now.microsecondsSinceEpoch}';
      final createdAt = _isEditing ? original!.createdAt : now;
      final archivedAt = _isEditing ? original!.archivedAt : null;
      final item = switch (widget.kind) {
        EquipmentKind.camera => CameraBody(
          id: id,
          name: _name.text,
          sensorWidthMm: _value(_first),
          sensorHeightMm: _value(_second),
          defaultCircleOfConfusionMm: _optionalValue(_third),
          notes: _nullableText(_notes.text),
          provenance: provenance,
          createdAt: createdAt,
          updatedAt: now,
          archivedAt: archivedAt,
        ),
        EquipmentKind.lens => Lens(
          id: id,
          name: _name.text,
          minimumFocalLengthMm: _value(_first),
          maximumFocalLengthMm: _value(_second),
          minimumAperture: _optionalValue(_third),
          maximumFocalLengthMinimumAperture: _optionalValue(_fourth),
          minimumFocusDistanceMm: _optionalValue(_fifth),
          notes: _nullableText(_notes.text),
          provenance: provenance,
          createdAt: createdAt,
          updatedAt: now,
          archivedAt: archivedAt,
        ),
        EquipmentKind.filter => NdFilter(
          id: id,
          name: _name.text,
          strengthStops: _value(_first),
          opticalDensity: _optionalValue(_second),
          filterFactor: _optionalValue(_third),
          notes: _nullableText(_notes.text),
          provenance: provenance,
          createdAt: createdAt,
          updatedAt: now,
          archivedAt: archivedAt,
        ),
        EquipmentKind.accessory => OpticalAccessory(
          id: id,
          name: _name.text,
          kind: _accessoryKind,
          value: _value(_first),
          notes: _nullableText(_notes.text),
          provenance: provenance,
          createdAt: createdAt,
          updatedAt: now,
          archivedAt: archivedAt,
        ),
      };
      final save = widget.onSave;
      final bool saved;
      if (save != null) {
        await save(item);
        saved = true;
      } else if (_isEditing) {
        saved = await ref
            .read(equipmentControllerProvider.notifier)
            .update(item);
      } else {
        saved = await ref
            .read(equipmentControllerProvider.notifier)
            .create(item);
      }
      if (!saved) {
        // The controller reports failure instead of throwing, so the editor
        // keeps the form open with the user's values intact.
        if (mounted) _reportSaveFailure();
        return;
      }
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } on Object {
      if (mounted) _reportSaveFailure();
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _reportSaveFailure() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Equipment could not be saved. Check the values and try again.',
        ),
      ),
    );
  }

  String _kindLabel() => switch (widget.kind) {
    EquipmentKind.camera => 'Camera',
    EquipmentKind.lens => 'Lens',
    EquipmentKind.filter => 'ND filter',
    EquipmentKind.accessory => 'Optical accessory',
  };
}

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required' : null;

String? _positiveNumber(
  String? value, {
  required bool optional,
  required bool allowZero,
}) {
  if (value == null || value.trim().isEmpty) {
    return optional ? null : 'This field is required';
  }
  final parsed = double.tryParse(value);
  if (parsed == null ||
      !parsed.isFinite ||
      (allowZero ? parsed < 0 : parsed <= 0)) {
    return allowZero
        ? 'Enter zero or a number greater than zero'
        : 'Enter a number greater than zero';
  }
  return null;
}

double _value(TextEditingController controller) =>
    double.parse(controller.text);
double? _optionalValue(TextEditingController controller) =>
    controller.text.trim().isEmpty ? null : double.parse(controller.text);
String? _nullableText(String value) =>
    value.trim().isEmpty ? null : value.trim();

String _sourceLabel(EquipmentSource source) => switch (source) {
  EquipmentSource.user => 'User entered',
  EquipmentSource.bundled => 'Bundled specification',
  EquipmentSource.userOverride => 'User override',
};

/// Sources a user may newly claim; see the dropdown comment above.
const List<EquipmentSource> _selectableSources = <EquipmentSource>[
  EquipmentSource.user,
  EquipmentSource.userOverride,
];
