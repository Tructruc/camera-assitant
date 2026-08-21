import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/data/repositories/preferences_repository.dart';
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
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(
          'Choose a calculator',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'All calculations work offline and preserve raw physical values.',
        ),
        const SizedBox(height: 12),
        SearchBar(
          hintText: 'Search calculators and planners',
          leading: const Icon(Icons.search),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 8),
        FilterChip(
          avatar: const Icon(Icons.star_outline),
          label: const Text('Favorites only'),
          selected: _favoritesOnly,
          onSelected: (value) => setState(() => _favoritesOnly = value),
        ),
        if (calculators.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No matching tools. Clear the search or favorites filter.',
              ),
            ),
          ),
        for (final purpose in CalculatorPurpose.values)
          if (calculators.any((item) => item.purpose == purpose)) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 4),
              child: Text(
                purpose.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final calculator in calculators.where(
              (item) => item.purpose == purpose,
            ))
              Card(
                child: ListTile(
                  leading: Icon(calculator.icon),
                  title: Text(calculator.label),
                  subtitle: Text(calculator.description),
                  trailing: IconButton(
                    tooltip: favorites.contains(calculator.id)
                        ? 'Remove ${calculator.label} from favorites'
                        : 'Add ${calculator.label} to favorites',
                    onPressed: preferences == null
                        ? null
                        : () =>
                              _toggleFavorite(ref, preferences, calculator.id),
                    icon: Icon(
                      favorites.contains(calculator.id)
                          ? Icons.star
                          : Icons.star_border,
                    ),
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
