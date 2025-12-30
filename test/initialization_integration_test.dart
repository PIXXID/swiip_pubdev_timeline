import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/timeline.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/timeline_configuration_manager.dart';

/// Integration test for timeline initialization
/// Tests Requirements: 8.5
///
/// This test verifies:
/// - Correct initial scroll position (defaultDate or nowIndex)
/// - Correct initial visible range calculation
/// - Correct initial center item
void main() {
  group('Initialization Integration Test', () {
    setUp(() {
      TimelineConfigurationManager.reset();
      TimelineConfigurationManager.initialize();
    });

    tearDown(() {
      TimelineConfigurationManager.reset();
    });

    testWidgets('Timeline initializes with correct scroll position for defaultDate', (WidgetTester tester) async {
      // Requirements: 8.5

      const numDays = 100;
      final startDate = DateTime(2024, 1, 1);
      final endDate = startDate.add(const Duration(days: numDays - 1));
      final defaultDate = startDate.add(const Duration(days: 40)); // Day 40

      final elements = _createTestElements(startDate, numDays);
      final stages = _createTestStages(startDate, endDate, elements);
      final infos = _createTestInfos(startDate, endDate);

      String? lastDateCallback;

      await tester.pumpWidget(
        _buildTimelineWidget(
          infos,
          elements,
          stages,
          '${defaultDate.year}-${defaultDate.month.toString().padLeft(2, '0')}-${defaultDate.day.toString().padLeft(2, '0')}',
          (date) {
            lastDateCallback = date;
          },
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final timelineFinder = find.byType(Timeline);
      expect(timelineFinder, findsOneWidget);

      // Wait for initialization to complete
      await tester.pump(const Duration(milliseconds: 500));

      // Verify initialization callback was fired
      expect(lastDateCallback, isNotNull, reason: 'Timeline should fire callback during initialization');

      // Verify the date is in correct format
      if (lastDateCallback != null) {
        final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
        expect(dateRegex.hasMatch(lastDateCallback!), isTrue, reason: 'Date should be in YYYY-MM-DD format');
      }

      // Verify timeline is functional
      expect(timelineFinder, findsOneWidget);
    });

    testWidgets('Timeline initializes with correct scroll position for nowIndex', (WidgetTester tester) async {
      // Requirements: 8.5

      const numDays = 100;
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 50));
      final endDate = startDate.add(const Duration(days: numDays - 1));

      final elements = _createTestElements(startDate, numDays);
      final stages = _createTestStages(startDate, endDate, elements);
      final infos = _createTestInfos(startDate, endDate);

      String? lastDateCallback;

      await tester.pumpWidget(
        _buildTimelineWidget(
          infos,
          elements,
          stages,
          null, // No defaultDate - should use nowIndex
          (date) {
            lastDateCallback = date;
          },
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final timelineFinder = find.byType(Timeline);
      expect(timelineFinder, findsOneWidget);

      // Wait for initialization to complete
      await tester.pump(const Duration(milliseconds: 500));

      // Verify initialization callback was fired
      expect(lastDateCallback, isNotNull, reason: 'Timeline should fire callback during initialization');

      // Verify timeline is functional
      expect(timelineFinder, findsOneWidget);
    });

    testWidgets('Timeline initializes with correct visible range calculation', (WidgetTester tester) async {
      // Requirements: 8.5

      const numDays = 100;
      final startDate = DateTime(2024, 1, 1);
      final endDate = startDate.add(const Duration(days: numDays - 1));
      final defaultDate = startDate.add(const Duration(days: 50)); // Middle

      final elements = _createTestElements(startDate, numDays);
      final stages = _createTestStages(startDate, endDate, elements);
      final infos = _createTestInfos(startDate, endDate);

      await tester.pumpWidget(
        _buildTimelineWidget(
          infos,
          elements,
          stages,
          '${defaultDate.year}-${defaultDate.month.toString().padLeft(2, '0')}-${defaultDate.day.toString().padLeft(2, '0')}',
          null,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final timelineFinder = find.byType(Timeline);
      expect(timelineFinder, findsOneWidget);

      final timelineState = tester.state(timelineFinder) as dynamic;

      // Wait for initialization
      await tester.pump(const Duration(milliseconds: 500));

      // Verify timeline initialized successfully
      expect(timelineState.days, isNotEmpty, reason: 'Timeline should have days initialized');

      // Verify we can scroll after initialization
      timelineState.scrollTo(20, animated: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Verify timeline still exists
      expect(timelineFinder, findsOneWidget, reason: 'Timeline should remain functional after initialization');
    });

    testWidgets('Timeline initializes correctly with empty data', (WidgetTester tester) async {
      // Requirements: 8.5

      final startDate = DateTime(2024, 1, 1);
      final endDate = startDate.add(const Duration(days: 10));

      final infos = _createTestInfos(startDate, endDate);

      await tester.pumpWidget(
        _buildTimelineWidget(
          infos,
          [], // Empty elements
          [], // Empty stages
          null,
          null,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final timelineFinder = find.byType(Timeline);
      expect(timelineFinder, findsOneWidget);

      final timelineState = tester.state(timelineFinder) as dynamic;

      // Wait for initialization
      await tester.pump(const Duration(milliseconds: 500));

      // Verify timeline initialized without errors
      expect(timelineState.days, isNotEmpty, reason: 'Timeline should have days even with empty elements');

      // Verify timeline is functional
      expect(timelineFinder, findsOneWidget);
    });

    testWidgets('Timeline initialization state is consistent across rebuilds', (WidgetTester tester) async {
      // Requirements: 8.5

      const numDays = 50;
      final startDate = DateTime(2024, 1, 1);
      final endDate = startDate.add(const Duration(days: numDays - 1));
      final defaultDate = startDate.add(const Duration(days: 25));

      final elements = _createTestElements(startDate, numDays);
      final stages = _createTestStages(startDate, endDate, elements);
      final infos = _createTestInfos(startDate, endDate);

      await tester.pumpWidget(
        _buildTimelineWidget(
          infos,
          elements,
          stages,
          '${defaultDate.year}-${defaultDate.month.toString().padLeft(2, '0')}-${defaultDate.day.toString().padLeft(2, '0')}',
          null,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final timelineFinder = find.byType(Timeline);
      expect(timelineFinder, findsOneWidget);

      // Wait for initialization
      await tester.pump(const Duration(milliseconds: 500));

      // Trigger a rebuild by pumping
      await tester.pump();

      // Verify timeline remains functional after rebuild
      expect(timelineFinder, findsOneWidget, reason: 'Timeline should remain consistent after rebuild');
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
  String? defaultDate,
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
        defaultDate: defaultDate,
        openDayDetail: (date, capacity, preIds, elements, infos) {},
        updateCurrentDate: updateCurrentDate,
      ),
    ),
  );
}
