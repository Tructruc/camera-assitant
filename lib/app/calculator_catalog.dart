import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/data/repositories/preferences_repository.dart';
import '../features/depth_of_field/presentation/depth_of_field_screen.dart';
import '../features/exposure_comparison/presentation/exposure_comparison_screen.dart';
import '../features/long_exposure/presentation/long_exposure_screen.dart';
import 'providers.dart';

enum CalculatorDestination {
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

  Widget screen() => switch (this) {
    depthOfField => const DepthOfFieldScreen(),
    exposureComparison => const ExposureComparisonScreen(),
    longExposure => const LongExposureScreen(),
  };
}

class CalculatorCatalogScreen extends ConsumerWidget {
  const CalculatorCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(preferencesProvider).valueOrNull;
    final favorites = preferences?.favoriteToolIds ?? const <String>[];
    final calculators = [...CalculatorDestination.values]
      ..sort((left, right) {
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
        const SizedBox(height: 16),
        for (final calculator in calculators)
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
                    : () => _toggleFavorite(ref, preferences, calculator.id),
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
        .save(
          AppPreferences(
            lengthDisplay: preferences.lengthDisplay,
            shutterDisplay: preferences.shutterDisplay,
            fractionStep: preferences.fractionStep,
            themeMode: preferences.themeMode,
            favoriteToolIds: favorites,
          ),
        );
  }
}
