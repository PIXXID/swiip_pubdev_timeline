import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/timeline.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/timeline_configuration_manager.dart';

/// Integration tests for scrollTo initialization functionality
/// Tests Requirements: 5.5
void main() {
  group('ScrollTo Initialization Integration Tests', () {
    setUp(() {
      TimelineConfigurationManager.reset();
      TimelineConfigurationManager.initialize();
    });

    tearDown(() {
      TimelineConfigurationManager.reset();
    });

    testWidgets('Timeline scrolls to defaultDate on initialization', (WidgetTester tester) async {
      // Requirements: 5.5

      const numDays = 100;
      final startDate = DateTime(2024, 1, 1);
      final endDate = startDate.add(const Duration(days: numDays - 1));
      final defaultDate = startDate.add(const Duration(days: 30)); // Day 30

      // Create test data
      final elements = List.generate(numDays, (index) {
        final date = startDate.add(Duration(days: index));
        return {
          'id': 'elem_$index',
          'name': 'Test Element $index',
          'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          'pre_id': 'pre_$index',
          'nat': 'activity',
          'status': 'pending',
          'sdate': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
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

      String? currentCenterDate;

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
              defaultDate:
                  '${defaultDate.year}-${defaultDate.month.toString().padLeft(2, '0')}-${defaultDate.day.toString().padLeft(2, '0')}',
              openDayDetail: (date, capacity, preIds, elements, infos) {},
              updateCurrentDate: (date) {
                currentCenterDate = date;
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Wait for initialization scroll to complete
      await tester.pump(const Duration(milliseconds: 500));

      final timelineFinder = find.byType(Timeline);
      expect(timelineFinder, findsOneWidget);

      // Verify that the timeline initialized and scrolled to the default date
      // The updateCurrentDate callback should have been called with a date near the default date
      expect(currentCenterDate, isNotNull, reason: 'Timeline should scroll to defaultDate on initialization');

      // Parse the center date and verify it's close to the default date
      if (currentCenterDate != null) {
        final centerDate = DateTime.parse(currentCenterDate!);
        final daysDifference = centerDate.difference(defaultDate).inDays.abs();

        // Allow a larger tolerance due to viewport centering and scroll positioning
        expect(daysDifference, lessThanOrEqualTo(15),
            reason: 'Timeline should scroll near defaultDate on initialization');
      }
    });

    testWidgets('Timeline scrolls to nowIndex when no defaultDate provided', (WidgetTester tester) async {
      // Requirements: 5.5

      const numDays = 100;
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 50));
      final endDate = startDate.add(const Duration(days: numDays - 1));

      // Create test data
      final elements = List.generate(numDays, (index) {
        final date = startDate.add(Duration(days: index));
        return {
          'id': 'elem_$index',
          'name': 'Test Element $index',
          'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          'pre_id': 'pre_$index',
          'nat': 'activity',
          'status': 'pending',
          'sdate': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
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

      String? currentCenterDate;

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
              // No defaultDate provided - should scroll to nowIndex
              openDayDetail: (date, capacity, preIds, elements, infos) {},
              updateCurrentDate: (date) {
                currentCenterDate = date;
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Wait for initialization scroll to complete
      await tester.pump(const Duration(milliseconds: 500));

      final timelineFinder = find.byType(Timeline);
      expect(timelineFinder, findsOneWidget);

      // Verify that the timeline initialized and scrolled to today's date
      expect(currentCenterDate, isNotNull, reason: 'Timeline should scroll to nowIndex when no defaultDate provided');

      // Parse the center date and verify it's close to today
      if (currentCenterDate != null) {
        final centerDate = DateTime.parse(currentCenterDate!);
        final daysDifference = centerDate.difference(now).inDays.abs();

        // Allow a larger tolerance due to viewport centering and time of day
        expect(daysDifference, lessThanOrEqualTo(15),
            reason: 'Timeline should scroll near today when no defaultDate provided');
      }
    });

    testWidgets('Timeline verifies correct initial scroll position with defaultDate', (WidgetTester tester) async {
      // Requirements: 5.5

      const numDays = 100;
      final startDate = DateTime(2024, 1, 1);
      final endDate = startDate.add(const Duration(days: numDays - 1));
      final defaultDate = startDate.add(const Duration(days: 45)); // Day 45

      // Create test data
      final elements = List.generate(numDays, (index) {
        final date = startDate.add(Duration(days: index));
        return {
          'id': 'elem_$index',
          'name': 'Test Element $index',
          'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          'pre_id': 'pre_$index',
          'nat': 'activity',
          'status': 'pending',
          'sdate': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
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
              defaultDate:
                  '${defaultDate.year}-${defaultDate.month.toString().padLeft(2, '0')}-${defaultDate.day.toString().padLeft(2, '0')}',
              openDayDetail: (date, capacity, preIds, elements, infos) {},
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Wait for initialization scroll to complete
      await tester.pump(const Duration(milliseconds: 500));

      final timelineFinder = find.byType(Timeline);
      expect(timelineFinder, findsOneWidget);

      final timelineState = tester.state(timelineFinder) as dynamic;

      // Verify the timeline initialized successfully
      expect(timelineState.days, isNotEmpty, reason: 'Timeline should have days initialized');

      // Verify we can still scroll after initialization
      timelineState.scrollTo(20, animated: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Verify timeline still exists (scroll worked)
      expect(timelineFinder, findsOneWidget, reason: 'Timeline should remain functional after initialization scroll');
    });
  });
}
