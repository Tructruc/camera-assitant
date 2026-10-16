/// Offline countdown model for a long (neutral-density) exposure.
///
/// Deliberately Flutter-free: the capability bounds, the state machine and the
/// readout formatting are plain Dart, so the timer can be driven by an injected
/// clock in a unit test and no widget can change how much time is left.
///
/// The timer measures elapsed wall-clock time rather than decrementing a
/// counter once per callback, so a countdown whose ticks were throttled while
/// the app was in the background resumes with the time that actually passed. It
/// controls nothing but this screen: no shutter, no alarm, no background work.
///
/// It does not calculate an exposure and never changes one. The canonical
/// filtered seconds come from the long-exposure calculator and are only read.
library;

import 'dart:math' as math;

/// Shortest exposure this timer will time, in seconds.
///
/// Below this the photographer uses the camera's own shutter, and the screen
/// says so; the timer never pretends to control the camera.
const double exposureTimerMinimumSeconds = 1;

/// Longest exposure this timer will time, in seconds (24 hours).
const double exposureTimerMaximumSeconds = 24 * 60 * 60;

/// How well a computed exposure time suits a visible countdown.
enum ExposureTimerSupport {
  /// A finite exposure of one second through 24 hours, inclusive.
  supported,

  /// Under a second: the camera's shutter covers it.
  tooShort,

  /// Over 24 hours: too long to sit and watch, and not timable here.
  tooLong,

  /// No usable computed exposure: missing, not finite, or not positive.
  unavailable,
}

/// Whether a computed exposure can be timed with a visible countdown.
///
/// The bounds are honest product limits, not a claim about the physics: the
/// underlying calculation is never narrowed to fit them.
ExposureTimerSupport exposureTimerSupportFor(double? seconds) {
  if (seconds == null || seconds.isNaN || seconds <= 0) {
    return ExposureTimerSupport.unavailable;
  }
  if (seconds < exposureTimerMinimumSeconds) {
    return ExposureTimerSupport.tooShort;
  }
  if (seconds > exposureTimerMaximumSeconds) {
    return ExposureTimerSupport.tooLong;
  }
  return ExposureTimerSupport.supported;
}

/// Which part of the timer's lifecycle the panel is in.
///
/// There is deliberately no paused phase: a pause button would imply control of
/// the camera, and this timer controls only the screen.
enum ExposureTimerPhase { ready, running, completed }

/// Immutable countdown state.
///
/// Every transition returns a new state, so a widget never mutates a countdown
/// it is painting. [startedAt] is the only clock anchor: the elapsed time is
/// always re-derived from it, which is what makes a backgrounded countdown
/// resume correctly and what makes the unit tests deterministic.
final class ExposureTimerState {
  ExposureTimerState.ready(this.targetSeconds)
    : phase = ExposureTimerPhase.ready,
      startedAt = null,
      elapsedSeconds = 0;

  const ExposureTimerState._({
    required this.targetSeconds,
    required this.phase,
    required this.startedAt,
    required this.elapsedSeconds,
  });

  /// The canonical computed exposure, in seconds, exactly as the calculator
  /// produced it. Fractional precision is preserved; nothing rounds it here.
  final double targetSeconds;

  final ExposureTimerPhase phase;

  /// When the current run started, or null while it is not running.
  final DateTime? startedAt;

  /// Clock time read since [startedAt], never below a value already read.
  final double elapsedSeconds;

  bool get isRunning => phase == ExposureTimerPhase.running;

  bool get isComplete => phase == ExposureTimerPhase.completed;

  /// Time left, never negative and never zero before the target is reached.
  double get remainingSeconds => math.max(0, targetSeconds - elapsedSeconds);

  /// How much of the exposure has passed, clamped to 0..1.
  double get progress {
    if (!targetSeconds.isFinite || targetSeconds <= 0) {
      return 0;
    }
    return (elapsedSeconds / targetSeconds).clamp(0.0, 1.0);
  }

  /// Starts - or deliberately restarts - the countdown at [now].
  ExposureTimerState start(DateTime now) => ExposureTimerState._(
    targetSeconds: targetSeconds,
    phase: ExposureTimerPhase.running,
    startedAt: now,
    elapsedSeconds: 0,
  );

  /// Re-reads the elapsed clock time.
  ///
  /// A target reached or passed is complete; a clock that stands still or steps
  /// backwards never completes the timer early and never rewinds it.
  ExposureTimerState tick(DateTime now) {
    final start = startedAt;
    if (phase != ExposureTimerPhase.running || start == null) {
      return this;
    }
    final measured =
        now.difference(start).inMicroseconds / Duration.microsecondsPerSecond;
    final elapsed = measured.isFinite && measured > elapsedSeconds
        ? measured
        : elapsedSeconds;
    if (elapsed >= targetSeconds) {
      return ExposureTimerState._(
        targetSeconds: targetSeconds,
        phase: ExposureTimerPhase.completed,
        startedAt: start,
        elapsedSeconds: targetSeconds,
      );
    }
    if (elapsed == elapsedSeconds) {
      return this;
    }
    return ExposureTimerState._(
      targetSeconds: targetSeconds,
      phase: ExposureTimerPhase.running,
      startedAt: start,
      elapsedSeconds: elapsed,
    );
  }

  /// Stops a run and returns to ready with the same target.
  ///
  /// The exposure is still known, so only its timing is abandoned; the panel
  /// then offers [start] again rather than pretending something was saved.
  ExposureTimerState cancel() => ExposureTimerState._(
    targetSeconds: targetSeconds,
    phase: ExposureTimerPhase.ready,
    startedAt: null,
    elapsedSeconds: 0,
  );
}

/// A countdown readout a photographer can read at a glance.
///
/// Under a minute it reads in tenths of a second; above it, as a clock. Both
/// round up, so a running timer never claims less time is left than there is,
/// and `0.0 s` / `0:00` appears only once the exposure is actually complete.
/// Values outside the timer's own range are clamped to it: this is a readout,
/// never a calculation, and it must not throw on a hostile double.
String formatExposureTimerSeconds(double seconds) {
  if (!seconds.isFinite || seconds < 0) {
    return '--';
  }
  final capped = math.min(seconds, exposureTimerMaximumSeconds);
  final tenths = (capped * 10).ceil();
  if (tenths < 600) {
    return '${(tenths / 10).toStringAsFixed(1)} s';
  }
  return _clock(capped.ceil());
}

String _clock(int totalSeconds) {
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  String pad(int value) => value.toString().padLeft(2, '0');
  return hours > 0
      ? '$hours:${pad(minutes)}:${pad(seconds)}'
      : '$minutes:${pad(seconds)}';
}
