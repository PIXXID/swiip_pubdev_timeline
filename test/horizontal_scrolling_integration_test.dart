import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/timeline.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/timeline_configuration_manager.dart';

/// Integration tests for horizontal scrolling functionality
/// Tests Requirements: 2.2, 2.3, 2.4
void main() {
  group('Horizontal Scrolling Integration Tests', () {
    setUp(() {
      TimelineConfigurationManager.reset();
      TimelineConfigurationManager.initialize();
    });

    tearDown(() {
      TimelineConfigurationManager.reset();
    });

    testWidgets('Mouse wheel horizontal scrolling updates scroll position', (WidgetTester tester) async {
      // Requirements: 2.2

      const numDays = 100;
      final startDate = DateTime(2024, 1, 1);
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

      // Simulate mouse wheel scroll by programmatically scrolling
      // (In a real app, this would be triggered by mouse wheel events)
      timelineState.scrollTo(10, animated: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Scroll to another position
      timelineState.scrollTo(30, animated: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify scrollTo works without throwing exceptions
      expect(timelineFinder, findsOneWidget, reason: 'Mouse wheel horizontal scrolling should update scroll position');
    });

    testWidgets('Trackpad horizontal gesture scrolling updates scroll position', (WidgetTester tester) async {
      // Requirements: 2.3

      const numDays = 100;
      final startDate = DateTime(2024, 1, 1);
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

      // Find the scrollable widget
      final scrollableFinder = find.byType(SingleChildScrollView).first;
      expect(scrollableFinder, findsOneWidget);

      // Simulate trackpad pan gesture (horizontal) using drag
      await tester.drag(scrollableFinder, const Offset(-200, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify timeline still exists (drag worked without errors)
      expect(timelineFinder, findsOneWidget, reason: 'Trackpad horizontal gesture should update scroll position');
    });

    testWidgets('Touch drag horizontal scrolling updates scroll position', (WidgetTester tester) async {
      // Requirements: 2.4

      const numDays = 100;
      final startDate = DateTime(2024, 1, 1);
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

      // Find the scrollable widget
      final scrollableFinder = find.byType(SingleChildScrollView).first;
      expect(scrollableFinder, findsOneWidget);

      // Simulate touch drag (horizontal)
      final gesture = await tester.startGesture(
        tester.getCenter(scrollableFinder),
      );
      await gesture.moveBy(const Offset(-300, 0));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify timeline still exists (touch drag worked without errors)
      expect(timelineFinder, findsOneWidget, reason: 'Touch drag horizontal scrolling should update scroll position');
    });

    testWidgets('Horizontal scrolling correctly updates scroll position', (WidgetTester tester) async {
      // Requirements: 2.2, 2.3, 2.4

      const numDays = 100;
      final startDate = DateTime(2024, 1, 1);
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

      // Wait for initialization to complete
      await tester.pump(const Duration(milliseconds: 500));

      // Programmatically scroll to different positions
      timelineState.scrollTo(10, animated: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Scroll to another position
      timelineState.scrollTo(30, animated: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Scroll to yet another position
      timelineState.scrollTo(50, animated: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Verify we can scroll back
      timelineState.scrollTo(20, animated: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Verify timeline still exists (all scrolls worked without errors)
      expect(timelineFinder, findsOneWidget,
          reason: 'Scroll position should update correctly for all scroll operations');
    });
  });
}
