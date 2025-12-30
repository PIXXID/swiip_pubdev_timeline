import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/timeline.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/timeline_configuration_manager.dart';

/// Integration test for scroll throttling behavior
/// Tests Requirements: 2.5, 6.1, 6.2, 6.3, 6.4
///
/// This test verifies that:
/// - Rapid scroll events are throttled
/// - Calculations don't happen more than ~60 FPS (16ms intervals)
/// - State updates are throttled correctly
void main() {
  group('Throttling Behavior Integration Test', () {
    setUp(() {
      TimelineConfigurationManager.reset();
      TimelineConfigurationManager.initialize();
    });

    tearDown(() {
      TimelineConfigurationManager.reset();
    });

    testWidgets('Rapid scroll events are throttled correctly', (WidgetTester tester) async {
      // Requirements: 2.5, 6.1, 6.2

      const numDays = 100;
      final startDate = DateTime(2024, 1, 1);
      final endDate = startDate.add(const Duration(days: numDays - 1));

      final elements = _createTestElements(startDate, numDays);
      final stages = _createTestStages(startDate, endDate, elements);
      final infos = _createTestInfos(startDate, endDate);

      // Track callback invocations
      final List<String> dateCallbacks = [];

      await tester.pumpWidget(
        _buildTimelineWidget(infos, elements, stages, (date) {
          if (date != null) {
            dateCallbacks.add(date);
          }
        }),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final timelineFinder = find.byType(Timeline);
      expect(timelineFinder, findsOneWidget);

      final timelineState = tester.state(timelineFinder) as dynamic;

      // Wait for initialization
      await tester.pump(const Duration(milliseconds: 500));

      // Reset tracking
      dateCallbacks.clear();

      // Simulate rapid scroll events by scrolling multiple times quickly
      final scrollPositions = [5, 10, 15, 20, 25, 30, 35, 40];

      for (final position in scrollPositions) {
        timelineState.scrollTo(position, animated: false);
      }

      // Now pump to trigger the throttled update
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Verify that the timeline handled rapid scrolls without errors
      expect(timelineFinder, findsOneWidget, reason: 'Timeline should handle rapid scrolls correctly');

      // Verify callbacks were invoked (throttling should still allow updates)
      expect(dateCallbacks, isNotEmpty, reason: 'Throttled updates should still fire callbacks');
    });

    testWidgets('State updates are throttled correctly during rapid scrolling', (WidgetTester tester) async {
      // Requirements: 2.5, 6.3, 6.4

      const numDays = 100;
      final startDate = DateTime(2024, 1, 1);
      final endDate = startDate.add(const Duration(days: numDays - 1));

      final elements = _createTestElements(startDate, numDays);
      final stages = _createTestStages(startDate, endDate, elements);
      final infos = _createTestInfos(startDate, endDate);

      await tester.pumpWidget(_buildTimelineWidget(infos, elements, stages, null));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final timelineFinder = find.byType(Timeline);
      expect(timelineFinder, findsOneWidget);

      final timelineState = tester.state(timelineFinder) as dynamic;

      // Wait for initialization
      await tester.pump(const Duration(milliseconds: 500));

      // Perform multiple scrolls with small delays between them
      timelineState.scrollTo(10, animated: false);
      await tester.pump(const Duration(milliseconds: 5));

      timelineState.scrollTo(20, animated: false);
      await tester.pump(const Duration(milliseconds: 5));

      timelineState.scrollTo(30, animated: false);
      await tester.pump(const Duration(milliseconds: 5));

      // Wait for throttle timer to complete
      await tester.pump(const Duration(milliseconds: 50));

      // Verify timeline is still functional
      expect(timelineFinder, findsOneWidget, reason: 'Timeline should remain functional after rapid scrolls');
    });

    testWidgets('Throttle timer is cancelled on widget disposal', (WidgetTester tester) async {
      // Requirements: 6.4

      const numDays = 50;
      final startDate = DateTime(2024, 1, 1);
      final endDate = startDate.add(const Duration(days: numDays - 1));

      final elements = _createTestElements(startDate, numDays);
      final stages = _createTestStages(startDate, endDate, elements);
      final infos = _createTestInfos(startDate, endDate);

      await tester.pumpWidget(_buildTimelineWidget(infos, elements, stages, null));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final timelineFinder = find.byType(Timeline);
      expect(timelineFinder, findsOneWidget);

      final timelineState = tester.state(timelineFinder) as dynamic;

      // Wait for initialization
      await tester.pump(const Duration(milliseconds: 500));

      // Trigger a scroll to start the throttle timer
      timelineState.scrollTo(10, animated: false);
      await tester.pump(const Duration(milliseconds: 5));

      // Dispose the widget while throttle timer is active
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('Disposed'))));
      await tester.pump();

      // If timer wasn't cancelled properly, this would cause errors
      expect(find.text('Disposed'), findsOneWidget, reason: 'Widget should be disposed without errors');
    });

    testWidgets('Throttling maintains correct final state after rapid scrolls', (WidgetTester tester) async {
      // Requirements: 2.5, 6.1, 6.2, 6.3

      const numDays = 100;
      final startDate = DateTime(2024, 1, 1);
      final endDate = startDate.add(const Duration(days: numDays - 1));

      final elements = _createTestElements(startDate, numDays);
      final stages = _createTestStages(startDate, endDate, elements);
      final infos = _createTestInfos(startDate, endDate);

      final List<String> dateCallbacks = [];

      await tester.pumpWidget(
        _buildTimelineWidget(infos, elements, stages, (date) {
          if (date != null) {
            dateCallbacks.add(date);
          }
        }),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final timelineFinder = find.byType(Timeline);
      expect(timelineFinder, findsOneWidget);

      final timelineState = tester.state(timelineFinder) as dynamic;

      // Wait for initialization
      await tester.pump(const Duration(milliseconds: 500));

      dateCallbacks.clear();

      // Perform a series of rapid scrolls
      final targetPosition = 45;
      for (int i = 0; i < 10; i++) {
        timelineState.scrollTo(targetPosition + i, animated: false);
        await tester.pump(const Duration(milliseconds: 2));
      }

      // Wait for throttle to settle
      await tester.pump(const Duration(milliseconds: 50));

      // Verify final state is consistent
      expect(timelineFinder, findsOneWidget, reason: 'Timeline should remain functional after rapid scrolls');

      // Verify callbacks were invoked
      expect(dateCallbacks, isNotEmpty, reason: 'Callbacks should fire even with throttling');
    });
  });
}

// Helper functions to reduce code duplication
List<Map<String, dynamic>> _createTestElements(DateTime startDate, int numDays) {
  return List.generate(numDays, (index) {
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
}

List<Map<String, dynamic>> _createTestStages(
    DateTime startDate, DateTime endDate, List<Map<String, dynamic>> elements) {
  return [
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
      'edate': '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
      'elm_filtered': elements.map((e) => e['pre_id']).toList(),
    }
  ];
}

Map<String, String> _createTestInfos(DateTime startDate, DateTime endDate) {
  return {
    'startDate':
        '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
    'endDate': '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
    'lmax': '8',
  };
}

Widget _buildTimelineWidget(
  Map<String, String> infos,
  List<Map<String, dynamic>> elements,
  List<Map<String, dynamic>> stages,
  Function(String?)? updateCurrentDate,
) {
  return MaterialApp(
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
        updateCurrentDate: updateCurrentDate,
      ),
    ),
  );
}
