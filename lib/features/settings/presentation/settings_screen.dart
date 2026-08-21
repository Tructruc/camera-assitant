import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/data/repositories/preferences_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(preferencesProvider);
    return preferences.when(
      loading: () => const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Loading settings'),
      ),
      error: (_, _) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Settings could not be loaded. Existing choices remain on this device.',
          ),
        ),
      ),
      data: (value) => ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('Display', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _SettingCard<LengthDisplay>(
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
            title: 'Exposure increments',
            subtitle: 'Used when presenting conventional photographic values.',
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
          Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _SettingCard<AppThemeMode>(
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
          const Text(
            'Privacy: equipment, preferences, and saved calculations stay on this device. The app has no account, advertising, or telemetry.',
          ),
        ],
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

class _SettingCard<T> extends StatelessWidget {
  const _SettingCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          Text(subtitle),
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
