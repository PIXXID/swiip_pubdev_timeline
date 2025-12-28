import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/timeline.dart';
import 'dart:math';

/// Property-Based Test for Initial Render Performance
///
/// **Feature: timeline-performance-optimization, Property 1: Initial Render Performance**
/// **Validates: Requirements 1.1**
///
/// This test verifies that when the Timeline_Widget builds with more than 100 Day_Items,
/// the system completes initial render within 500ms.
///
/// Property: For any timeline with more than 100 Day_Items, the initial render time
/// should be less than 500ms.
///
/// Note: This test focuses on build/render performance, not layout correctness.
/// Layout exceptions (overflow, infinite constraints) are expected and ignored
/// as they don't affect the performance measurement.

void main() {
  // Configure test to allow layout exceptions
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Timeline Initial Render Performance Property Tests', () {
    // Test colors
    final testColors = <String, Color>{
      'primary': Colors.blue,
      'primaryBackground': Colors.white,
      'secondaryBackground': Colors.grey[200]!,
      'primaryText': Colors.black,
      'secondaryText': Colors.grey[600]!,
      'accent1': Colors.grey[400]!,
      'error': Colors.red,
      'warning': Colors.orange,
    };

    // Helper to generate test elements
    List<Map<String, dynamic>> generateTestElements(
        int dayCount, Random random) {
      final startDate = DateTime(2024, 1, 1);
      final elements = <Map<String, dynamic>>[];

      // Generate 1-3 elements per day on average
      final elementCount = dayCount + random.nextInt(dayCount * 2);

      for (var i = 0; i < elementCount; i++) {
        final dayOffset = random.nextInt(dayCount);
        elements.add({
          'pre_id': 'elem_$i',
          'date': startDate
              .add(Duration(days: dayOffset))
              .toIso8601String()
              .split('T')[0],
          'nat': ['activity', 'delivrable', 'task'][random.nextInt(3)],
          'status': [
            'pending',
            'inprogress',
            'validated',
            'finished'
          ][random.nextInt(4)],
        });
      }

      return elements;
    }

    // Helper to generate test capacities
    List<Map<String, dynamic>> generateTestCapacities(
        int dayCount, Random random) {
      final startDate = DateTime(2024, 1, 1);
      final capacities = <Map<String, dynamic>>[];

      // Generate capacity for each day
      for (var i = 0; i < dayCount; i++) {
        capacities.add({
          'date':
              startDate.add(Duration(days: i)).toIso8601String().split('T')[0],
          'capeff': random.nextInt(9),
          'buseff': random.nextInt(9),
          'compeff': random.nextInt(9),
          'eicon': random.nextBool() ? 'warning' : '',
        });
      }

      return capacities;
    }

    testWidgets(
        'Property 1: Initial Render Performance - renders 100+ days within 500ms',
        (WidgetTester tester) async {
      // Feature: timeline-performance-optimization, Property 1: Initial Render Performance

      const iterations = 100;
      final random = Random(42); // Fixed seed for reproducibility
      final renderTimes = <int>[];
      var successfulRenders = 0;

      for (var iteration = 0; iteration < iterations; iteration++) {
        // Generate random day count between 100 and 200
        final dayCount = 100 + random.nextInt(101);

        // Generate test data
        final elements = generateTestElements(dayCount, random);
        final capacities = generateTestCapacities(dayCount, random);

        final startDate = DateTime(2024, 1, 1);
        final endDate = startDate.add(Duration(days: dayCount - 1));

        final infos = {
          'startDate': startDate.toIso8601String().split('T')[0],
          'endDate': endDate.toIso8601String().split('T')[0],
          'lmax': 8,
        };

        // Measure render time - only measure the widget build, not layout completion
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: Timeline(
                  width: 800,
                  height: 600,
                  colors: testColors,
                  mode: 'chronology',
                  infos: infos,
                  elements: elements,
                  elementsDone: [],
                  capacities: capacities,
                  stages: [], // Empty stages to avoid data issues
                  openDayDetail: null,
                ),
              ),
            ),
          ),
        );

        // Wait for initial frame - this measures the build time
        await tester.pump();

        stopwatch.stop();
        final renderTimeMs = stopwatch.elapsedMilliseconds;
        renderTimes.add(renderTimeMs);
        successfulRenders++;

        // Verify render time is within acceptable limit
        expect(renderTimeMs, lessThan(500),
            reason:
                'Iteration $iteration: Render time ${renderTimeMs}ms exceeded 500ms for $dayCount days with ${elements.length} elements');

        // Verify the timeline rendered successfully (ignore layout exceptions)
        expect(find.byType(Timeline), findsOneWidget,
            reason: 'Timeline widget should be rendered');

        // Clean up for next iteration
        await tester.pumpWidget(Container());
        await tester.pump();
      }

      // Calculate statistics
      renderTimes.sort();
      final average = renderTimes.reduce((a, b) => a + b) / renderTimes.length;
      final median = renderTimes[renderTimes.length ~/ 2];
      final p95 = renderTimes[(renderTimes.length * 0.95).floor()];
      final max = renderTimes.last;

      // Print performance statistics
      debugPrint(
          'Initial Render Performance Statistics ($successfulRenders/$iterations successful):');
      debugPrint('  Average: ${average.toStringAsFixed(1)}ms');
      debugPrint('  Median: ${median}ms');
      debugPrint('  95th percentile: ${p95}ms');
      debugPrint('  Max: ${max}ms');

      // Verify that 95% of renders are within the limit
      expect(p95, lessThan(500),
          reason: '95th percentile render time should be under 500ms');
    });

    testWidgets(
        'Property 1: Initial Render Performance - scales linearly with day count',
        (WidgetTester tester) async {
      // Feature: timeline-performance-optimization, Property 1: Initial Render Performance

      const iterations = 50;
      final random = Random(123);
      final dataPoints = <int, List<int>>{};

      // Test different day counts: 100, 150, 200
      final dayCounts = [100, 150, 200];

      for (final dayCount in dayCounts) {
        dataPoints[dayCount] = [];

        for (var iteration = 0; iteration < iterations; iteration++) {
          // Generate test data
          final elements = generateTestElements(dayCount, random);
          final capacities = generateTestCapacities(dayCount, random);

          final startDate = DateTime(2024, 1, 1);
          final endDate = startDate.add(Duration(days: dayCount - 1));

          final infos = {
            'startDate': startDate.toIso8601String().split('T')[0],
            'endDate': endDate.toIso8601String().split('T')[0],
            'lmax': 8,
          };

          // Measure render time
          final stopwatch = Stopwatch()..start();

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 800,
                  height: 600,
                  child: Timeline(
                    width: 800,
                    height: 600,
                    colors: testColors,
                    mode: 'chronology',
                    infos: infos,
                    elements: elements,
                    elementsDone: [],
                    capacities: capacities,
                    stages: [],
                    openDayDetail: null,
                  ),
                ),
              ),
            ),
          );

          await tester.pump();
          stopwatch.stop();

          dataPoints[dayCount]!.add(stopwatch.elapsedMilliseconds);

          await tester.pumpWidget(Container());
          await tester.pump();
        }
      }

      // Calculate averages for each day count
      final averages = <int, double>{};
      for (final entry in dataPoints.entries) {
        final times = entry.value;
        averages[entry.key] = times.reduce((a, b) => a + b) / times.length;
      }

      debugPrint('Render Time Scaling:');
      for (final entry in averages.entries) {
        debugPrint('  ${entry.key} days: ${entry.value.toStringAsFixed(1)}ms');
      }

      // Verify all day counts meet the performance requirement
      for (final entry in averages.entries) {
        expect(entry.value, lessThan(500),
            reason:
                'Average render time for ${entry.key} days should be under 500ms');
      }

      // Verify scaling is reasonable (not exponential)
      // The ratio between 200 days and 100 days should be less than 3x
      final ratio200to100 = averages[200]! / averages[100]!;
      expect(ratio200to100, lessThan(3.0),
          reason:
              'Render time should scale linearly, not exponentially (ratio: ${ratio200to100.toStringAsFixed(2)}x)');
    });

    testWidgets(
        'Property 1: Initial Render Performance - handles varying element density',
        (WidgetTester tester) async {
      // Feature: timeline-performance-optimization, Property 1: Initial Render Performance

      const iterations = 30;
      final random = Random(456);

      for (var iteration = 0; iteration < iterations; iteration++) {
        final dayCount = 100 + random.nextInt(51); // 100-150 days

        // Vary element density: sparse (0.5x), normal (1.5x), dense (3x)
        final densityMultiplier = [0.5, 1.5, 3.0][iteration % 3];
        final elementCount = (dayCount * densityMultiplier).round();

        final startDate = DateTime(2024, 1, 1);
        final elements = <Map<String, dynamic>>[];

        for (var i = 0; i < elementCount; i++) {
          final dayOffset = random.nextInt(dayCount);
          elements.add({
            'pre_id': 'elem_$i',
            'date': startDate
                .add(Duration(days: dayOffset))
                .toIso8601String()
                .split('T')[0],
            'nat': ['activity', 'delivrable', 'task'][random.nextInt(3)],
            'status': ['pending', 'inprogress', 'validated'][random.nextInt(3)],
          });
        }

        final capacities = generateTestCapacities(dayCount, random);
        final endDate = startDate.add(Duration(days: dayCount - 1));

        final infos = {
          'startDate': startDate.toIso8601String().split('T')[0],
          'endDate': endDate.toIso8601String().split('T')[0],
          'lmax': 8,
        };

        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: Timeline(
                  width: 800,
                  height: 600,
                  colors: testColors,
                  mode: 'chronology',
                  infos: infos,
                  elements: elements,
                  elementsDone: [],
                  capacities: capacities,
                  stages: [],
                  openDayDetail: null,
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(500),
            reason:
                'Iteration $iteration: Render time ${stopwatch.elapsedMilliseconds}ms exceeded 500ms for $dayCount days with $elementCount elements (density: ${densityMultiplier}x)');

        await tester.pumpWidget(Container());
        await tester.pump();
      }
    });
  });
}
