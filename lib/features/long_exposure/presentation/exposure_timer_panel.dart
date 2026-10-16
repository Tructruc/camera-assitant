/// Presentation for the offline exposure timer.
///
/// The screen offers the timer with the answer it would time; the panel is a
/// modal route of its own, so nothing that happens behind it can retime a
/// running exposure. It controls only the screen: no shutter, no alarm, no
/// background execution, and no promise of precision beyond `DateTime`.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/design_tokens.dart';
import '../domain/exposure_timer.dart';

/// Reads the current time. Injected so a widget test can drive the countdown
/// deterministically instead of watching the wall clock.
typedef ExposureTimerClock = DateTime Function();

/// How often a running countdown repaints. The elapsed time is read from the
/// clock, so this only decides how smoothly the readout moves.
const Duration kExposureTimerTickInterval = Duration(milliseconds: 100);

/// Stable keys for the timer's controls and readouts.
abstract final class ExposureTimerKeys {
  /// The screen action that opens the panel.
  static const Key action = Key('exposure-timer-action');

  /// The panel itself.
  static const Key panel = Key('exposure-timer-panel');

  /// The large countdown readout.
  static const Key remaining = Key('exposure-timer-remaining');

  /// What the readout currently means: target, remaining or complete.
  static const Key label = Key('exposure-timer-label');

  /// The live-region status line. It changes on transitions only.
  static const Key announcement = Key('exposure-timer-announcement');

  static const Key start = Key('exposure-timer-start');
  static const Key cancel = Key('exposure-timer-cancel');
  static const Key close = Key('exposure-timer-close');
  static const Key restart = Key('exposure-timer-restart');

  /// The running-timer close confirmation.
  static const Key confirm = Key('exposure-timer-confirm');
  static const Key keepTiming = Key('exposure-timer-keep-timing');
  static const Key discard = Key('exposure-timer-discard');
}

/// Opens the countdown panel for [targetSeconds].
///
/// [targetSeconds] is the canonical computed filtered time - the full double,
/// never the rounded display string - and it is read once, here. Escaping,
/// going back and tapping outside all route through the panel's own guard,
/// which is free when nothing is running and asks first while a countdown is.
/// A drag cannot dismiss a dialog, so an accidental gesture cannot discard a
/// running exposure either.
Future<void> showExposureTimerPanel(
  BuildContext context, {
  required double targetSeconds,
  ExposureTimerClock? clock,
  Duration tickInterval = kExposureTimerTickInterval,
}) {
  return showDialog<void>(
    context: context,
    // Enabled on purpose: the barrier tap and the escape key then ask the
    // panel's PopScope instead of popping blind, which is what lets a running
    // countdown survive both and still lets a ready or completed panel close.
    barrierDismissible: true,
    builder: (context) => ExposureTimerPanel(
      targetSeconds: targetSeconds,
      clock: clock,
      tickInterval: tickInterval,
    ),
  );
}

/// The screen action that offers the timer for a computed exposure.
///
/// It sits with the answer it times, above the full result details, and says in
/// words when the timer is not the right tool: under a second the camera's
/// shutter covers it, and past 24 hours the timer is unsupported. The physics
/// is untouched either way - only the offer changes.
class ExposureTimerAction extends StatelessWidget {
  const ExposureTimerAction({
    required this.seconds,
    this.clock,
    this.tickInterval = kExposureTimerTickInterval,
    super.key,
  });

  /// The canonical filtered exposure from the calculator, in seconds, with its
  /// full precision.
  final double seconds;

  /// Test seam: the clock the panel will measure elapsed time with.
  final ExposureTimerClock? clock;

  /// Test seam: how often the panel repaints a running countdown.
  final Duration tickInterval;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final support = exposureTimerSupportFor(seconds);
    final note = switch (support) {
      ExposureTimerSupport.supported =>
        'Timed countdown with this result. Keep this screen open; '
            'no camera or shutter control.',
      ExposureTimerSupport.tooShort =>
        'Under one second: use the camera\'s shutter for this exposure.',
      ExposureTimerSupport.tooLong =>
        'Longer than 24 hours: this timer cannot time that exposure.',
      ExposureTimerSupport.unavailable => 'No valid exposure time to time.',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: AppGap.md),
        FilledButton.tonal(
          key: ExposureTimerKeys.action,
          onPressed: support == ExposureTimerSupport.supported
              ? () {
                  unawaited(_open(context));
                }
              : null,
          child: const Text('Exposure timer'),
        ),
        const SizedBox(height: AppGap.xs),
        Text(
          note,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Future<void> _open(BuildContext context) => showExposureTimerPanel(
    context,
    targetSeconds: seconds,
    clock: clock,
    tickInterval: tickInterval,
  );
}

/// The countdown itself: target, one Start, progress, Cancel, completion and
/// Restart, with explicit close guards while a countdown is running.
class ExposureTimerPanel extends StatefulWidget {
  const ExposureTimerPanel({
    required this.targetSeconds,
    this.clock,
    this.tickInterval = kExposureTimerTickInterval,
    super.key,
  });

  /// The frozen canonical exposure this panel times. Later changes to the
  /// calculator that produced it are deliberately ignored: an active exposure
  /// cannot be retimed from behind the panel.
  final double targetSeconds;

  final ExposureTimerClock? clock;
  final Duration tickInterval;

  @override
  State<ExposureTimerPanel> createState() => _ExposureTimerPanelState();
}

class _ExposureTimerPanelState extends State<ExposureTimerPanel> {
  late ExposureTimerState _state;
  Timer? _ticker;
  String _announcement = '';
  bool _confirming = false;

  ExposureTimerClock get _clock => widget.clock ?? DateTime.now;

  @override
  void initState() {
    super.initState();
    _state = ExposureTimerState.ready(widget.targetSeconds);
    _announcement = _readyAnnouncement();
  }

  @override
  void dispose() {
    // Every tick belongs to this panel: nothing may setState after it is gone.
    _cancelTicker();
    super.dispose();
  }

  void _cancelTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  String _readyAnnouncement() =>
      'Exposure timer ready. Target ${formatExposureTimerSeconds(widget.targetSeconds)}.';

  void _start() {
    _cancelTicker();
    final started = _state.start(_clock());
    setState(() {
      _state = started;
      _announcement =
          'Timing started. '
          '${formatExposureTimerSeconds(started.targetSeconds)} of exposure.';
    });
    _ticker = Timer.periodic(widget.tickInterval, (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    final current = _state;
    if (!current.isRunning) return;
    // The clock, not the callback count, decides how much time has passed: a
    // countdown throttled in the background resumes with the real elapsed time.
    final next = current.tick(_clock());
    if (next.elapsedSeconds == current.elapsedSeconds &&
        next.phase == current.phase) {
      return;
    }
    if (next.isComplete) {
      // Completion is the end of the ticks, not a repaint every tick.
      _cancelTicker();
    }
    setState(() {
      _state = next;
      if (next.isComplete) {
        _announcement = 'Exposure complete.';
      }
    });
  }

  void _cancel() {
    _cancelTicker();
    setState(() {
      _state = _state.cancel();
      _announcement = 'Timer cancelled. Ready to start again.';
    });
  }

  Future<void> _requestClose() async {
    if (!_state.isRunning) {
      Navigator.of(context).pop();
      return;
    }
    await _confirmDiscard();
  }

  /// A running countdown is never closed by a stray gesture or keystroke: the
  /// photographer confirms, and "keep timing" leaves it running untouched.
  Future<void> _confirmDiscard() async {
    if (_confirming) return;
    _confirming = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: ExposureTimerKeys.confirm,
        title: const Text('Discard the running timer?'),
        content: const Text(
          'The exposure is still being timed. Closing this panel abandons '
          'the countdown.',
        ),
        actions: <Widget>[
          TextButton(
            key: ExposureTimerKeys.keepTiming,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep timing'),
          ),
          FilledButton(
            key: ExposureTimerKeys.discard,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard timer'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    _confirming = false;
    if (discard ?? false) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      // The clock can finish while the confirmation is open.
      _announcement = _state.isComplete
          ? 'Exposure complete.'
          : 'Timer still running.';
    });
  }

  String get _label => switch (_state.phase) {
    ExposureTimerPhase.ready => 'Target exposure',
    ExposureTimerPhase.running => 'Remaining',
    ExposureTimerPhase.completed => 'Timed exposure',
  };

  String get _value => switch (_state.phase) {
    ExposureTimerPhase.ready || ExposureTimerPhase.completed =>
      formatExposureTimerSeconds(_state.targetSeconds),
    ExposureTimerPhase.running => formatExposureTimerSeconds(
      _state.remainingSeconds,
    ),
  };

  List<Widget> _actions() {
    switch (_state.phase) {
      case ExposureTimerPhase.ready:
        return <Widget>[
          TextButton(
            key: ExposureTimerKeys.close,
            onPressed: () {
              unawaited(_requestClose());
            },
            child: const Text('Close'),
          ),
          FilledButton(
            key: ExposureTimerKeys.start,
            autofocus: true,
            onPressed: _start,
            child: const Text('Start'),
          ),
        ];
      case ExposureTimerPhase.running:
        return <Widget>[
          TextButton(
            key: ExposureTimerKeys.close,
            onPressed: () {
              unawaited(_requestClose());
            },
            child: const Text('Close'),
          ),
          // The running state's one clear state-changing control; leaving the
          // panel is the secondary path and is guarded because it abandons the
          // exposure.
          FilledButton(
            key: ExposureTimerKeys.cancel,
            onPressed: _cancel,
            child: const Text('Cancel'),
          ),
        ];
      case ExposureTimerPhase.completed:
        return <Widget>[
          TextButton(
            key: ExposureTimerKeys.close,
            onPressed: () {
              unawaited(_requestClose());
            },
            child: const Text('Close'),
          ),
          FilledButton(
            key: ExposureTimerKeys.restart,
            onPressed: _start,
            child: const Text('Restart'),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = _state;
    return PopScope(
      // Escape, the system back gesture and an outside tap all land here. While
      // a countdown runs the pop is vetoed and the confirmation speaks for it;
      // a ready or completed panel closes freely.
      canPop: !state.isRunning,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _confirming) return;
        unawaited(_requestClose());
      },
      child: AlertDialog(
        key: ExposureTimerKeys.panel,
        scrollable: true,
        title: const Text('Exposure timer'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              _label,
              key: ExposureTimerKeys.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: AppGap.xs),
            // The readout can be long ('24:00:00') at 200 percent text on a
            // narrow phone; it scales down instead of clipping.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _value,
                key: ExposureTimerKeys.remaining,
                style: theme.textTheme.headlineMedium?.tabular,
              ),
            ),
            const SizedBox(height: AppGap.md),
            // No `semanticsValue` here on purpose: a determinate indicator is
            // published with the progress-bar role, whose value must be a plain
            // number or a percentage. A worded value ('0 percent') trips the
            // framework's own role check, and the default already announces the
            // same rounded percentage this line used to spell out.
            LinearProgressIndicator(
              value: state.progress,
              minHeight: 8,
              semanticsLabel: 'Exposure progress',
            ),
            const SizedBox(height: AppGap.md),
            // One live region, rewritten on transitions only: a screen reader
            // hears the start, the completion and the cancellation, not a
            // number every tick.
            Semantics(
              liveRegion: true,
              label: _announcement,
              excludeSemantics: true,
              child: Text(
                _announcement,
                key: ExposureTimerKeys.announcement,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: AppGap.sm),
            Text(
              'Keep this screen open. No camera control or background alarm.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: _actions(),
      ),
    );
  }
}
