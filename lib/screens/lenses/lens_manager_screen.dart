import 'package:camera_assistant/data/database/lens_library_transfer.dart';
import 'package:camera_assistant/data/database/lens_database.dart';
import 'package:camera_assistant/domain/models/lens.dart';
import 'package:camera_assistant/domain/models/mount_preset.dart';
import 'package:camera_assistant/shared/utils/formatters.dart';
import 'package:camera_assistant/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LensManagerScreen extends StatefulWidget {
  const LensManagerScreen({super.key});

  @override
  State<LensManagerScreen> createState() => _LensManagerScreenState();
}

class _LensManagerScreenState extends State<LensManagerScreen> {
  final _db = LensDatabase.instance;
  List<Lens> _lenses = const [];
  bool _loading = true;
  bool _transferring = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final lenses = await _db.getLenses();
    if (!mounted) {
      return;
    }
    setState(() {
      _lenses = lenses;
      _loading = false;
    });
  }

  Future<void> _createLens() async {
    final lens = await _openLensEditor();
    if (lens == null) {
      return;
    }
    await _db.insertLens(lens);
    await _reload();
  }

  Future<void> _editLens(Lens existing) async {
    final updated = await _openLensEditor(initial: existing);
    if (updated == null) {
      return;
    }
    await _db.updateLens(updated.copyWith(id: existing.id));
    await _reload();
  }

  Future<Lens?> _openLensEditor({Lens? initial}) {
    return Navigator.of(context).push<Lens>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _LensEditorScreen(initial: initial),
      ),
    );
  }

  Future<void> _deleteLens(Lens lens) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Lens'),
            content: Text('Delete "${lens.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || lens.id == null) {
      return;
    }
    await _db.deleteLens(lens.id!);
    await _reload();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _exportLensLibrary() async {
    setState(() => _transferring = true);

    try {
      final backupJson = await _db.exportLensLibrary();
      await Clipboard.setData(ClipboardData(text: backupJson));
      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (context) => _LensExportDialog(
          lensCount: _lenses.length,
          backupJson: backupJson,
        ),
      );

      if (!mounted) {
        return;
      }
      final noun = _lenses.length == 1 ? 'lens' : 'lenses';
      _showMessage(
          'Copied ${_lenses.length} $noun backup JSON to the clipboard.');
    } catch (_) {
      if (mounted) {
        _showMessage('Could not export the lens library.');
      }
    } finally {
      if (mounted) {
        setState(() => _transferring = false);
      }
    }
  }

  Future<void> _importLensLibrary() async {
    final request = await showDialog<_LensImportRequest>(
      context: context,
      builder: (context) => const _LensImportDialog(),
    );

    if (!mounted || request == null) {
      return;
    }

    late final List<Lens> importedLenses;
    try {
      importedLenses = LensLibraryTransfer.decode(request.rawJson);
    } on FormatException catch (error) {
      _showMessage(error.message.toString());
      return;
    } catch (_) {
      _showMessage('Could not read that lens backup JSON.');
      return;
    }

    if (request.replaceExisting && _lenses.isNotEmpty) {
      final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Replace lens library'),
              content: Text(
                'This will delete ${_lenses.length} saved lenses and import '
                '${importedLenses.length} lenses from the backup.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Replace'),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirmed || !mounted) {
        return;
      }
    }

    setState(() => _transferring = true);

    try {
      final importedCount = await _db.importLensLibrary(
        request.rawJson,
        replaceExisting: request.replaceExisting,
      );
      await _reload();
      if (!mounted) {
        return;
      }

      final noun = importedCount == 1 ? 'lens' : 'lenses';
      final verb = request.replaceExisting ? 'Imported' : 'Added';
      _showMessage('$verb $importedCount $noun.');
    } on FormatException catch (error) {
      if (mounted) {
        _showMessage(error.message.toString());
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Could not import the lens library.');
      }
    } finally {
      if (mounted) {
        setState(() => _transferring = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loading || _transferring;

    return Scaffold(
      appBar: AppBar(title: const Text('Lens Manager')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              SectionCard(
                title: 'Lens Library',
                subtitle:
                    'Save your lenses so calculators can fill in values for you.',
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: busy ? null : _createLens,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Lens'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: busy ? null : _exportLensLibrary,
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('Export JSON'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: busy ? null : _importLensLibrary,
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Import JSON'),
                      ),
                    ],
                  ),
                  if (_transferring) ...[
                    const SizedBox(height: 10),
                    const LinearProgressIndicator(),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    'Back up the full lens library as JSON or restore it from a backup.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(18),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_lenses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text('No lenses yet. Add your first lens.'),
                    )
                  else
                    ..._lenses.map(
                      (lens) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _LensTile(
                          lens: lens,
                          onEdit: () => _editLens(lens),
                          onDelete: () => _deleteLens(lens),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LensExportDialog extends StatelessWidget {
  const _LensExportDialog({
    required this.lensCount,
    required this.backupJson,
  });

  final int lensCount;
  final String backupJson;

  @override
  Widget build(BuildContext context) {
    final noun = lensCount == 1 ? 'lens' : 'lenses';
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: const Text('Lens Backup Ready'),
      content: SizedBox(
        width: 640,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Copied $lensCount $noun to the clipboard.'),
            const SizedBox(height: 8),
            Text(
              'Save this JSON somewhere safe so you can restore the library later.',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: SingleChildScrollView(
                child: SelectableText(
                  backupJson,
                  style: textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _LensImportRequest {
  const _LensImportRequest({
    required this.rawJson,
    required this.replaceExisting,
  });

  final String rawJson;
  final bool replaceExisting;
}

class _LensImportDialog extends StatefulWidget {
  const _LensImportDialog();

  @override
  State<_LensImportDialog> createState() => _LensImportDialogState();
}

class _LensImportDialogState extends State<_LensImportDialog> {
  late final TextEditingController _jsonController;
  bool _replaceExisting = true;
  bool _pasting = false;

  @override
  void initState() {
    super.initState();
    _jsonController = TextEditingController();
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _pasteClipboard() async {
    setState(() => _pasting = true);

    try {
      final data = await Clipboard.getData('text/plain');
      final text = data?.text?.trim();
      if (!mounted || text == null || text.isEmpty) {
        return;
      }
      _jsonController.text = text;
    } finally {
      if (mounted) {
        setState(() => _pasting = false);
      }
    }
  }

  void _submit() {
    final rawJson = _jsonController.text.trim();
    if (rawJson.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      _LensImportRequest(
        rawJson: rawJson,
        replaceExisting: _replaceExisting,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import Lens Backup'),
      content: SizedBox(
        width: 640,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste the JSON exported from Camera Assistant.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _jsonController,
              minLines: 12,
              maxLines: 16,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: '{\n  "lenses": []\n}',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _pasting ? null : _pasteClipboard,
                  icon: const Icon(Icons.content_paste_go_outlined),
                  label: const Text('Paste clipboard'),
                ),
              ],
            ),
            CheckboxListTile(
              value: _replaceExisting,
              contentPadding: EdgeInsets.zero,
              title: const Text('Replace current lens library'),
              subtitle: const Text('Turn this off to append imported lenses.'),
              onChanged: (value) {
                setState(() => _replaceExisting = value ?? true);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _jsonController.text.trim().isEmpty ? null : _submit,
          child: const Text('Import'),
        ),
      ],
    );
  }
}

class _LensTile extends StatelessWidget {
  const _LensTile({
    required this.lens,
    required this.onEdit,
    required this.onDelete,
  });

  final Lens lens;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final identity = lens.identityLabel == lens.name
        ? null
        : '${lens.identityLabel} | ${lens.name}';
    final metadata = <String>[
      if ((lens.mount ?? '').isNotEmpty) lens.mount!,
      lens.focusType.label,
      lens.stabilization.label,
      lens.ownershipStatus.label,
      if (lens.condition != null) lens.condition!.label,
    ];
    final physical = <String>[
      if (lens.weightG != null) '${_formatWholeNumber(lens.weightG)} g',
      if (lens.lengthMm != null) 'L ${_formatWholeNumber(lens.lengthMm)} mm',
      if (lens.diameterMm != null)
        'D ${_formatWholeNumber(lens.diameterMm)} mm',
      if (lens.filterThreadMm != null)
        'Filter ${_formatWholeNumber(lens.filterThreadMm)} mm',
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border:
            Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lens.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                if (identity != null) Text(identity),
                Text('${lens.focalLabel} | ${lens.apertureLabel}'),
                Text(
                  'Min focus: ${lens.minFocusDistanceM.toStringAsFixed(2)} m'
                  '${lens.apertureBlades == null ? '' : ' | ${lens.apertureBlades} blades'}',
                ),
                if (metadata.isNotEmpty) Text(metadata.join(' | ')),
                if (physical.isNotEmpty) Text(physical.join(' | ')),
                if ((lens.serialNumber ?? '').isNotEmpty)
                  Text('Serial: ${lens.serialNumber}'),
                if (lens.purchaseDate != null || lens.purchasePrice != null)
                  Text(
                    [
                      if (lens.purchaseDate != null)
                        'Purchased ${_formatDate(lens.purchaseDate!)}',
                      if (lens.purchasePrice != null)
                        'Price ${lens.purchasePrice!.toStringAsFixed(2)}',
                    ].join(' | '),
                  ),
                if ((lens.notes ?? '').isNotEmpty) Text(lens.notes!),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _LensEditorScreen extends StatefulWidget {
  const _LensEditorScreen({this.initial});

  final Lens? initial;

  @override
  State<_LensEditorScreen> createState() => _LensEditorScreenState();
}

class _LensEditorScreenState extends State<_LensEditorScreen> {
  late final TextEditingController _name;
  late final TextEditingController _brand;
  late final TextEditingController _model;
  late final TextEditingController _serialNumber;
  late final TextEditingController _singleFocal;
  late final TextEditingController _zoomMinFocal;
  late final TextEditingController _zoomMaxFocal;
  late final TextEditingController _minApertureWide;
  late final TextEditingController _minApertureTele;
  late final TextEditingController _maxAperture;
  late final TextEditingController _minFocusDistance;
  late final TextEditingController _filterThread;
  late final TextEditingController _apertureBlades;
  late final TextEditingController _weight;
  late final TextEditingController _length;
  late final TextEditingController _diameter;
  late final TextEditingController _purchaseDate;
  late final TextEditingController _purchasePrice;
  late final TextEditingController _notes;

  late bool _isZoom;
  late bool _variableAperture;
  late LensFocusType _focusType;
  late LensStabilization _stabilization;
  late LensOwnershipStatus _ownershipStatus;
  late String? _selectedMount;
  LensCondition? _condition;
  String? _error;

  List<String> get _mountOptions {
    final options =
        mountPresets.map((mount) => mount.name).toList(growable: false);
    final currentMount = _selectedMount?.trim();
    if (currentMount != null &&
        currentMount.isNotEmpty &&
        !options.contains(currentMount)) {
      return [currentMount, ...options];
    }
    return options;
  }

  String _mountDisplayLabel(String mount) {
    for (final preset in mountPresets) {
      if (preset.name == mount) {
        return preset.label;
      }
    }
    return mount;
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _isZoom = initial?.isZoom ?? false;
    _variableAperture = initial?.variableAperture ?? false;
    _focusType = initial?.focusType ?? LensFocusType.manual;
    _stabilization = initial?.stabilization ?? LensStabilization.none;
    _ownershipStatus = initial?.ownershipStatus ?? LensOwnershipStatus.owned;
    _selectedMount = _resolveInitialMount(initial?.mount);
    _condition = initial?.condition;
    _name = TextEditingController(text: initial?.name ?? '');
    _brand = TextEditingController(text: initial?.brand ?? '');
    _model = TextEditingController(text: initial?.model ?? '');
    _serialNumber = TextEditingController(text: initial?.serialNumber ?? '');
    _singleFocal = TextEditingController(
      text: (initial?.minFocalLengthMm ?? 50).toStringAsFixed(0),
    );
    _zoomMinFocal = TextEditingController(
      text: (initial?.minFocalLengthMm ?? 24).toStringAsFixed(0),
    );
    _zoomMaxFocal = TextEditingController(
      text: (initial?.maxFocalLengthMm ?? 70).toStringAsFixed(0),
    );
    _minApertureWide = TextEditingController(
      text: (initial?.minApertureWide ?? 2.8).toStringAsFixed(1),
    );
    _minApertureTele = TextEditingController(
      text: (initial?.minApertureTele ?? 4.0).toStringAsFixed(1),
    );
    _maxAperture = TextEditingController(
      text: (initial?.maxAperture ?? 22.0).toStringAsFixed(1),
    );
    _minFocusDistance = TextEditingController(
      text: (initial?.minFocusDistanceM ?? 0.3).toStringAsFixed(2),
    );
    _filterThread = TextEditingController(
      text: initial?.filterThreadMm == null
          ? ''
          : _formatMaybeDecimal(initial!.filterThreadMm!),
    );
    _apertureBlades =
        TextEditingController(text: initial?.apertureBlades?.toString() ?? '');
    _weight = TextEditingController(
      text: initial?.weightG == null
          ? ''
          : _formatMaybeDecimal(initial!.weightG!),
    );
    _length = TextEditingController(
      text: initial?.lengthMm == null
          ? ''
          : _formatMaybeDecimal(initial!.lengthMm!),
    );
    _diameter = TextEditingController(
      text: initial?.diameterMm == null
          ? ''
          : _formatMaybeDecimal(initial!.diameterMm!),
    );
    _purchaseDate = TextEditingController(
      text: initial?.purchaseDate == null
          ? ''
          : _formatDate(initial!.purchaseDate!),
    );
    _purchasePrice = TextEditingController(
      text: initial?.purchasePrice == null
          ? ''
          : initial!.purchasePrice!.toStringAsFixed(2),
    );
    _notes = TextEditingController(text: initial?.notes ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _model.dispose();
    _serialNumber.dispose();
    _singleFocal.dispose();
    _zoomMinFocal.dispose();
    _zoomMaxFocal.dispose();
    _minApertureWide.dispose();
    _minApertureTele.dispose();
    _maxAperture.dispose();
    _minFocusDistance.dispose();
    _filterThread.dispose();
    _apertureBlades.dispose();
    _weight.dispose();
    _length.dispose();
    _diameter.dispose();
    _purchaseDate.dispose();
    _purchasePrice.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _resolveInitialMount(String? mount) {
    final preset = resolveMountPreset(mount);
    if (preset != null) {
      return preset.name;
    }
    final cleaned = mount?.trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }

  Future<void> _pickPurchaseDate() async {
    final now = DateTime.now();
    final initialDate = _parseDateInput(_purchaseDate.text) ??
        widget.initial?.purchaseDate ??
        now;
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 5, 12, 31),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _purchaseDate.text = _formatDate(selected);
    });
  }

  void _submit() {
    final name = _name.text.trim();
    final brand = _cleanOptionalText(_brand.text);
    final model = _cleanOptionalText(_model.text);
    final serialNumber = _cleanOptionalText(_serialNumber.text);
    final mount =
        _selectedMount?.trim().isEmpty ?? true ? null : _selectedMount!.trim();
    final wideMin = parseDouble(_minApertureWide.text);
    final teleMin = parseDouble(_minApertureTele.text);
    final maxA = parseDouble(_maxAperture.text);
    final minFocus = parseDouble(_minFocusDistance.text);
    final filterThread = _parseOptionalDouble(_filterThread.text);
    final apertureBlades = _parseOptionalInt(_apertureBlades.text);
    final weight = _parseOptionalDouble(_weight.text);
    final length = _parseOptionalDouble(_length.text);
    final diameter = _parseOptionalDouble(_diameter.text);
    final purchaseDate = _parseDateInput(_purchaseDate.text);
    final purchasePrice = _parseOptionalDouble(_purchasePrice.text);
    final notes = _cleanOptionalText(_notes.text);

    final minF = _isZoom
        ? parseDouble(_zoomMinFocal.text)
        : parseDouble(_singleFocal.text);
    final maxF = _isZoom
        ? parseDouble(_zoomMaxFocal.text)
        : parseDouble(_singleFocal.text);

    if (name.isEmpty ||
        wideMin == null ||
        teleMin == null ||
        maxA == null ||
        minFocus == null ||
        minF == null ||
        maxF == null ||
        filterThread == _invalidDouble ||
        weight == _invalidDouble ||
        length == _invalidDouble ||
        diameter == _invalidDouble ||
        purchasePrice == _invalidDouble ||
        apertureBlades == _invalidInt) {
      setState(() => _error = 'Fill all fields with valid numbers.');
      return;
    }

    if (wideMin <= 0 ||
        teleMin <= 0 ||
        maxA <= 0 ||
        minFocus <= 0 ||
        minF <= 0 ||
        maxF <= 0 ||
        (filterThread is double && filterThread <= 0) ||
        (weight is double && weight <= 0) ||
        (length is double && length <= 0) ||
        (diameter is double && diameter <= 0) ||
        (purchasePrice is double && purchasePrice < 0) ||
        (apertureBlades is int && apertureBlades <= 0)) {
      setState(() => _error = 'All values must be positive.');
      return;
    }

    if (_purchaseDate.text.trim().isNotEmpty && purchaseDate == null) {
      setState(() => _error = 'Purchase date must use YYYY-MM-DD.');
      return;
    }

    if (minF > maxF) {
      setState(() => _error = 'Min focal length must be <= max focal length.');
      return;
    }

    if (!_variableAperture && wideMin != teleMin) {
      setState(() => _error =
          'For constant aperture lenses, wide and tele values must match.');
      return;
    }

    final hardestWideOpen = wideMin > teleMin ? wideMin : teleMin;
    if (maxA < hardestWideOpen) {
      setState(() => _error =
          'Max aperture must be >= the widest minimum aperture values.');
      return;
    }

    Navigator.of(context).pop(
      Lens(
        id: widget.initial?.id,
        name: name,
        brand: brand,
        model: model,
        serialNumber: serialNumber,
        mount: mount,
        minApertureWide: wideMin,
        minApertureTele: _variableAperture ? teleMin : wideMin,
        maxAperture: maxA,
        variableAperture: _variableAperture,
        minFocalLengthMm: minF,
        maxFocalLengthMm: maxF,
        minFocusDistanceM: minFocus,
        filterThreadMm: filterThread is double ? filterThread : null,
        apertureBlades: apertureBlades is int ? apertureBlades : null,
        focusType: _focusType,
        stabilization: _stabilization,
        weightG: weight is double ? weight : null,
        lengthMm: length is double ? length : null,
        diameterMm: diameter is double ? diameter : null,
        notes: notes,
        purchaseDate: purchaseDate,
        purchasePrice: purchasePrice is double ? purchasePrice : null,
        condition: _condition,
        ownershipStatus: _ownershipStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mountLabel =
        _selectedMount?.trim().isEmpty ?? true ? null : _selectedMount!.trim();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'Add Lens' : 'Edit Lens'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 120),
          children: [
            Card(
              clipBehavior: Clip.antiAlias,
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primaryContainer.withValues(alpha: 0.92),
                      scheme.tertiaryContainer.withValues(alpha: 0.62),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name.text.trim().isEmpty
                          ? 'Build a lens profile'
                          : _name.text.trim(),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Capture the lens in sections instead of squeezing everything into one small dialog.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            scheme.onPrimaryContainer.withValues(alpha: 0.86),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _EditorChip(
                          icon: _isZoom
                              ? Icons.zoom_in_map_outlined
                              : Icons.camera_alt_outlined,
                          label: _isZoom ? 'Zoom lens' : 'Prime lens',
                        ),
                        _EditorChip(
                          icon: Icons.tune_outlined,
                          label: _variableAperture
                              ? 'Variable aperture'
                              : 'Constant aperture',
                        ),
                        _EditorChip(
                          icon: Icons.sync_alt_outlined,
                          label: _ownershipStatus.label,
                        ),
                        if (mountLabel != null)
                          _EditorChip(
                            icon: Icons.link_outlined,
                            label: mountLabel,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SectionCard(
              title: 'Identity',
              subtitle:
                  'Naming, brand, model, and mount information stay readable here.',
              children: [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Lens name'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _brand,
                  decoration: const InputDecoration(labelText: 'Brand'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _model,
                  decoration: const InputDecoration(labelText: 'Model'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _selectedMount,
                  decoration: const InputDecoration(labelText: 'Mount'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Not set'),
                    ),
                    ..._mountOptions.map(
                      (mount) => DropdownMenuItem<String?>(
                        value: mount,
                        child: Text(_mountDisplayLabel(mount)),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedMount = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _serialNumber,
                  decoration: const InputDecoration(labelText: 'Serial number'),
                ),
              ],
            ),
            SectionCard(
              title: 'Optics',
              subtitle:
                  'Core focal, aperture, and focus data used by the calculators.',
              children: [
                _ModePanel(
                  title: 'Lens layout',
                  subtitle:
                      'Choose the focal range style and aperture behavior first.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, label: Text('Prime')),
                          ButtonSegment(value: true, label: Text('Zoom')),
                        ],
                        selected: {_isZoom},
                        onSelectionChanged: (selected) {
                          setState(() => _isZoom = selected.first);
                        },
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Variable aperture lens'),
                        subtitle: const Text('Example: f/3.5-5.6'),
                        value: _variableAperture,
                        onChanged: (value) =>
                            setState(() => _variableAperture = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_isZoom) ...[
                  TextField(
                    controller: _zoomMinFocal,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Min focal length (mm)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _zoomMaxFocal,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Max focal length (mm)'),
                  ),
                ] else ...[
                  TextField(
                    controller: _singleFocal,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Focal length (mm)'),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _minApertureWide,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: _variableAperture
                        ? 'Min aperture at wide focal'
                        : 'Minimum aperture (f-number)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _minApertureTele,
                  enabled: _variableAperture,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Min aperture at tele focal',
                    helperText: _variableAperture
                        ? null
                        : 'Matches the wide value for constant-aperture lenses.',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _maxAperture,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Max aperture (f-number)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _minFocusDistance,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Minimum focus distance (m)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _filterThread,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Filter thread (mm)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _apertureBlades,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Aperture blades'),
                ),
              ],
            ),
            SectionCard(
              title: 'Handling & Build',
              subtitle:
                  'Mechanical behavior and physical dimensions for real-world use.',
              children: [
                DropdownButtonFormField<LensFocusType>(
                  initialValue: _focusType,
                  decoration: const InputDecoration(labelText: 'Focus type'),
                  items: LensFocusType.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _focusType = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<LensStabilization>(
                  initialValue: _stabilization,
                  decoration: const InputDecoration(labelText: 'Stabilization'),
                  items: LensStabilization.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _stabilization = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _weight,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Weight (g)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _length,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Length (mm)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _diameter,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Diameter (mm)'),
                ),
              ],
            ),
            SectionCard(
              title: 'Ownership',
              subtitle:
                  'Track status, condition, and purchase details without mixing them into optics.',
              children: [
                DropdownButtonFormField<LensOwnershipStatus>(
                  initialValue: _ownershipStatus,
                  decoration:
                      const InputDecoration(labelText: 'Ownership status'),
                  items: LensOwnershipStatus.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _ownershipStatus = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<LensCondition?>(
                  initialValue: _condition,
                  decoration: const InputDecoration(labelText: 'Condition'),
                  items: [
                    const DropdownMenuItem<LensCondition?>(
                      value: null,
                      child: Text('Not set'),
                    ),
                    ...LensCondition.values.map(
                      (value) => DropdownMenuItem<LensCondition?>(
                        value: value,
                        child: Text(value.label),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _condition = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _purchaseDate,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Purchase date',
                    hintText: 'YYYY-MM-DD',
                    suffixIcon: IconButton(
                      onPressed: _pickPurchaseDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                  onTap: _pickPurchaseDate,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _purchasePrice,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Purchase price'),
                ),
              ],
            ),
            SectionCard(
              title: 'Notes',
              subtitle:
                  'For quirks, adapter details, or anything not worth a dedicated field.',
              children: [
                TextField(
                  controller: _notes,
                  minLines: 5,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withValues(alpha: 0.97),
            border: Border(
              top: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
          child: Row(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: scheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save Lens'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModePanel extends StatelessWidget {
  const _ModePanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _EditorChip extends StatelessWidget {
  const _EditorChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.onPrimaryContainer.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onPrimaryContainer),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

const Object _invalidDouble = Object();
const Object _invalidInt = Object();

Object? _parseOptionalDouble(String text) {
  final cleaned = text.trim();
  if (cleaned.isEmpty) {
    return null;
  }
  return parseDouble(cleaned) ?? _invalidDouble;
}

Object? _parseOptionalInt(String text) {
  final cleaned = text.trim();
  if (cleaned.isEmpty) {
    return null;
  }
  return int.tryParse(cleaned) ?? _invalidInt;
}

String? _cleanOptionalText(String text) {
  final cleaned = text.trim();
  return cleaned.isEmpty ? null : cleaned;
}

DateTime? _parseDateInput(String text) {
  final cleaned = text.trim();
  if (cleaned.isEmpty) {
    return null;
  }
  return DateTime.tryParse(cleaned);
}

String _formatDate(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

String _formatMaybeDecimal(double value) {
  return value.truncateToDouble() == value
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}

String _formatWholeNumber(double? value) {
  if (value == null) {
    return '';
  }
  return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
}
