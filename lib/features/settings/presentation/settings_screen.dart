import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/data/repositories/preferences_repository.dart';
import '../../../core/presentation/calculator/calculator_components.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(preferencesProvider);
    return preferences.when(
      loading: () => const LoadingSkeleton(
        label: 'Loading settings',
        rowHeight: 120,
        rows: 5,
      ),
      error: (_, _) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Settings could not be loaded. Existing choices remain on this device.',
          ),
        ),
      ),
      data: (value) => AppContentFrame(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            const _SectionHeader(icon: Icons.straighten, label: 'Display'),
            _SettingCard<LengthDisplay>(
              icon: Icons.straighten,
              title: 'Distance units',
              subtitle: 'Canonical calculation values are never changed.',
              value: value.lengthDisplay,
              options: const <(LengthDisplay, String)>[
                (LengthDisplay.metric, 'Metric (m and mm)'),
                (LengthDisplay.imperial, 'Imperial (ft and in)'),
              ],
              onChanged: (choice) =>
                  _save(context, ref, value.copyWith(lengthDisplay: choice)),
            ),
            _SettingCard<ShutterDisplay>(
              icon: Icons.timer_outlined,
              title: 'Shutter display',
              subtitle: 'Choose raw seconds or a conventional camera value.',
              value: value.shutterDisplay,
              options: const <(ShutterDisplay, String)>[
                (ShutterDisplay.exact, 'Exact seconds'),
                (ShutterDisplay.conventional, 'Conventional shutter'),
              ],
              onChanged: (choice) =>
                  _save(context, ref, value.copyWith(shutterDisplay: choice)),
            ),
            _SettingCard<FractionStep>(
              icon: Icons.exposure_outlined,
              title: 'Exposure increments',
              subtitle:
                  'Used when presenting conventional photographic values.',
              value: value.fractionStep,
              options: const <(FractionStep, String)>[
                (FractionStep.whole, 'Whole stops'),
                (FractionStep.half, 'Half stops'),
                (FractionStep.third, 'Third stops'),
              ],
              onChanged: (choice) =>
                  _save(context, ref, value.copyWith(fractionStep: choice)),
            ),
            _SettingCard<NorthReference>(
              icon: Icons.explore_outlined,
              title: 'North reference',
              subtitle:
                  'Magnetic bearings require local declination; planners keep true bearings visible when it is unavailable.',
              value: value.northReference,
              options: const <(NorthReference, String)>[
                (NorthReference.trueNorth, 'True north'),
                (NorthReference.magneticNorth, 'Magnetic north'),
              ],
              onChanged: (choice) =>
                  _save(context, ref, value.copyWith(northReference: choice)),
            ),
            const SizedBox(height: 16),
            const _SectionHeader(
              icon: Icons.explore_outlined,
              label: 'Planner defaults',
            ),
            _SettingCard<DefaultStarSharpness>(
              icon: Icons.nightlight_round,
              title: 'Default star sharpness',
              subtitle:
                  'Applied when opening or resetting the night-sky planner.',
              value: value.defaultStarSharpness,
              options: const <(DefaultStarSharpness, String)>[
                (DefaultStarSharpness.strict, 'Strict'),
                (DefaultStarSharpness.balanced, 'Balanced'),
                (DefaultStarSharpness.relaxed, 'Relaxed'),
              ],
              onChanged: (choice) => _save(
                context,
                ref,
                value.copyWith(defaultStarSharpness: choice),
              ),
            ),
            _SettingCard<double>(
              icon: Icons.align_horizontal_left,
              title: 'Alignment angular tolerance',
              subtitle:
                  'Applied when opening or resetting the alignment planner.',
              value: value.defaultAlignmentToleranceDegrees,
              options: const <(double, String)>[
                (1, '1°'),
                (2, '2°'),
                (3, '3°'),
                (5, '5°'),
                (10, '10°'),
              ],
              onChanged: (choice) => _save(
                context,
                ref,
                value.copyWith(defaultAlignmentToleranceDegrees: choice),
              ),
            ),
            const SizedBox(height: 16),
            const _SectionHeader(
              icon: Icons.dark_mode_outlined,
              label: 'Appearance',
            ),
            _SettingCard<AppThemeMode>(
              icon: Icons.brightness_6_outlined,
              title: 'Theme',
              subtitle:
                  'Low-light mode uses a black surface and restrained red accents.',
              value: value.themeMode,
              options: const <(AppThemeMode, String)>[
                (AppThemeMode.system, 'Use device setting'),
                (AppThemeMode.light, 'Light'),
                (AppThemeMode.dark, 'Dark'),
                (AppThemeMode.lowLight, 'Low-light red'),
              ],
              onChanged: (choice) =>
                  _save(context, ref, value.copyWith(themeMode: choice)),
            ),
            const SizedBox(height: 16),
            Text(
              'Privacy: equipment, preferences, and saved calculations stay on '
              'this device. The app has no account, advertising, or telemetry.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    AppPreferences preferences,
  ) async {
    try {
      await ref.read(preferencesRepositoryProvider).save(preferences);
    } on Object {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Setting could not be saved.')),
      );
    }
  }
}

/// A small muted section label with an icon, matching the catalog headers.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingCard<T> extends StatelessWidget {
  const _SettingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            RadioGroup<T>(
              groupValue: value,
              onChanged: (choice) {
                if (choice != null && choice != value) onChanged(choice);
              },
              child: Column(
                children: <Widget>[
                  for (final option in options)
                    RadioListTile<T>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(option.$2),
                      value: option.$1,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
