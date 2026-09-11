/// Shared navigation helpers for the offline integration journeys.
///
/// `scrollUntilVisible` can leave the list mid-fling, so tapping straight after
/// it intermittently lands on the wrong tile and the journey fails for a reason
/// unrelated to the product. Every tap after a scroll goes through [tapVisible],
/// which settles the frame first.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Scrolls [finder] into view, settles, and taps it.
Future<void> tapVisible(
  WidgetTester tester,
  Finder finder, {
  double delta = 300,
}) async {
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Scrolls [finder] into view and settles, without tapping it.
Future<void> reveal(
  WidgetTester tester,
  Finder finder, {
  double delta = 300,
}) async {
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

/// Scrolls a planner list to the end of its result card so the save action is
/// fully inside the viewport before it is tapped. [extra] nudges further for
/// screens whose action row sits under a taller result.
Future<void> scrollToResultActions(
  WidgetTester tester, {
  double extra = 250,
}) async {
  await reveal(tester, find.text('Save result'));
  await tester.drag(find.byType(ListView).first, Offset(0, -extra));
  await tester.pumpAndSettle();
}

/// Pins a deterministic, tablet-sized logical viewport for a journey.
///
/// The host window that `flutter test integration_test` creates varies between
/// runs; a smaller window leaves controls below the fold unbuilt, so taps fail
/// for reasons unrelated to the product. Pinning the size makes every journey
/// reproducible. Journeys that deliberately test a small phone viewport (the
/// 200% text-scale journey) set their own size instead.
void configureJourneyView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
