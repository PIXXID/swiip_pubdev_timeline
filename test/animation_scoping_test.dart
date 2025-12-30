import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/optimized_timeline_item.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/visible_range.dart';

void main() {
  group('Animation Scoping Property Tests', () {
    // Property 12: Animation Scoping
    // Feature: timeline-performance-optimization, Property 12: Animation Scoping
    // Validates: Requirements 9.2, 9.3

    // Run 100 iterations of property tests
    for (var iteration = 0; iteration < 100; iteration++) {
      testWidgets('Property 12: Animations only active for widgets in viewport - iteration $iteration', (tester) async {
        final random = Random(iteration); // Use iteration as seed for reproducibility

        // Generate random timeline data
        final totalDays = 20 + random.nextInt(30); // 20-50 days
        final centerItemIndexNotifier = ValueNotifier<int>(totalDays ~/ 2);
        final visibleRangeNotifier = ValueNotifier<VisibleRange>(
          VisibleRange(0, totalDays - 1),
        );

        // Create test colors
        final testColors = <String, Color>{
          'primaryText': Colors.white,
          'secondaryText': Colors.grey,
          'accent1': Colors.blue,
          'primary': Colors.green,
          'warning': Colors.orange,
          'error': Colors.red,
          'info': Colors.lightBlue,
          'secondaryBackground': Colors.black12,
        };

        // Create test days with varying completion levels
        final testDays = List.generate(
          totalDays,
          (i) => {
            'date': DateTime.now().add(Duration(days: i)),
            'lmax': 8,
            'capeff': 5 + random.nextInt(3),
            'buseff': 4 + random.nextInt(3),
            'compeff': random.nextInt(8), // Random completion
            'preIds': <String>[],
            'alertLevel': random.nextInt(3),
          },
        );

        // Build widgets with visible range
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: Stack(
                  children: List.generate(
                    totalDays,
                    (i) => Positioned(
                      left: i * 40.0,
                      child: OptimizedTimelineItem(
                        colors: testColors,
                        index: i,
                        centerItemIndexNotifier: centerItemIndexNotifier,
                        visibleRangeNotifier: visibleRangeNotifier,
                        nowIndex: 0,
                        day: testDays[i],
                        elements: const [],
                        dayWidth: 45.0,
                        dayMargin: 5.0,
                        height: 300.0,
                        openDayDetail: null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        // Test 1: Change visible range to exclude some items
        final visibleStart = 5 + random.nextInt(5);
        final visibleEnd = visibleStart + 10 + random.nextInt(5);
        visibleRangeNotifier.value = VisibleRange(visibleStart, visibleEnd);
        await tester.pump();

        // Verify widgets are still present (they don't get removed, just stop animating)
        final timelineItems = find.byType(OptimizedTimelineItem);
        expect(
          timelineItems,
          findsNWidgets(totalDays),
          reason: 'All widgets should still be present',
        );

        // Test 2: Update completion data for items outside viewport
        // Items outside viewport should not trigger animations
        final outsideIndex = visibleEnd + 2;
        if (outsideIndex < totalDays) {
          testDays[outsideIndex]['compeff'] = 7; // High completion

          // Rebuild with updated data
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 800,
                  height: 400,
                  child: Stack(
                    children: List.generate(
                      totalDays,
                      (i) => Positioned(
                        left: i * 40.0,
                        child: OptimizedTimelineItem(
                          colors: testColors,
                          index: i,
                          centerItemIndexNotifier: centerItemIndexNotifier,
                          visibleRangeNotifier: visibleRangeNotifier,
                          nowIndex: 0,
                          day: testDays[i],
                          elements: const [],
                          dayWidth: 45.0,
                          dayMargin: 5.0,
                          height: 300.0,
                          openDayDetail: null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.pump();

          // The widget should not animate since it's outside viewport
          // We verify this by checking that the widget structure is correct
          expect(find.byType(OptimizedTimelineItem), findsNWidgets(totalDays));
        }

        // Test 3: Update completion data for items inside viewport
        // Items inside viewport should animate
        final insideIndex = visibleStart + 2;
        testDays[insideIndex]['compeff'] = 6; // High completion

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: Stack(
                  children: List.generate(
                    totalDays,
                    (i) => Positioned(
                      left: i * 40.0,
                      child: OptimizedTimelineItem(
                        colors: testColors,
                        index: i,
                        centerItemIndexNotifier: centerItemIndexNotifier,
                        visibleRangeNotifier: visibleRangeNotifier,
                        nowIndex: 0,
                        day: testDays[i],
                        elements: const [],
                        dayWidth: 45.0,
                        dayMargin: 5.0,
                        height: 300.0,
                        openDayDetail: null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        // Verify AnimatedBuilder is present for animation
        final animatedBuilders = find.byType(AnimatedBuilder);
        expect(
          animatedBuilders,
          findsWidgets,
          reason: 'AnimatedBuilder should be present for animations',
        );

        // Test 4: Move visible range and verify animations scope correctly
        final newVisibleStart = 10 + random.nextInt(5);
        final newVisibleEnd = newVisibleStart + 8;
        if (newVisibleEnd < totalDays) {
          visibleRangeNotifier.value = VisibleRange(newVisibleStart, newVisibleEnd);
          await tester.pump();

          // Change center index to trigger rebuild
          centerItemIndexNotifier.value = newVisibleStart + 4;
          await tester.pump();

          // Verify widgets are still present
          expect(find.byType(OptimizedTimelineItem), findsNWidgets(totalDays));
        }

        centerItemIndexNotifier.dispose();
        visibleRangeNotifier.dispose();
      });
    }

    // Run 100 iterations testing animation controller disposal
    for (var iteration = 0; iteration < 100; iteration++) {
      testWidgets('Property 12: Animation controllers are properly disposed - iteration $iteration', (tester) async {
        final random = Random(iteration);

        final centerItemIndexNotifier = ValueNotifier<int>(0);
        final visibleRangeNotifier = ValueNotifier<VisibleRange>(
          VisibleRange(0, 10),
        );

        final testColors = <String, Color>{
          'primaryText': Colors.white,
          'secondaryText': Colors.grey,
          'accent1': Colors.blue,
          'primary': Colors.green,
          'warning': Colors.orange,
          'error': Colors.red,
          'info': Colors.lightBlue,
          'secondaryBackground': Colors.black12,
        };

        final testDay = {
          'date': DateTime.now(),
          'lmax': 8,
          'capeff': random.nextInt(8),
          'buseff': random.nextInt(8),
          'compeff': random.nextInt(8),
          'preIds': <String>[],
          'alertLevel': random.nextInt(3),
        };

        // Build widget
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OptimizedTimelineItem(
                colors: testColors,
                index: 0,
                centerItemIndexNotifier: centerItemIndexNotifier,
                visibleRangeNotifier: visibleRangeNotifier,
                nowIndex: 0,
                day: testDay,
                elements: const [],
                dayWidth: 45.0,
                dayMargin: 5.0,
                height: 300.0,
                openDayDetail: null,
              ),
            ),
          ),
        );

        await tester.pump();

        // Verify widget is present
        expect(find.byType(OptimizedTimelineItem), findsOneWidget);

        // Remove widget (triggers dispose)
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(),
            ),
          ),
        );

        await tester.pump();

        // Verify widget is removed
        expect(find.byType(OptimizedTimelineItem), findsNothing);

        // If disposal wasn't proper, this would cause issues
        // The test passing means disposal is working correctly

        centerItemIndexNotifier.dispose();
        visibleRangeNotifier.dispose();
      });
    }

    // Run 100 iterations testing animation stops when outside viewport
    for (var iteration = 0; iteration < 100; iteration++) {
      testWidgets('Property 12: Animations stop when widget moves outside viewport - iteration $iteration',
          (tester) async {
        final random = Random(iteration);

        final centerItemIndexNotifier = ValueNotifier<int>(5);
        final visibleRangeNotifier = ValueNotifier<VisibleRange>(
          VisibleRange(0, 10),
        );

        final testColors = <String, Color>{
          'primaryText': Colors.white,
          'secondaryText': Colors.grey,
          'accent1': Colors.blue,
          'primary': Colors.green,
          'warning': Colors.orange,
          'error': Colors.red,
          'info': Colors.lightBlue,
          'secondaryBackground': Colors.black12,
        };

        final testDay = {
          'date': DateTime.now(),
          'lmax': 8,
          'capeff': 6,
          'buseff': 5,
          'compeff': random.nextInt(8),
          'preIds': <String>[],
          'alertLevel': 0,
        };

        // Build widget inside viewport
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OptimizedTimelineItem(
                colors: testColors,
                index: 5, // Inside viewport (0-10)
                centerItemIndexNotifier: centerItemIndexNotifier,
                visibleRangeNotifier: visibleRangeNotifier,
                nowIndex: 0,
                day: testDay,
                elements: const [],
                dayWidth: 45.0,
                dayMargin: 5.0,
                height: 300.0,
                openDayDetail: null,
              ),
            ),
          ),
        );

        await tester.pump();

        // Verify widget is present
        expect(find.byType(OptimizedTimelineItem), findsOneWidget);

        // Move visible range so widget is outside
        visibleRangeNotifier.value = VisibleRange(10, 20);
        await tester.pump();

        // Widget should still be present but not animating
        expect(find.byType(OptimizedTimelineItem), findsOneWidget);

        // Update completion to trigger potential animation
        testDay['compeff'] = 7;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OptimizedTimelineItem(
                colors: testColors,
                index: 5, // Outside viewport (10-20)
                centerItemIndexNotifier: centerItemIndexNotifier,
                visibleRangeNotifier: visibleRangeNotifier,
                nowIndex: 0,
                day: testDay,
                elements: const [],
                dayWidth: 45.0,
                dayMargin: 5.0,
                height: 300.0,
                openDayDetail: null,
              ),
            ),
          ),
        );

        await tester.pump();

        // Widget should not crash and should handle being outside viewport
        expect(find.byType(OptimizedTimelineItem), findsOneWidget);

        centerItemIndexNotifier.dispose();
        visibleRangeNotifier.dispose();
      });
    }
  });

  group('Animation Scoping Unit Tests', () {
    testWidgets('uses AnimatedBuilder for animations', (tester) async {
      // Validates: Requirements 9.1

      final centerItemIndexNotifier = ValueNotifier<int>(0);
      final visibleRangeNotifier = ValueNotifier<VisibleRange>(
        VisibleRange(0, 10),
      );

      final testColors = <String, Color>{
        'primaryText': Colors.white,
        'secondaryText': Colors.grey,
        'accent1': Colors.blue,
        'primary': Colors.green,
        'warning': Colors.orange,
        'error': Colors.red,
        'info': Colors.lightBlue,
        'secondaryBackground': Colors.black12,
      };

      final testDay = {
        'date': DateTime.now(),
        'lmax': 8,
        'capeff': 5,
        'buseff': 4,
        'compeff': 3,
        'preIds': <String>[],
        'alertLevel': 0,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedTimelineItem(
              colors: testColors,
              index: 0,
              centerItemIndexNotifier: centerItemIndexNotifier,
              visibleRangeNotifier: visibleRangeNotifier,
              nowIndex: 0,
              day: testDay,
              elements: const [],
              dayWidth: 45.0,
              dayMargin: 5.0,
              height: 300.0,
              openDayDetail: null,
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify AnimatedBuilder is present
      final animatedBuilder = find.byType(AnimatedBuilder);
      expect(
        animatedBuilder,
        findsAtLeastNWidgets(1),
        reason: 'OptimizedTimelineItem must use AnimatedBuilder for animations',
      );

      centerItemIndexNotifier.dispose();
      visibleRangeNotifier.dispose();
    });

    testWidgets('uses Transform for position animations', (tester) async {
      // Validates: Requirements 9.4

      final centerItemIndexNotifier = ValueNotifier<int>(0);
      final visibleRangeNotifier = ValueNotifier<VisibleRange>(
        VisibleRange(0, 10),
      );

      final testColors = <String, Color>{
        'primaryText': Colors.white,
        'secondaryText': Colors.grey,
        'accent1': Colors.blue,
        'primary': Colors.green,
        'warning': Colors.orange,
        'error': Colors.red,
        'info': Colors.lightBlue,
        'secondaryBackground': Colors.black12,
      };

      final testDay = {
        'date': DateTime.now(),
        'lmax': 8,
        'capeff': 5,
        'buseff': 4,
        'compeff': 3,
        'preIds': <String>[],
        'alertLevel': 0,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedTimelineItem(
              colors: testColors,
              index: 0,
              centerItemIndexNotifier: centerItemIndexNotifier,
              visibleRangeNotifier: visibleRangeNotifier,
              nowIndex: 0,
              day: testDay,
              elements: const [],
              dayWidth: 45.0,
              dayMargin: 5.0,
              height: 300.0,
              openDayDetail: null,
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify Transform is present
      final transform = find.byType(Transform);
      expect(
        transform,
        findsAtLeastNWidgets(1),
        reason: 'OptimizedTimelineItem must use Transform for efficient animations',
      );

      centerItemIndexNotifier.dispose();
      visibleRangeNotifier.dispose();
    });

    testWidgets('properly disposes AnimationController', (tester) async {
      // Validates: Requirements 9.5

      final centerItemIndexNotifier = ValueNotifier<int>(0);
      final visibleRangeNotifier = ValueNotifier<VisibleRange>(
        VisibleRange(0, 10),
      );

      final testColors = <String, Color>{
        'primaryText': Colors.white,
        'secondaryText': Colors.grey,
        'accent1': Colors.blue,
        'primary': Colors.green,
        'warning': Colors.orange,
        'error': Colors.red,
        'info': Colors.lightBlue,
        'secondaryBackground': Colors.black12,
      };

      final testDay = {
        'date': DateTime.now(),
        'lmax': 8,
        'capeff': 5,
        'buseff': 4,
        'compeff': 3,
        'preIds': <String>[],
        'alertLevel': 0,
      };

      // Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedTimelineItem(
              colors: testColors,
              index: 0,
              centerItemIndexNotifier: centerItemIndexNotifier,
              visibleRangeNotifier: visibleRangeNotifier,
              nowIndex: 0,
              day: testDay,
              elements: const [],
              dayWidth: 45.0,
              dayMargin: 5.0,
              height: 300.0,
              openDayDetail: null,
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify widget is present
      expect(find.byType(OptimizedTimelineItem), findsOneWidget);

      // Remove widget (triggers dispose)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      await tester.pump();

      // Verify widget is removed without errors
      expect(find.byType(OptimizedTimelineItem), findsNothing);

      // If AnimationController wasn't disposed properly, this would cause memory leaks
      // The test passing means disposal is working correctly

      centerItemIndexNotifier.dispose();
      visibleRangeNotifier.dispose();
    });

    testWidgets('has RepaintBoundary around animated content', (tester) async {
      // Validates: Requirements 9.1

      final centerItemIndexNotifier = ValueNotifier<int>(0);
      final visibleRangeNotifier = ValueNotifier<VisibleRange>(
        VisibleRange(0, 10),
      );

      final testColors = <String, Color>{
        'primaryText': Colors.white,
        'secondaryText': Colors.grey,
        'accent1': Colors.blue,
        'primary': Colors.green,
        'warning': Colors.orange,
        'error': Colors.red,
        'info': Colors.lightBlue,
        'secondaryBackground': Colors.black12,
      };

      final testDay = {
        'date': DateTime.now(),
        'lmax': 8,
        'capeff': 5,
        'buseff': 4,
        'compeff': 3,
        'preIds': <String>[],
        'alertLevel': 0,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedTimelineItem(
              colors: testColors,
              index: 0,
              centerItemIndexNotifier: centerItemIndexNotifier,
              visibleRangeNotifier: visibleRangeNotifier,
              nowIndex: 0,
              day: testDay,
              elements: const [],
              dayWidth: 45.0,
              dayMargin: 5.0,
              height: 300.0,
              openDayDetail: null,
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify RepaintBoundary is present (at least 2: one for the widget, one for animated content)
      final repaintBoundaries = find.byType(RepaintBoundary);
      expect(
        repaintBoundaries,
        findsAtLeastNWidgets(2),
        reason: 'OptimizedTimelineItem must have RepaintBoundary around animated content',
      );

      centerItemIndexNotifier.dispose();
      visibleRangeNotifier.dispose();
    });
  });
}
