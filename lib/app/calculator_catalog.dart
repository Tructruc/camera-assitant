import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/data/repositories/preferences_repository.dart';
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

enum CalculatorDestination {
  savedLocations(
    id: 'saved_locations',
    label: 'Saved locations',
    description: 'Reusable offline coordinates and elevations',
    icon: Icons.location_on_outlined,
  ),
  alignment(
    id: 'sun_moon_alignment',
    label: 'Sun & Moon alignment',
    description: 'Search bearings, elevations, and shooting times',
    icon: Icons.align_horizontal_left,
  ),
  astronomy(
    id: 'astronomy',
    label: 'Night-sky planner',
    description: 'Targets, events, sharp stars, and star trails',
    icon: Icons.nightlight_round,
  ),
  depthOfField(
    id: 'depth_of_field',
    label: 'Depth of field',
    description: 'Hyperfocal, near, far, and total focus range',
    icon: Icons.center_focus_strong,
  ),
  exposureComparison(
    id: 'exposure_comparison',
    label: 'Exposure comparison',
    description: 'Compare aperture, shutter, and ISO in stops',
    icon: Icons.exposure,
  ),
  longExposure(
    id: 'long_exposure_nd',
    label: 'Long exposure / ND',
    description: 'Stack ND filters and calculate shutter time',
    icon: Icons.timer_outlined,
  ),
  fieldOfView(
    id: 'field_of_view',
    label: 'Field of view',
    description: 'Viewing angles and scene coverage',
    icon: Icons.aspect_ratio,
  ),
  diffraction(
    id: 'diffraction',
    label: 'Diffraction guidance',
    description: 'Airy disk size and sensor sampling',
    icon: Icons.blur_circular,
  ),
  focusStacking(
    id: 'focus_stacking',
    label: 'Focus stack planner',
    description: 'Ordered focus distances with overlap',
    icon: Icons.layers_outlined,
  ),
  flashExposure(
    id: 'flash_exposure',
    label: 'Flash exposure',
    description: 'Guide number, power, ISO, and distance',
    icon: Icons.flash_on_outlined,
  ),
  timelapse(
    id: 'timelapse',
    label: 'Timelapse planner',
    description: 'Frames, playback, storage, and exposure ramp',
    icon: Icons.movie_creation_outlined,
  ),
  macro(
    id: 'macro',
    label: 'Macro planner',
    description: 'Extension, reversed, and coupled-lens estimates',
    icon: Icons.local_florist_outlined,
  ),
  panorama(
    id: 'panorama',
    label: 'Panorama planner',
    description: 'Frame grids, overlap, movement, and coverage',
    icon: Icons.panorama_horizontal_outlined,
  );

  const CalculatorDestination({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
  });

  final String id;
  final String label;
  final String description;
  final IconData icon;

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
    final preferences = ref.watch(preferencesProvider).valueOrNull;
    final favorites = preferences?.favoriteToolIds ?? const <String>[];
    final normalizedQuery = _query.trim().toLowerCase();
    final calculators =
        CalculatorDestination.values.where((calculator) {
          if (_favoritesOnly && !favorites.contains(calculator.id)) {
            return false;
          }
          return normalizedQuery.isEmpty ||
              calculator.label.toLowerCase().contains(normalizedQuery) ||
              calculator.description.toLowerCase().contains(normalizedQuery) ||
              calculator.purpose.label.toLowerCase().contains(normalizedQuery);
        }).toList()..sort((left, right) {
          final leftFavorite = favorites.contains(left.id);
          final rightFavorite = favorites.contains(right.id);
          if (leftFavorite == rightFavorite) {
            return left.index.compareTo(right.index);
          }
          return leftFavorite ? -1 : 1;
        });
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[
        Text(
          'Choose a calculator',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          'All calculations work offline and preserve raw physical values.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        SearchBar(
          hintText: 'Search calculators and planners',
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
          if (calculators.any((item) => item.purpose == purpose)) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
              child: Row(
                children: <Widget>[
                  Icon(
                    _purposeIcon(purpose),
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    purpose.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
            for (final calculator in calculators.where(
              (item) => item.purpose == purpose,
            ))
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(calculator.icon, size: 20),
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
                        tooltip: favorites.contains(calculator.id)
                            ? 'Remove ${calculator.label} from favorites'
                            : 'Add ${calculator.label} to favorites',
                        onPressed: preferences == null
                            ? null
                            : () => _toggleFavorite(
                                ref,
                                preferences,
                                calculator.id,
                              ),
                        icon: Icon(
                          favorites.contains(calculator.id)
                              ? Icons.star
                              : Icons.star_border,
                          size: 20,
                          color: favorites.contains(calculator.id)
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ],
                  ),
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (context) => Scaffold(
                        appBar: AppBar(title: Text(calculator.label)),
                        body: SafeArea(child: calculator.screen()),
                      ),
                    ),
                  ),
                ),
              ),
          ],
      ],
    );
  }

  static IconData _purposeIcon(CalculatorPurpose purpose) => switch (purpose) {
    CalculatorPurpose.planning => Icons.explore_outlined,
    CalculatorPurpose.focusAndOptics => Icons.center_focus_strong_outlined,
    CalculatorPurpose.exposureAndLight => Icons.exposure_outlined,
    CalculatorPurpose.capturePlanning => Icons.movie_creation_outlined,
    CalculatorPurpose.macro => Icons.local_florist_outlined,
  };

  Future<void> _toggleFavorite(
    WidgetRef ref,
    AppPreferences preferences,
    String id,
  ) async {
    final favorites = [...preferences.favoriteToolIds];
    favorites.contains(id) ? favorites.remove(id) : favorites.add(id);
    await ref
        .read(preferencesRepositoryProvider)
        .save(preferences.copyWith(favoriteToolIds: favorites));
  }
}
