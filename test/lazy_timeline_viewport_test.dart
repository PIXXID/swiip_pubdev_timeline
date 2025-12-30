import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/lazy_timeline_viewport.dart';

void main() {
  group('LazyTimelineViewport Property Tests', () {
    testWidgets(
        'Property 3: Viewport-Based Rendering - renders only visible items plus buffer',
        (WidgetTester tester) async {
      // Feature: timeline-performance-optimization, Property 3: Viewport-based rendering
      // Validates: Requirements 3.2, 8.2

      final random = Random();

      // Run property test with 100 iterations
      for (var iteration = 0; iteration < 100; iteration++) {
        // Generate random timeline with more than 200 days
        final totalDays = 200 + random.nextInt(300); // 200-500 days
        final dayWidth = 40.0 + random.nextDouble() * 20; // 40-60 width
        final dayMargin = 3.0 + random.nextDouble() * 5; // 3-8 margin
        final viewportWidth = 600.0 + random.nextDouble() * 600; // 600-1200

        // Generate test data
        final days = List.generate(
          totalDays,
          (i) => {
            'date': DateTime.now().add(Duration(days: i)),
            'lmax': 8,
            'capeff': random.nextInt(8),
            'buseff': random.nextInt(8),
            'preIds': <String>[],
          },
        );

        // Calculate visible range
        final visibleDays = (viewportWidth / (dayWidth - dayMargin)).ceil();
        const buffer = 5;
        final visibleStart = 0;
        final visibleEnd = (visibleDays + buffer * 2).clamp(0, totalDays);
        final centerItemIndex = visibleDays ~/ 2;

        // Track how many widgets were built
        var builtWidgetCount = 0;
        // Build the LazyTimelineViewport
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: viewportWidth,
                height: 400,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: LazyTimelineViewport(
                    visibleStart: visibleStart,
                    visibleEnd: visibleEnd,
                    centerItemIndex: centerItemIndex,
                    items: days,
                    itemWidth: dayWidth,
                    itemMargin: dayMargin,
                    itemBuilder: (context, index) {
                      builtWidgetCount++;
                      return Container(
                        key: ValueKey('day_$index'),
                        width: dayWidth - dayMargin,
                        height: 100,
                        color: Colors.blue,
                        child: Text('Day $index'),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Calculate expected visible items
        final visibleDays = (viewportWidth / (dayWidth - dayMargin)).ceil();
        const buffer = 5; // Buffer from TimelineController
        final expectedMaxRendered = visibleDays + (buffer * 2);

        // Verify that rendered items are significantly less than total
        expect(
          builtWidgetCount,
          lessThan(totalDays),
          reason:
              'Should render fewer items than total (rendered $builtWidgetCount, total $totalDays)',
        );

        // Verify that rendered items match expected viewport + buffer
        expect(
          builtWidgetCount,
          lessThanOrEqualTo(expectedMaxRendered + 5), // +5 for tolerance
          reason:
              'Should render approximately viewport + buffer items (rendered $builtWidgetCount, expected ~$expectedMaxRendered)',
        );

        // Verify that at least some items are rendered
        expect(
          builtWidgetCount,
          greaterThan(0),
          reason: 'Should render at least some items',
        );
      }
    }, timeout: const Timeout(Duration(minutes: 5)));

    testWidgets(
        'Property 3: Viewport-Based Rendering - updates rendered items when visible range changes',
        (WidgetTester tester) async {
      // Verify that changing the visible range updates the rendered items

      final random = Random();

      for (var iteration = 0; iteration < 100; iteration++) {
        final totalDays = 200 + random.nextInt(200);
        final dayWidth = 45.0;
        final dayMargin = 5.0;
        final viewportWidth = 800.0;

        final days = List.generate(
          totalDays,
          (i) => {
            'date': DateTime.now().add(Duration(days: i)),
            'lmax': 8,
          },
        );

        // Calculate initial visible range
        final visibleDays = (viewportWidth / (dayWidth - dayMargin)).ceil();
        const buffer = 5;
        var visibleStart = 0;
        var visibleEnd = (visibleDays + buffer * 2).clamp(0, totalDays);
        var centerItemIndex = visibleDays ~/ 2;

        var builtWidgetCount = 0;
        final builtIndices = <int>{};

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: viewportWidth,
                height: 400,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return LazyTimelineViewport(
                      visibleStart: visibleStart,
                      visibleEnd: visibleEnd,
                      centerItemIndex: centerItemIndex,
                      items: days,
                      itemWidth: dayWidth,
                      itemMargin: dayMargin,
                      itemBuilder: (context, index) {
                        builtWidgetCount++;
                        builtIndices.add(index);
                        return SizedBox(
                          key: ValueKey('day_$index'),
                          width: dayWidth - dayMargin,
                          height: 100,
                          child: Text('Day $index'),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final initialBuildCount = builtWidgetCount;
        final initialIndices = Set<int>.from(builtIndices);

        // Change the visible range by simulating scroll to middle
        final scrollOffset = (totalDays / 2) * (dayWidth - dayMargin);
        final newCenterIndex = (scrollOffset / (dayWidth - dayMargin)).round();
        visibleStart =
            (newCenterIndex - (visibleDays ~/ 2) - buffer).clamp(0, totalDays);
        visibleEnd =
            (newCenterIndex + (visibleDays ~/ 2) + buffer).clamp(0, totalDays);
        centerItemIndex = newCenterIndex;

        // Rebuild with new visible range
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: viewportWidth,
                height: 400,
                child: LazyTimelineViewport(
                  visibleStart: visibleStart,
                  visibleEnd: visibleEnd,
                  centerItemIndex: centerItemIndex,
                  items: days,
                  itemWidth: dayWidth,
                  itemMargin: dayMargin,
                  itemBuilder: (context, index) {
                    builtWidgetCount++;
                    builtIndices.add(index);
                    return SizedBox(
                      key: ValueKey('day_$index'),
                      width: dayWidth - dayMargin,
                      height: 100,
                      child: Text('Day $index'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle(const Duration(milliseconds: 50));

        // Verify that new items were built
        expect(
          builtWidgetCount,
          greaterThan(initialBuildCount),
          reason: 'Should build new items when visible range changes',
        );

        // Verify that different indices are now visible
        final hasNewIndices =
            builtIndices.any((index) => !initialIndices.contains(index));
        expect(
          hasNewIndices,
          isTrue,
          reason: 'Should render different items after scroll',
        );
      }
    }, timeout: const Timeout(Duration(minutes: 5)));

    testWidgets(
        'Property 3: Viewport-Based Rendering - handles edge cases at timeline boundaries',
        (WidgetTester tester) async {
      // Verify correct behavior at start and end of timeline

      final random = Random();

      for (var iteration = 0; iteration < 100; iteration++) {
        final totalDays = 200 + random.nextInt(100);
        final dayWidth = 45.0;
        final dayMargin = 5.0;
        final viewportWidth = 800.0;

        final days = List.generate(
          totalDays,
          (i) => {'date': DateTime.now().add(Duration(days: i))},
        );

        // Calculate visible range
        final visibleDays = (viewportWidth / (dayWidth - dayMargin)).ceil();
        const buffer = 5;
        var visibleStart = 0;
        var visibleEnd = (visibleDays + buffer * 2).clamp(0, totalDays);
        var centerItemIndex = visibleDays ~/ 2;

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
                  return SizedBox(
                    key: ValueKey('day_$index'),
                    width: dayWidth - dayMargin,
                    height: 100,
                  );
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Test at start (offset = 0)
        visibleStart = 0;
        visibleEnd = (visibleDays + buffer * 2).clamp(0, totalDays);
        centerItemIndex = 0;

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
                  return SizedBox(
                    key: ValueKey('day_$index'),
                    width: dayWidth - dayMargin,
                    height: 100,
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull,
            reason: 'Should handle start boundary without errors');

        // Test at end (offset = max)
        final maxOffset = totalDays * (dayWidth - dayMargin);
        final endCenterIndex = (maxOffset / (dayWidth - dayMargin))
            .round()
            .clamp(0, totalDays - 1);
        visibleStart =
            (endCenterIndex - (visibleDays ~/ 2) - buffer).clamp(0, totalDays);
        visibleEnd = totalDays;
        centerItemIndex = endCenterIndex;

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
                  return SizedBox(
                    key: ValueKey('day_$index'),
                    width: dayWidth - dayMargin,
                    height: 100,
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull,
            reason: 'Should handle end boundary without errors');

        // Test beyond end (should clamp)
        visibleStart = (totalDays - visibleDays - buffer).clamp(0, totalDays);
        visibleEnd = totalDays;
        centerItemIndex = totalDays - 1;

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
                  return SizedBox(
                    key: ValueKey('day_$index'),
                    width: dayWidth - dayMargin,
                    height: 100,
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull,
            reason: 'Should handle beyond-end offset without errors');
      }
    }, timeout: const Timeout(Duration(minutes: 5)));
  });

  group('LazyTimelineViewport Unit Tests', () {
    testWidgets('renders empty timeline without errors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyTimelineViewport(
              visibleStart: 0,
              visibleEnd: 0,
              centerItemIndex: 0,
              items: const [],
              itemWidth: 45.0,
              itemMargin: 5.0,
              itemBuilder: (context, index) {
                return Container();
              },
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders single item timeline', (WidgetTester tester) async {
      final days = [
        {'date': DateTime.now()}
      ];

      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyTimelineViewport(
              visibleStart: 0,
              visibleEnd: 1,
              centerItemIndex: 0,
              items: days,
              itemWidth: 45.0,
              itemMargin: 5.0,
              itemBuilder: (context, index) {
                buildCount++;
                return SizedBox(
                  key: ValueKey('day_$index'),
                  width: 40,
                  height: 100,
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(buildCount, greaterThan(0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses Stack with Positioned for layout',
        (WidgetTester tester) async {
      final days = List.generate(
        10,
        (i) => {'date': DateTime.now().add(Duration(days: i))},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyTimelineViewport(
              visibleStart: 0,
              visibleEnd: 10,
              centerItemIndex: 5,
              items: days,
              itemWidth: 45.0,
              itemMargin: 5.0,
              itemBuilder: (context, index) {
                return SizedBox(
                  key: ValueKey('day_$index'),
                  width: 40,
                  height: 100,
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Stack is used within LazyTimelineViewport
      final stackFinder = find.descendant(
        of: find.byType(LazyTimelineViewport),
        matching: find.byType(Stack),
      );
      expect(stackFinder, findsOneWidget);

      // Verify Positioned widgets are used
      expect(find.byType(Positioned), findsWidgets);
    });

    testWidgets('calculates correct total width', (WidgetTester tester) async {
      final totalDays = 100;
      final dayWidth = 45.0;

      final days = List.generate(
        totalDays,
        (i) => {'date': DateTime.now().add(Duration(days: i))},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyTimelineViewport(
              visibleStart: 0,
              visibleEnd: 20,
              centerItemIndex: 10,
              items: days,
              itemWidth: dayWidth,
              itemMargin: 5.0,
              itemBuilder: (context, index) {
                return SizedBox(
                  key: ValueKey('day_$index'),
                  width: 40,
                  height: 100,
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the SizedBox that contains the Stack
      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(LazyTimelineViewport),
          matching: find.byType(SizedBox),
        ),
      );

      final expectedWidth = totalDays * dayWidth;
      expect(sizedBox.width, equals(expectedWidth));
    });

    testWidgets('only calls itemBuilder for visible items',
        (WidgetTester tester) async {
      final totalDays = 300;

      final days = List.generate(
        totalDays,
        (i) => {'date': DateTime.now().add(Duration(days: i))},
      );

      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: LazyTimelineViewport(
                visibleStart: 0,
                visibleEnd: 25, // Only render first 25 items
                centerItemIndex: 12,
                items: days,
                itemWidth: 45.0,
                itemMargin: 5.0,
                itemBuilder: (context, index) {
                  buildCount++;
                  return SizedBox(
                    key: ValueKey('day_$index'),
                    width: 40,
                    height: 100,
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should build significantly fewer items than total
      expect(buildCount, lessThan(totalDays));
      expect(buildCount, greaterThan(0));
    });
  });
}
