/// The tool catalog: every calculator the app ships, and the two surfaces that
/// launch them (the Plan hub and the searchable Tools catalog).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/presentation/calculator/calculator_components.dart';
import '../features/alignment/presentation/alignment_screen.dart';
import '../features/astronomy/presentation/astronomy_screen.dart';
import '../features/depth_of_field/presentation/depth_of_field_screen.dart';
import '../features/exposure_comparison/presentation/exposure_comparison_screen.dart';
import '../features/flash_exposure/presentation/flash_exposure_screen.dart';
import '../features/long_exposure/presentation/long_exposure_screen.dart';
import '../features/macro/presentation/macro_screen.dart';
import '../features/optics/presentation/optics_screens.dart';
import '../features/panorama/presentation/panorama_screen.dart';
import '../features/planning/presentation/saved_locations_screen.dart';
import '../features/timelapse/presentation/timelapse_screen.dart';
import 'providers.dart';
import 'theme/app_theme.dart';

enum CalculatorDestination {
  savedLocations(
    id: 'saved_locations',
    label: 'Saved locations',
    description: 'Reusable offline coordinates and elevations',
    icon: Icons.location_on_outlined,
    keywords: <String>[
      'coordinates',
      'gps',
      'latitude',
      'longitude',
      'elevation',
      'map',
      'location',
    ],
  ),
  alignment(
    id: 'sun_moon_alignment',
    label: 'Sun & Moon alignment',
    description: 'Search bearings, elevations, and shooting times',
    icon: Icons.align_horizontal_left,
    keywords: <String>[
      'sun',
      'moon',
      'milky way',
      'golden hour',
      'blue hour',
      'azimuth',
      'bearing',
      'rise',
      'set',
      'eclipse',
      'alignment',
    ],
  ),
  astronomy(
    id: 'astronomy',
    label: 'Night-sky planner',
    description: 'Targets, events, sharp stars, and star trails',
    icon: Icons.nightlight_round,
    keywords: <String>[
      'stars',
      'star trails',
      'night sky',
      'dark sky',
      'deep sky',
      'targets',
      'astro',
      'meteor',
      'milky way',
      'polar alignment',
    ],
  ),
  depthOfField(
    id: 'depth_of_field',
    label: 'Depth of field',
    description: 'Hyperfocal, near, far, and total focus range',
    icon: Icons.center_focus_strong,
    keywords: <String>[
      'dof',
      'bokeh',
      'hyperfocal',
      'sharpness',
      'focus range',
      'blur',
      'coc',
    ],
  ),
  exposureComparison(
    id: 'exposure_comparison',
    label: 'Exposure comparison',
    description: 'Compare aperture, shutter, and ISO in stops',
    icon: Icons.exposure,
    keywords: <String>[
      'stops',
      'ev',
      'equivalent exposure',
      'iso',
      'shutter',
      'aperture',
      'exposure triangle',
    ],
  ),
  longExposure(
    id: 'long_exposure_nd',
    label: 'Long exposure / ND',
    description: 'Stack ND filters and calculate shutter time',
    icon: Icons.timer_outlined,
    keywords: <String>[
      'nd',
      'neutral density',
      'filter',
      'filters',
      'bulb',
      'seconds',
      'smooth water',
      'light trails',
    ],
  ),
  fieldOfView(
    id: 'field_of_view',
    label: 'Field of view',
    description: 'Viewing angles and scene coverage',
    icon: Icons.aspect_ratio,
    keywords: <String>[
      'fov',
      'angle',
      'coverage',
      'crop factor',
      'equivalent focal length',
      'wide angle',
      'telephoto',
    ],
  ),
  diffraction(
    id: 'diffraction',
    label: 'Diffraction guidance',
    description: 'Airy disk size and sensor sampling',
    icon: Icons.blur_circular,
    keywords: <String>[
      'airy disk',
      'sweet spot',
      'sharpness',
      'pixel pitch',
      'softness',
      'resolution',
    ],
  ),
  focusStacking(
    id: 'focus_stacking',
    label: 'Focus stack planner',
    description: 'Ordered focus distances with overlap',
    icon: Icons.layers_outlined,
    keywords: <String>[
      'focus bracket',
      'stacking',
      'stack',
      'macro focus',
      'depth',
      'merge',
    ],
  ),
  flashExposure(
    id: 'flash_exposure',
    label: 'Flash exposure',
    description: 'Guide number, power, ISO, and distance',
    icon: Icons.flash_on_outlined,
    keywords: <String>[
      'gn',
      'guide number',
      'strobe',
      'speedlight',
      'flash power',
      'fill flash',
      'sync',
    ],
  ),
  timelapse(
    id: 'timelapse',
    label: 'Timelapse planner',
    description: 'Frames, playback, storage, and exposure ramp',
    icon: Icons.movie_creation_outlined,
    keywords: <String>[
      'time lapse',
      'interval',
      'hyperlapse',
      'frames',
      'storage',
      'playback',
      'ramp',
    ],
  ),
  macro(
    id: 'macro',
    label: 'Macro planner',
    description: 'Extension, reversed, and coupled-lens estimates',
    icon: Icons.local_florist_outlined,
    keywords: <String>[
      'close-up',
      'closeup',
      'extension tube',
      'reversed lens',
      'magnification',
      'reproduction ratio',
      'diopter',
    ],
  ),
  panorama(
    id: 'panorama',
    label: 'Panorama planner',
    description: 'Frame grids, overlap, movement, and coverage',
    icon: Icons.panorama_horizontal_outlined,
    keywords: <String>[
      'pano',
      'stitch',
      'overlap',
      'grid',
      'sweep',
      'multi-row',
    ],
  );

  const CalculatorDestination({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    this.keywords = const <String>[],
  });

  final String id;
  final String label;
  final String description;
  final IconData icon;

  /// Photographic synonyms that search matches, so a photographer can look for
  /// "bokeh" or "ND" instead of the catalog's own wording. Never used to infer
  /// physical meaning - the calculators only ever read canonical raw values.
  final List<String> keywords;

  CalculatorPurpose get purpose => switch (this) {
    savedLocations || alignment || astronomy => CalculatorPurpose.planning,
    depthOfField ||
    fieldOfView ||
    diffraction ||
    focusStacking => CalculatorPurpose.focusAndOptics,
    exposureComparison ||
    longExposure ||
    flashExposure => CalculatorPurpose.exposureAndLight,
    timelapse || panorama => CalculatorPurpose.capturePlanning,
    macro => CalculatorPurpose.macro,
  };

  Widget screen() => switch (this) {
    savedLocations => const SavedLocationsScreen(),
    alignment => const AlignmentScreen(),
    astronomy => const AstronomyScreen(),
    depthOfField => const DepthOfFieldScreen(),
    exposureComparison => const ExposureComparisonScreen(),
    longExposure => const LongExposureScreen(),
    fieldOfView => const FieldOfViewScreen(),
    diffraction => const DiffractionScreen(),
    focusStacking => const FocusStackScreen(),
    flashExposure => const FlashExposureScreen(),
    timelapse => const TimelapseScreen(),
    macro => const MacroScreen(),
    panorama => const PanoramaScreen(),
  };

  /// Whether this tool answers a search for [normalizedQuery] (already trimmed
  /// and lower-cased) through its name, its description, its family or one of
  /// its photographic synonyms.
  bool matchesQuery(String normalizedQuery) {
    if (normalizedQuery.isEmpty) return true;
    // A very short query is matched on whole words only: "nd" is a filter,
    // while "nd" inside "and" or "finder" is not a search hit. Without this a
    // two-letter query matches nearly every description in the catalog.
    final wholeWordOnly = normalizedQuery.length < 3;
    bool matches(String text) {
      final normalized = text.toLowerCase();
      if (!wholeWordOnly) return normalized.contains(normalizedQuery);
      return normalized.split(RegExp(r'[^a-z0-9]+')).contains(normalizedQuery);
    }

    if (matches(label)) return true;
    if (matches(description)) return true;
    if (matches(purpose.label)) return true;
    for (final keyword in keywords) {
      if (matches(keyword)) return true;
    }
    return false;
  }
}

enum CalculatorPurpose {
  planning('Location & sky planning'),
  focusAndOptics('Focus & optics'),
  exposureAndLight('Exposure & light'),
  capturePlanning('Capture planning'),
  macro('Macro');

  const CalculatorPurpose(this.label);
  final String label;
}

/// Opens a tool on its own screen, with its own app bar and back navigation.
void openCalculator(BuildContext context, CalculatorDestination destination) {
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (context) => Scaffold(
        appBar: AppBar(title: Text(destination.label)),
        body: SafeArea(child: destination.screen()),
      ),
    ),
  );
}

/// The Plan destination: a concise field launchpad.
///
/// Planning tools that need coordinates or the sky get a full row each because
/// they carry a decision; the capture-critical tools are compact shortcuts,
/// grouped by the kind of shot job they answer, so the surface stays scannable
/// instead of turning into a wall of equal chips. Every tool appears exactly
/// once, opens directly, and no connectivity state is reported - every number is
/// computed on this device.
class PlanHubScreen extends StatelessWidget {
  const PlanHubScreen({required this.onOpenTools, super.key});

  /// Switches the shell to the searchable Tools destination.
  final VoidCallback onOpenTools;

  /// The settings decisions most shoots turn on. Listed so the group reads as
  /// one block even as the catalog grows.
  static const _fieldEssentials = <CalculatorDestination>[
    CalculatorDestination.depthOfField,
    CalculatorDestination.longExposure,
    CalculatorDestination.exposureComparison,
  ];

  /// The sequence jobs that are planned before the shutter opens.
  static const _captureSequences = <CalculatorDestination>[
    CalculatorDestination.timelapse,
    CalculatorDestination.panorama,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final planning = CalculatorDestination.values
        .where((tool) => tool.purpose == CalculatorPurpose.planning)
        .toList(growable: false);
    final shotWorkflow = CalculatorDestination.values
        .where((tool) => tool.purpose != CalculatorPurpose.planning)
        .toList(growable: false);
    // Two named groups plus the remainder. The remainder is derived from the
    // shot workflow itself, so a tool can never fall out of the Plan hub when a
    // group list changes.
    final essentials = _fieldEssentials
        .where(shotWorkflow.contains)
        .toList(growable: false);
    final sequences = _captureSequences
        .where(shotWorkflow.contains)
        .toList(growable: false);
    final grouped = <CalculatorDestination>{...essentials, ...sequences};
    final moreTools = shotWorkflow
        .where((tool) => !grouped.contains(tool))
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[
        Text('Plan a shot', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          'Sun, Moon, night sky and your saved coordinates - all computed on '
          'this device, with no network needed.',
          style: theme.textTheme.bodySmall,
        ),
        const _SectionLabel('When & where'),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              for (final (index, tool) in planning.indexed) ...<Widget>[
                if (index > 0) const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    tool.icon,
                    color: accentForIcon(
                      tool.icon,
                      AppAccents.of(context),
                    ).onContainer,
                  ),
                  title: Text(tool.label),
                  subtitle: Text(
                    tool.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => openCalculator(context, tool),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose saved coordinates in a planner, or enter a site manually. '
          'Live positioning is requested only inside a planner.',
          style: theme.textTheme.bodySmall,
        ),
        const _SectionLabel('Shot workflow'),
        _ToolGroup(label: 'Field essentials', tools: essentials),
        _ToolGroup(label: 'Capture sequences', tools: sequences),
        _ToolGroup(label: 'More tools', tools: moreTools),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onOpenTools,
          icon: const Icon(Icons.search, size: 20),
          label: const Text('Browse and search all tools'),
        ),
      ],
    );
  }
}

/// A labelled, wrapping row of direct shortcuts to tools.
///
/// The label names the kind of job the group answers; each chip still opens its
/// tool in one tap, so grouping adds orientation without adding a step.
class _ToolGroup extends StatelessWidget {
  const _ToolGroup({required this.label, required this.tools});

  final String label;
  final List<CalculatorDestination> tools;

  @override
  Widget build(BuildContext context) {
    if (tools.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final tool in tools)
                Tooltip(
                  message: tool.description,
                  child: ActionChip(
                    avatar: Icon(tool.icon, size: 18),
                    label: Text(tool.label),
                    onPressed: () => openCalculator(context, tool),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// The Tools destination: every calculator, grouped by the photographic task it
/// belongs to, searchable by name or by synonym, with favorites pinned.
class CalculatorCatalogScreen extends ConsumerStatefulWidget {
  const CalculatorCatalogScreen({super.key});

  @override
  ConsumerState<CalculatorCatalogScreen> createState() =>
      _CalculatorCatalogScreenState();
}

class _CalculatorCatalogScreenState
    extends ConsumerState<CalculatorCatalogScreen> {
  var _query = '';
  var _favoritesOnly = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preferences = ref.watch(preferencesProvider).valueOrNull;
    final favorites = preferences?.favoriteToolIds ?? const <String>[];
    final normalizedQuery = _query.trim().toLowerCase();
    final searching = normalizedQuery.isNotEmpty;
    final calculators = CalculatorDestination.values
        .where((calculator) {
          if (_favoritesOnly && !favorites.contains(calculator.id)) {
            return false;
          }
          return calculator.matchesQuery(normalizedQuery);
        })
        .toList(growable: false);
    final favoriteTools = calculators
        .where((calculator) => favorites.contains(calculator.id))
        .toList(growable: false);
    // Shortcuts only exist for a resting catalog: a search result or a filtered
    // list must be exactly what it says it is.
    final showFavorites =
        !searching && !_favoritesOnly && favoriteTools.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[
        Text('Choose a calculator', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          'All calculations work offline and preserve raw physical values.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        SearchBar(
          hintText: 'Search tools - try bokeh, ND, star trails',
          leading: const Icon(Icons.search),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilterChip(
            avatar: const Icon(Icons.star_outline, size: 18),
            label: const Text('Favorites only'),
            selected: _favoritesOnly,
            onSelected: (value) => setState(() => _favoritesOnly = value),
          ),
        ),
        if (showFavorites) ...<Widget>[
          const _SectionLabel('Your favorites'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final tool in favoriteTools)
                ActionChip(
                  avatar: Icon(tool.icon, size: 18),
                  label: Text(tool.label),
                  onPressed: () => openCalculator(context, tool),
                ),
            ],
          ),
        ],
        if (calculators.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: EmptyState(
              icon: Icons.search_off,
              title: 'No matching tools',
              description:
                  'Clear the search or the favorites filter to see every calculator.',
            ),
          ),
        for (final purpose in CalculatorPurpose.values)
          if (calculators.any((item) => item.purpose == purpose)) ...<Widget>[
            _PurposeHeader(purpose: purpose),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  for (final (index, calculator)
                      in calculators
                          .where((item) => item.purpose == purpose)
                          .indexed) ...<Widget>[
                    if (index > 0) const Divider(height: 1),
                    _CalculatorRow(
                      calculator: calculator,
                      favorite: favorites.contains(calculator.id),
                      canFavorite: preferences != null,
                      onToggleFavorite: () => _toggleFavorite(calculator.id),
                      onOpen: () => openCalculator(context, calculator),
                    ),
                  ],
                ],
              ),
            ),
          ],
      ],
    );
  }

  Future<void> _toggleFavorite(String id) async {
    try {
      await ref.read(preferencesRepositoryProvider).update((current) {
        final favorites = [...current.favoriteToolIds];
        favorites.contains(id) ? favorites.remove(id) : favorites.add(id);
        return current.copyWith(favoriteToolIds: favorites);
      });
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The favorite could not be saved. Your calculator list is unchanged; try again.',
          ),
        ),
      );
    }
  }
}

IconData _purposeIcon(CalculatorPurpose purpose) => switch (purpose) {
  CalculatorPurpose.planning => Icons.explore_outlined,
  CalculatorPurpose.focusAndOptics => Icons.center_focus_strong_outlined,
  CalculatorPurpose.exposureAndLight => Icons.exposure_outlined,
  CalculatorPurpose.capturePlanning => Icons.movie_creation_outlined,
  CalculatorPurpose.macro => Icons.local_florist_outlined,
};

class _PurposeHeader extends StatelessWidget {
  const _PurposeHeader({required this.purpose});

  final CalculatorPurpose purpose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _purposeIcon(purpose);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            size: 16,
            color: accentForIcon(icon, AppAccents.of(context)).onContainer,
          ),
          const SizedBox(width: 8),
          // Expanded, so a long group label wraps rather than overflowing the
          // row at large system text scales.
          Expanded(
            child: Text(
              purpose.label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalculatorRow extends StatelessWidget {
  const _CalculatorRow({
    required this.calculator,
    required this.favorite,
    required this.canFavorite,
    required this.onToggleFavorite,
    required this.onOpen,
  });

  final CalculatorDestination calculator;
  final bool favorite;
  final bool canFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentForIcon(calculator.icon, AppAccents.of(context));
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: accent.container,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(calculator.icon, size: 20, color: accent.onContainer),
      ),
      title: Text(calculator.label),
      subtitle: Text(
        calculator.description,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            tooltip: favorite
                ? 'Remove ${calculator.label} from favorites'
                : 'Add ${calculator.label} to favorites',
            onPressed: canFavorite ? onToggleFavorite : null,
            icon: Icon(
              favorite ? Icons.star : Icons.star_border,
              size: 20,
              color: favorite
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.outline),
        ],
      ),
      onTap: onOpen,
    );
  }
}
