import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/app/theme/app_theme.dart';
import 'package:photography_assistant/core/data/database/app_database.dart'
    hide CameraBody, CalculationSnapshot, NdFilter, SavedLocation;
import 'package:photography_assistant/core/presentation/calculator/calculator_components.dart';
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';
import 'package:photography_assistant/features/long_exposure/domain/exposure_timer.dart';
import 'package:photography_assistant/features/long_exposure/presentation/exposure_timer_panel.dart';
import 'package:photography_assistant/features/long_exposure/presentation/long_exposure_screen.dart';

/// The offline exposure timer's interaction contract.
///
/// A timer is offered with the answer it would time, above the full result
/// details. It hands the panel the canonical filtered seconds - not the rounded
/// display - freezes that target for the run, measures elapsed clock time with
/// an injected clock, and never lets an outside tap, escape, back gesture or
/// drag discard a running exposure without an explicit confirmation. The
/// calculator, its snapshot schema and the physics are untouched: only the
/// offer to time the result is new.
void main() {
  late AppDatabase database;
  late DateTime now;

  // 1/30 s at ten stops of ND: 34.133333... s, which the screen displays as
  // '34.1 s' and the timer reads as the canonical double.
  const canonicalTarget = 34.13333333333333;

  setUp(() {
    database = AppDatabase.inMemory();
    now = DateTime.utc(2026, 10, 1, 21);
  });
  tearDown(() => database.close());

  /// The injected clock the panel measures elapsed time with.
  DateTime clock() => now;

  /// Advances the fake clock and lets the running countdown read it.
  Future<void> tick(WidgetTester tester, Duration advance) async {
    now = now.add(advance);
    await tester.pump(const Duration(milliseconds: 100));
  }

  Widget app(Widget screen) => ProviderScope(
    key: UniqueKey(),
    overrides: <Override>[
      appDatabaseProvider.overrideWithValue(database),
      equipmentRepositoryProvider.overrideWithValue(
        DriftEquipmentRepository(database),
      ),
    ],
    child: MaterialApp(home: Scaffold(body: screen)),
  );

  /// Unmounting before the test ends lets Riverpod dispose the local database
  /// streams and the page cancel its own live-calculation timer.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  /// Brings [finder] on screen, whichever way it lies.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 10000));
      await tester.pumpAndSettle();
    }
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        300,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(finder.first);
    await tester.pumpAndSettle();
  }

  /// Opens the timer panel from a stand-in calculator screen whose "inputs" are
  /// the value of [seconds]: changing the notifier later is exactly what a live
  /// calculator does behind the open panel.
  Future<void> openPanel(
    WidgetTester tester, {
    required ValueNotifier<double> seconds,
    ThemeData? theme,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: _TimerHost(seconds: seconds, clock: clock),
      ),
    );
    await tester.tap(find.byKey(const Key('timer-host-open')));
    await tester.pumpAndSettle();
  }

  String labelOf(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(ExposureTimerKeys.label)).data!;

  String readoutOf(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(ExposureTimerKeys.remaining)).data!;

  String? statusOf(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(ExposureTimerKeys.announcement)).data;

  group('on the long-exposure screen', () {
    testWidgets('offers the timer with the answer, before the result details', (
      tester,
    ) async {
      await tester.pumpWidget(app(const LongExposureScreen()));
      await tester.pumpAndSettle();

      final action = find.byKey(ExposureTimerKeys.action);
      await reveal(tester, action);
      expect(action, findsOneWidget);
      // It is a sibling of the result card, not an action buried inside it.
      expect(
        find.descendant(
          of: find.byType(CalculationResultView),
          matching: action,
        ),
        findsNothing,
      );
      await reveal(
        tester,
        find.textContaining('Timed countdown with this result'),
      );
      // The offer never prints a number: the untruncated target lives in the
      // panel, so the rounded display cannot be mistaken for the timed value.
      expect(find.text('34.2 s'), findsNothing);

      // The action sits above the full result details in the screen's own
      // layout order, which for this vertical list is what the eye sees.
      final list = tester.widget<ListView>(find.byType(ListView).first);
      final children =
          (list.childrenDelegate as SliverChildListDelegate).children;
      final actionIndex = children.indexWhere(
        (child) => child is ExposureTimerAction,
      );
      final resultIndex = children.indexWhere(
        (child) => child is CalculationResultView,
      );
      expect(actionIndex, greaterThanOrEqualTo(0));
      expect(resultIndex, greaterThan(actionIndex));

      // Revealing the note below the action scrolled it off the top, so bring
      // the button back on screen before tapping it.
      await reveal(tester, action);
      await tester.tap(action);
      await tester.pumpAndSettle();

      expect(find.byKey(ExposureTimerKeys.panel), findsOneWidget);
      expect(labelOf(tester), 'Target exposure');
      // Canonical capture: the panel read the computed 34.1333... s, so its
      // round-up readout is 34.2 s. A panel handed the rounded display would
      // read 34.1 s here, exactly like the result behind it still does.
      expect(readoutOf(tester), '34.2 s');
      expect(find.text('34.1 s'), findsOneWidget);
      expect(
        find.text(
          'Keep this screen open. No camera control or background alarm.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(ExposureTimerKeys.start), findsOneWidget);

      // Ready state: nothing is running, so the panel closes freely.
      await tester.tap(find.byKey(ExposureTimerKeys.close));
      await tester.pumpAndSettle();
      expect(find.byKey(ExposureTimerKeys.panel), findsNothing);
      expect(action, findsOneWidget);
      await unmount(tester);
    });

    testWidgets('names a subsecond exposure as the camera shutter\'s job', (
      tester,
    ) async {
      await tester.pumpWidget(app(const LongExposureScreen()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('long-base')), '1/1000');
      await tester.enterText(find.byKey(const Key('long-stops')), '');
      await tester.pumpAndSettle();

      final action = find.byKey(ExposureTimerKeys.action);
      await reveal(tester, action);
      expect(
        tester.widget<FilledButton>(action).onPressed,
        isNull,
        reason: 'a subsecond exposure must not offer a timer',
      );
      expect(
        find.text(
          "Under one second: use the camera's shutter for this exposure.",
        ),
        findsOneWidget,
      );
      expect(find.byKey(ExposureTimerKeys.panel), findsNothing);
      await unmount(tester);
    });

    testWidgets('names an exposure past 24 hours as unsupported', (
      tester,
    ) async {
      await tester.pumpWidget(app(const LongExposureScreen()));
      await tester.pumpAndSettle();
      // 30 s at 12 stops is 122,880 s: a valid calculation the timer cannot
      // time, and the note says so rather than changing the physics.
      await tester.enterText(find.byKey(const Key('long-base')), '30');
      await tester.enterText(find.byKey(const Key('long-stops')), '12');
      await tester.pumpAndSettle();

      final action = find.byKey(ExposureTimerKeys.action);
      await reveal(tester, action);
      expect(tester.widget<FilledButton>(action).onPressed, isNull);
      expect(
        find.text(
          'Longer than 24 hours: this timer cannot time that exposure.',
        ),
        findsOneWidget,
      );
      expect(find.byType(CalculationResultView), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('offers nothing at all when the calculation is invalid', (
      tester,
    ) async {
      await tester.pumpWidget(app(const LongExposureScreen()));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('long-stops')),
        '1000000000000',
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('overflows the exposure time'),
        findsOneWidget,
      );
      expect(find.byType(CalculationResultView), findsNothing);
      expect(find.byKey(ExposureTimerKeys.action), findsNothing);
      await unmount(tester);
    });
  });

  group('the timer panel', () {
    testWidgets('starts, counts, completes and restarts honestly', (
      tester,
    ) async {
      final seconds = ValueNotifier<double>(canonicalTarget);
      addTearDown(seconds.dispose);
      await openPanel(tester, seconds: seconds);

      // Ready: the frozen target and one deliberate Start.
      expect(labelOf(tester), 'Target exposure');
      expect(readoutOf(tester), '34.2 s');
      expect(find.byKey(ExposureTimerKeys.start), findsOneWidget);
      expect(find.byKey(ExposureTimerKeys.cancel), findsNothing);
      expect(statusOf(tester), 'Exposure timer ready. Target 34.2 s.');
      expect(
        find.text(
          'Keep this screen open. No camera control or background alarm.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(ExposureTimerKeys.start));
      await tester.pump();
      expect(labelOf(tester), 'Remaining');
      expect(readoutOf(tester), '34.2 s');
      expect(find.byKey(ExposureTimerKeys.cancel), findsOneWidget);
      expect(find.byKey(ExposureTimerKeys.start), findsNothing);
      expect(statusOf(tester), 'Timing started. 34.2 s of exposure.');

      await tick(tester, const Duration(seconds: 5));
      expect(readoutOf(tester), '29.2 s');
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        closeTo(5 / canonicalTarget, 1e-6),
      );

      // 45 s in: finished, and the ticks stop instead of chattering.
      await tick(tester, const Duration(seconds: 40));
      expect(labelOf(tester), 'Timed exposure');
      expect(readoutOf(tester), '34.2 s');
      expect(statusOf(tester), 'Exposure complete.');
      expect(find.byKey(ExposureTimerKeys.restart), findsOneWidget);
      expect(find.byKey(ExposureTimerKeys.cancel), findsNothing);

      // Nothing keeps re-completing after the fact.
      await tick(tester, const Duration(minutes: 5));
      expect(labelOf(tester), 'Timed exposure');
      expect(statusOf(tester), 'Exposure complete.');

      // Restart runs the frozen target again from zero.
      await tester.tap(find.byKey(ExposureTimerKeys.restart));
      await tester.pump();
      expect(labelOf(tester), 'Remaining');
      expect(readoutOf(tester), '34.2 s');
      await tick(tester, const Duration(seconds: 2));
      expect(readoutOf(tester), '32.2 s');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('cancel stops the countdown and keeps the target to restart', (
      tester,
    ) async {
      final seconds = ValueNotifier<double>(canonicalTarget);
      addTearDown(seconds.dispose);
      await openPanel(tester, seconds: seconds);

      await tester.tap(find.byKey(ExposureTimerKeys.start));
      await tester.pump();
      await tick(tester, const Duration(seconds: 3));
      expect(readoutOf(tester), '31.2 s');

      await tester.tap(find.byKey(ExposureTimerKeys.cancel));
      await tester.pump();
      expect(labelOf(tester), 'Target exposure');
      expect(readoutOf(tester), '34.2 s');
      expect(find.byKey(ExposureTimerKeys.start), findsOneWidget);
      expect(statusOf(tester), 'Timer cancelled. Ready to start again.');

      // Cancelled means stopped: the clock moving on does not move the readout.
      await tick(tester, const Duration(seconds: 30));
      expect(labelOf(tester), 'Target exposure');
      expect(readoutOf(tester), '34.2 s');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('closing a running timer asks, and keeping it keeps timing', (
      tester,
    ) async {
      final seconds = ValueNotifier<double>(canonicalTarget);
      addTearDown(seconds.dispose);
      await openPanel(tester, seconds: seconds);

      await tester.tap(find.byKey(ExposureTimerKeys.start));
      await tester.pump();
      await tick(tester, const Duration(seconds: 2));
      expect(readoutOf(tester), '32.2 s');

      await tester.tap(find.byKey(ExposureTimerKeys.close));
      await tester.pumpAndSettle();
      expect(find.byKey(ExposureTimerKeys.confirm), findsOneWidget);
      expect(find.text('Discard the running timer?'), findsOneWidget);

      await tester.tap(find.byKey(ExposureTimerKeys.keepTiming));
      await tester.pumpAndSettle();
      expect(find.byKey(ExposureTimerKeys.confirm), findsNothing);
      expect(find.byKey(ExposureTimerKeys.panel), findsOneWidget);
      expect(readoutOf(tester), '32.2 s');
      expect(statusOf(tester), 'Timer still running.');

      // It really kept timing: three more seconds are gone.
      await tick(tester, const Duration(seconds: 3));
      expect(readoutOf(tester), '29.2 s');

      await tester.tap(find.byKey(ExposureTimerKeys.close));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ExposureTimerKeys.discard));
      await tester.pumpAndSettle();
      expect(find.byKey(ExposureTimerKeys.panel), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('completion during a close confirmation stays complete', (
      tester,
    ) async {
      final seconds = ValueNotifier<double>(1);
      addTearDown(seconds.dispose);
      await openPanel(tester, seconds: seconds);
      await tester.tap(find.byKey(ExposureTimerKeys.start));
      await tester.pump();
      await tester.tap(find.byKey(ExposureTimerKeys.close));
      await tester.pumpAndSettle();
      expect(find.byKey(ExposureTimerKeys.confirm), findsOneWidget);

      await tick(tester, const Duration(seconds: 2));
      await tester.tap(find.byKey(ExposureTimerKeys.keepTiming));
      await tester.pumpAndSettle();
      expect(find.byKey(ExposureTimerKeys.confirm), findsNothing);
      expect(labelOf(tester), 'Timed exposure');
      expect(find.byKey(ExposureTimerKeys.restart), findsOneWidget);
      expect(statusOf(tester), 'Exposure complete.');
      expect(find.text('Timer still running.'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('an outside tap, escape or back asks instead of discarding', (
      tester,
    ) async {
      final seconds = ValueNotifier<double>(canonicalTarget);
      addTearDown(seconds.dispose);
      await openPanel(tester, seconds: seconds);

      await tester.tap(find.byKey(ExposureTimerKeys.start));
      await tester.pump();
      await tick(tester, const Duration(seconds: 1));
      expect(readoutOf(tester), '33.2 s');

      // An outside tap cannot discard the running exposure.
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();
      expect(find.byKey(ExposureTimerKeys.confirm), findsOneWidget);
      expect(find.byKey(ExposureTimerKeys.panel), findsOneWidget);
      await tester.tap(find.byKey(ExposureTimerKeys.keepTiming));
      await tester.pumpAndSettle();

      // Escape is a guard, not a shortcut past the confirmation.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(ExposureTimerKeys.confirm), findsOneWidget);
      await tester.tap(find.byKey(ExposureTimerKeys.keepTiming));
      await tester.pumpAndSettle();

      // So is the system back gesture.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(ExposureTimerKeys.confirm), findsOneWidget);
      await tester.tap(find.byKey(ExposureTimerKeys.keepTiming));
      await tester.pumpAndSettle();
      expect(readoutOf(tester), '33.2 s');

      // Once cancelled there is nothing to discard, so escape closes freely.
      await tester.tap(find.byKey(ExposureTimerKeys.cancel));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(ExposureTimerKeys.panel), findsNothing);
      expect(find.byKey(ExposureTimerKeys.confirm), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('a calculator change behind the panel cannot retime it', (
      tester,
    ) async {
      final seconds = ValueNotifier<double>(canonicalTarget);
      addTearDown(seconds.dispose);
      await openPanel(tester, seconds: seconds);

      await tester.tap(find.byKey(ExposureTimerKeys.start));
      await tester.pump();
      await tick(tester, const Duration(seconds: 5));
      expect(readoutOf(tester), '29.2 s');

      // The calculator recalculates to a ten-minute exposure behind the panel.
      seconds.value = 600;
      await tester.pump();
      expect(labelOf(tester), 'Remaining');
      expect(readoutOf(tester), '29.2 s');

      // The run keeps counting the exposure it started with, not the new one.
      await tick(tester, const Duration(seconds: 5));
      expect(readoutOf(tester), '24.2 s');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('disposing the panel cancels every tick', (tester) async {
      final seconds = ValueNotifier<double>(canonicalTarget);
      addTearDown(seconds.dispose);
      await openPanel(tester, seconds: seconds);

      await tester.tap(find.byKey(ExposureTimerKeys.start));
      await tester.pump();
      await tick(tester, const Duration(seconds: 1));

      // Unmounting disposes the panel; a surviving periodic tick would either
      // setState after dispose or leave a pending timer for the test teardown
      // to fail on.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 10));
      expect(tester.takeException(), isNull);

      // The clock moving on after disposal must change nothing.
      now = now.add(const Duration(hours: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });
  });

  group('the timer panel stays usable', () {
    testWidgets('on a 320 wide phone at 200% text', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final seconds = ValueNotifier<double>(canonicalTarget);
      addTearDown(seconds.dispose);
      await openPanel(tester, seconds: seconds, textScale: 2);

      expect(tester.takeException(), isNull);
      expect(readoutOf(tester), '34.2 s');
      expect(
        find.text(
          'Keep this screen open. No camera control or background alarm.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(ExposureTimerKeys.start));
      await tester.pump();
      await tick(tester, const Duration(seconds: 4));
      expect(readoutOf(tester), '30.2 s');
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('with the longest supported exposure at 200% text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final seconds = ValueNotifier<double>(exposureTimerMaximumSeconds);
      addTearDown(seconds.dispose);
      await openPanel(tester, seconds: seconds, textScale: 2);

      expect(tester.takeException(), isNull);
      expect(readoutOf(tester), '24:00:00');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('in landscape', (tester) async {
      tester.view.physicalSize = const Size(568, 320);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final seconds = ValueNotifier<double>(canonicalTarget);
      addTearDown(seconds.dispose);
      await openPanel(tester, seconds: seconds);

      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(ExposureTimerKeys.start));
      await tester.pump();
      await tick(tester, const Duration(seconds: 2));
      expect(readoutOf(tester), '32.2 s');
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('in the low-light theme', (tester) async {
      final seconds = ValueNotifier<double>(canonicalTarget);
      addTearDown(seconds.dispose);
      await openPanel(tester, seconds: seconds, theme: AppTheme.lowLight);

      expect(tester.takeException(), isNull);
      expect(find.byKey(ExposureTimerKeys.start), findsOneWidget);
      await tester.tap(find.byKey(ExposureTimerKeys.start));
      await tester.pump();
      await tick(tester, const Duration(seconds: 1));
      expect(readoutOf(tester), '33.2 s');
      await tester.tap(find.byKey(ExposureTimerKeys.cancel));
      await tester.pump();
      expect(find.byKey(ExposureTimerKeys.start), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });
}

/// A stand-in calculator screen: the button opens the panel with the seconds
/// its "inputs" currently hold, and changing [seconds] rebuilds this host -
/// exactly what a live calculator does while the panel is open.
class _TimerHost extends StatelessWidget {
  const _TimerHost({required this.seconds, required this.clock});

  final ValueNotifier<double> seconds;
  final ExposureTimerClock clock;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ValueListenableBuilder<double>(
      valueListenable: seconds,
      builder: (context, value, child) => Center(
        child: ElevatedButton(
          key: const Key('timer-host-open'),
          onPressed: () {
            unawaited(
              showExposureTimerPanel(
                context,
                targetSeconds: value,
                clock: clock,
              ),
            );
          },
          child: const Text('open timer'),
        ),
      ),
    ),
  );
}
