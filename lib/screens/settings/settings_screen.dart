import 'package:flutter/material.dart';
import 'package:camera_assistant/domain/models/app_settings.dart';
import 'package:camera_assistant/domain/models/mount_preset.dart';
import 'package:camera_assistant/domain/models/sensor_preset.dart';
import 'package:camera_assistant/screens/lenses/lens_manager_screen.dart';
import 'package:camera_assistant/shared/widgets/section_card.dart';

class SettingsScreen extends StatefulWidget {
  final AppSettings settings;
  final Function(AppSettings) onSettingsChanged;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;

  static const _homeTools = [
    _HomeToolInfo(
      id: 'exposure',
      title: 'Exposure',
      subtitle: 'Match one exposure to another.',
      icon: Icons.exposure,
    ),
    _HomeToolInfo(
      id: 'dof',
      title: 'DOF',
      subtitle: 'Check depth of field and focus range.',
      icon: Icons.filter_center_focus,
    ),
    _HomeToolInfo(
      id: 'focus_stacking',
      title: 'Focus Stacking',
      subtitle: 'Plan focus positions and frame count for a stack.',
      icon: Icons.layers_outlined,
    ),
    _HomeToolInfo(
      id: 'panorama_planner',
      title: 'Panorama Planner',
      subtitle: 'Plan frames and overlap for a panorama.',
      icon: Icons.crop_landscape,
    ),
    _HomeToolInfo(
      id: 'extension_tubes',
      title: 'Extension Tubes',
      subtitle: 'See close-focus range and magnification.',
      icon: Icons.add_circle_outline,
    ),
    _HomeToolInfo(
      id: 'reverse_lens',
      title: 'Reverse Lens',
      subtitle: 'Estimate magnification and focus distance.',
      icon: Icons.sync_alt,
    ),
    _HomeToolInfo(
      id: 'dual_lens_macro',
      title: 'Dual Lens Macro',
      subtitle: 'Estimate stacked-lens magnification and exposure loss.',
      icon: Icons.join_inner,
    ),
    _HomeToolInfo(
      id: 'sun_planner',
      title: 'Sun Planner',
      subtitle: 'Plan sunrise, sunset, and golden hour.',
      icon: Icons.wb_sunny_outlined,
    ),
    _HomeToolInfo(
      id: 'long_exposure',
      title: 'Long Exposure',
      subtitle: 'Convert ND filters and estimate motion blur.',
      icon: Icons.shutter_speed,
    ),
  ];

  List<MountPreset> get _selectedMounts => mountPresets
      .where((mount) => _settings.enabledMountIds.contains(mount.id))
      .toList();

  List<SensorPreset> get _selectedSensors =>
      resolveEnabledSensorPresets(_settings.enabledSensorIds);

  int get _folderedToolCount => _settings.homeFolders.fold(
        0,
        (count, folder) => count + folder.toolIds.length,
      );

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  void _updateSettings(AppSettings newSettings) {
    setState(() => _settings = newSettings);
    widget.onSettingsChanged(newSettings);
  }

  Future<void> _editMounts() async {
    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _MountSelectorSheet(
          initialSelectedIds: _settings.enabledMountIds,
        );
      },
    );

    if (selected == null) {
      return;
    }

    _updateSettings(_settings.copyWith(enabledMountIds: selected));
  }

  Future<void> _editSensors() async {
    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _SensorSelectorSheet(
          initialSelectedIds: _settings.enabledSensorIds,
        );
      },
    );

    if (selected == null) {
      return;
    }

    _updateSettings(_settings.copyWith(enabledSensorIds: selected));
  }

  Future<void> _editHomeOrganization() async {
    final result = await showModalBottomSheet<_HomeOrganizationResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _HomeOrganizerSheet(
          tools: _homeTools,
          initialOrder: _settings.homeToolOrder,
          initialFolders: _settings.homeFolders,
        );
      },
    );

    if (result == null) {
      return;
    }

    _updateSettings(
      _settings.copyWith(
        homeToolOrder: result.homeToolOrder,
        homeFolders: result.homeFolders,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            title: 'Home Tools',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.dashboard_customize_outlined),
                title: const Text('Organize home cards'),
                subtitle: Text(
                  _settings.homeFolders.isEmpty
                      ? 'Reorder cards'
                      : '${_settings.homeFolders.length} folders, $_folderedToolCount cards in folders',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _editHomeOrganization,
              ),
            ],
          ),
          SectionCard(
            title: 'Distance Units',
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'm',
                    label: Text('Meters (m)'),
                  ),
                  ButtonSegment(
                    value: 'ft',
                    label: Text('Feet (ft)'),
                  ),
                ],
                selected: {_settings.distanceUnit},
                onSelectionChanged: (value) {
                  _updateSettings(_settings.copyWith(
                    distanceUnit: value.first,
                  ));
                },
              ),
            ],
          ),
          SectionCard(
            title: 'Time Format',
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: '12h',
                    label: Text('12-hour'),
                  ),
                  ButtonSegment(
                    value: '24h',
                    label: Text('24-hour'),
                  ),
                ],
                selected: {_settings.timeUnit},
                onSelectionChanged: (value) {
                  _updateSettings(_settings.copyWith(
                    timeUnit: value.first,
                  ));
                },
              ),
            ],
          ),
          SectionCard(
            title: 'Lens Mounts',
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedMounts
                    .map(
                      (mount) => Chip(
                        label: Text(mount.name),
                        avatar: Text(
                          mount.registerDistanceMm.toStringAsFixed(0),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_selectedMounts.length} mounts selected',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _editMounts,
                    icon: const Icon(Icons.tune),
                    label: const Text('Edit mounts'),
                  ),
                ],
              ),
            ],
          ),
          SectionCard(
            title: 'Sensor Formats',
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedSensors
                    .map(
                      (sensor) => Chip(
                        label: Text(sensor.label),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_selectedSensors.length} formats selected',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _editSensors,
                    icon: const Icon(Icons.photo_camera_back_outlined),
                    label: const Text('Edit formats'),
                  ),
                ],
              ),
            ],
          ),
          SectionCard(
            title: 'Appearance',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dark mode'),
                value: _settings.darkMode,
                onChanged: (value) {
                  _updateSettings(_settings.copyWith(darkMode: value));
                },
              ),
            ],
          ),
          SectionCard(
            title: 'Lens Library',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.camera_outlined),
                title: const Text('Edit saved lenses'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LensManagerScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          SectionCard(
            title: 'About',
            children: [
              Text(
                'Camera Assistant v0.1.0',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeToolInfo {
  const _HomeToolInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
}

class _HomeOrganizationResult {
  const _HomeOrganizationResult({
    required this.homeToolOrder,
    required this.homeFolders,
  });

  final List<String> homeToolOrder;
  final List<HomeFolder> homeFolders;
}

class _HomeOrganizerSheet extends StatefulWidget {
  const _HomeOrganizerSheet({
    required this.tools,
    required this.initialOrder,
    required this.initialFolders,
  });

  final List<_HomeToolInfo> tools;
  final List<String> initialOrder;
  final List<HomeFolder> initialFolders;

  @override
  State<_HomeOrganizerSheet> createState() => _HomeOrganizerSheetState();
}

class _HomeOrganizerSheetState extends State<_HomeOrganizerSheet> {
  static const double _previewHysteresis = 18;

  late List<String> _topLevelOrder;
  late List<HomeFolder> _folders;
  final Map<String, GlobalKey> _folderBodyKeys = {};
  final Map<String, GlobalKey> _nestedRowKeys = {};
  final Map<String, GlobalKey> _topLevelRowKeys = {};
  final GlobalKey _topLevelListKey = GlobalKey();
  int? _topLevelPreviewIndex;
  final Map<String, int> _folderPreviewIndexes = {};

  Map<String, _HomeToolInfo> get _toolsById {
    return {for (final tool in widget.tools) tool.id: tool};
  }

  @override
  void initState() {
    super.initState();
    _topLevelOrder = List<String>.from(widget.initialOrder);
    _folders = widget.initialFolders
        .map(
          (folder) =>
              folder.copyWith(toolIds: List<String>.from(folder.toolIds)),
        )
        .toList();
    _normalizeState();
  }

  Set<String> get _folderedToolIds {
    return _folders.expand((folder) => folder.toolIds).toSet();
  }

  bool _isFolderOrderKey(String value) => value.startsWith('folder:');

  bool _isToolId(String value) => _toolsById.containsKey(value);

  List<String> get _visibleTopLevelOrder {
    final folderedToolIds = _folderedToolIds;
    final validToolIds = _toolsById.keys.toSet();
    final folderKeys = _folders.map((folder) => folder.orderKey).toSet();
    final ordered = <String>[];
    final seen = <String>{};

    for (final id in _topLevelOrder) {
      final isTool = validToolIds.contains(id) && !folderedToolIds.contains(id);
      final isFolder = folderKeys.contains(id);
      if ((isTool || isFolder) && seen.add(id)) {
        ordered.add(id);
      }
    }

    for (final tool in widget.tools) {
      if (!folderedToolIds.contains(tool.id) && seen.add(tool.id)) {
        ordered.add(tool.id);
      }
    }

    for (final folder in _folders) {
      if (seen.add(folder.orderKey)) {
        ordered.add(folder.orderKey);
      }
    }

    return ordered;
  }

  void _normalizeState() {
    final validToolIds = _toolsById.keys.toSet();
    final claimed = <String>{};

    _folders = _folders.map((folder) {
      final uniqueToolIds = <String>[];
      for (final id in folder.toolIds) {
        if (validToolIds.contains(id) && claimed.add(id)) {
          uniqueToolIds.add(id);
        }
      }
      return folder.copyWith(toolIds: uniqueToolIds);
    }).toList();

    _topLevelOrder = _visibleTopLevelOrder;
  }

  Future<void> _createFolder() async {
    final name = await _promptForFolderName(
      title: 'New folder',
      actionLabel: 'Create',
    );

    if (!mounted || name == null || name.isEmpty) {
      return;
    }

    setState(() {
      final folder = HomeFolder(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        toolIds: const [],
      );
      _folders = [..._folders, folder];
      _topLevelOrder = _visibleTopLevelOrder;
    });
  }

  Future<void> _renameFolder(HomeFolder folder) async {
    final name = await _promptForFolderName(
      title: 'Rename folder',
      actionLabel: 'Save',
      initialValue: folder.name,
    );

    if (!mounted || name == null || name.isEmpty) {
      return;
    }

    setState(() {
      _folders = [
        for (final item in _folders)
          if (item.id == folder.id) item.copyWith(name: name) else item,
      ];
    });
  }

  Future<String?> _promptForFolderName({
    required String title,
    required String actionLabel,
    String initialValue = '',
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _FolderNameSheet(
          title: title,
          actionLabel: actionLabel,
          initialValue: initialValue,
        );
      },
    );
  }

  void _deleteFolder(HomeFolder folder) {
    setState(() {
      _folders = _folders.where((item) => item.id != folder.id).toList();
      _topLevelOrder = _visibleTopLevelOrder
          .where((id) => id != folder.orderKey)
          .toList(growable: false);
      _normalizeState();
    });
  }

  void _insertTopLevelItem(int index, String itemId) {
    if (!_isFolderOrderKey(itemId) && !_isToolId(itemId)) {
      return;
    }

    setState(() {
      final current = List<String>.from(_visibleTopLevelOrder)
        ..removeWhere((id) => id == itemId);
      final boundedIndex = index.clamp(0, current.length);
      current.insert(boundedIndex, itemId);
      if (_isToolId(itemId)) {
        _folders = [
          for (final item in _folders)
            item.copyWith(
              toolIds: item.toolIds.where((id) => id != itemId).toList(),
            ),
        ];
      }
      _topLevelOrder = current;
      _normalizeState();
    });
  }

  GlobalKey _folderBodyKey(String folderId) {
    return _folderBodyKeys.putIfAbsent(folderId, () => GlobalKey());
  }

  GlobalKey _topLevelRowKey(String itemId) {
    return _topLevelRowKeys.putIfAbsent(itemId, () => GlobalKey());
  }

  GlobalKey _nestedRowKey(String folderId, String toolId) {
    return _nestedRowKeys.putIfAbsent('$folderId:$toolId', () => GlobalKey());
  }

  bool _isPointInside(GlobalKey key, Offset globalOffset) {
    final context = key.currentContext;
    final box = context?.findRenderObject() as RenderBox?;
    if (box == null) {
      return false;
    }
    final rect = box.localToGlobal(Offset.zero) & box.size;
    return rect.contains(globalOffset);
  }

  int _folderInsertIndexByOffset(String folderId, Offset globalOffset) {
    final folder = _folders.firstWhere((item) => item.id == folderId);

    for (var index = 0; index < folder.toolIds.length; index++) {
      final box = _nestedRowKeys['$folderId:${folder.toolIds[index]}']
          ?.currentContext
          ?.findRenderObject() as RenderBox?;
      if (box == null) {
        continue;
      }
      final midpointY =
          box.localToGlobal(Offset.zero).dy + (box.size.height / 2);
      if (globalOffset.dy < midpointY) {
        return index;
      }
    }

    return folder.toolIds.length;
  }

  int _topLevelInsertIndexByOffset(Offset globalOffset) {
    final order = _visibleTopLevelOrder;

    for (var index = 0; index < order.length; index++) {
      final box = _topLevelRowKeys[order[index]]
          ?.currentContext
          ?.findRenderObject() as RenderBox?;
      if (box == null) {
        continue;
      }
      final midpointY =
          box.localToGlobal(Offset.zero).dy + (box.size.height / 2);
      if (globalOffset.dy < midpointY) {
        return index;
      }
    }

    return order.length;
  }

  int _topLevelDropIndexForRow(String itemId, Offset globalOffset) {
    final current = _visibleTopLevelOrder;
    final rowIndex = current.indexOf(itemId);
    if (rowIndex == -1) {
      return current.length;
    }

    final box = _topLevelRowKeys[itemId]?.currentContext?.findRenderObject()
        as RenderBox?;
    if (box == null) {
      return rowIndex;
    }

    final midpointY = box.localToGlobal(Offset.zero).dy + (box.size.height / 2);
    final currentPreview = _topLevelPreviewIndex;
    if (currentPreview == rowIndex &&
        globalOffset.dy <= midpointY + _previewHysteresis) {
      return rowIndex;
    }
    if (currentPreview == rowIndex + 1 &&
        globalOffset.dy >= midpointY - _previewHysteresis) {
      return rowIndex + 1;
    }

    return globalOffset.dy < midpointY ? rowIndex : rowIndex + 1;
  }

  int _folderDropIndexForRow(
    String folderId,
    String targetToolId,
    Offset globalOffset,
  ) {
    final folder = _folders.firstWhere((item) => item.id == folderId);
    final rowIndex = folder.toolIds.indexOf(targetToolId);
    if (rowIndex == -1) {
      return folder.toolIds.length;
    }

    final box = _nestedRowKeys['$folderId:$targetToolId']
        ?.currentContext
        ?.findRenderObject() as RenderBox?;
    if (box == null) {
      return rowIndex;
    }

    final midpointY = box.localToGlobal(Offset.zero).dy + (box.size.height / 2);
    final currentPreview = _folderPreviewIndexes[folderId];
    if (currentPreview == rowIndex &&
        globalOffset.dy <= midpointY + _previewHysteresis) {
      return rowIndex;
    }
    if (currentPreview == rowIndex + 1 &&
        globalOffset.dy >= midpointY - _previewHysteresis) {
      return rowIndex + 1;
    }

    return globalOffset.dy < midpointY ? rowIndex : rowIndex + 1;
  }

  void _clearDragPreviews() {
    if (_topLevelPreviewIndex == null && _folderPreviewIndexes.isEmpty) {
      return;
    }

    setState(() {
      _topLevelPreviewIndex = null;
      _folderPreviewIndexes.clear();
    });
  }

  void _setTopLevelPreviewIndex(int? index) {
    final normalizedIndex = index?.clamp(0, _visibleTopLevelOrder.length);
    if (_topLevelPreviewIndex == normalizedIndex &&
        _folderPreviewIndexes.isEmpty) {
      return;
    }

    setState(() {
      _topLevelPreviewIndex = normalizedIndex;
      _folderPreviewIndexes.clear();
    });
  }

  void _setFolderPreviewIndex(String folderId, int? index) {
    final folder = _folders.firstWhere((item) => item.id == folderId);
    final normalizedIndex = index?.clamp(0, folder.toolIds.length);
    if (_topLevelPreviewIndex == null &&
        _folderPreviewIndexes.length == (normalizedIndex == null ? 0 : 1) &&
        _folderPreviewIndexes[folderId] == normalizedIndex) {
      return;
    }

    setState(() {
      _topLevelPreviewIndex = null;
      _folderPreviewIndexes.clear();
      if (normalizedIndex != null) {
        _folderPreviewIndexes[folderId] = normalizedIndex;
      }
    });
  }

  void _handleToolDragEnd(String toolId, DraggableDetails details) {
    if (details.wasAccepted) {
      _clearDragPreviews();
      return;
    }
    if (_isPointInside(_topLevelListKey, details.offset)) {
      _insertTopLevelItem(_topLevelInsertIndexByOffset(details.offset), toolId);
      _clearDragPreviews();
      return;
    }
    for (final folder in _folders) {
      if (_isPointInside(_folderBodyKey(folder.id), details.offset)) {
        _insertToolAtFolder(
          folder.id,
          _folderInsertIndexByOffset(folder.id, details.offset),
          toolId,
        );
        _clearDragPreviews();
        return;
      }
    }

    _clearDragPreviews();
  }

  void _handleTopLevelItemDragEnd(String itemId, DraggableDetails details) {
    if (details.wasAccepted) {
      _clearDragPreviews();
      return;
    }
    if (_isPointInside(_topLevelListKey, details.offset)) {
      _insertTopLevelItem(_topLevelInsertIndexByOffset(details.offset), itemId);
      _clearDragPreviews();
      return;
    }

    _clearDragPreviews();
  }

  void _insertToolAtFolder(String folderId, int index, String toolId) {
    if (!_isToolId(toolId)) {
      return;
    }

    setState(() {
      _topLevelOrder = List<String>.from(_visibleTopLevelOrder)
        ..removeWhere((id) => id == toolId);
      _folders = [
        for (final item in _folders)
          item.copyWith(
            toolIds: item.toolIds.where((id) => id != toolId).toList(),
          ),
      ];
      _folders = [
        for (final item in _folders)
          if (item.id == folderId)
            item.copyWith(
              toolIds: [
                ...item.toolIds.take(index.clamp(0, item.toolIds.length)),
                toolId,
                ...item.toolIds.skip(index.clamp(0, item.toolIds.length)),
              ],
            )
          else
            item,
      ];
      _normalizeState();
    });
  }

  Widget _buildNestedDraggableToolTile(
    ThemeData theme,
    String folderId,
    _HomeToolInfo tool,
  ) {
    return Container(
      key: _nestedRowKey(folderId, tool.id),
      child: LongPressDraggable<String>(
        key: ValueKey('nested-$folderId-${tool.id}'),
        data: tool.id,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragEnd: (details) => _handleToolDragEnd(tool.id, details),
        feedback: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Card(
              child: ListTile(
                dense: true,
                leading: Icon(tool.icon, size: 20),
                title: Text(tool.title),
                trailing: const Icon(Icons.drag_handle, size: 18),
              ),
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.35,
          child: Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              dense: true,
              leading: Icon(tool.icon, size: 20),
              title: Text(tool.title),
              trailing: const Icon(Icons.drag_handle, size: 18),
            ),
          ),
        ),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: theme.cardColor.withValues(alpha: 0.72),
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 2,
            ),
            leading: Icon(tool.icon, size: 20),
            title: Text(tool.title),
            trailing: const Icon(Icons.drag_handle, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildNestedToolDropWrapper(
    ThemeData theme,
    String folderId,
    String targetToolId,
    Widget child,
  ) {
    return DragTarget<String>(
      key: ValueKey('folder-row-drop-$folderId-$targetToolId'),
      onWillAcceptWithDetails: (details) => _isToolId(details.data),
      onMove: (details) {
        _setFolderPreviewIndex(
          folderId,
          _folderDropIndexForRow(folderId, targetToolId, details.offset),
        );
      },
      onAcceptWithDetails: (details) {
        _insertToolAtFolder(
          folderId,
          _folderDropIndexForRow(folderId, targetToolId, details.offset),
          details.data,
        );
        _clearDragPreviews();
      },
      builder: (context, candidateData, rejectedData) {
        final highlight = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          decoration: BoxDecoration(
            color: highlight
                ? theme.colorScheme.tertiaryContainer.withValues(alpha: 0.24)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  highlight ? theme.colorScheme.tertiary : Colors.transparent,
            ),
          ),
          child: child,
        );
      },
    );
  }

  Widget _buildOrganizerToolRow(
    ThemeData theme,
    _HomeToolInfo tool,
  ) {
    return LongPressDraggable<String>(
      key: ValueKey('top-level-tool-${tool.id}'),
      data: tool.id,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragEnd: (details) => _handleToolDragEnd(tool.id, details),
      feedback: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Card(
            child: ListTile(
              leading: Icon(tool.icon),
              title: Text(tool.title),
              trailing: const Icon(Icons.drag_handle),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: Icon(tool.icon),
            title: Text(tool.title),
            trailing: const Icon(Icons.drag_handle),
          ),
        ),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(tool.icon),
          title: Text(tool.title),
          trailing: const Icon(Icons.drag_handle),
        ),
      ),
    );
  }

  Widget _buildFolderHeader(
    ThemeData theme,
    HomeFolder folder,
    int toolCount,
  ) {
    Widget headerContent({
      required bool highlighted,
      required bool dragged,
    }) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: highlighted
              ? theme.colorScheme.tertiaryContainer.withValues(alpha: 0.35)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.folder_open_outlined),
          title: Text(folder.name),
          subtitle: Text(
            toolCount == 0
                ? 'Drop a card here'
                : '$toolCount cards in this folder',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: dragged ? null : () => _renameFolder(folder),
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Rename folder',
              ),
              IconButton(
                onPressed: dragged ? null : () => _deleteFolder(folder),
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete folder',
              ),
              const Icon(Icons.drag_handle),
            ],
          ),
        ),
      );
    }

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => _isToolId(details.data),
      onMove: (_) => _setFolderPreviewIndex(folder.id, toolCount),
      onAcceptWithDetails: (details) {
        _insertToolAtFolder(folder.id, toolCount, details.data);
        _clearDragPreviews();
      },
      builder: (context, candidateData, rejectedData) {
        final highlight = candidateData.isNotEmpty;
        return LongPressDraggable<String>(
          data: folder.orderKey,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          onDragEnd: (details) =>
              _handleTopLevelItemDragEnd(folder.orderKey, details),
          feedback: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.folder_open_outlined),
                  title: Text(folder.name),
                  subtitle: Text(
                    toolCount == 0 ? 'Empty folder' : '$toolCount cards',
                  ),
                  trailing: const Icon(Icons.drag_handle),
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.4,
            child: headerContent(
              highlighted: highlight,
              dragged: true,
            ),
          ),
          child: headerContent(
            highlighted: highlight,
            dragged: false,
          ),
        );
      },
    );
  }

  Widget _buildOrganizerFolderRow(
    ThemeData theme,
    HomeFolder folder,
  ) {
    final folderTools = folder.toolIds
        .map((id) => _toolsById[id])
        .whereType<_HomeToolInfo>()
        .toList();

    return Card(
      key: ValueKey('top-level-folder-${folder.id}'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFolderHeader(theme, folder, folderTools.length),
            const SizedBox(height: 10),
            AnimatedContainer(
              key: ValueKey('folder-body-${folder.id}'),
              duration: const Duration(milliseconds: 160),
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 72),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest
                    .withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              child: Container(
                key: _folderBodyKey(folder.id),
                child: DragTarget<String>(
                  onWillAcceptWithDetails: (details) => _isToolId(details.data),
                  onMove: (details) {
                    _setFolderPreviewIndex(
                      folder.id,
                      _folderInsertIndexByOffset(folder.id, details.offset),
                    );
                  },
                  onAcceptWithDetails: (details) {
                    _insertToolAtFolder(
                      folder.id,
                      _folderInsertIndexByOffset(folder.id, details.offset),
                      details.data,
                    );
                    _clearDragPreviews();
                  },
                  builder: (context, candidateData, rejectedData) {
                    final highlight = candidateData.isNotEmpty;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      decoration: BoxDecoration(
                        color: highlight
                            ? theme.colorScheme.tertiaryContainer
                                .withValues(alpha: 0.20)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_folderPreviewIndexes[folder.id] == 0)
                            _buildInsertionPreview(
                              theme,
                              key: ValueKey('folder-preview-${folder.id}-0'),
                            ),
                          if (folderTools.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Long-press a card and drop it here.',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          for (var nestedIndex = 0;
                              nestedIndex < folderTools.length;
                              nestedIndex++) ...[
                            if (nestedIndex > 0) const SizedBox(height: 8),
                            _buildNestedToolDropWrapper(
                              theme,
                              folder.id,
                              folderTools[nestedIndex].id,
                              _buildNestedDraggableToolTile(
                                theme,
                                folder.id,
                                folderTools[nestedIndex],
                              ),
                            ),
                            if (_folderPreviewIndexes[folder.id] ==
                                nestedIndex + 1)
                              _buildInsertionPreview(
                                theme,
                                key: ValueKey(
                                  'folder-preview-${folder.id}-${nestedIndex + 1}',
                                ),
                              ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopLevelItem(
    ThemeData theme,
    String itemId,
  ) {
    final child = _isFolderOrderKey(itemId)
        ? _buildOrganizerFolderRow(
            theme,
            _folders.firstWhere((folder) => folder.orderKey == itemId),
          )
        : _buildOrganizerToolRow(theme, _toolsById[itemId]!);

    final acceptsTools = !_isFolderOrderKey(itemId);

    return Container(
      key: _topLevelRowKey(itemId),
      margin: const EdgeInsets.only(bottom: 10),
      child: DragTarget<String>(
        onWillAcceptWithDetails: (details) =>
            _isFolderOrderKey(details.data) ||
            (acceptsTools && _isToolId(details.data)),
        onMove: (details) {
          _setTopLevelPreviewIndex(
            _topLevelDropIndexForRow(itemId, details.offset),
          );
        },
        onAcceptWithDetails: (details) {
          _insertTopLevelItem(
            _topLevelDropIndexForRow(itemId, details.offset),
            details.data,
          );
          _clearDragPreviews();
        },
        builder: (context, candidateData, rejectedData) {
          final highlight = candidateData.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            decoration: BoxDecoration(
              color: highlight
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.20)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color:
                    highlight ? theme.colorScheme.primary : Colors.transparent,
              ),
            ),
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildInsertionPreview(
    ThemeData theme, {
    Key? key,
  }) {
    return AnimatedContainer(
      key: key,
      duration: const Duration(milliseconds: 140),
      height: 18,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary,
          width: 1.5,
        ),
      ),
    );
  }

  void _reset() {
    setState(() {
      _folders = [];
      _topLevelOrder = List<String>.from(AppSettings.defaultHomeToolOrder);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final visibleOrder = _visibleTopLevelOrder;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
        child: SizedBox(
          height: 700,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Organize Home Cards',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _createFolder,
                    icon: const Icon(Icons.create_new_folder_outlined),
                    label: const Text('New folder'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _reset,
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  key: _topLevelListKey,
                  children: [
                    if (_topLevelPreviewIndex == 0)
                      _buildInsertionPreview(
                        theme,
                        key: const ValueKey('top-level-preview-0'),
                      ),
                    for (var index = 0;
                        index < visibleOrder.length;
                        index++) ...[
                      _buildTopLevelItem(theme, visibleOrder[index]),
                      if (_topLevelPreviewIndex == index + 1)
                        _buildInsertionPreview(
                          theme,
                          key: ValueKey('top-level-preview-${index + 1}'),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(
                        _HomeOrganizationResult(
                          homeToolOrder: _visibleTopLevelOrder,
                          homeFolders: _folders,
                        ),
                      ),
                      child: const Text('Save'),
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

class _FolderNameSheet extends StatefulWidget {
  const _FolderNameSheet({
    required this.title,
    required this.actionLabel,
    required this.initialValue,
  });

  final String title;
  final String actionLabel;
  final String initialValue;

  @override
  State<_FolderNameSheet> createState() => _FolderNameSheetState();
}

class _FolderNameSheetState extends State<_FolderNameSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(labelText: 'Folder name'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    child: Text(widget.actionLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MountSelectorSheet extends StatefulWidget {
  const _MountSelectorSheet({required this.initialSelectedIds});

  final List<String> initialSelectedIds;

  @override
  State<_MountSelectorSheet> createState() => _MountSelectorSheetState();
}

class _MountSelectorSheetState extends State<_MountSelectorSheet> {
  final _search = TextEditingController();
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.initialSelectedIds.toSet();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _query => _search.text.trim().toLowerCase();

  List<MountPreset> _groupMounts(String group) {
    return mountPresets.where((mount) {
      final matchesGroup = mount.group == group;
      if (!matchesGroup) {
        return false;
      }
      if (_query.isEmpty) {
        return true;
      }
      return mount.name.toLowerCase().contains(_query) ||
          mount.label.toLowerCase().contains(_query);
    }).toList();
  }

  void _toggleGroup(List<MountPreset> mounts, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.addAll(mounts.map((mount) => mount.id));
      } else {
        _selectedIds.removeAll(mounts.map((mount) => mount.id));
      }
    });
  }

  Widget _buildGroup(String title, List<MountPreset> mounts) {
    if (mounts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            TextButton(
              onPressed: () => _toggleGroup(mounts, true),
              child: const Text('All'),
            ),
            TextButton(
              onPressed: () => _toggleGroup(mounts, false),
              child: const Text('None'),
            ),
          ],
        ),
        ...mounts.map(
          (mount) => CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _selectedIds.contains(mount.id),
            title: Text(mount.name),
            subtitle: Text(
                'Register distance: ${mount.registerDistanceMm.toStringAsFixed(1)} mm'),
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (value) {
              setState(() {
                if (value ?? false) {
                  _selectedIds.add(mount.id);
                } else {
                  _selectedIds.remove(mount.id);
                }
              });
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final modern = _groupMounts('Modern');
    final vintage = _groupMounts('Vintage');
    final mediumFormat = _groupMounts('Medium Format');
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _search,
              decoration: const InputDecoration(
                labelText: 'Search mounts',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${_selectedIds.length} selected',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedIds = AppSettings.defaultMountIds.toSet();
                    });
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGroup('Modern', modern),
                    _buildGroup('Vintage', vintage),
                    _buildGroup('Medium Format', mediumFormat),
                    if (modern.isEmpty &&
                        vintage.isEmpty &&
                        mediumFormat.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No mounts match your search.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context)
                        .pop(_selectedIds.toList(growable: false)),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SensorSelectorSheet extends StatefulWidget {
  const _SensorSelectorSheet({required this.initialSelectedIds});

  final List<String> initialSelectedIds;

  @override
  State<_SensorSelectorSheet> createState() => _SensorSelectorSheetState();
}

class _SensorSelectorSheetState extends State<_SensorSelectorSheet> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.initialSelectedIds.toSet();
    if (_selectedIds.isEmpty) {
      _selectedIds = AppSettings.defaultSensorIds.toSet();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${_selectedIds.length} selected',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedIds = AppSettings.defaultSensorIds.toSet();
                    });
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: sensorPresets
                      .map(
                        (sensor) => CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _selectedIds.contains(sensor.id),
                          title: Text(sensor.label),
                          subtitle: Text(
                            'Circle of confusion: ${sensor.cocMm.toStringAsFixed(3)} mm',
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (value) {
                            setState(() {
                              if (value ?? false) {
                                _selectedIds.add(sensor.id);
                                return;
                              }
                              if (_selectedIds.length > 1) {
                                _selectedIds.remove(sensor.id);
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context)
                        .pop(_selectedIds.toList(growable: false)),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
