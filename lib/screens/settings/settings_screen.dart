import 'package:flutter/material.dart';
import 'package:camera_assistant/domain/models/app_settings.dart';
import 'package:camera_assistant/domain/models/mount_preset.dart';
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

  List<_HomeToolInfo> get _orderedHomeTools {
    final toolsById = {for (final tool in _homeTools) tool.id: tool};
    final ordered = <_HomeToolInfo>[];
    final seen = <String>{};

    for (final id in _settings.homeToolOrder) {
      final tool = toolsById[id];
      if (tool != null && seen.add(id)) {
        ordered.add(tool);
      }
    }

    for (final tool in _homeTools) {
      if (seen.add(tool.id)) {
        ordered.add(tool);
      }
    }

    return ordered;
  }

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

  Future<void> _editHomeOrganization() async {
    final result = await showModalBottomSheet<_HomeOrganizationResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _HomeOrganizerSheet(
          tools: _orderedHomeTools,
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
                      ? 'Reorder cards or place them into folders.'
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
              const SizedBox(height: 8),
              Text(
                'These mounts will be available in the reverse lens tool.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          SectionCard(
            title: 'Appearance',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dark mode'),
                subtitle: const Text('Use a darker look throughout the app'),
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
                subtitle:
                    const Text('Add or update lenses for the calculators'),
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
              const SizedBox(height: 8),
              Text(
                'Tools for exposure, focus, sun planning, and macro shooting.',
                style: Theme.of(context).textTheme.bodySmall,
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
  late List<String> _topLevelOrder;
  late List<HomeFolder> _folders;

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

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final current = List<String>.from(_visibleTopLevelOrder);
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = current.removeAt(oldIndex);
      current.insert(newIndex, item);
      _topLevelOrder = current;
    });
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

  Future<void> _editFolderCards(HomeFolder folder) async {
    final toolIds = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _FolderToolPickerSheet(
          folderName: folder.name,
          tools: widget.tools,
          selectedToolIds: folder.toolIds,
          blockedToolIds: _folders
              .where((item) => item.id != folder.id)
              .expand((item) => item.toolIds)
              .toSet(),
        );
      },
    );

    if (toolIds == null) {
      return;
    }

    setState(() {
      _folders = [
        for (final item in _folders)
          if (item.id == folder.id) item.copyWith(toolIds: toolIds) else item,
      ];
      _normalizeState();
    });
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
              const SizedBox(height: 6),
              Text(
                'Reorder top-level cards and create folders for grouped tools.',
                style: theme.textTheme.bodyMedium,
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
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top Level',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 320,
                        child: ReorderableListView.builder(
                          itemCount: visibleOrder.length,
                          onReorder: _onReorder,
                          buildDefaultDragHandles: false,
                          itemBuilder: (context, index) {
                            final id = visibleOrder[index];
                            final isFolder = id.startsWith('folder:');
                            if (isFolder) {
                              final folder = _folders.firstWhere(
                                (item) => item.orderKey == id,
                              );
                              return Card(
                                key: ValueKey(id),
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading:
                                      const Icon(Icons.folder_open_outlined),
                                  title: Text(folder.name),
                                  subtitle: Text(
                                    folder.toolIds.isEmpty
                                        ? 'No cards yet'
                                        : '${folder.toolIds.length} cards',
                                  ),
                                  trailing: ReorderableDragStartListener(
                                    index: index,
                                    child: const Icon(Icons.drag_handle),
                                  ),
                                ),
                              );
                            }

                            final tool = _toolsById[id]!;
                            return Card(
                              key: ValueKey(id),
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: Icon(tool.icon),
                                title: Text(tool.title),
                                subtitle: Text(tool.subtitle),
                                trailing: ReorderableDragStartListener(
                                  index: index,
                                  child: const Icon(Icons.drag_handle),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Folders',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_folders.isEmpty)
                        Text(
                          'No folders yet.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ..._folders.map((folder) {
                        final folderTools = folder.toolIds
                            .map((id) => _toolsById[id])
                            .whereType<_HomeToolInfo>()
                            .toList();
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        folder.name,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _renameFolder(folder),
                                      icon: const Icon(Icons.edit_outlined),
                                      tooltip: 'Rename folder',
                                    ),
                                    IconButton(
                                      onPressed: () => _deleteFolder(folder),
                                      icon: const Icon(Icons.delete_outline),
                                      tooltip: 'Delete folder',
                                    ),
                                  ],
                                ),
                                if (folderTools.isEmpty)
                                  Text(
                                    'No cards assigned.',
                                    style: theme.textTheme.bodyMedium,
                                  )
                                else
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: folderTools
                                        .map(
                                          (tool) => Chip(
                                            avatar: Icon(tool.icon, size: 18),
                                            label: Text(tool.title),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: FilledButton.tonalIcon(
                                    onPressed: () => _editFolderCards(folder),
                                    icon:
                                        const Icon(Icons.folder_copy_outlined),
                                    label: const Text('Choose cards'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
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

class _FolderToolPickerSheet extends StatefulWidget {
  const _FolderToolPickerSheet({
    required this.folderName,
    required this.tools,
    required this.selectedToolIds,
    required this.blockedToolIds,
  });

  final String folderName;
  final List<_HomeToolInfo> tools;
  final List<String> selectedToolIds;
  final Set<String> blockedToolIds;

  @override
  State<_FolderToolPickerSheet> createState() => _FolderToolPickerSheetState();
}

class _FolderToolPickerSheetState extends State<_FolderToolPickerSheet> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.selectedToolIds.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
        child: SizedBox(
          height: 560,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cards in ${widget.folderName}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'A card can only belong to one folder.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  children: widget.tools.map((tool) {
                    final blocked = widget.blockedToolIds.contains(tool.id);
                    return CheckboxListTile(
                      value: _selectedIds.contains(tool.id),
                      title: Text(tool.title),
                      subtitle: Text(
                        blocked
                            ? 'Already assigned to another folder'
                            : tool.subtitle,
                      ),
                      secondary: Icon(tool.icon),
                      controlAffinity: ListTileControlAffinity.leading,
                      enabled: !blocked || _selectedIds.contains(tool.id),
                      onChanged: (value) {
                        setState(() {
                          if (value ?? false) {
                            _selectedIds.add(tool.id);
                          } else {
                            _selectedIds.remove(tool.id);
                          }
                        });
                      },
                    );
                  }).toList(),
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
                        widget.tools
                            .where((tool) => _selectedIds.contains(tool.id))
                            .map((tool) => tool.id)
                            .toList(growable: false),
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
