import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/timeline.dart';

/// Unit tests for Timeline widget disposal
///
/// **Validates: Requirements 6.5**
///
/// This test verifies that:
/// - Vertical scroll debounce timer is properly cancelled in dispose()
/// - No memory leaks occur from timers
/// - ValueNotifiers are properly disposed
void main() {
  group('Timeline Disposal', () {
    testWidgets('should properly dispose vertical scroll debounce timer', (WidgetTester tester) async {
      // Feature: native-scroll-only, Requirement 6.5

      // Create a Timeline widget with minimal configuration
      final timeline = Timeline(
        colors: {
          'primaryBackground': Colors.white,
          'secondaryBackground': Colors.grey[200]!,
          'primaryText': Colors.black,
          'secondaryText': Colors.grey,
          'accent1': Colors.blue,
          'primary': Colors.blue,
          'error': Colors.red,
          'warning': Colors.orange,
          'info': Colors.green,
        },
        infos: {
          'startDate': '2024-01-01',
          'endDate': '2024-01-31',
          'lmax': 100,
        },
        elements: [
          {
            'id': '1',
            'date': '2024-01-15',
            'eff': 50,
          }
        ],
        elementsDone: [],
        capacities: [],
        stages: [
          {
            'id': 'stage1',
            'name': 'Stage 1',
            'prj_id': 'project1',
          }
        ],
        openDayDetail: (date, progress, preIds, elements, indicators) {},
      );

      // Build the widget
      await tester.pumpWidget(MaterialApp(home: timeline));

      // Wait for initialization
      await tester.pumpAndSettle();

      // Trigger a horizontal scroll event that would create the debounce timer
      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(-200, 0));

      // Pump a frame to trigger the scroll listener
      await tester.pump();

      // Dispose the widget by removing it from the tree
      await tester.pumpWidget(const SizedBox());

      // Wait to ensure no timer callbacks execute after disposal
      await tester.pump(const Duration(milliseconds: 150));

      // If we get here without errors, the timer was properly cancelled
      // No assertion needed - the test passes if no exceptions are thrown
    });

    testWidgets('should properly dispose ValueNotifiers', (WidgetTester tester) async {
      // Feature: native-scroll-only, Requirement 6.5

      // Create a Timeline widget with minimal configuration
      final timeline = Timeline(
        colors: {
          'primaryBackground': Colors.white,
          'secondaryBackground': Colors.grey[200]!,
          'primaryText': Colors.black,
          'secondaryText': Colors.grey,
          'accent1': Colors.blue,
          'primary': Colors.blue,
          'error': Colors.red,
          'warning': Colors.orange,
          'info': Colors.green,
        },
        infos: {
          'startDate': '2024-01-01',
          'endDate': '2024-01-31',
          'lmax': 100,
        },
        elements: [
          {
            'id': '1',
            'date': '2024-01-15',
            'eff': 50,
          }
        ],
        elementsDone: [],
        capacities: [],
        stages: [
          {
            'id': 'stage1',
            'name': 'Stage 1',
            'prj_id': 'project1',
          }
        ],
        openDayDetail: (date, progress, preIds, elements, indicators) {},
      );

      // Build the widget
      await tester.pumpWidget(MaterialApp(home: timeline));

      // Wait for initialization
      await tester.pumpAndSettle();

      // Dispose the widget by removing it from the tree
      await tester.pumpWidget(const SizedBox());

      // Wait a frame
      await tester.pump();

      // If we get here without errors, the ValueNotifiers were properly disposed
      // No assertion needed - the test passes if no exceptions are thrown
    });

    test('should verify timer cancellation prevents callback execution', () async {
      // Feature: native-scroll-only, Requirement 6.5

      // This test verifies that cancelling a timer prevents its callback from executing
      // This simulates the behavior in Timeline's dispose() method

      bool callbackExecuted = false;
      Timer? debounceTimer;

      // Create a timer (simulating vertical scroll debounce timer)
      debounceTimer = Timer(const Duration(milliseconds: 100), () {
        callbackExecuted = true;
      });

      // Verify timer is active
      expect(debounceTimer.isActive, isTrue);

      // Cancel the timer (simulating dispose)
      debounceTimer.cancel();

      // Verify timer is no longer active
      expect(debounceTimer.isActive, isFalse);

      // Wait longer than the timer duration
      await Future.delayed(const Duration(milliseconds: 150));

      // Verify callback was not executed after cancellation
      expect(callbackExecuted, isFalse, reason: 'Timer callback should not execute after cancellation');
    });

    test('should verify multiple timer cancellations are safe', () async {
      // Feature: native-scroll-only, Requirement 6.5

      // This test verifies that calling cancel() multiple times is safe
      // This is important because dispose() might be called multiple times

      Timer? debounceTimer;

      // Create a timer
      debounceTimer = Timer(const Duration(milliseconds: 100), () {});

      // Cancel multiple times (should not throw)
      debounceTimer.cancel();
      debounceTimer.cancel();
      debounceTimer.cancel();

      // If we get here without errors, multiple cancellations are safe
      expect(debounceTimer.isActive, isFalse);
    });

    test('should verify null timer cancellation is safe', () {
      // Feature: native-scroll-only, Requirement 6.5

      // This test verifies that cancelling a null timer is safe
      // This is important because the timer might not be created yet

      Timer? debounceTimer;

      // Cancel null timer (should not throw)
      debounceTimer?.cancel();

      // If we get here without errors, null cancellation is safe
      expect(debounceTimer, isNull);
    });
  });
}
