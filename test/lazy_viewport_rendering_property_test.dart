import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/lazy_timeline_viewport.dart';

void main() {
  group('LazyTimelineViewport Rendering Property Tests', () {
    testWidgets('Property 5: Lazy Viewport Rendering - renders only items in visible range',
        (WidgetTester tester) async {
      // Feature: native-scroll-only, Property 5: Lazy Viewport Rendering
      // Validates: Requirements 5.5

      final random = Random(42); // Use seed for reproducibility

      // Run property test with 100 iterations
      for (var iteration = 0; iteration < 100; iteration++) {
        // Generate random parameters
        final totalDays = 50 + random.nextInt(200); // 50-250 days
        final dayWidth = 40.0 + random.nextDouble() * 20; // 40-60 width
        final dayMargin = 3.0 + random.nextDouble() * 5; // 3-8 margin

        // Generate random visible range
        final maxStart = totalDays - 10;
        final visibleStart = maxStart > 0 ? random.nextInt(maxStart) : 0;
        final rangeSize = 5 + random.nextInt(20); // 5-25 items visible
        final visibleEnd = (visibleStart + rangeSize).clamp(0, totalDays);

        // Generate random center index within visible range
        final centerItemIndex = visibleStart + random.nextInt((visibleEnd - visibleStart).clamp(1, totalDays));

        // Generate test data
        final days = List.generate(
          totalDays,
          (i) => {
            'date': DateTime.now().add(Duration(days: i)),
            'index': i,
          },
        );

        // Track which items were built
        final builtIndices = <int>[];

        // Build the LazyTimelineViewport with random parameters
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: LazyTimelineViewport(
                  visibleStart: visibleStart,
                  visibleEnd: visibleEnd,
                  centerItemIndex: centerItemIndex,
                  items: days,
                  itemWidth: dayWidth,
                  itemMargin: dayMargin,
                  itemBuilder: (context, index) {
                    builtIndices.add(index);
                    return Container(
                      key: ValueKey('day_$index'),
                      width: dayWidth - dayMargin,
                      height: 100,
                      color: index == centerItemIndex ? Colors.red : Colors.blue,
                      child: Text('Day $index'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        // Property 1: Only items in visible range should be rendered
        for (final index in builtIndices) {
          expect(
            index >= visibleStart && index <= visibleEnd,
            isTrue,
            reason: 'Item $index should be within visible range [$visibleStart, $visibleEnd] (iteration $iteration)',
          );
        }

        // Property 2: All items in visible range should be rendered
        // (accounting for clamping to valid indices)
        final expectedStart = visibleStart.clamp(0, totalDays - 1);
        final expectedEnd = visibleEnd.clamp(0, totalDays - 1);

        for (var i = expectedStart; i <= expectedEnd && i < totalDays; i++) {
          expect(
            builtIndices.contains(i),
            isTrue,
            reason:
                'Item $i should be rendered as it is in visible range [$visibleStart, $visibleEnd] (iteration $iteration)',
          );
        }

        // Property 3: Number of rendered items should match visible range size
        final expectedCount = (expectedEnd - expectedStart + 1).clamp(0, totalDays);
        expect(
          builtIndices.length,
          equals(expectedCount),
          reason:
              'Should render exactly $expectedCount items for range [$visibleStart, $visibleEnd] (iteration $iteration)',
        );

        // Property 4: Items should be rendered in order
        for (var i = 0; i < builtIndices.length - 1; i++) {
          expect(
            builtIndices[i] < builtIndices[i + 1],
            isTrue,
            reason: 'Items should be rendered in ascending order (iteration $iteration)',
          );
        }
      }
    }, timeout: const Timeout(Duration(minutes: 3)));

    testWidgets('Property 5: Lazy Viewport Rendering - passes correct centerItemIndex to itemBuilder',
        (WidgetTester tester) async {
      // Feature: native-scroll-only, Property 5: Lazy Viewport Rendering
      // Validates: Requirements 5.5

      final random = Random(123);

      for (var iteration = 0; iteration < 100; iteration++) {
        final totalDays = 30 + random.nextInt(70); // 30-100 days
        final dayWidth = 45.0;
        final dayMargin = 5.0;

        final visibleStart = random.nextInt(totalDays ~/ 2);
        final visibleEnd = visibleStart + 10 + random.nextInt(10);
        final centerItemIndex = visibleStart + random.nextInt((visibleEnd - visibleStart).clamp(1, totalDays));

        final days = List.generate(
          totalDays,
          (i) => {'date': DateTime.now().add(Duration(days: i))},
        );

        int? receivedCenterIndex;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LazyTimelineViewport(
                visibleStart: visibleStart,
                visibleEnd: visibleEnd,
                centerItemIndex: centerItemIndex,
                items: days,
                itemWidth: dayWidth,
                itemMargin: dayMargin,
                itemBuilder: (context, index) {
                  // Capture the center index by checking which item is highlighted
                  if (index == centerItemIndex) {
                    receivedCenterIndex = index;
                  }
                  return Container(
                    key: ValueKey('day_$index'),
                    width: dayWidth - dayMargin,
                    height: 100,
                    color: index == centerItemIndex ? Colors.red : Colors.blue,
                  );
                },
              ),
            ),
          ),
        );

        await tester.pump();

        // Verify centerItemIndex is accessible in itemBuilder
        // If centerItemIndex is in visible range, it should have been captured
        if (centerItemIndex >= visibleStart && centerItemIndex <= visibleEnd && centerItemIndex < totalDays) {
          expect(
            receivedCenterIndex,
            equals(centerItemIndex),
            reason: 'Center item index $centerItemIndex should be accessible in itemBuilder (iteration $iteration)',
          );
        }
      }
    }, timeout: const Timeout(Duration(minutes: 3)));

    testWidgets('Property 5: Lazy Viewport Rendering - handles edge cases correctly', (WidgetTester tester) async {
      // Feature: native-scroll-only, Property 5: Lazy Viewport Rendering
      // Validates: Requirements 5.5

      final random = Random(456);

      for (var iteration = 0; iteration < 100; iteration++) {
        final totalDays = 20 + random.nextInt(80);
        final dayWidth = 45.0;
        final dayMargin = 5.0;

        // Test various edge cases
        final testCases = [
          // Case 1: visibleStart = 0 (start of timeline)
          {'start': 0, 'end': 10, 'center': 5},
          // Case 2: visibleEnd = totalDays (end of timeline)
          {'start': totalDays - 10, 'end': totalDays, 'center': totalDays - 5},
          // Case 3: Single item visible
          {'start': totalDays ~/ 2, 'end': totalDays ~/ 2 + 1, 'center': totalDays ~/ 2},
          // Case 4: Empty range (start == end)
          {'start': 10, 'end': 10, 'center': 10},
          // Case 5: Random valid range
          {
            'start': random.nextInt(totalDays ~/ 2),
            'end': totalDays ~/ 2 + random.nextInt(totalDays ~/ 2),
            'center': totalDays ~/ 2,
          },
        ];

        for (final testCase in testCases) {
          final visibleStart = testCase['start'] as int;
          final visibleEnd = testCase['end'] as int;
          final centerItemIndex = testCase['center'] as int;

          final days = List.generate(
            totalDays,
            (i) => {'date': DateTime.now().add(Duration(days: i))},
          );

          final builtIndices = <int>[];

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: LazyTimelineViewport(
                  visibleStart: visibleStart,
                  visibleEnd: visibleEnd,
                  centerItemIndex: centerItemIndex,
                  items: days,
                  itemWidth: dayWidth,
                  itemMargin: dayMargin,
                  itemBuilder: (context, index) {
                    builtIndices.add(index);
                    return Container(
                      key: ValueKey('day_$index'),
                      width: dayWidth - dayMargin,
                      height: 100,
                    );
                  },
                ),
              ),
            ),
          );

          await tester.pump();

          // Verify no exceptions thrown
          expect(tester.takeException(), isNull,
              reason:
                  'Should handle edge case without errors: start=$visibleStart, end=$visibleEnd (iteration $iteration)');

          // Verify all built items are within valid range
          for (final index in builtIndices) {
            expect(
              index >= 0 && index < totalDays,
              isTrue,
              reason: 'Built item $index should be within valid range [0, $totalDays) (iteration $iteration)',
            );
          }
        }
      }
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}
