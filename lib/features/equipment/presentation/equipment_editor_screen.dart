/// Validated camera, lens, and ND-filter editor with provenance fields.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../domain/equipment.dart';
import 'equipment_controller.dart';
import 'equipment_specs.dart';

typedef EquipmentSave = Future<void> Function(EquipmentItem item);

/// One standard value a field can be filled with. Applying it writes the raw
/// number through the same controller the keyboard writes to, so a preset is a
/// shortcut and never a replacement for exact entry.
final class _Preset {
  const _Preset(this.label, this.apply);

  final String label;
  final VoidCallback apply;
}

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

  /// Drives the collapsed optional-details section, so a failed validation on
  /// a field the user cannot see reveals itself instead of silently refusing
  /// the save.
  final _advanced = ExpansibleController();

  var _source = EquipmentSource.user;
  var _accessoryKind = OpticalAccessoryKind.extensionTube;
  var _saving = false;
  String? _nameError;

  bool get _isEditing => widget.item != null && !widget.duplicate;

  /// Whether this kind has a collapsed optional-details section at all.
  bool get _hasAdvancedSection => switch (widget.kind) {
    EquipmentKind.camera || EquipmentKind.lens || EquipmentKind.filter => true,
    EquipmentKind.accessory => false,
  };

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
    // The tile only disposes a controller it created itself.
    _advanced.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Form(
        key: _formKey,
        child: AppContentFrame(
          child: Column(
            children: <Widget>[
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppGap.lg,
                    AppGap.lg,
                    AppGap.lg,
                    AppGap.md,
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
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
                        if (_nameError != null) {
                          setState(() => _nameError = null);
                        }
                      },
                    ),
                    const SizedBox(height: AppGap.md),
                    ..._kindFields(),
                    const SizedBox(height: AppGap.lg),
                    _GroupLabel(
                      icon: Icons.verified_outlined,
                      label: 'Provenance',
                    ),
                    const SizedBox(height: AppGap.sm),
                    DropdownButtonFormField<EquipmentSource>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Value source',
                        helperText:
                            'Where these figures came from. Saved results keep '
                            'the values they were calculated with.',
                      ),
                      initialValue: _source,
                      // No bundled equipment catalog ships yet, so "bundled" is
                      // not offered as a new claim. A row that already carries it
                      // must stay selectable, though: Flutter asserts that the
                      // current value has exactly one matching item, and
                      // silently rewriting the source of an existing row would
                      // corrupt its provenance.
                      items:
                          <EquipmentSource>[
                                ..._selectableSources,
                                if (!_selectableSources.contains(_source))
                                  _source,
                              ]
                              .map(
                                (source) => DropdownMenuItem<EquipmentSource>(
                                  value: source,
                                  child: Text(_sourceLabel(source)),
                                ),
                              )
                              .toList(growable: false),
                      onChanged: (value) =>
                          setState(() => _source = value ?? _source),
                    ),
                    const SizedBox(height: AppGap.md),
                    TextFormField(
                      controller: _sourceNote,
                      decoration: const InputDecoration(
                        labelText: 'Source note',
                      ),
                    ),
                    const SizedBox(height: AppGap.md),
                    TextFormField(
                      controller: _notes,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      maxLines: 3,
                    ),
                    if (_hasAdvancedSection) ...<Widget>[
                      const SizedBox(height: AppGap.sm),
                      _advancedSection(),
                    ],
                  ],
                ),
              ),
              _saveBar(),
            ],
          ),
        ),
      ),
    );
  }

  /// The primary action stays on screen: a long form must not have to be
  /// scrolled to its end, or past a keyboard, before it can be saved.
  Widget _saveBar() => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppGap.lg,
        AppGap.sm,
        AppGap.lg,
        AppGap.md,
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(
            _saving
                ? 'Saving…'
                : '${_isEditing ? 'Update' : 'Save'} '
                      '${_kindLabel().toLowerCase()}',
          ),
        ),
      ),
    ),
  );

  List<Widget> _kindFields() => switch (widget.kind) {
    EquipmentKind.camera => <Widget>[
      _presets(
        label: 'Sensor format',
        presets: <_Preset>[
          for (final (name, width, height) in sensorFormats)
            _Preset(name, () => _applySensorFormat(width, height)),
        ],
        helper:
            'Fills both sensor dimensions with the standard size; either '
            'field stays editable.',
      ),
      const SizedBox(height: AppGap.sm),
      _numberField(_first, 'Sensor width (mm)'),
      const SizedBox(height: AppGap.md),
      _numberField(_second, 'Sensor height (mm)'),
    ],
    EquipmentKind.lens => <Widget>[
      _presets(
        label: 'Common lenses',
        presets: <_Preset>[
          for (final range in _lensRanges)
            _Preset(
              range.$1,
              () => _applyPair(_first, range.$2, _second, range.$3),
            ),
        ],
      ),
      const SizedBox(height: AppGap.sm),
      _numberField(_first, 'Minimum focal length (mm)'),
      const SizedBox(height: AppGap.md),
      _numberField(_second, 'Maximum focal length (mm)'),
      const SizedBox(height: AppGap.md),
      _presets(
        label: 'Common apertures',
        presets: <_Preset>[
          for (final aperture in _apertures)
            _Preset('f/${equipmentNumber(aperture)}', () {
              setState(() => _setNumber(_third, aperture));
            }),
        ],
      ),
      const SizedBox(height: AppGap.sm),
      _numberField(_third, 'Maximum aperture (f-number)', optional: true),
      const SizedBox(height: AppGap.md),
      _numberField(_fifth, 'Minimum focus distance (mm)', optional: true),
    ],
    EquipmentKind.filter => <Widget>[
      _presets(
        label: 'Common strengths',
        presets: <_Preset>[
          for (final stops in _filterStops)
            _Preset(
              '$stops ${stops == 1 ? 'stop' : 'stops'}',
              () => setState(() => _setNumber(_first, stops.toDouble())),
            ),
        ],
        helper: 'Names: ND8 = 3 stops · ND64 = 6 stops · ND1000 = 10 stops.',
      ),
      const SizedBox(height: AppGap.sm),
      _numberField(_first, 'Filter strength (stops)', allowZero: true),
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
      const SizedBox(height: AppGap.md),
      _presets(
        label: _accessoryKind == OpticalAccessoryKind.extensionTube
            ? 'Common tube lengths'
            : 'Common factors',
        presets: <_Preset>[
          for (final value
              in _accessoryKind == OpticalAccessoryKind.extensionTube
                  ? _tubeLengths
                  : _converterFactors)
            _Preset(
              _accessoryKind == OpticalAccessoryKind.extensionTube
                  ? '${equipmentNumber(value)} mm'
                  : '${equipmentNumber(value)}×',
              () => setState(() => _setNumber(_first, value)),
            ),
        ],
      ),
      const SizedBox(height: AppGap.sm),
      _numberField(
        _first,
        _accessoryKind == OpticalAccessoryKind.extensionTube
            ? 'Extension length (mm)'
            : 'Magnification factor (×)',
      ),
    ],
  };

  /// The fields that are genuinely optional: an advanced model assumption, a
  /// rarely quoted specification, or a derived consistency value. They keep
  /// their exact values and their validation; the section simply opens itself
  /// when the edited item already carries one.
  Widget _advancedSection() {
    final children = switch (widget.kind) {
      EquipmentKind.camera => <Widget>[
        _numberField(
          _third,
          'Default circle of confusion (mm)',
          optional: true,
          helper: 'Leave blank to use the calculator default.',
        ),
      ],
      EquipmentKind.lens => <Widget>[
        _numberField(
          _fourth,
          'Maximum focal length aperture (f-number)',
          optional: true,
          helper: 'Only when the long end is darker than the wide end.',
        ),
      ],
      EquipmentKind.filter => <Widget>[
        _numberField(
          _second,
          'Optical density',
          optional: true,
          allowZero: true,
          helper: 'Must agree with the stops value (stops × 0.301).',
        ),
        const SizedBox(height: AppGap.md),
        _numberField(
          _third,
          'Filter factor',
          optional: true,
          helper: 'Must agree with the stops value (2^stops).',
        ),
      ],
      EquipmentKind.accessory => const <Widget>[],
    };
    final item = widget.item;
    final expanded = switch (item) {
      CameraBody(defaultCircleOfConfusionMm: final coc) => coc != null,
      Lens(maximumFocalLengthMinimumAperture: final aperture) =>
        aperture != null,
      NdFilter(opticalDensity: final density, filterFactor: final factor) =>
        density != null || factor != null,
      _ => false,
    };
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        controller: _advanced,
        initiallyExpanded: expanded,
        // Kept mounted: a hidden field must still validate, so collapsing the
        // section can never turn an invalid value into a silent save.
        maintainState: true,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: AppGap.xs),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Icon(Icons.tune),
        title: const Text('Advanced'),
        children: children,
      ),
    );
  }

  Widget _presets({
    required String label,
    required List<_Preset> presets,
    String? helper,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Wrap(
        spacing: AppGap.sm,
        runSpacing: AppGap.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          for (final preset in presets)
            ActionChip(
              label: Text(preset.label),
              onPressed: preset.apply,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
      if (helper case final text?) ...<Widget>[
        const SizedBox(height: AppGap.xs),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    ],
  );

  TextFormField _numberField(
    TextEditingController controller,
    String label, {
    bool optional = false,
    bool allowZero = false,
    String? helper,
  }) => TextFormField(
    controller: controller,
    decoration: InputDecoration(labelText: label, helperText: helper),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    validator: (value) =>
        _positiveNumber(value, optional: optional, allowZero: allowZero),
  );

  void _setNumber(TextEditingController controller, double value) {
    controller.text = equipmentNumber(value);
  }

  /// Whether a field behind the collapsed section fails the same validator its
  /// visible siblings use. Those fields stay mounted, so the form still
  /// refuses to save; this only decides whether the section must open to show
  /// the reason.
  bool _advancedFieldsInvalid() {
    bool invalid(TextEditingController controller, {bool allowZero = false}) =>
        _positiveNumber(
          controller.text,
          optional: true,
          allowZero: allowZero,
        ) !=
        null;
    return switch (widget.kind) {
      EquipmentKind.camera => invalid(_third),
      EquipmentKind.lens => invalid(_fourth),
      EquipmentKind.filter =>
        invalid(_second, allowZero: true) || invalid(_third),
      EquipmentKind.accessory => false,
    };
  }

  void _applySensorFormat(double widthMm, double heightMm) {
    setState(() {
      _setNumber(_first, widthMm);
      _setNumber(_second, heightMm);
    });
  }

  void _applyPair(
    TextEditingController first,
    double firstValue,
    TextEditingController second,
    double secondValue,
  ) {
    setState(() {
      _setNumber(first, firstValue);
      _setNumber(second, secondValue);
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      // A field inside the collapsed section still validates; bring the
      // section into view when that is where the refusal came from, so the
      // reason is readable instead of the save appearing inert.
      if (_hasAdvancedSection && _advancedFieldsInvalid()) _advanced.expand();
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
    // activeItems, not items: this is a uniqueness question against the whole
    // active inventory, so it must not inherit the inventory's own Kit kind
    // filter (a camera named like an existing lens is still a clash) while it
    // keeps skipping archived items, which the partial unique index excludes.
    var clash = false;
    try {
      clash = ref
          .read(equipmentControllerProvider)
          .activeItems
          .any(
            (entry) =>
                entry.item.normalizedName == wanted &&
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

/// A small muted group heading, matching the sections used elsewhere.
class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppGap.sm),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ],
    );
  }
}

/// Focal ranges a photographer recognizes: zooms that cover a working range,
/// then the classic single focal lengths.
const List<(String, double, double)> _lensRanges = <(String, double, double)>[
  ('16–35', 16, 35),
  ('24–70', 24, 70),
  ('24–105', 24, 105),
  ('70–200', 70, 200),
  ('100–400', 100, 400),
  ('35 mm', 35, 35),
  ('50 mm', 50, 50),
  ('85 mm', 85, 85),
  ('135 mm', 135, 135),
];

/// Widest apertures of common prime and zoom lenses.
const List<double> _apertures = <double>[1.2, 1.4, 1.8, 2, 2.8, 4, 5.6, 8, 11];

/// Whole-stop strengths of the neutral-density filters people own.
const List<int> _filterStops = <int>[1, 2, 3, 4, 6, 10, 15];

/// Extension tube lengths sold as kits.
const List<double> _tubeLengths = <double>[8, 10, 12, 16, 20, 25, 36];

/// Teleconverter magnifications.
const List<double> _converterFactors = <double>[1.4, 1.7, 2];

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
