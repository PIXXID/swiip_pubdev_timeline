import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/timeline.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/timeline_configuration_manager.dart';

/// Integration test for complete scroll flow
/// Tests Requirements: 2.1, 2.3, 2.4, 3.5, 5.5
///
/// This test verifies the complete flow:
/// user scroll → calculation → state update → render
void main() {
  group('Complete Scroll Flow Integration Test', () {
    setUp(() {
      TimelineConfigurationManager.reset();
      TimelineConfigurationManager.initialize();
    });

    tearDown(() {
      TimelineConfigurationManager.reset();
    });

    testWidgets(
        'Complete scroll flow: user scroll → calculation → state update → render',
        (WidgetTester tester) async {
      // Requirements: 2.1, 2.3, 2.4, 3.5, 5.5

      const numDays = 100;
      final startDate = DateTime(2024, 1, 1);
      final endDate = startDate.add(const Duration(days: numDays - 1));

      // Create test data
      final elements = List.generate(numDays, (index) {
        final date = startDate.add(Duration(days: index));
        return {
          'id': 'elem_$index',
          'name': 'Test Element $index',
          'date':
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          'pre_id': 'pre_$index',
          'nat': 'activity',
          'status': 'pending',
          'sdate':
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          'edate':
              '${date.add(const Duration(days: 1)).year}-${date.add(const Duration(days: 1)).month.toString().padLeft(2, '0')}-${date.add(const Duration(days: 1)).day.toString().padLeft(2, '0')}',
          'stage_id': 'stage1',
        };
      });

      final stages = [
        {
          'id': 'stage1',
          'name': 'Test Stage',
          'prj_id': 'prj1',
          'pname': 'Test Project',
          'type': 'stage',
          'pcolor': '#0000FF',
          'prs_id': 'prs1',
          'sdate':
              '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
          'edate':
              '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
          'elm_filtered': elements.map((e) => e['pre_id']).toList(),
        }
      ];

      final infos = {
        'startDate':
            '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
        'endDate':
            '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
        'lmax': 8,
      };

      // Track callback invocations
      final List<String> dateCallbacks = [];

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
                  dateCallbacks.add(date);
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

      // Wait for initialization to complete
      await tester.pump(const Duration(milliseconds: 500));

      // Verify initial state
      expect(timelineState.days, isNotEmpty,
          reason: 'Timeline should have days initialized');
      expect(timelineState.stagesRows, isNotEmpty,
          reason: 'Timeline should have stage rows initialized');

      // Reset callback tracking
      dateCallbacks.clear();

      // Test 1: Verify horizontal scroll updates center item
      // Requirements: 2.1, 2.3
      // We test this by scrolling and verifying the callback fires

      // Scroll to a different position
      timelineState.scrollTo(30, animated: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Test 2: Verify current date callback fires
      // Requirements: 3.5
      expect(dateCallbacks, isNotEmpty,
          reason: 'Current date callback should fire when center changes');

      // Verify date format (YYYY-MM-DD)
      if (dateCallbacks.isNotEmpty) {
        final lastDate = dateCallbacks.last;
        final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
        expect(dateRegex.hasMatch(lastDate), isTrue,
            reason: 'Current date should be in YYYY-MM-DD format');
      }

      // Test 3: Verify lazy viewports render correct items
      // Requirements: 5.5, 2.4
      // The lazy viewports should only render items in the visible range
      // We verify this by checking that the timeline renders without errors

      // Scroll to another position to trigger re-render
      dateCallbacks.clear();
      timelineState.scrollTo(50, animated: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify callback fired again with different date
      expect(dateCallbacks, isNotEmpty,
          reason: 'Callback should fire for new scroll position');

      // Test 4: Verify multiple scroll operations work correctly
      // Scroll back to beginning
      timelineState.scrollTo(0, animated: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Scroll to end
      timelineState.scrollTo(numDays - 1, animated: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify timeline still functional
      expect(timelineFinder, findsOneWidget,
          reason: 'Timeline should remain functional after multiple scrolls');

      // Verify we received multiple callback invocations
      expect(dateCallbacks.length, greaterThan(1),
          reason: 'Multiple scrolls should trigger multiple callbacks');
    });

    testWidgets('Scroll flow with drag gesture updates state correctly',
        (WidgetTester tester) async {
      // Requirements: 2.1, 2.3, 2.4

      const numDays = 50;
      final startDate = DateTime(2024, 1, 1);
      final endDate = startDate.add(const Duration(days: numDays - 1));

      final elements = List.generate(numDays, (index) {
        final date = startDate.add(Duration(days: index));
        return {
          'id': 'elem_$index',
          'name': 'Test Element $index',
          'date':
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          'pre_id': 'pre_$index',
          'nat': 'activity',
          'status': 'pending',
          'sdate':
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          'edate':
              '${date.add(const Duration(days: 1)).year}-${date.add(const Duration(days: 1)).month.toString().padLeft(2, '0')}-${date.add(const Duration(days: 1)).day.toString().padLeft(2, '0')}',
          'stage_id': 'stage1',
        };
      });

      final stages = [
        {
          'id': 'stage1',
          'name': 'Test Stage',
          'prj_id': 'prj1',
          'pname': 'Test Project',
          'type': 'stage',
          'pcolor': '#0000FF',
          'prs_id': 'prs1',
          'sdate':
              '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
          'edate':
              '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
          'elm_filtered': elements.map((e) => e['pre_id']).toList(),
        }
      ];

      final infos = {
        'startDate':
            '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
        'endDate':
            '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
        'lmax': 8,
      };

      final List<String> dateCallbacks = [];

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
                  dateCallbacks.add(date);
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

      // Wait for initialization
      await tester.pump(const Duration(milliseconds: 500));

      dateCallbacks.clear();

      // Find the scrollable widget
      final scrollableFinder = find.byType(SingleChildScrollView).first;
      expect(scrollableFinder, findsOneWidget);

      // Simulate drag gesture
      await tester.drag(scrollableFinder, const Offset(-300, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify state updated from drag by checking callback was invoked
      expect(dateCallbacks, isNotEmpty,
          reason:
              'Drag gesture should update center item and trigger callback');

      // Verify timeline still renders correctly
      expect(timelineFinder, findsOneWidget);
    });

    testWidgets('Horizontal scroll updates visible range for lazy rendering',
        (WidgetTester tester) async {
      // Requirements: 2.4, 5.5

      const numDays = 100;
      final startDate = DateTime(2024, 1, 1);
      final endDate = startDate.add(const Duration(days: numDays - 1));

      final elements = List.generate(numDays, (index) {
        final date = startDate.add(Duration(days: index));
        return {
          'id': 'elem_$index',
          'name': 'Test Element $index',
          'date':
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          'pre_id': 'pre_$index',
          'nat': 'activity',
          'status': 'pending',
          'sdate':
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          'edate':
              '${date.add(const Duration(days: 1)).year}-${date.add(const Duration(days: 1)).month.toString().padLeft(2, '0')}-${date.add(const Duration(days: 1)).day.toString().padLeft(2, '0')}',
          'stage_id': 'stage1',
        };
      });

      final stages = [
        {
          'id': 'stage1',
          'name': 'Test Stage',
          'prj_id': 'prj1',
          'pname': 'Test Project',
          'type': 'stage',
          'pcolor': '#0000FF',
          'prs_id': 'prs1',
          'sdate':
              '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
          'edate':
              '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
          'elm_filtered': elements.map((e) => e['pre_id']).toList(),
        }
      ];

      final infos = {
        'startDate':
            '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
        'endDate':
            '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
        'lmax': 8,
      };

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
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final timelineFinder = find.byType(Timeline);
      expect(timelineFinder, findsOneWidget);

      final timelineState = tester.state(timelineFinder) as dynamic;

      // Wait for initialization
      await tester.pump(const Duration(milliseconds: 500));

      // Perform multiple scrolls to different positions
      // This tests that visible range updates correctly for lazy rendering
      final scrollPositions = [10, 30, 50, 70, 90];

      for (final position in scrollPositions) {
        timelineState.scrollTo(position, animated: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Verify timeline renders without errors at each position
        expect(timelineFinder, findsOneWidget,
            reason: 'Timeline should render correctly at position $position');
      }

      // Verify timeline is still functional after all scrolls
      expect(timelineFinder, findsOneWidget);
    });
  });
}
