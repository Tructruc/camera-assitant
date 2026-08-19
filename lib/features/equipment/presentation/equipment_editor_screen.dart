/// Validated camera, lens, and ND-filter editor with provenance fields.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/equipment.dart';
import 'equipment_controller.dart';

typedef EquipmentSave = Future<void> Function(EquipmentItem item);

class EquipmentEditorScreen extends ConsumerStatefulWidget {
  const EquipmentEditorScreen({required this.kind, this.onSave, super.key});

  final EquipmentKind kind;
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
  final _sourceNote = TextEditingController();
  final _notes = TextEditingController();
  var _source = EquipmentSource.user;
  var _saving = false;

  @override
  void dispose() {
    for (final controller in <TextEditingController>[
      _name,
      _first,
      _second,
      _third,
      _fourth,
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
              decoration: InputDecoration(labelText: '${_kindLabel()} name'),
              textInputAction: TextInputAction.next,
              validator: _required,
            ),
            const SizedBox(height: 12),
            ..._kindFields(),
            const SizedBox(height: 12),
            DropdownButtonFormField<EquipmentSource>(
              decoration: const InputDecoration(labelText: 'Value source'),
              initialValue: _source,
              items: EquipmentSource.values
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
            if (widget.kind != EquipmentKind.camera)
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(
                _saving ? 'Saving…' : 'Save ${_kindLabel().toLowerCase()}',
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
      _numberField(_fourth, 'Minimum focus distance (mm)', optional: true),
    ],
    EquipmentKind.filter => <Widget>[
      _numberField(_first, 'Filter strength (stops)', allowZero: true),
      const SizedBox(height: 12),
      _numberField(_second, 'Optical density', optional: true, allowZero: true),
      const SizedBox(height: 12),
      _numberField(_third, 'Filter factor', optional: true),
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
    setState(() => _saving = true);
    try {
      final now = DateTime.now().toUtc();
      final provenance = EquipmentProvenance(
        source: _source,
        note: _nullableText(_sourceNote.text),
      );
      final id = 'equipment-${now.microsecondsSinceEpoch}';
      final item = switch (widget.kind) {
        EquipmentKind.camera => CameraBody(
          id: id,
          name: _name.text,
          sensorWidthMm: _value(_first),
          sensorHeightMm: _value(_second),
          defaultCircleOfConfusionMm: _optionalValue(_third),
          provenance: provenance,
          createdAt: now,
          updatedAt: now,
        ),
        EquipmentKind.lens => Lens(
          id: id,
          name: _name.text,
          minimumFocalLengthMm: _value(_first),
          maximumFocalLengthMm: _value(_second),
          minimumAperture: _optionalValue(_third),
          minimumFocusDistanceMm: _optionalValue(_fourth),
          notes: _nullableText(_notes.text),
          provenance: provenance,
          createdAt: now,
          updatedAt: now,
        ),
        EquipmentKind.filter => NdFilter(
          id: id,
          name: _name.text,
          strengthStops: _value(_first),
          opticalDensity: _optionalValue(_second),
          filterFactor: _optionalValue(_third),
          notes: _nullableText(_notes.text),
          provenance: provenance,
          createdAt: now,
          updatedAt: now,
        ),
      };
      final save = widget.onSave;
      if (save != null) {
        await save(item);
      } else {
        await ref.read(equipmentControllerProvider.notifier).create(item);
      }
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Equipment could not be saved. Check the values and try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _kindLabel() => switch (widget.kind) {
    EquipmentKind.camera => 'Camera',
    EquipmentKind.lens => 'Lens',
    EquipmentKind.filter => 'ND filter',
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
