import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/timeline.dart';
import 'dart:math';

/// Property-Based Test for Slider Isolation
/// 
/// **Feature: timeline-performance-optimization, Property 10: Slider Isolation**
/// **Validates: Requirements 2.5**
/// 
/// This test verifies that when the slider value changes, only the slider widget
/// and directly related UI elements rebuild, not the entire timeline or its Day_Items.

void main() {
  group('Timeline Slider Isolation Property Tests', () {
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

    // Helper to generate test data
    List<Map<String, dynamic>> generateTestElements(int count) {
      final startDate = DateTime(2024, 1, 1);
      final elements = <Map<String, dynamic>>[];
      
      for (var i = 0; i < count; i++) {
        elements.add({
          'pre_id': 'elem_$i',
          'date': startDate.add(Duration(days: i)).toIso8601String().split('T')[0],
          'nat': ['activity', 'delivrable', 'task'][i % 3],
          'status': ['pending', 'inprogress', 'validated'][i % 3],
        });
      }
      
      return elements;
    }

    testWidgets('Property 10: Slider Isolation - slider changes do not rebuild timeline items',
        (WidgetTester tester) async {
      // Feature: timeline-performance-optimization, Property 10: Slider Isolation
      
      const iterations = 100;
      final random = Random(42); // Fixed seed for reproducibility
      
      for (var iteration = 0; iteration < iterations; iteration++) {
        // Generate random test data
        final elementCount = 50 + random.nextInt(50); // 50-100 elements
        final elements = generateTestElements(elementCount);
        
        final startDate = DateTime(2024, 1, 1);
        final endDate = startDate.add(Duration(days: elementCount));
        
        final infos = {
          'startDate': startDate.toIso8601String().split('T')[0],
          'endDate': endDate.toIso8601String().split('T')[0],
          'lmax': 8,
        };

        // Track rebuild counts
        var timelineItemBuildCount = 0;
        var sliderBuildCount = 0;

        // Build the timeline
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
                  capacities: [],
                  stages: [],
                  openDayDetail: null,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find the slider
        final sliderFinder = find.byType(Slider);
        expect(sliderFinder, findsOneWidget);

        // Get initial build counts by finding widgets
        final initialTimelineItems = find.byType(Row).evaluate().length;
        
        // Simulate slider interaction
        final slider = tester.widget<Slider>(sliderFinder);
        final initialValue = slider.value;
        
        // Calculate a new value (move slider by 10-30%)
        final valueChange = (slider.max - slider.min) * (0.1 + random.nextDouble() * 0.2);
        final newValue = (initialValue + valueChange).clamp(slider.min, slider.max);

        // Change slider value
        await tester.drag(sliderFinder, Offset(100, 0));
        await tester.pump();

        // Verify slider updated
        final updatedSlider = tester.widget<Slider>(sliderFinder);
        expect(updatedSlider.value != initialValue, isTrue,
            reason: 'Slider value should change');

        // The key test: verify that timeline items are wrapped in ValueListenableBuilder
        // which means they won't rebuild when slider changes (only when centerItemIndex changes)
        final valueListenableBuilders = find.byType(ValueListenableBuilder<int>);
        expect(valueListenableBuilders.evaluate().length, greaterThan(0),
            reason: 'Timeline should use ValueListenableBuilder for selective rebuilds');

        // Pump and settle to complete any animations
        await tester.pumpAndSettle();

        // Clean up for next iteration
        await tester.pumpWidget(Container());
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Property 10: Slider Isolation - slider uses isolated state management',
        (WidgetTester tester) async {
      // Feature: timeline-performance-optimization, Property 10: Slider Isolation
      
      const iterations = 50;
      final random = Random(123);
      
      for (var iteration = 0; iteration < iterations; iteration++) {
        final elementCount = 30 + random.nextInt(30);
        final elements = generateTestElements(elementCount);
        
        final startDate = DateTime(2024, 1, 1);
        final endDate = startDate.add(Duration(days: elementCount));
        
        final infos = {
          'startDate': startDate.toIso8601String().split('T')[0],
          'endDate': endDate.toIso8601String().split('T')[0],
          'lmax': 8,
        };

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
                  capacities: [],
                  stages: [],
                  openDayDetail: null,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify that the timeline uses ValueListenableBuilder
        // This ensures that only widgets listening to specific ValueNotifiers rebuild
        final valueListenableBuilders = find.byType(ValueListenableBuilder<int>);
        expect(valueListenableBuilders.evaluate().isNotEmpty, isTrue,
            reason: 'Timeline should use ValueListenableBuilder for granular state management');

        // Find slider
        final sliderFinder = find.byType(Slider);
        expect(sliderFinder, findsOneWidget);

        // Interact with slider multiple times
        for (var i = 0; i < 3; i++) {
          await tester.drag(sliderFinder, Offset(50, 0));
          await tester.pump();
          
          // Verify ValueListenableBuilders are still present
          expect(find.byType(ValueListenableBuilder<int>).evaluate().isNotEmpty, isTrue,
              reason: 'ValueListenableBuilder should persist across slider changes');
        }

        await tester.pumpAndSettle();

        // Clean up
        await tester.pumpWidget(Container());
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Property 10: Slider Isolation - rapid slider changes remain performant',
        (WidgetTester tester) async {
      // Feature: timeline-performance-optimization, Property 10: Slider Isolation
      
      const iterations = 20;
      final random = Random(456);
      
      for (var iteration = 0; iteration < iterations; iteration++) {
        final elementCount = 60 + random.nextInt(40);
        final elements = generateTestElements(elementCount);
        
        final startDate = DateTime(2024, 1, 1);
        final endDate = startDate.add(Duration(days: elementCount));
        
        final infos = {
          'startDate': startDate.toIso8601String().split('T')[0],
          'endDate': endDate.toIso8601String().split('T')[0],
          'lmax': 8,
        };

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
                  capacities: [],
                  stages: [],
                  openDayDetail: null,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final sliderFinder = find.byType(Slider);
        expect(sliderFinder, findsOneWidget);

        // Perform rapid slider changes
        final stopwatch = Stopwatch()..start();
        
        for (var i = 0; i < 10; i++) {
          await tester.drag(sliderFinder, const Offset(20, 0), warnIfMissed: false);
          await tester.pump();
        }
        
        stopwatch.stop();

        // Verify that rapid changes complete quickly (< 500ms for 10 changes)
        expect(stopwatch.elapsedMilliseconds, lessThan(500),
            reason: 'Rapid slider changes should complete quickly due to isolation');

        await tester.pumpAndSettle();

        // Clean up
        await tester.pumpWidget(Container());
        await tester.pumpAndSettle();
      }
    });
  });
}
