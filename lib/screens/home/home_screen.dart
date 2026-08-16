import 'package:camera_assistant/app/routes.dart';
import 'package:camera_assistant/app/tools/tool_catalog.dart';
import 'package:camera_assistant/app/tools/tool_definition.dart';
import 'package:camera_assistant/domain/models/app_settings.dart';
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
  List<ToolDefinition> get _allTools => ToolCatalog.tools;

  void _openTool(BuildContext context, ToolDefinition tool) {
    Navigator.of(context).pushNamed(AppRoutes.tool(tool.id));
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.settings);
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
        .whereType<ToolDefinition>()
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
                              final cardWidth = columns == 1
                                  ? width
                                  : (width - ((columns - 1) * 14)) / columns;

                              return SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(0, 8, 0, 20),
                                child: Wrap(
                                  spacing: 14,
                                  runSpacing: 14,
                                  children: [
                                    for (final entry in entries)
                                      SizedBox(
                                        width: cardWidth,
                                        child: entry.tool != null
                                            ? _ToolCard(
                                                tool: entry.tool!,
                                                onTap: () => _openTool(
                                                  context,
                                                  entry.tool!,
                                                ),
                                              )
                                            : _FolderCard(
                                                folder: entry.folder!,
                                                toolCount: entry
                                                    .folder!.toolIds.length,
                                                onTap: () => _openFolder(
                                                  context,
                                                  entry.folder!,
                                                ),
                                              ),
                                      ),
                                  ],
                                ),
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

class _HomeEntry {
  const _HomeEntry.tool(ToolDefinition value)
      : tool = value,
        folder = null;

  const _HomeEntry.folder(HomeFolder value)
      : tool = null,
        folder = value;

  final ToolDefinition? tool;
  final HomeFolder? folder;
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
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.folder_open_outlined,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      folder.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                toolCount == 1 ? '1 card' : '$toolCount cards',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
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
  final List<ToolDefinition> tools;
  final ValueChanged<ToolDefinition> onOpenTool;

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

  final ToolDefinition tool;
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
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(tool.icon, color: scheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tool.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
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
