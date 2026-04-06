import 'package:camera_assistant/data/database/lens_database.dart';
import 'package:camera_assistant/domain/models/lens.dart';
import 'package:camera_assistant/shared/utils/formatters.dart';
import 'package:camera_assistant/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';

class LensManagerScreen extends StatefulWidget {
  const LensManagerScreen({super.key});

  @override
  State<LensManagerScreen> createState() => _LensManagerScreenState();
}

class _LensManagerScreenState extends State<LensManagerScreen> {
  final _db = LensDatabase.instance;
  List<Lens> _lenses = const [];
  bool _loading = true;

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
    final lens = await showDialog<Lens>(
      context: context,
      builder: (context) => const _LensFormDialog(),
    );
    if (lens == null) {
      return;
    }
    await _db.insertLens(lens);
    await _reload();
  }

  Future<void> _editLens(Lens existing) async {
    final updated = await showDialog<Lens>(
      context: context,
      builder: (context) => _LensFormDialog(initial: existing),
    );
    if (updated == null) {
      return;
    }
    await _db.updateLens(updated.copyWith(id: existing.id));
    await _reload();
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

  @override
  Widget build(BuildContext context) {
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: _createLens,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Lens'),
                    ),
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
                Text('${lens.focalLabel} | ${lens.apertureLabel}'),
                Text(
                    'Min focus distance: ${lens.minFocusDistanceM.toStringAsFixed(2)}m'),
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

class _LensFormDialog extends StatefulWidget {
  const _LensFormDialog({this.initial});

  final Lens? initial;

  @override
  State<_LensFormDialog> createState() => _LensFormDialogState();
}

class _LensFormDialogState extends State<_LensFormDialog> {
  late final TextEditingController _name;
  late final TextEditingController _singleFocal;
  late final TextEditingController _zoomMinFocal;
  late final TextEditingController _zoomMaxFocal;
  late final TextEditingController _minApertureWide;
  late final TextEditingController _minApertureTele;
  late final TextEditingController _maxAperture;
  late final TextEditingController _minFocusDistance;

  late bool _isZoom;
  late bool _variableAperture;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _isZoom = initial?.isZoom ?? false;
    _variableAperture = initial?.variableAperture ?? false;
    _name = TextEditingController(text: initial?.name ?? '');
    _singleFocal = TextEditingController(
        text: (initial?.minFocalLengthMm ?? 50).toStringAsFixed(0));
    _zoomMinFocal = TextEditingController(
        text: (initial?.minFocalLengthMm ?? 24).toStringAsFixed(0));
    _zoomMaxFocal = TextEditingController(
        text: (initial?.maxFocalLengthMm ?? 70).toStringAsFixed(0));
    _minApertureWide = TextEditingController(
        text: (initial?.minApertureWide ?? 2.8).toStringAsFixed(1));
    _minApertureTele = TextEditingController(
        text: (initial?.minApertureTele ?? 4.0).toStringAsFixed(1));
    _maxAperture = TextEditingController(
        text: (initial?.maxAperture ?? 22.0).toStringAsFixed(1));
    _minFocusDistance = TextEditingController(
        text: (initial?.minFocusDistanceM ?? 0.3).toStringAsFixed(2));
  }

  @override
  void dispose() {
    _name.dispose();
    _singleFocal.dispose();
    _zoomMinFocal.dispose();
    _zoomMaxFocal.dispose();
    _minApertureWide.dispose();
    _minApertureTele.dispose();
    _maxAperture.dispose();
    _minFocusDistance.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    final wideMin = parseDouble(_minApertureWide.text);
    final teleMin = parseDouble(_minApertureTele.text);
    final maxA = parseDouble(_maxAperture.text);
    final minFocus = parseDouble(_minFocusDistance.text);

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
        maxF == null) {
      setState(() => _error = 'Fill all fields with valid numbers.');
      return;
    }

    if (wideMin <= 0 ||
        teleMin <= 0 ||
        maxA <= 0 ||
        minFocus <= 0 ||
        minF <= 0 ||
        maxF <= 0) {
      setState(() => _error = 'All values must be positive.');
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
        minApertureWide: wideMin,
        minApertureTele: _variableAperture ? teleMin : wideMin,
        maxAperture: maxA,
        variableAperture: _variableAperture,
        minFocalLengthMm: minF,
        maxFocalLengthMm: maxF,
        minFocusDistanceM: minFocus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add Lens' : 'Edit Lens'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Lens name'),
            ),
            const SizedBox(height: 12),
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
            if (_isZoom) ...[
              TextField(
                controller: _zoomMinFocal,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Min focal length (mm)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _zoomMaxFocal,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Max focal length (mm)'),
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
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Variable aperture lens'),
              subtitle: const Text('Example: f/3.5-5.6'),
              value: _variableAperture,
              onChanged: (value) => setState(() => _variableAperture = value),
            ),
            TextField(
              controller: _minApertureWide,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: _variableAperture
                    ? 'Min aperture at wide focal (f-number)'
                    : 'Minimum aperture (f-number)',
              ),
            ),
            const SizedBox(height: 8),
            if (_variableAperture)
              TextField(
                controller: _minApertureTele,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Min aperture at tele focal (f-number)',
                ),
              )
            else
              TextField(
                controller: _minApertureTele,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Min aperture at tele focal (same as wide)',
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _maxAperture,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Max aperture (f-number)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _minFocusDistance,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Minimum focus distance (m)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
