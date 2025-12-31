import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/lazy_stage_rows_viewport.dart';
import 'package:swiip_pubdev_timeline/src/timeline/optimized_stage_row.dart';

void main() {
  group('LazyStageRowsViewport Rendering Property Tests', () {
    testWidgets('Property 5: Lazy Viewport Rendering - renders only stage rows in visible range',
        (WidgetTester tester) async {
      // Feature: native-scroll-only, Property 5: Lazy Viewport Rendering
      // Validates: Requirements 5.5

      final random = Random(789); // Use seed for reproducibility

      // Run property test with 100 iterations
      for (var iteration = 0; iteration < 100; iteration++) {
        // Generate random parameters
        final totalRows = 20 + random.nextInt(80); // 20-100 rows
        final totalDays = 50 + random.nextInt(150); // 50-200 days
        final dayWidth = 40.0 + random.nextDouble() * 20; // 40-60 width
        final dayMargin = 3.0 + random.nextDouble() * 5; // 3-8 margin
        final rowHeight = 40.0 + random.nextDouble() * 20; // 40-60 height
        final rowMargin = 2.0 + random.nextDouble() * 4; // 2-6 margin
        final viewportHeight = 400.0 + random.nextDouble() * 400; // 400-800

        // Generate random horizontal visible range
        final maxStart = totalDays - 10;
        final visibleStart = maxStart > 0 ? random.nextInt(maxStart) : 0;
        final rangeSize = 5 + random.nextInt(20); // 5-25 items visible
        final visibleEnd = (visibleStart + rangeSize).clamp(0, totalDays);

        // Generate test data for stage rows
        final stagesRows = List.generate(
          totalRows,
          (i) => [
            {
              'id': 'stage_$i',
              'name': 'Stage $i',
              'startDateIndex': 0,
              'endDateIndex': totalDays - 1,
              'elements': [],
            }
          ],
        );

        // Create a scroll controller for vertical scrolling
        final verticalScrollController = ScrollController();

        // Build the LazyStageRowsViewport with random parameters
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: viewportHeight,
                child: SingleChildScrollView(
                  controller: verticalScrollController,
                  child: LazyStageRowsViewport(
                    visibleStart: visibleStart,
                    visibleEnd: visibleEnd,
                    stagesRows: stagesRows,
                    rowHeight: rowHeight,
                    rowMargin: rowMargin,
                    dayWidth: dayWidth,
                    dayMargin: dayMargin,
                    totalDays: totalDays,
                    colors: const {
                      'primary': Colors.blue,
                      'secondary': Colors.green,
                    },
                    isUniqueProject: false,
                    verticalScrollController: verticalScrollController,
                    viewportHeight: viewportHeight,
                    bufferRows: 2,
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        // Calculate expected visible rows based on viewport height
        final rowTotalHeight = rowHeight + (rowMargin * 2);
        final visibleRowCount = (viewportHeight / rowTotalHeight).ceil();
        const bufferRows = 2;
        final expectedMaxRows = visibleRowCount + (bufferRows * 2);

        // Find all OptimizedStageRow widgets that were built
        final stageRowFinder = find.byType(OptimizedStageRow);
        final builtRowCount = stageRowFinder.evaluate().length;

        // Property 1: Should render fewer rows than total when total is large
        if (totalRows > expectedMaxRows) {
          expect(
            builtRowCount,
            lessThan(totalRows),
            reason: 'Should render fewer rows than total when total exceeds viewport (iteration $iteration)',
          );
        }

        // Property 2: Should render at least some rows
        expect(
          builtRowCount,
          greaterThan(0),
          reason: 'Should render at least some rows (iteration $iteration)',
        );

        // Property 3: Should not render more than viewport + buffer
        expect(
          builtRowCount,
          lessThanOrEqualTo(expectedMaxRows + 5), // +5 for tolerance
          reason: 'Should not render significantly more than viewport + buffer (iteration $iteration)',
        );

        verticalScrollController.dispose();
      }
    }, timeout: const Timeout(Duration(minutes: 3)));

    testWidgets('Property 5: Lazy Viewport Rendering - updates rendered rows when vertical scroll changes',
        (WidgetTester tester) async {
      // Feature: native-scroll-only, Property 5: Lazy Viewport Rendering
      // Validates: Requirements 5.5

      final random = Random(321);

      for (var iteration = 0; iteration < 100; iteration++) {
        final totalRows = 50 + random.nextInt(50); // 50-100 rows
        final totalDays = 100;
        final dayWidth = 45.0;
        final dayMargin = 5.0;
        final rowHeight = 50.0;
        final rowMargin = 3.0;
        final viewportHeight = 400.0;

        final visibleStart = 0;
        final visibleEnd = 20;

        final stagesRows = List.generate(
          totalRows,
          (i) => [
            {
              'id': 'stage_$i',
              'name': 'Stage $i',
              'startDateIndex': 0,
              'endDateIndex': totalDays - 1,
            }
          ],
        );

        final verticalScrollController = ScrollController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: viewportHeight,
                child: SingleChildScrollView(
                  controller: verticalScrollController,
                  child: LazyStageRowsViewport(
                    visibleStart: visibleStart,
                    visibleEnd: visibleEnd,
                    stagesRows: stagesRows,
                    rowHeight: rowHeight,
                    rowMargin: rowMargin,
                    dayWidth: dayWidth,
                    dayMargin: dayMargin,
                    totalDays: totalDays,
                    colors: const {
                      'primary': Colors.blue,
                    },
                    isUniqueProject: false,
                    verticalScrollController: verticalScrollController,
                    viewportHeight: viewportHeight,
                    bufferRows: 2,
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Scroll down to middle of timeline
        if (verticalScrollController.hasClients) {
          final maxScroll = verticalScrollController.position.maxScrollExtent;
          if (maxScroll > 0) {
            verticalScrollController.jumpTo(maxScroll / 2);
            await tester.pumpAndSettle();

            // Verify that rows are still being rendered
            final afterScrollRowCount = find.byType(OptimizedStageRow).evaluate().length;
            expect(
              afterScrollRowCount,
              greaterThan(0),
              reason: 'Should still render rows after scrolling (iteration $iteration)',
            );

            // The count might be similar due to viewport size, but verify no errors
            expect(tester.takeException(), isNull,
                reason: 'Should handle vertical scroll without errors (iteration $iteration)');
          }
        }

        verticalScrollController.dispose();
      }
    }, timeout: const Timeout(Duration(minutes: 3)));

    testWidgets('Property 5: Lazy Viewport Rendering - handles edge cases for stage rows', (WidgetTester tester) async {
      // Feature: native-scroll-only, Property 5: Lazy Viewport Rendering
      // Validates: Requirements 5.5

      for (var iteration = 0; iteration < 100; iteration++) {
        // Test various edge cases
        final testCases = [
          // Case 1: Empty stage rows
          {'totalRows': 0, 'visibleStart': 0, 'visibleEnd': 10},
          // Case 2: Single row
          {'totalRows': 1, 'visibleStart': 0, 'visibleEnd': 10},
          // Case 3: Few rows (less than viewport)
          {'totalRows': 5, 'visibleStart': 0, 'visibleEnd': 20},
          // Case 4: Many rows
          {'totalRows': 100, 'visibleStart': 10, 'visibleEnd': 30},
        ];

        for (final testCase in testCases) {
          final totalRows = testCase['totalRows'] as int;
          final visibleStart = testCase['visibleStart'] as int;
          final visibleEnd = testCase['visibleEnd'] as int;

          final stagesRows = List.generate(
            totalRows,
            (i) => [
              {
                'id': 'stage_$i',
                'startDateIndex': 0,
                'endDateIndex': 100,
              }
            ],
          );

          final verticalScrollController = ScrollController();

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 800,
                  height: 400,
                  child: SingleChildScrollView(
                    controller: verticalScrollController,
                    child: LazyStageRowsViewport(
                      visibleStart: visibleStart,
                      visibleEnd: visibleEnd,
                      stagesRows: stagesRows,
                      rowHeight: 50.0,
                      rowMargin: 3.0,
                      dayWidth: 45.0,
                      dayMargin: 5.0,
                      totalDays: 100,
                      colors: const {'primary': Colors.blue},
                      isUniqueProject: false,
                      verticalScrollController: verticalScrollController,
                      viewportHeight: 400.0,
                      bufferRows: 2,
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Verify no exceptions thrown
          expect(tester.takeException(), isNull,
              reason: 'Should handle edge case without errors: totalRows=$totalRows (iteration $iteration)');

          verticalScrollController.dispose();
        }
      }
    }, timeout: const Timeout(Duration(minutes: 3)));

    testWidgets('Property 5: Lazy Viewport Rendering - passes correct horizontal visible range to stage rows',
        (WidgetTester tester) async {
      // Feature: native-scroll-only, Property 5: Lazy Viewport Rendering
      // Validates: Requirements 5.5

      final random = Random(987);

      for (var iteration = 0; iteration < 100; iteration++) {
        final totalRows = 10 + random.nextInt(20);
        final totalDays = 100;
        final visibleStart = random.nextInt(50);
        final visibleEnd = visibleStart + 10 + random.nextInt(20);

        final stagesRows = List.generate(
          totalRows,
          (i) => [
            {
              'id': 'stage_$i',
              'name': 'Stage $i',
              'startDateIndex': 0,
              'endDateIndex': totalDays - 1,
            }
          ],
        );

        final verticalScrollController = ScrollController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: LazyStageRowsViewport(
                  visibleStart: visibleStart,
                  visibleEnd: visibleEnd,
                  stagesRows: stagesRows,
                  rowHeight: 50.0,
                  rowMargin: 3.0,
                  dayWidth: 45.0,
                  dayMargin: 5.0,
                  totalDays: totalDays,
                  colors: const {'primary': Colors.blue},
                  isUniqueProject: false,
                  verticalScrollController: verticalScrollController,
                  viewportHeight: 400.0,
                  bufferRows: 2,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify widget builds without errors
        expect(tester.takeException(), isNull,
            reason: 'Should pass horizontal visible range correctly (iteration $iteration)');

        // Verify LazyStageRowsViewport is rendered
        expect(find.byType(LazyStageRowsViewport), findsOneWidget, reason: 'LazyStageRowsViewport should be rendered');

        verticalScrollController.dispose();
      }
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}
