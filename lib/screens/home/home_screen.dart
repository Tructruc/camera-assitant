import 'package:camera_assistant/domain/models/app_settings.dart';
import 'package:camera_assistant/screens/dof/dof_calculator_screen.dart';
import 'package:camera_assistant/screens/exposure/exposure_calculator_screen.dart';
import 'package:camera_assistant/screens/focus_stacking/focus_stacking_planner_screen.dart';
import 'package:camera_assistant/screens/long_exposure/long_exposure_screen.dart';
import 'package:camera_assistant/screens/macro/macro_calculator_screen.dart';
import 'package:camera_assistant/screens/settings/settings_screen.dart';
import 'package:camera_assistant/screens/sun_planner/sun_planner_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<_ToolItem> get _allTools => [
        _ToolItem(
          id: 'exposure',
          title: 'Exposure',
          subtitle: 'Match one exposure to another.',
          icon: Icons.exposure,
          builder: () => const ExposureCalculatorScreen(),
        ),
        _ToolItem(
          id: 'dof',
          title: 'DOF',
          subtitle: 'Check depth of field and focus range.',
          icon: Icons.filter_center_focus,
          builder: () => DofCalculatorScreen(settings: widget.settings),
        ),
        _ToolItem(
          id: 'focus_stacking',
          title: 'Focus Stacking',
          subtitle: 'Plan focus positions and frame count for a stack.',
          icon: Icons.layers_outlined,
          builder: () => FocusStackingPlannerScreen(settings: widget.settings),
        ),
        _ToolItem(
          id: 'extension_tubes',
          title: 'Extension Tubes',
          subtitle: 'See close-focus range and magnification.',
          icon: Icons.add_circle_outline,
          builder: () => MacroCalculatorScreen(settings: widget.settings),
        ),
        _ToolItem(
          id: 'reverse_lens',
          title: 'Reverse Lens',
          subtitle: 'Estimate magnification and focus distance.',
          icon: Icons.sync_alt,
          builder: () => MacroCalculatorScreen(
            settings: widget.settings,
            initialMode: MacroToolMode.reverseLens,
          ),
        ),
        _ToolItem(
          id: 'dual_lens_macro',
          title: 'Dual Lens Macro',
          subtitle: 'Estimate stacked-lens magnification and exposure loss.',
          icon: Icons.join_inner,
          builder: () => MacroCalculatorScreen(
            settings: widget.settings,
            initialMode: MacroToolMode.dualLens,
          ),
        ),
        _ToolItem(
          id: 'sun_planner',
          title: 'Sun Planner',
          subtitle: 'Plan sunrise, sunset, and golden hour.',
          icon: Icons.wb_sunny_outlined,
          builder: () => SunPlannerScreen(settings: widget.settings),
        ),
        _ToolItem(
          id: 'long_exposure',
          title: 'Long Exposure',
          subtitle: 'Convert ND filters and estimate motion blur.',
          icon: Icons.shutter_speed,
          builder: () => const LongExposureScreen(),
        ),
      ];

  void _openTool(BuildContext context, _ToolItem tool) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ToolScaffold(title: tool.title, child: tool.builder()),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ToolScaffold(
          title: 'Settings',
          child: SettingsScreen(
            settings: widget.settings,
            onSettingsChanged: widget.onSettingsChanged,
          ),
        ),
      ),
    );
  }

  List<_HomeEntry> get _orderedEntries {
    final toolsById = {for (final tool in _allTools) tool.id: tool};
    final foldersByKey = {
      for (final folder in widget.settings.homeFolders) folder.orderKey: folder,
    };
    final folderedToolIds =
        widget.settings.homeFolders.expand((folder) => folder.toolIds).toSet();
    final ordered = <_HomeEntry>[];
    final seen = <String>{};

    for (final id in widget.settings.homeToolOrder) {
      final tool = toolsById[id];
      if (tool != null && !folderedToolIds.contains(id) && seen.add(id)) {
        ordered.add(_HomeEntry.tool(tool));
      }

      final folder = foldersByKey[id];
      if (folder != null && seen.add(id)) {
        ordered.add(_HomeEntry.folder(folder));
      }
    }

    for (final tool in _allTools) {
      if (!folderedToolIds.contains(tool.id) && seen.add(tool.id)) {
        ordered.add(_HomeEntry.tool(tool));
      }
    }

    for (final folder in widget.settings.homeFolders) {
      if (seen.add(folder.orderKey)) {
        ordered.add(_HomeEntry.folder(folder));
      }
    }

    return ordered;
  }

  Future<void> _openFolder(BuildContext context, HomeFolder folder) async {
    final toolsById = {for (final tool in _allTools) tool.id: tool};
    final tools = folder.toolIds
        .map((id) => toolsById[id])
        .whereType<_ToolItem>()
        .toList(growable: false);
    if (tools.isEmpty) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return _FolderSheet(
          title: folder.name,
          tools: tools,
          onOpenTool: (tool) {
            Navigator.of(context).pop();
            _openTool(this.context, tool);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final entries = _orderedEntries;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.surface,
              scheme.surfaceContainerLowest,
              scheme.surface,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -90,
              top: -80,
              child: _BlurBubble(
                color: scheme.primaryContainer.withValues(alpha: 0.5),
                size: 220,
              ),
            ),
            Positioned(
              left: -70,
              top: 180,
              child: _BlurBubble(
                color: scheme.tertiaryContainer.withValues(alpha: 0.3),
                size: 190,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    _TopHeader(
                      onOpenSettings: () => _openSettings(context),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 920),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              final columns = width >= 860
                                  ? 3
                                  : width >= 560
                                      ? 2
                                      : 1;
                              final childAspectRatio = columns == 1
                                  ? 1.88
                                  : columns == 2
                                      ? 1.42
                                      : 1.24;

                              return GridView.builder(
                                padding: const EdgeInsets.fromLTRB(0, 8, 0, 20),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 14,
                                  childAspectRatio: childAspectRatio,
                                ),
                                itemCount: entries.length,
                                itemBuilder: (context, index) {
                                  final entry = entries[index];
                                  if (entry.tool != null) {
                                    final tool = entry.tool!;
                                    return _ToolCard(
                                      tool: tool,
                                      onTap: () => _openTool(context, tool),
                                    );
                                  }

                                  return _FolderCard(
                                    folder: entry.folder!,
                                    toolCount: entry.folder!.toolIds.length,
                                    onTap: () =>
                                        _openFolder(context, entry.folder!),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolItem {
  const _ToolItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget Function() builder;
}

class _HomeEntry {
  const _HomeEntry.tool(_ToolItem value)
      : tool = value,
        folder = null;

  const _HomeEntry.folder(HomeFolder value)
      : tool = null,
        folder = value;

  final _ToolItem? tool;
  final HomeFolder? folder;
}

class _ToolScaffold extends StatelessWidget {
  const _ToolScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.surface,
              scheme.surfaceContainerLowest,
              scheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.folder,
    required this.toolCount,
    required this.onTap,
  });

  final HomeFolder folder;
  final int toolCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.tertiaryContainer.withValues(alpha: 0.72),
                scheme.primaryContainer.withValues(alpha: 0.44),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child:
                        Icon(Icons.folder_open_outlined, color: scheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    folder.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    toolCount == 1
                        ? '1 card inside'
                        : '$toolCount cards inside',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    'Open folder',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: scheme.primary,
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

class _FolderSheet extends StatelessWidget {
  const _FolderSheet({
    required this.title,
    required this.tools,
    required this.onOpenTool,
  });

  final String title;
  final List<_ToolItem> tools;
  final ValueChanged<_ToolItem> onOpenTool;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
        child: SizedBox(
          height: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose a card from this folder.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: tools.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final tool = tools[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(tool.icon),
                        title: Text(tool.title),
                        subtitle: Text(tool.subtitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => onOpenTool(tool),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.onOpenSettings,
  });

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              scheme.primaryContainer.withValues(alpha: 0.82),
              scheme.tertiaryContainer.withValues(alpha: 0.62),
            ],
          ),
          border:
              Border.all(color: scheme.outlineVariant.withValues(alpha: 0.55)),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.camera_alt_rounded,
              color: scheme.onPrimaryContainer,
              size: 26,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Photography toolkit',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    'Choose a tool to get started.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: onOpenSettings,
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool, required this.onTap});

  final _ToolItem tool;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.cardColor,
                scheme.surfaceContainerHighest.withValues(alpha: 0.18),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(tool.icon, color: scheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tool.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tool.subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    'Open',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: scheme.primary,
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

class _BlurBubble extends StatelessWidget {
  const _BlurBubble({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
