import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/lazy_timeline_viewport.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/models.dart';

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

        // Create controller
        final controller = TimelineController(
          dayWidth: dayWidth,
          dayMargin: dayMargin,
          totalDays: totalDays,
          viewportWidth: viewportWidth,
        );

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
                    controller: controller,
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

        controller.dispose();
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

        final controller = TimelineController(
          dayWidth: dayWidth,
          dayMargin: dayMargin,
          totalDays: totalDays,
          viewportWidth: viewportWidth,
        );

        var builtWidgetCount = 0;
        final builtIndices = <int>{};

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: viewportWidth,
                height: 400,
                child: LazyTimelineViewport(
                  controller: controller,
                  items: days,
                  itemWidth: dayWidth,
                  itemMargin: dayMargin,
                  itemBuilder: (context, index) {
                    builtWidgetCount++;
                    builtIndices.add(index);
                    return Container(
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

        await tester.pumpAndSettle();

        final initialBuildCount = builtWidgetCount;
        final initialIndices = Set<int>.from(builtIndices);

        // Change the visible range by updating scroll offset
        final newOffset =
            (totalDays / 2) * (dayWidth - dayMargin); // Scroll to middle
        controller.updateScrollOffset(newOffset);

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

        controller.dispose();
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

        final controller = TimelineController(
          dayWidth: dayWidth,
          dayMargin: dayMargin,
          totalDays: totalDays,
          viewportWidth: viewportWidth,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LazyTimelineViewport(
                controller: controller,
                items: days,
                itemWidth: dayWidth,
                itemMargin: dayMargin,
                itemBuilder: (context, index) {
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

        await tester.pumpAndSettle();

        // Test at start (offset = 0)
        controller.updateScrollOffset(0);
        await tester.pumpAndSettle(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull,
            reason: 'Should handle start boundary without errors');

        // Test at end (offset = max)
        final maxOffset = totalDays * (dayWidth - dayMargin);
        controller.updateScrollOffset(maxOffset);
        await tester.pumpAndSettle(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull,
            reason: 'Should handle end boundary without errors');

        // Test beyond end (should clamp)
        controller.updateScrollOffset(maxOffset * 2);
        await tester.pumpAndSettle(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull,
            reason: 'Should handle beyond-end offset without errors');

        controller.dispose();
      }
    }, timeout: const Timeout(Duration(minutes: 5)));
  });

  group('LazyTimelineViewport Unit Tests', () {
    testWidgets('renders empty timeline without errors',
        (WidgetTester tester) async {
      final controller = TimelineController(
        dayWidth: 45.0,
        dayMargin: 5.0,
        totalDays: 0,
        viewportWidth: 800.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyTimelineViewport(
              controller: controller,
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
      controller.dispose();
    });

    testWidgets('renders single item timeline', (WidgetTester tester) async {
      final controller = TimelineController(
        dayWidth: 45.0,
        dayMargin: 5.0,
        totalDays: 1,
        viewportWidth: 800.0,
      );

      final days = [
        {'date': DateTime.now()}
      ];

      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyTimelineViewport(
              controller: controller,
              items: days,
              itemWidth: 45.0,
              itemMargin: 5.0,
              itemBuilder: (context, index) {
                buildCount++;
                return Container(
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

      controller.dispose();
    });

    testWidgets('uses Stack with Positioned for layout',
        (WidgetTester tester) async {
      final controller = TimelineController(
        dayWidth: 45.0,
        dayMargin: 5.0,
        totalDays: 10,
        viewportWidth: 800.0,
      );

      final days = List.generate(
        10,
        (i) => {'date': DateTime.now().add(Duration(days: i))},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyTimelineViewport(
              controller: controller,
              items: days,
              itemWidth: 45.0,
              itemMargin: 5.0,
              itemBuilder: (context, index) {
                return Container(
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

      controller.dispose();
    });

    testWidgets('calculates correct total width',
        (WidgetTester tester) async {
      final totalDays = 100;
      final dayWidth = 45.0;

      final controller = TimelineController(
        dayWidth: dayWidth,
        dayMargin: 5.0,
        totalDays: totalDays,
        viewportWidth: 800.0,
      );

      final days = List.generate(
        totalDays,
        (i) => {'date': DateTime.now().add(Duration(days: i))},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyTimelineViewport(
              controller: controller,
              items: days,
              itemWidth: dayWidth,
              itemMargin: 5.0,
              itemBuilder: (context, index) {
                return Container(
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

      controller.dispose();
    });

    testWidgets('only calls itemBuilder for visible items',
        (WidgetTester tester) async {
      final totalDays = 300;
      final controller = TimelineController(
        dayWidth: 45.0,
        dayMargin: 5.0,
        totalDays: totalDays,
        viewportWidth: 800.0,
      );

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
                controller: controller,
                items: days,
                itemWidth: 45.0,
                itemMargin: 5.0,
                itemBuilder: (context, index) {
                  buildCount++;
                  return Container(
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

      controller.dispose();
    });
  });
}

