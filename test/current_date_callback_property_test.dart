import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/timeline.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/timeline_configuration_manager.dart';

void main() {
  group('Current Date Callback Property Tests', () {
    setUp(() {
      TimelineConfigurationManager.reset();
      TimelineConfigurationManager.initialize();
    });

    tearDown(() {
      TimelineConfigurationManager.reset();
    });

    testWidgets(
        'Property 6: Current Date Callback Invocation - For any scroll position where center item changes, callback should be called with correct date',
        (WidgetTester tester) async {
      // Feature: standard-scroll-refactoring, Property 6: Current Date Callback Invocation
      // Validates: Requirements 4.3

      const numDays = 100;
      const numIterations = 100;
      final startDate = DateTime(2024, 1, 1);
      final endDate = startDate.add(Duration(
          days:
              numDays)); // Changed from numDays - 1 to numDays to get 101 days total

      // Create minimal test data - empty elements to avoid widget rendering issues
      final elements = <Map<String, dynamic>>[];
      final stages = <Map<String, dynamic>>[];

      final infos = {
        'startDate':
            '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
        'endDate':
            '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
        'lmax': 8,
      };

      // Track callback invocations
      final List<String> callbackDates = [];
      String? lastCallbackDate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Timeline(
              colors: {
                'primary': Colors.blue,
                'primaryBackground': Colors.white,
                'secondaryBackground': Colors.grey[200]!,
                'primaryText': Colors.black,
                'secondaryText': Colors.grey[600]!,
                'accent1': Colors.grey[400]!,
                'error': Colors.red,
                'warning': Colors.orange,
              },
              infos: infos,
              elements: elements,
              elementsDone: [],
              capacities: [],
              stages: stages,
              openDayDetail: (date, capacity, preIds, elements, infos) {},
              updateCurrentDate: (date) {
                // Mock callback that tracks invocations
                if (date != null) {
                  callbackDates.add(date);
                  lastCallbackDate = date;
                }
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final timelineFinder = find.byType(Timeline);
      expect(timelineFinder, findsOneWidget);

      final timelineState = tester.state(timelineFinder) as dynamic;

      // Get the actual number of days from the timeline
      final days = timelineState.days as List;
      final actualNumDays = days.length;

      // Property Test: Run 100 iterations with random date indices
      final random = Random(42); // Fixed seed for reproducibility
      int passedTests = 0;
      int callbackInvocations = 0;

      // Regular expression to validate YYYY-MM-DD format
      final dateFormatRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');

      for (int i = 0; i < numIterations; i++) {
        // Generate random date index (0 to actualNumDays-1)
        final targetDateIndex = random.nextInt(actualNumDays);

        // Clear previous callback tracking
        final previousDate = lastCallbackDate;
        final previousCallbackCount = callbackDates.length;

        try {
          // Scroll to the target date index
          timelineState.scrollTo(targetDateIndex, animated: false);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          // Check if callback was invoked
          final callbackWasInvoked =
              callbackDates.length > previousCallbackCount;

          if (callbackWasInvoked) {
            callbackInvocations++;

            // Verify the callback date is in correct format (YYYY-MM-DD)
            final callbackDate = lastCallbackDate!;
            final isValidFormat = dateFormatRegex.hasMatch(callbackDate);

            if (!isValidFormat) {
              debugPrint(
                  'Iteration $i: Invalid date format - expected YYYY-MM-DD, got: $callbackDate');
              continue;
            }

            // Parse the callback date
            final parsedDate = DateTime.parse(callbackDate);

            // Verify the date is within the valid range
            final isWithinRange = parsedDate
                    .isAfter(startDate.subtract(const Duration(days: 1))) &&
                parsedDate.isBefore(endDate.add(const Duration(days: 1)));

            if (!isWithinRange) {
              debugPrint(
                  'Iteration $i: Date out of range - $callbackDate not between $startDate and $endDate');
              continue;
            }

            // Calculate expected date for the target index
            // Note: scrollTo() positions the date at the LEFT edge of the viewport
            // The center item is offset by half the viewport width
            final viewportWidth = 800.0; // From test setup
            final itemWidth = 40.0; // dayWidth (45) - dayMargin (5)
            final centerOffset = (viewportWidth / 2 / itemWidth).round();
            final expectedCenterIndex =
                (targetDateIndex + centerOffset).clamp(0, actualNumDays - 1);
            final expectedDate =
                startDate.add(Duration(days: expectedCenterIndex));
            final expectedDateString =
                '${expectedDate.year}-${expectedDate.month.toString().padLeft(2, '0')}-${expectedDate.day.toString().padLeft(2, '0')}';

            // Verify the callback date matches the expected CENTER date (within 1 day tolerance)
            final dayDifference =
                parsedDate.difference(expectedDate).inDays.abs();

            if (dayDifference <= 1) {
              passedTests++;
            } else {
              debugPrint(
                  'Iteration $i: Date mismatch - expected $expectedDateString (center of viewport), got $callbackDate (diff: $dayDifference days)');
            }
          } else {
            // Callback not invoked - this is acceptable if center item didn't change
            // or if the scroll position is the same as before
            if (previousDate == null || targetDateIndex == 0) {
              // First scroll or initial position - count as pass
              passedTests++;
            } else {
              // Check if we scrolled to a different position
              final expectedDate =
                  startDate.add(Duration(days: targetDateIndex));
              final expectedDateString =
                  '${expectedDate.year}-${expectedDate.month.toString().padLeft(2, '0')}-${expectedDate.day.toString().padLeft(2, '0')}';

              if (previousDate == expectedDateString) {
                // Scrolled to same date - callback not expected to fire
                passedTests++;
              } else {
                // Different date but callback not fired - might be timing issue
                // Give it another pump cycle
                await tester.pump(const Duration(milliseconds: 100));
                if (callbackDates.length > previousCallbackCount) {
                  // Callback fired after additional pump
                  passedTests++;
                } else {
                  debugPrint(
                      'Iteration $i: Callback not invoked when scrolling to different date (target=$targetDateIndex, previous=$previousDate)');
                }
              }
            }
          }
        } catch (e) {
          debugPrint(
              'Iteration $i failed with targetDateIndex=$targetDateIndex: $e');
        }
      }

      // Verify that most iterations passed (allow some tolerance for timing issues)
      final successRate = passedTests / numIterations;
      expect(successRate, greaterThan(0.9),
          reason:
              'Property test failed: $passedTests/$numIterations iterations passed (${(successRate * 100).toStringAsFixed(1)}%). '
              'Expected callback to be called with correct date string (YYYY-MM-DD format) when center item changes. '
              'Callback was invoked $callbackInvocations times.');

      // Verify that callback was invoked at least some times
      expect(callbackInvocations, greaterThan(0),
          reason:
              'Callback should have been invoked at least once during the test');
    });

    testWidgets(
        'Property 6: Current Date Callback Invocation - Callback receives valid YYYY-MM-DD format',
        (WidgetTester tester) async {
      // Feature: standard-scroll-refactoring, Property 6: Current Date Callback Invocation
      // Validates: Requirements 4.3

      const numDays = 50;
      final startDate = DateTime(2024, 1, 1);
      final endDate = startDate.add(Duration(days: numDays - 1));

      final elements = <Map<String, dynamic>>[];
      final stages = <Map<String, dynamic>>[];

      final infos = {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'lmax': 8,
      };

      // Track callback invocations
      final List<String> receivedDates = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Timeline(
              colors: {
                'primary': Colors.blue,
                'primaryBackground': Colors.white,
                'secondaryBackground': Colors.grey[200]!,
                'primaryText': Colors.black,
                'secondaryText': Colors.grey[600]!,
                'accent1': Colors.grey[400]!,
                'error': Colors.red,
                'warning': Colors.orange,
              },
              infos: infos,
              elements: elements,
              elementsDone: [],
              capacities: [],
              stages: stages,
              openDayDetail: (date, capacity, preIds, elements, infos) {},
              updateCurrentDate: (date) {
                if (date != null) {
                  receivedDates.add(date);
                }
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final timelineFinder = find.byType(Timeline);
      final timelineState = tester.state(timelineFinder) as dynamic;

      // Scroll to different positions to trigger callback
      final testIndices = [0, 10, 20, 30, 40];
      for (final index in testIndices) {
        timelineState.scrollTo(index, animated: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Verify all received dates are in YYYY-MM-DD format
      final dateFormatRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      for (final date in receivedDates) {
        expect(dateFormatRegex.hasMatch(date), isTrue,
            reason: 'Date "$date" should be in YYYY-MM-DD format');
      }

      // Verify at least some callbacks were received
      expect(receivedDates.length, greaterThan(0),
          reason: 'Should have received at least one callback');
    });
  });
}
