import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/features/long_exposure/domain/exposure_timer.dart';
import 'package:photography_assistant/features/long_exposure/domain/long_exposure_calculator.dart';

/// Contract for the offline exposure timer's pure half.
///
/// The timer owns no physics: it reads the canonical filtered seconds the
/// long-exposure calculator produced, keeps them unrounded, and measures
/// elapsed clock time. These cases pin the honest capability bounds, the
/// elapsed-time semantics (including a backgrounded resume and a hostile
/// clock), the completion rule, cancel/restart, and the readout that never
/// understates the time left.
void main() {
  final t0 = DateTime.utc(2026, 10, 1, 21);

  group('capability bounds', () {
    test('times finite exposures from one second through 24 hours', () {
      expect(exposureTimerSupportFor(1), ExposureTimerSupport.supported);
      expect(exposureTimerSupportFor(1.5), ExposureTimerSupport.supported);
      expect(
        exposureTimerSupportFor(34.13333333333333),
        ExposureTimerSupport.supported,
      );
      expect(exposureTimerSupportFor(3600), ExposureTimerSupport.supported);
      expect(
        exposureTimerSupportFor(exposureTimerMaximumSeconds),
        ExposureTimerSupport.supported,
      );
    });

    test('names a subsecond exposure as the camera shutter\'s job', () {
      expect(exposureTimerSupportFor(0.999), ExposureTimerSupport.tooShort);
      expect(exposureTimerSupportFor(1 / 1000), ExposureTimerSupport.tooShort);
      expect(exposureTimerSupportFor(0.000001), ExposureTimerSupport.tooShort);
    });

    test('names an exposure past 24 hours as unsupported', () {
      expect(exposureTimerSupportFor(86400.0001), ExposureTimerSupport.tooLong);
      expect(exposureTimerSupportFor(122880), ExposureTimerSupport.tooLong);
      expect(exposureTimerSupportFor(1e300), ExposureTimerSupport.tooLong);
      expect(
        exposureTimerSupportFor(double.infinity),
        ExposureTimerSupport.tooLong,
      );
    });

    test('has no target to time when the value is missing or not positive', () {
      expect(exposureTimerSupportFor(null), ExposureTimerSupport.unavailable);
      expect(exposureTimerSupportFor(0), ExposureTimerSupport.unavailable);
      expect(exposureTimerSupportFor(-1), ExposureTimerSupport.unavailable);
      expect(
        exposureTimerSupportFor(double.nan),
        ExposureTimerSupport.unavailable,
      );
    });
  });

  group('state machine', () {
    test('opens ready on the canonical target without rounding it', () {
      final state = ExposureTimerState.ready(34.13333333333333);

      expect(state.phase, ExposureTimerPhase.ready);
      expect(state.targetSeconds, 34.13333333333333);
      expect(state.startedAt, isNull);
      expect(state.elapsedSeconds, 0);
      expect(state.remainingSeconds, 34.13333333333333);
      expect(state.progress, 0);
      expect(state.isRunning, isFalse);
      expect(state.isComplete, isFalse);
    });

    test('start anchors the run at the clock reading', () {
      final running = ExposureTimerState.ready(100).start(t0);

      expect(running.phase, ExposureTimerPhase.running);
      expect(running.isRunning, isTrue);
      expect(running.startedAt, t0);
      expect(running.elapsedSeconds, 0);
      expect(running.remainingSeconds, 100);
    });

    test('tick measures elapsed clock time, not the callback count', () {
      final ticked = ExposureTimerState.ready(
        100,
      ).start(t0).tick(t0.add(const Duration(milliseconds: 2500)));

      expect(ticked.elapsedSeconds, closeTo(2.5, 1e-9));
      expect(ticked.remainingSeconds, closeTo(97.5, 1e-9));
      expect(ticked.progress, closeTo(0.025, 1e-9));
    });

    test('a resumed countdown reflects the whole time that passed', () {
      // The app was backgrounded and the ticks stopped: the next reading must
      // resume with the 90 s that really elapsed, not with one tick's worth.
      final resumed = ExposureTimerState.ready(
        100,
      ).start(t0).tick(t0.add(const Duration(seconds: 90)));

      expect(resumed.elapsedSeconds, closeTo(90, 1e-9));
      expect(resumed.remainingSeconds, closeTo(10, 1e-9));
      expect(resumed.isRunning, isTrue);
    });

    test('starved ticks cannot drift the measured time', () {
      var state = ExposureTimerState.ready(100).start(t0);

      // The ticker was starved, so only three readings arrive - each must
      // measure from the start rather than add a nominal interval, or the
      // countdown would finish late by however many ticks were missed.
      for (var reading = 1; reading <= 3; reading++) {
        state = state.tick(t0.add(Duration(seconds: 20 * reading)));
      }

      expect(state.elapsedSeconds, 60);
      expect(state.remainingSeconds, 40);
      expect(state.isRunning, isTrue);
    });

    test('never completes early and never reports a negative remaining', () {
      final running = ExposureTimerState.ready(100).start(t0);

      final almost = running.tick(t0.add(const Duration(milliseconds: 99999)));
      expect(almost.isRunning, isTrue);
      expect(almost.remainingSeconds, greaterThan(0));
      expect(almost.progress, lessThan(1));

      final complete = running.tick(t0.add(const Duration(seconds: 100)));
      expect(complete.phase, ExposureTimerPhase.completed);
      expect(complete.isComplete, isTrue);
      expect(complete.elapsedSeconds, 100);
      expect(complete.remainingSeconds, 0);
      expect(complete.progress, 1);

      final late = running.tick(t0.add(const Duration(seconds: 250)));
      expect(late.isComplete, isTrue);
      expect(late.elapsedSeconds, 100);
      expect(late.remainingSeconds, 0);
      expect(late.progress, 1);
    });

    test('a stopped or rewound clock cannot rewind or complete the timer', () {
      final advanced = ExposureTimerState.ready(
        100,
      ).start(t0).tick(t0.add(const Duration(seconds: 30)));

      final rewound = advanced.tick(t0.subtract(const Duration(seconds: 600)));
      expect(rewound.elapsedSeconds, closeTo(30, 1e-9));
      expect(rewound.remainingSeconds, closeTo(70, 1e-9));
      expect(rewound.isRunning, isTrue);
      expect(rewound.isComplete, isFalse);
    });

    test('a reading that changes nothing returns the same state', () {
      final ready = ExposureTimerState.ready(100);
      expect(ready.tick(t0), same(ready));

      final running = ready.start(t0);
      expect(running.tick(t0), same(running));

      final complete = running.tick(t0.add(const Duration(seconds: 100)));
      expect(
        complete.tick(t0.add(const Duration(seconds: 500))),
        same(complete),
      );
    });

    test('cancel returns to ready on the same target with no residue', () {
      final spent = ExposureTimerState.ready(
        34.13333333333333,
      ).start(t0).tick(t0.add(const Duration(seconds: 5)));

      final cancelled = spent.cancel();
      expect(cancelled.phase, ExposureTimerPhase.ready);
      expect(cancelled.isRunning, isFalse);
      expect(cancelled.startedAt, isNull);
      expect(cancelled.elapsedSeconds, 0);
      expect(cancelled.targetSeconds, 34.13333333333333);
      expect(cancelled.remainingSeconds, 34.13333333333333);
    });

    test('restart runs the frozen target again from zero', () {
      final complete = ExposureTimerState.ready(
        34.13333333333333,
      ).start(t0).tick(t0.add(const Duration(seconds: 60)));
      expect(complete.isComplete, isTrue);

      final restartedAt = t0.add(const Duration(seconds: 90));
      final restarted = complete.start(restartedAt);
      expect(restarted.phase, ExposureTimerPhase.running);
      expect(restarted.startedAt, restartedAt);
      expect(restarted.elapsedSeconds, 0);
      expect(restarted.targetSeconds, 34.13333333333333);
      expect(restarted.remainingSeconds, 34.13333333333333);
    });

    test('the target is frozen across every transition', () {
      const canonical = 34.13333333333333;
      var state = ExposureTimerState.ready(canonical);
      expect(state.targetSeconds, canonical);

      state = state.start(t0).tick(t0.add(const Duration(seconds: 10)));
      expect(state.targetSeconds, canonical);

      state = state.cancel();
      expect(state.targetSeconds, canonical);

      state = state.start(t0).tick(t0.add(const Duration(seconds: 40)));
      expect(state.isComplete, isTrue);
      expect(state.targetSeconds, canonical);

      state = state.start(t0);
      expect(state.targetSeconds, canonical);
    });
  });

  group('readout formatting', () {
    test('reads short exposures in tenths of a second, rounding up', () {
      expect(formatExposureTimerSeconds(0), '0.0 s');
      expect(formatExposureTimerSeconds(0.04), '0.1 s');
      expect(formatExposureTimerSeconds(12.34), '12.4 s');
      expect(formatExposureTimerSeconds(34.13333333333333), '34.2 s');
      expect(formatExposureTimerSeconds(59.9), '59.9 s');
    });

    test('reads longer exposures as a clock, rounding up', () {
      expect(formatExposureTimerSeconds(59.95), '1:00');
      expect(formatExposureTimerSeconds(60), '1:00');
      expect(formatExposureTimerSeconds(61.2), '1:02');
      expect(formatExposureTimerSeconds(273.07), '4:34');
      expect(formatExposureTimerSeconds(3600), '1:00:00');
      expect(formatExposureTimerSeconds(86400), '24:00:00');
    });

    test('a leftover fraction of a second is never rounded down to zero', () {
      expect(formatExposureTimerSeconds(0.001), '0.1 s');
      expect(formatExposureTimerSeconds(0.0000001), '0.1 s');
      expect(formatExposureTimerSeconds(59.99), '1:00');
    });

    test('a hostile value is still a readout, not a crash', () {
      expect(formatExposureTimerSeconds(double.nan), '--');
      expect(formatExposureTimerSeconds(-1), '--');
      expect(formatExposureTimerSeconds(double.infinity), '--');
      expect(formatExposureTimerSeconds(double.negativeInfinity), '--');
      expect(formatExposureTimerSeconds(1e300), '24:00:00');
    });
  });

  test('times the calculator\'s canonical seconds, not a rounded display', () {
    final output = const LongExposureCalculator()
        .calculate(
          const LongExposureInput(
            baseTimeSeconds: 1 / 30,
            filters: <NdInput>[NdInput.stops(10)],
          ),
        )
        .output!;
    final canonical = output.filteredTime.seconds;

    // The screen's own one-decimal display of this exposure is '34.1'; the
    // timer reads the canonical double instead and rounds up for safety, so its
    // readout is deliberately not that rounded string.
    expect(canonical.toStringAsFixed(1), '34.1');
    expect(formatExposureTimerSeconds(canonical), '34.2 s');
    expect(ExposureTimerState.ready(canonical).targetSeconds, canonical);
  });
}
