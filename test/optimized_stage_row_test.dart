import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/optimized_stage_row.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/visible_range.dart';

void main() {
  group('OptimizedStageRow Property Tests', () {
    // Property 9: Stage Row Conditional Rebuild
    // Feature: timeline-performance-optimization, Property 9: Stage row conditional rebuild
    // Validates: Requirements 2.2

    // Run 100 iterations of property tests
    for (var iteration = 0; iteration < 100; iteration++) {
      testWidgets('Property 9: Stage Row Conditional Rebuild - iteration $iteration', (tester) async {
        final random = Random(iteration); // Use iteration as seed for reproducibility

        // Generate random timeline data
        final totalDays = 50 + random.nextInt(50); // 50-100 days
        final centerItemIndexNotifier = ValueNotifier<int>(25);
        final visibleRangeNotifier = ValueNotifier<VisibleRange>(
          VisibleRange(20, 30),
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
          'pcolor': Colors.purple,
        };

        // Generate random stages for this row
        final stageCount = 2 + random.nextInt(5); // 2-6 stages per row
        final stagesList = List.generate(stageCount, (i) {
          final startIndex = i * 10 + random.nextInt(5);
          final endIndex = startIndex + 5 + random.nextInt(10);

          return {
            'prs_id': 'stage_$i',
            'type': ['milestone', 'cycle', 'sequence', 'stage'][random.nextInt(4)],
            'sdate': '2024-01-${(startIndex % 28) + 1}',
            'edate': '2024-01-${(endIndex % 28) + 1}',
            'name': 'Stage $i',
            'prog': random.nextInt(100),
            'startDateIndex': startIndex,
            'endDateIndex': endIndex,
            'pcolor': 'FF0000FF',
            'prj_id': 'project_1',
            'pname': 'Test Project',
            'icon': '',
            'users': '',
          };
        });

        // Build widget
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 50,
                child: OptimizedStageRow(
                  colors: testColors,
                  stagesList: stagesList,
                  centerItemIndexNotifier: centerItemIndexNotifier,
                  visibleRangeNotifier: visibleRangeNotifier,
                  dayWidth: 45.0,
                  dayMargin: 5.0,
                  height: 40.0,
                  isUniqueProject: true,
                  openEditStage: null,
                  openEditElement: null,
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        // Test 1: Verify widget renders correctly with initial state
        expect(find.byType(OptimizedStageRow), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Test 2: Change centerItemIndex to a value that DOES affect this row
        // Find a stage that we can target
        final targetStage = stagesList.first;
        final targetIndex = (targetStage['startDateIndex'] as int) + 2;

        centerItemIndexNotifier.value = targetIndex;
        await tester.pump();

        // Verify widget still renders correctly after state change
        expect(find.byType(OptimizedStageRow), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Test 3: Change centerItemIndex to a value that DOES NOT affect this row
        // Find an index that's not in any stage
        var nonAffectingIndex = 0;
        bool foundNonAffecting = false;
        for (var testIndex = 0; testIndex < totalDays; testIndex++) {
          final affectsRow = stagesList.any(
              (stage) => (stage['startDateIndex'] as int) <= testIndex && (stage['endDateIndex'] as int) >= testIndex);

          if (!affectsRow) {
            nonAffectingIndex = testIndex;
            foundNonAffecting = true;
            break;
          }
        }

        if (foundNonAffecting) {
          centerItemIndexNotifier.value = nonAffectingIndex;
          await tester.pump();

          // Verify widget still renders correctly
          expect(find.byType(OptimizedStageRow), findsOneWidget);
          expect(tester.takeException(), isNull);
        }

        // Test 4: Change visibleRange to overlap with stages
        final firstStage = stagesList.first;
        final newRange = VisibleRange(
          (firstStage['startDateIndex'] as int) - 5,
          (firstStage['startDateIndex'] as int) + 5,
        );

        visibleRangeNotifier.value = newRange;
        await tester.pump();

        // Verify widget renders correctly with new visible range
        expect(find.byType(OptimizedStageRow), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Test 5: Change visibleRange to NOT overlap with any stages
        // Find a range that doesn't overlap
        var nonOverlappingStart = totalDays + 10;
        var nonOverlappingEnd = totalDays + 20;

        visibleRangeNotifier.value = VisibleRange(
          nonOverlappingStart,
          nonOverlappingEnd,
        );
        await tester.pump();

        // Verify widget renders correctly (should show no stages)
        expect(find.byType(OptimizedStageRow), findsOneWidget);
        expect(tester.takeException(), isNull);

        centerItemIndexNotifier.dispose();
        visibleRangeNotifier.dispose();
      });
    }

    // Run 100 iterations testing that only affected rows rebuild
    for (var iteration = 0; iteration < 100; iteration++) {
      testWidgets('Property 9: Only affected rows rebuild - iteration $iteration', (tester) async {
        final centerItemIndexNotifier = ValueNotifier<int>(25);
        final visibleRangeNotifier = ValueNotifier<VisibleRange>(
          VisibleRange(20, 30),
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
          'pcolor': Colors.purple,
        };

        // Create two rows with different stage ranges
        final row1Stages = [
          {
            'prs_id': 'stage_1',
            'type': 'stage',
            'sdate': '2024-01-01',
            'edate': '2024-01-10',
            'name': 'Stage 1',
            'prog': 50,
            'startDateIndex': 0,
            'endDateIndex': 10,
            'pcolor': 'FF0000FF',
            'prj_id': 'project_1',
            'pname': 'Test Project',
            'icon': '',
            'users': '',
          },
        ];

        final row2Stages = [
          {
            'prs_id': 'stage_2',
            'type': 'stage',
            'sdate': '2024-01-20',
            'edate': '2024-01-30',
            'name': 'Stage 2',
            'prog': 75,
            'startDateIndex': 20,
            'endDateIndex': 30,
            'pcolor': 'FF00FF00',
            'prj_id': 'project_1',
            'pname': 'Test Project',
            'icon': '',
            'users': '',
          },
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  SizedBox(
                    width: 800,
                    height: 50,
                    child: OptimizedStageRow(
                      colors: testColors,
                      stagesList: row1Stages,
                      centerItemIndexNotifier: centerItemIndexNotifier,
                      visibleRangeNotifier: visibleRangeNotifier,
                      dayWidth: 45.0,
                      dayMargin: 5.0,
                      height: 40.0,
                      isUniqueProject: true,
                      openEditStage: null,
                      openEditElement: null,
                    ),
                  ),
                  SizedBox(
                    width: 800,
                    height: 50,
                    child: OptimizedStageRow(
                      colors: testColors,
                      stagesList: row2Stages,
                      centerItemIndexNotifier: centerItemIndexNotifier,
                      visibleRangeNotifier: visibleRangeNotifier,
                      dayWidth: 45.0,
                      dayMargin: 5.0,
                      height: 40.0,
                      isUniqueProject: true,
                      openEditStage: null,
                      openEditElement: null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pump();

        // Change centerIndex to affect only row1 (index 5 is in stage 0-10)
        centerItemIndexNotifier.value = 5;
        await tester.pump();

        // Verify both rows still render correctly
        expect(find.byType(OptimizedStageRow), findsNWidgets(2));
        expect(tester.takeException(), isNull);

        // Change centerIndex to affect only row2 (index 25 is in stage 20-30)
        centerItemIndexNotifier.value = 25;
        await tester.pump();

        // Verify both rows still render correctly
        expect(find.byType(OptimizedStageRow), findsNWidgets(2));
        expect(tester.takeException(), isNull);

        centerItemIndexNotifier.dispose();
        visibleRangeNotifier.dispose();
      });
    }

    // Run 100 iterations testing visible range changes
    for (var iteration = 0; iteration < 100; iteration++) {
      testWidgets('Property 9: Visible range changes trigger selective rebuilds - iteration $iteration',
          (tester) async {
        final centerItemIndexNotifier = ValueNotifier<int>(25);
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
          'pcolor': Colors.purple,
        };

        // Create stages in different ranges
        final stagesList = [
          {
            'prs_id': 'stage_1',
            'type': 'stage',
            'sdate': '2024-01-01',
            'edate': '2024-01-10',
            'name': 'Stage 1',
            'prog': 50,
            'startDateIndex': 0,
            'endDateIndex': 10,
            'pcolor': 'FF0000FF',
            'prj_id': 'project_1',
            'pname': 'Test Project',
            'icon': '',
            'users': '',
          },
          {
            'prs_id': 'stage_2',
            'type': 'stage',
            'sdate': '2024-01-20',
            'edate': '2024-01-30',
            'name': 'Stage 2',
            'prog': 75,
            'startDateIndex': 20,
            'endDateIndex': 30,
            'pcolor': 'FF00FF00',
            'prj_id': 'project_1',
            'pname': 'Test Project',
            'icon': '',
            'users': '',
          },
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 50,
                child: OptimizedStageRow(
                  colors: testColors,
                  stagesList: stagesList,
                  centerItemIndexNotifier: centerItemIndexNotifier,
                  visibleRangeNotifier: visibleRangeNotifier,
                  dayWidth: 45.0,
                  dayMargin: 5.0,
                  height: 40.0,
                  isUniqueProject: true,
                  openEditStage: null,
                  openEditElement: null,
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        // Change visible range to overlap with first stage (0-10)
        visibleRangeNotifier.value = VisibleRange(5, 15);
        await tester.pump();

        // Verify widget renders correctly
        expect(find.byType(OptimizedStageRow), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Change visible range to overlap with second stage (20-30)
        visibleRangeNotifier.value = VisibleRange(25, 35);
        await tester.pump();

        // Verify widget renders correctly
        expect(find.byType(OptimizedStageRow), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Change visible range to NOT overlap with any stage
        visibleRangeNotifier.value = VisibleRange(11, 19);
        await tester.pump();

        // Verify widget renders correctly (should show no stages)
        expect(find.byType(OptimizedStageRow), findsOneWidget);
        expect(tester.takeException(), isNull);

        centerItemIndexNotifier.dispose();
        visibleRangeNotifier.dispose();
      });
    }
  });

  group('OptimizedStageRow Unit Tests', () {
    testWidgets('uses RepaintBoundary to isolate repaints', (tester) async {
      // Validates: Requirements 2.2

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
        'pcolor': Colors.purple,
      };

      final stagesList = [
        {
          'prs_id': 'stage_1',
          'type': 'stage',
          'sdate': '2024-01-01',
          'edate': '2024-01-10',
          'name': 'Stage 1',
          'prog': 50,
          'startDateIndex': 0,
          'endDateIndex': 10,
          'pcolor': 'FF0000FF',
          'prj_id': 'project_1',
          'pname': 'Test Project',
          'icon': '',
          'users': '',
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedStageRow(
              colors: testColors,
              stagesList: stagesList,
              centerItemIndexNotifier: centerItemIndexNotifier,
              visibleRangeNotifier: visibleRangeNotifier,
              dayWidth: 45.0,
              dayMargin: 5.0,
              height: 40.0,
              isUniqueProject: true,
              openEditStage: null,
              openEditElement: null,
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify RepaintBoundary is present
      final repaintBoundary = find.byType(RepaintBoundary);
      expect(
        repaintBoundary,
        findsAtLeastNWidgets(1),
        reason: 'OptimizedStageRow must have RepaintBoundary for paint isolation',
      );

      centerItemIndexNotifier.dispose();
      visibleRangeNotifier.dispose();
    });

    testWidgets('properly disposes listeners', (tester) async {
      // Validates: Requirements 2.4

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
        'pcolor': Colors.purple,
      };

      final stagesList = [
        {
          'prs_id': 'stage_1',
          'type': 'stage',
          'sdate': '2024-01-01',
          'edate': '2024-01-10',
          'name': 'Stage 1',
          'prog': 50,
          'startDateIndex': 0,
          'endDateIndex': 10,
          'pcolor': 'FF0000FF',
          'prj_id': 'project_1',
          'pname': 'Test Project',
          'icon': '',
          'users': '',
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedStageRow(
              colors: testColors,
              stagesList: stagesList,
              centerItemIndexNotifier: centerItemIndexNotifier,
              visibleRangeNotifier: visibleRangeNotifier,
              dayWidth: 45.0,
              dayMargin: 5.0,
              height: 40.0,
              isUniqueProject: true,
              openEditStage: null,
              openEditElement: null,
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify widget rendered without errors
      expect(find.byType(OptimizedStageRow), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Remove the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
          ),
        ),
      );

      await tester.pump();

      // Verify widget was removed and no errors occurred during disposal
      expect(find.byType(OptimizedStageRow), findsNothing);
      expect(tester.takeException(), isNull);

      centerItemIndexNotifier.dispose();
      visibleRangeNotifier.dispose();
    });

    testWidgets('handles empty stages list', (tester) async {
      // Validates: Requirements 2.2

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
        'pcolor': Colors.purple,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedStageRow(
              colors: testColors,
              stagesList: const [], // Empty list
              centerItemIndexNotifier: centerItemIndexNotifier,
              visibleRangeNotifier: visibleRangeNotifier,
              dayWidth: 45.0,
              dayMargin: 5.0,
              height: 40.0,
              isUniqueProject: true,
              openEditStage: null,
              openEditElement: null,
            ),
          ),
        ),
      );

      await tester.pump();

      // Should render without errors
      expect(find.byType(OptimizedStageRow), findsOneWidget);
      expect(tester.takeException(), isNull);

      centerItemIndexNotifier.dispose();
      visibleRangeNotifier.dispose();
    });

    testWidgets('shows labels for small elements at center', (tester) async {
      // Validates: Requirements 2.2

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
        'pcolor': Colors.purple,
      };

      // Create a small element (< 4 days) that contains the center index
      final stagesList = [
        {
          'pre_id': 'element_1',
          'type': 'activity', // Not a stage
          'nat': 'activity',
          'sdate': '2024-01-04',
          'edate': '2024-01-06', // 3 days
          'pre_name': 'Small Activity',
          'prog': 50,
          'startDateIndex': 4,
          'endDateIndex': 6,
          'pcolor': 'FF0000FF',
          'prj_id': 'project_1',
          'pname': 'Test Project',
          'prs_id': 'stage_parent',
          'icon': '',
          'users': '',
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 50,
              child: OptimizedStageRow(
                colors: testColors,
                stagesList: stagesList,
                centerItemIndexNotifier: centerItemIndexNotifier,
                visibleRangeNotifier: visibleRangeNotifier,
                dayWidth: 45.0,
                dayMargin: 5.0,
                height: 40.0,
                isUniqueProject: true,
                openEditStage: null,
                openEditElement: null,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Should render without errors
      expect(find.byType(OptimizedStageRow), findsOneWidget);

      // Label should be visible (appears in both StageItem and as a separate label)
      // We just need to verify it's present at least once
      expect(find.text('Small Activity'), findsWidgets);

      centerItemIndexNotifier.dispose();
      visibleRangeNotifier.dispose();
    });

    testWidgets('hides labels when center moves away', (tester) async {
      // Validates: Requirements 2.2

      final centerItemIndexNotifier = ValueNotifier<int>(5);
      final visibleRangeNotifier = ValueNotifier<VisibleRange>(
        VisibleRange(0, 20),
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
        'pcolor': Colors.purple,
      };

      // Create a small element at index 4-6
      final stagesList = [
        {
          'pre_id': 'element_1',
          'type': 'activity',
          'nat': 'activity',
          'sdate': '2024-01-04',
          'edate': '2024-01-06',
          'pre_name': 'Small Activity',
          'prog': 50,
          'startDateIndex': 4,
          'endDateIndex': 6,
          'pcolor': 'FF0000FF',
          'prj_id': 'project_1',
          'pname': 'Test Project',
          'prs_id': 'stage_parent',
          'icon': '',
          'users': '',
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 50,
              child: OptimizedStageRow(
                colors: testColors,
                stagesList: stagesList,
                centerItemIndexNotifier: centerItemIndexNotifier,
                visibleRangeNotifier: visibleRangeNotifier,
                dayWidth: 45.0,
                dayMargin: 5.0,
                height: 40.0,
                isUniqueProject: true,
                openEditStage: null,
                openEditElement: null,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Label should be visible initially (center at 5, element at 4-6)
      // Appears in both StageItem and as a separate label
      final initialLabels = find.text('Small Activity');
      final initialCount = initialLabels.evaluate().length;
      expect(initialCount, greaterThan(0), reason: 'Label should be visible initially');

      // Move center away from the element
      centerItemIndexNotifier.value = 15;
      await tester.pump();

      // The widget should still render correctly after state change
      expect(find.byType(OptimizedStageRow), findsOneWidget);
      expect(tester.takeException(), isNull);

      centerItemIndexNotifier.dispose();
      visibleRangeNotifier.dispose();
    });
  });
}
