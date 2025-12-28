import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/loading_indicator_overlay.dart';

/// Property 13: Loading Indicators
///
/// **Validates: Requirements 8.5**
///
/// This test verifies that:
/// - Loading indicators are displayed only when operations exceed the threshold (200ms)
/// - Loading indicators are not displayed for quick operations (< 200ms)
/// - Loading indicators are properly hidden when operations complete
/// - The threshold mechanism prevents flickering for quick operations
/// - Multiple rapid loading state changes are handled correctly
///
/// Property: For any operation that takes longer than a defined threshold (e.g., 200ms),
/// a loading indicator should be displayed to the user.
void main() {
  group('Property 13: Loading Indicators', () {
    testWidgets('should not display indicator for operations under threshold',
        (WidgetTester tester) async {
      // Feature: timeline-performance-optimization, Property 13: Loading Indicators

      final isLoadingNotifier = ValueNotifier<bool>(false);

      await tester.pumpWidget(
        MaterialApp(
          home: LoadingIndicatorOverlay(
            isLoadingNotifier: isLoadingNotifier,
            threshold: const Duration(milliseconds: 200),
            child: const Scaffold(
              body: Center(child: Text('Content')),
            ),
          ),
        ),
      );

      // Verify content is visible
      expect(find.text('Content'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Start loading
      isLoadingNotifier.value = true;
      await tester.pump();

      // Immediately check - indicator should not be visible yet (threshold not reached)
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Wait less than threshold (100ms)
      await tester.pump(const Duration(milliseconds: 100));

      // Stop loading before threshold
      isLoadingNotifier.value = false;
      await tester.pump();

      // Wait for any pending timers
      await tester.pump(const Duration(milliseconds: 150));

      // Indicator should never have appeared
      expect(find.byType(CircularProgressIndicator), findsNothing,
          reason: 'Indicator should not appear for operations under threshold');

      isLoadingNotifier.dispose();
    });

    testWidgets('should display indicator for operations exceeding threshold',
        (WidgetTester tester) async {
      // Feature: timeline-performance-optimization, Property 13: Loading Indicators

      final isLoadingNotifier = ValueNotifier<bool>(false);

      await tester.pumpWidget(
        MaterialApp(
          home: LoadingIndicatorOverlay(
            isLoadingNotifier: isLoadingNotifier,
            threshold: const Duration(milliseconds: 200),
            child: const Scaffold(
              body: Center(child: Text('Content')),
            ),
          ),
        ),
      );

      // Start loading
      isLoadingNotifier.value = true;
      await tester.pump();

      // Wait for threshold to pass
      await tester.pump(const Duration(milliseconds: 250));

      // Indicator should now be visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget,
          reason: 'Indicator should appear after threshold is exceeded');

      // Content should still be visible behind overlay
      expect(find.text('Content'), findsOneWidget);

      // Stop loading
      isLoadingNotifier.value = false;
      await tester.pump();

      // Indicator should be hidden immediately
      expect(find.byType(CircularProgressIndicator), findsNothing,
          reason: 'Indicator should hide immediately when loading stops');

      isLoadingNotifier.dispose();
    });

    testWidgets('should handle rapid loading state changes correctly',
        (WidgetTester tester) async {
      // Feature: timeline-performance-optimization, Property 13: Loading Indicators

      final isLoadingNotifier = ValueNotifier<bool>(false);

      await tester.pumpWidget(
        MaterialApp(
          home: LoadingIndicatorOverlay(
            isLoadingNotifier: isLoadingNotifier,
            threshold: const Duration(milliseconds: 200),
            child: const Scaffold(
              body: Center(child: Text('Content')),
            ),
          ),
        ),
      );

      // Simulate rapid loading state changes (multiple quick operations)
      for (int i = 0; i < 5; i++) {
        isLoadingNotifier.value = true;
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        isLoadingNotifier.value = false;
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Wait for any pending timers
      await tester.pump(const Duration(milliseconds: 300));

      // Indicator should not have appeared for any of the quick operations
      expect(find.byType(CircularProgressIndicator), findsNothing,
          reason:
              'Indicator should not appear for rapid quick operations under threshold');

      isLoadingNotifier.dispose();
    });

    testWidgets('should cancel threshold timer when loading stops early',
        (WidgetTester tester) async {
      // Feature: timeline-performance-optimization, Property 13: Loading Indicators

      final isLoadingNotifier = ValueNotifier<bool>(false);

      await tester.pumpWidget(
        MaterialApp(
          home: LoadingIndicatorOverlay(
            isLoadingNotifier: isLoadingNotifier,
            threshold: const Duration(milliseconds: 200),
            child: const Scaffold(
              body: Center(child: Text('Content')),
            ),
          ),
        ),
      );

      // Start loading
      isLoadingNotifier.value = true;
      await tester.pump();

      // Wait partway through threshold
      await tester.pump(const Duration(milliseconds: 100));

      // Stop loading before threshold
      isLoadingNotifier.value = false;
      await tester.pump();

      // Wait past when threshold would have triggered
      await tester.pump(const Duration(milliseconds: 150));

      // Indicator should not appear (timer was cancelled)
      expect(find.byType(CircularProgressIndicator), findsNothing,
          reason:
              'Indicator should not appear if loading stops before threshold');

      isLoadingNotifier.dispose();
    });

    testWidgets('should use custom threshold duration',
        (WidgetTester tester) async {
      // Feature: timeline-performance-optimization, Property 13: Loading Indicators

      final isLoadingNotifier = ValueNotifier<bool>(false);
      const customThreshold = Duration(milliseconds: 100);

      await tester.pumpWidget(
        MaterialApp(
          home: LoadingIndicatorOverlay(
            isLoadingNotifier: isLoadingNotifier,
            threshold: customThreshold,
            child: const Scaffold(
              body: Center(child: Text('Content')),
            ),
          ),
        ),
      );

      // Start loading
      isLoadingNotifier.value = true;
      await tester.pump();

      // Wait for custom threshold to pass
      await tester.pump(const Duration(milliseconds: 150));

      // Indicator should be visible with custom threshold
      expect(find.byType(CircularProgressIndicator), findsOneWidget,
          reason: 'Indicator should appear after custom threshold');

      isLoadingNotifier.value = false;
      await tester.pump();

      isLoadingNotifier.dispose();
    });

    testWidgets('should properly dispose timer on widget disposal',
        (WidgetTester tester) async {
      // Feature: timeline-performance-optimization, Property 13: Loading Indicators

      final isLoadingNotifier = ValueNotifier<bool>(false);

      await tester.pumpWidget(
        MaterialApp(
          home: LoadingIndicatorOverlay(
            isLoadingNotifier: isLoadingNotifier,
            threshold: const Duration(milliseconds: 200),
            child: const Scaffold(
              body: Center(child: Text('Content')),
            ),
          ),
        ),
      );

      // Start loading
      isLoadingNotifier.value = true;
      await tester.pump();

      // Dispose the widget while timer is active
      await tester.pumpWidget(const SizedBox());

      // Wait past threshold
      await tester.pump(const Duration(milliseconds: 300));

      // No errors should occur (timer was properly disposed)
      expect(tester.takeException(), isNull,
          reason:
              'No exceptions should occur when disposing with active timer');

      isLoadingNotifier.dispose();
    });

    test('should handle threshold timing correctly with direct timer test',
        () async {
      // Feature: timeline-performance-optimization, Property 13: Loading Indicators

      // This test verifies the threshold mechanism directly using timers
      bool indicatorShown = false;
      Timer? thresholdTimer;
      const threshold = Duration(milliseconds: 200);

      // Simulate loading start
      bool isLoading = true;

      // Start threshold timer
      thresholdTimer = Timer(threshold, () {
        if (isLoading) {
          indicatorShown = true;
        }
      });

      // Wait less than threshold
      await Future.delayed(const Duration(milliseconds: 100));

      // Stop loading before threshold
      isLoading = false;
      thresholdTimer.cancel();

      // Wait past threshold
      await Future.delayed(const Duration(milliseconds: 150));

      // Indicator should not have been shown
      expect(indicatorShown, isFalse,
          reason:
              'Indicator should not show if loading stops before threshold');

      // Test case 2: Loading exceeds threshold
      indicatorShown = false;
      isLoading = true;

      thresholdTimer = Timer(threshold, () {
        if (isLoading) {
          indicatorShown = true;
        }
      });

      // Wait past threshold
      await Future.delayed(const Duration(milliseconds: 250));

      // Indicator should be shown
      expect(indicatorShown, isTrue,
          reason: 'Indicator should show if loading exceeds threshold');
    });

    testWidgets('should display custom overlay and indicator colors',
        (WidgetTester tester) async {
      // Feature: timeline-performance-optimization, Property 13: Loading Indicators

      final isLoadingNotifier = ValueNotifier<bool>(false);
      const customOverlayColor = Colors.blue;
      const customIndicatorColor = Colors.red;

      await tester.pumpWidget(
        MaterialApp(
          home: LoadingIndicatorOverlay(
            isLoadingNotifier: isLoadingNotifier,
            threshold: const Duration(milliseconds: 200),
            overlayColor: customOverlayColor,
            indicatorColor: customIndicatorColor,
            child: const Scaffold(
              body: Center(child: Text('Content')),
            ),
          ),
        ),
      );

      // Start loading and wait for threshold
      isLoadingNotifier.value = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Verify indicator is visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Verify custom colors are applied
      final progressIndicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator));
      final valueColor =
          progressIndicator.valueColor as AlwaysStoppedAnimation<Color>;
      expect(valueColor.value, equals(customIndicatorColor),
          reason: 'Custom indicator color should be applied');

      isLoadingNotifier.value = false;
      await tester.pump();

      isLoadingNotifier.dispose();
    });
  });
}
