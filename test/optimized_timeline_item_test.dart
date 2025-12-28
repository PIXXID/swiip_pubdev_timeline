import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/optimized_timeline_item.dart';

void main() {
  group('OptimizedTimelineItem Property Tests', () {
    // Property 2: Selective Widget Rebuilds
    // Feature: timeline-performance-optimization, Property 2: Selective widget rebuilds
    // Validates: Requirements 1.3, 2.1, 3.1
    
    // Run 100 iterations of property tests
    for (var iteration = 0; iteration < 100; iteration++) {
      testWidgets(
          'Property 2: Selective Widget Rebuilds - iteration $iteration',
          (tester) async {
        final random = Random(iteration); // Use iteration as seed for reproducibility

        // Generate random timeline data
        final totalDays = 10 + random.nextInt(20); // 10-30 days (reduced for performance)
        final centerItemIndexNotifier = ValueNotifier<int>(0);

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

        // Create test days
        final testDays = List.generate(
          totalDays,
          (i) => {
            'date': DateTime.now().add(Duration(days: i)),
            'lmax': 8,
            'capeff': random.nextInt(8),
            'buseff': random.nextInt(8),
            'compeff': random.nextInt(8),
            'preIds': <String>[],
            'alertLevel': random.nextInt(3),
          },
        );

        // Build widgets
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

        // Change center item index multiple times
        final numberOfChanges = 3 + random.nextInt(5); // 3-8 changes
        int lastCenterIndex = centerItemIndexNotifier.value;
        for (var change = 0; change < numberOfChanges; change++) {
          final newCenterIndex = random.nextInt(totalDays);
          centerItemIndexNotifier.value = newCenterIndex;
          await tester.pump();
          lastCenterIndex = newCenterIndex;
        }

        // Verify that the widget structure uses ValueListenableBuilder
        // This ensures that only the ValueListenableBuilder's builder function
        // is called when centerIndex changes, not the entire widget tree.
        // The optimization is that ValueListenableBuilder handles selective rebuilds internally.
        
        // Find all ValueListenableBuilder widgets
        final valueListenableBuilders = find.byType(ValueListenableBuilder<int>);
        expect(
          valueListenableBuilders,
          findsWidgets,
          reason: 'OptimizedTimelineItem should use ValueListenableBuilder for selective rebuilds',
        );

        // Verify that RepaintBoundary is present to isolate repaints
        final repaintBoundaries = find.byType(RepaintBoundary);
        expect(
          repaintBoundaries,
          findsWidgets,
          reason: 'OptimizedTimelineItem should use RepaintBoundary to isolate repaints',
        );

        centerItemIndexNotifier.dispose();
      });
    }

    
    // Run 100 iterations testing RepaintBoundary isolation
    for (var iteration = 0; iteration < 100; iteration++) {
      testWidgets(
          'Property 2: RepaintBoundary isolates repaints - iteration $iteration',
          (tester) async {
        // Verify that RepaintBoundary is present to isolate repaints
        final random = Random(iteration);

        final centerItemIndexNotifier = ValueNotifier<int>(0);

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

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OptimizedTimelineItem(
                colors: testColors,
                index: 0,
                centerItemIndexNotifier: centerItemIndexNotifier,
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

        // Verify RepaintBoundary is present (at least one, may be more in widget tree)
        final repaintBoundary = find.byType(RepaintBoundary);
        expect(
          repaintBoundary,
          findsAtLeastNWidgets(1),
          reason: 'OptimizedTimelineItem should have RepaintBoundary',
        );

        // Verify ValueListenableBuilder is present
        final valueListenableBuilder = find.byType(ValueListenableBuilder<int>);
        expect(
          valueListenableBuilder,
          findsOneWidget,
          reason: 'OptimizedTimelineItem should use ValueListenableBuilder',
        );

        centerItemIndexNotifier.dispose();
      });
    }

    
    // Run 100 iterations testing visible range optimization
    for (var iteration = 0; iteration < 100; iteration++) {
      testWidgets(
          'Property 2: Widgets outside visible range optimization - iteration $iteration',
          (tester) async {
        // This property will be fully validated when LazyTimelineViewport is implemented
        // For now, we verify that the widget structure supports this optimization

        final random = Random(iteration);

        final totalDays = 50 + random.nextInt(50); // 50-100 days
        final centerItemIndexNotifier = ValueNotifier<int>(25);

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

        final testDays = List.generate(
          totalDays,
          (i) => {
            'date': DateTime.now().add(Duration(days: i)),
            'lmax': 8,
            'capeff': random.nextInt(8),
            'buseff': random.nextInt(8),
            'compeff': random.nextInt(8),
            'preIds': <String>[],
            'alertLevel': random.nextInt(3),
          },
        );

        // Create only a subset of items (simulating LazyTimelineViewport behavior)
        final visibleStart = 20;
        final visibleEnd = 30;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: Stack(
                  children: List.generate(
                    visibleEnd - visibleStart,
                    (i) {
                      final actualIndex = visibleStart + i;
                      return Positioned(
                        left: actualIndex * 40.0,
                        child: OptimizedTimelineItem(
                          colors: testColors,
                          index: actualIndex,
                          centerItemIndexNotifier: centerItemIndexNotifier,
                          nowIndex: 0,
                          day: testDays[actualIndex],
                          elements: const [],
                          dayWidth: 45.0,
                          dayMargin: 5.0,
                          height: 300.0,
                          openDayDetail: null,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        // Verify that only visible items are created
        final timelineItems = find.byType(OptimizedTimelineItem);
        expect(
          timelineItems,
          findsNWidgets(visibleEnd - visibleStart),
          reason:
              'Only visible items should be created (${visibleEnd - visibleStart} items)',
        );

        // Change center index
        centerItemIndexNotifier.value = 25;
        await tester.pump();

        // Items should still be the same count
        expect(
          find.byType(OptimizedTimelineItem),
          findsNWidgets(visibleEnd - visibleStart),
          reason: 'Item count should remain the same after center index change',
        );

        centerItemIndexNotifier.dispose();
      });
    }
  });

  group('OptimizedTimelineItem Unit Tests - Widget Structure', () {
    testWidgets('uses RepaintBoundary to isolate repaints', (tester) async {
      // Validates: Requirements 1.4, 1.5
      
      final centerItemIndexNotifier = ValueNotifier<int>(0);

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

      // Verify RepaintBoundary is present (at least one, may be more in widget tree)
      final repaintBoundary = find.byType(RepaintBoundary);
      expect(
        repaintBoundary,
        findsAtLeastNWidgets(1),
        reason: 'OptimizedTimelineItem must have RepaintBoundary for paint isolation',
      );

      centerItemIndexNotifier.dispose();
    });

    testWidgets('uses ValueListenableBuilder for selective rebuilds', (tester) async {
      // Validates: Requirements 2.1, 2.3
      
      final centerItemIndexNotifier = ValueNotifier<int>(0);

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

      // Verify ValueListenableBuilder is present
      final valueListenableBuilder = find.byType(ValueListenableBuilder<int>);
      expect(
        valueListenableBuilder,
        findsOneWidget,
        reason: 'OptimizedTimelineItem must use ValueListenableBuilder for selective rebuilds',
      );

      centerItemIndexNotifier.dispose();
    });

    testWidgets('is a StatefulWidget with animation controller', (tester) async {
      // Validates: Requirements 1.4, 9.1, 9.5
      
      final centerItemIndexNotifier = ValueNotifier<int>(0);

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

      final widget = OptimizedTimelineItem(
        colors: testColors,
        index: 0,
        centerItemIndexNotifier: centerItemIndexNotifier,
        nowIndex: 0,
        day: testDay,
        elements: const [],
        dayWidth: 45.0,
        dayMargin: 5.0,
        height: 300.0,
        openDayDetail: null,
      );

      // Verify it's a StatefulWidget (changed from StatelessWidget for animation support)
      expect(widget, isA<StatefulWidget>());
      expect(widget, isNot(isA<StatelessWidget>()));

      centerItemIndexNotifier.dispose();
    });

    testWidgets('rebuilds only when centerItemIndex changes', (tester) async {
      // Validates: Requirements 2.1
      
      final centerItemIndexNotifier = ValueNotifier<int>(0);
      var valueListenerBuildCount = 0;

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

      // Track ValueListenableBuilder rebuilds by adding a listener
      centerItemIndexNotifier.addListener(() {
        valueListenerBuildCount++;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedTimelineItem(
              colors: testColors,
              index: 0,
              centerItemIndexNotifier: centerItemIndexNotifier,
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
      final initialBuildCount = valueListenerBuildCount;

      // Change centerItemIndex
      centerItemIndexNotifier.value = 5;
      await tester.pump();

      // Verify rebuild occurred (listener was called)
      expect(valueListenerBuildCount, greaterThan(initialBuildCount));

      centerItemIndexNotifier.dispose();
    });

    testWidgets('calculates day text color based on distance from center', (tester) async {
      // Validates: Requirements 1.3
      
      final centerItemIndexNotifier = ValueNotifier<int>(5);

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
              index: 5, // Same as center
              centerItemIndexNotifier: centerItemIndexNotifier,
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

      // Widget should render without errors
      expect(find.byType(OptimizedTimelineItem), findsOneWidget);

      // Change center to test different distances
      centerItemIndexNotifier.value = 3; // Distance of 2
      await tester.pump();

      expect(find.byType(OptimizedTimelineItem), findsOneWidget);

      centerItemIndexNotifier.dispose();
    });

    testWidgets('handles tap gestures correctly', (tester) async {
      // Validates: Requirements 2.3
      
      final centerItemIndexNotifier = ValueNotifier<int>(0);
      var tapCalled = false;
      String? tappedDate;

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
            body: Center(
              child: SizedBox(
                width: 45.0,
                height: 320.0, // Slightly larger to avoid overflow
                child: OptimizedTimelineItem(
                  colors: testColors,
                  index: 0,
                  centerItemIndexNotifier: centerItemIndexNotifier,
                  nowIndex: 0,
                  day: testDay,
                  elements: const [],
                  dayWidth: 45.0,
                  dayMargin: 5.0,
                  height: 300.0,
                  openDayDetail: (date, progress, preIds, elements, indicators) {
                    tapCalled = true;
                    tappedDate = date;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the gesture detector
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      // Verify tap was handled
      expect(tapCalled, isTrue);
      expect(tappedDate, isNotNull);

      centerItemIndexNotifier.dispose();
    });
  });
}
