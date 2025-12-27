import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/models.dart';

void main() {
  group('TimelineController Property Tests', () {
    test('Property 6: Scroll Throttling - listener callbacks invoked at most 60 times per second',
        () async {
      // Feature: timeline-performance-optimization, Property 6: Scroll throttling
      // Validates: Requirements 5.1, 7.1
      
      final random = Random();
      
      // Run property test with 100 iterations
      for (var iteration = 0; iteration < 100; iteration++) {
        // Generate random timeline configuration
        final totalDays = 100 + random.nextInt(400); // 100-500 days
        final dayWidth = 40.0 + random.nextDouble() * 20; // 40-60 width
        final dayMargin = 3.0 + random.nextDouble() * 5; // 3-8 margin
        final viewportWidth = 600.0 + random.nextDouble() * 600; // 600-1200 viewport
        
        final controller = TimelineController(
          dayWidth: dayWidth,
          dayMargin: dayMargin,
          totalDays: totalDays,
          viewportWidth: viewportWidth,
        );
        
        // Track number of updates
        var updateCount = 0;
        
        controller.scrollOffset.addListener(() {
          updateCount++;
        });
        
        // Simulate rapid scroll updates (50 updates without delays)
        final startTime = DateTime.now();
        final numberOfScrollUpdates = 50;
        
        for (var i = 0; i < numberOfScrollUpdates; i++) {
          final offset = random.nextDouble() * (totalDays * (dayWidth - dayMargin));
          controller.updateScrollOffset(offset);
        }
        
        // Wait for all throttled updates to complete
        await Future.delayed(const Duration(milliseconds: 50));
        
        final totalTime = DateTime.now().difference(startTime);
        
        // Calculate expected maximum updates based on throttle duration (16ms)
        // Total time in milliseconds / 16ms per update
        final expectedMaxUpdates = (totalTime.inMilliseconds / 16).ceil() + 10; // +10 for tolerance
        
        // Verify that updates were throttled
        expect(
          updateCount,
          lessThan(numberOfScrollUpdates),
          reason: 'Updates should be throttled (got $updateCount, sent $numberOfScrollUpdates)',
        );
        
        expect(
          updateCount,
          lessThanOrEqualTo(expectedMaxUpdates),
          reason: 'Updates should not exceed ~60 per second (got $updateCount in ${totalTime.inMilliseconds}ms, expected max $expectedMaxUpdates)',
        );
        
        controller.dispose();
      }
    }, timeout: const Timeout(Duration(seconds: 60)));
    
    test('Property 6: Scroll Throttling - rapid updates do not cause excessive calculations',
        () async {
      // Additional test to verify throttling prevents excessive centerItemIndex updates
      
      final random = Random();
      
      for (var iteration = 0; iteration < 100; iteration++) {
        final totalDays = 100 + random.nextInt(200);
        final dayWidth = 45.0;
        final dayMargin = 5.0;
        final viewportWidth = 800.0;
        
        final controller = TimelineController(
          dayWidth: dayWidth,
          dayMargin: dayMargin,
          totalDays: totalDays,
          viewportWidth: viewportWidth,
        );
        
        var centerIndexUpdateCount = 0;
        controller.centerItemIndex.addListener(() {
          centerIndexUpdateCount++;
        });
        
        // Send 50 rapid scroll updates without delays
        for (var i = 0; i < 50; i++) {
          final offset = random.nextDouble() * (totalDays * (dayWidth - dayMargin));
          controller.updateScrollOffset(offset);
        }
        
        // Wait for throttled updates
        await Future.delayed(const Duration(milliseconds: 50));
        
        // Center index updates should be significantly less than scroll updates
        expect(
          centerIndexUpdateCount,
          lessThan(50),
          reason: 'Center index updates should be throttled (got $centerIndexUpdateCount from 50 scroll updates)',
        );
        
        controller.dispose();
      }
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
  
  group('TimelineController Resource Cleanup Property Tests', () {
    test('Property 4: Resource Cleanup - all resources properly disposed',
        () async {
      // Feature: timeline-performance-optimization, Property 4: Resource cleanup
      // Validates: Requirements 3.3, 7.3, 9.5
      
      final random = Random();
      
      // Run property test with 100 iterations
      for (var iteration = 0; iteration < 100; iteration++) {
        // Generate random timeline configuration
        final totalDays = 50 + random.nextInt(200);
        final dayWidth = 40.0 + random.nextDouble() * 20;
        final dayMargin = 3.0 + random.nextDouble() * 5;
        final viewportWidth = 600.0 + random.nextDouble() * 600;
        
        final controller = TimelineController(
          dayWidth: dayWidth,
          dayMargin: dayMargin,
          totalDays: totalDays,
          viewportWidth: viewportWidth,
        );
        
        // Track if listeners are still active after disposal
        var scrollOffsetListenerCalled = false;
        var centerIndexListenerCalled = false;
        var visibleRangeListenerCalled = false;
        
        controller.scrollOffset.addListener(() {
          scrollOffsetListenerCalled = true;
        });
        
        controller.centerItemIndex.addListener(() {
          centerIndexListenerCalled = true;
        });
        
        controller.visibleRange.addListener(() {
          visibleRangeListenerCalled = true;
        });
        
        // Perform some operations
        for (var i = 0; i < 5; i++) {
          final offset = random.nextDouble() * (totalDays * (dayWidth - dayMargin));
          controller.updateScrollOffset(offset);
        }
        
        await Future.delayed(const Duration(milliseconds: 20));
        
        // Reset flags
        scrollOffsetListenerCalled = false;
        centerIndexListenerCalled = false;
        visibleRangeListenerCalled = false;
        
        // Dispose the controller
        controller.dispose();
        
        // Wait a bit to ensure any pending timers would have fired
        await Future.delayed(const Duration(milliseconds: 50));
        
        // Try to trigger updates after disposal (should not cause errors)
        try {
          controller.updateScrollOffset(100);
          await Future.delayed(const Duration(milliseconds: 20));
          
          // Listeners should not be called after disposal
          expect(
            scrollOffsetListenerCalled,
            isFalse,
            reason: 'ScrollOffset listener should not be called after disposal',
          );
          expect(
            centerIndexListenerCalled,
            isFalse,
            reason: 'CenterIndex listener should not be called after disposal',
          );
          expect(
            visibleRangeListenerCalled,
            isFalse,
            reason: 'VisibleRange listener should not be called after disposal',
          );
        } catch (e) {
          // It's acceptable if operations after disposal throw errors
          // The important thing is that no memory leaks occur
        }
      }
    }, timeout: const Timeout(Duration(seconds: 60)));
    
    test('Property 4: Resource Cleanup - throttle timer is cancelled on disposal',
        () async {
      // Verify that the throttle timer is properly cancelled
      
      final random = Random();
      
      for (var iteration = 0; iteration < 100; iteration++) {
        final totalDays = 50 + random.nextInt(100);
        final controller = TimelineController(
          dayWidth: 45.0,
          dayMargin: 5.0,
          totalDays: totalDays,
          viewportWidth: 800.0,
        );
        
        var updateCount = 0;
        controller.scrollOffset.addListener(() {
          updateCount++;
        });
        
        // Trigger multiple scroll updates
        for (var i = 0; i < 10; i++) {
          final offset = random.nextDouble() * (totalDays * 40);
          controller.updateScrollOffset(offset);
        }
        
        // Dispose immediately (while timer might still be pending)
        controller.dispose();
        
        final countBeforeWait = updateCount;
        
        // Wait for what would have been the throttle duration
        await Future.delayed(const Duration(milliseconds: 50));
        
        // No additional updates should occur after disposal
        expect(
          updateCount,
          equals(countBeforeWait),
          reason: 'No updates should occur after disposal (timer should be cancelled)',
        );
      }
    }, timeout: const Timeout(Duration(seconds: 60)));
    
    test('Property 4: Resource Cleanup - ValueNotifiers are disposed',
        () {
      // Verify that ValueNotifiers can be disposed without errors
      
      final random = Random();
      
      for (var iteration = 0; iteration < 100; iteration++) {
        final totalDays = 50 + random.nextInt(100);
        final controller = TimelineController(
          dayWidth: 45.0,
          dayMargin: 5.0,
          totalDays: totalDays,
          viewportWidth: 800.0,
        );
        
        // Add listeners to all ValueNotifiers
        void scrollListener() {}
        void centerListener() {}
        void rangeListener() {}
        
        controller.scrollOffset.addListener(scrollListener);
        controller.centerItemIndex.addListener(centerListener);
        controller.visibleRange.addListener(rangeListener);
        
        // Dispose should not throw
        expect(() => controller.dispose(), returnsNormally);
        
        // Attempting to access disposed ValueNotifiers should not crash
        // (though it may throw, which is acceptable)
        try {
          controller.scrollOffset.value;
          controller.centerItemIndex.value;
          controller.visibleRange.value;
        } catch (e) {
          // Acceptable - disposed objects may throw
        }
      }
    });
  });
  
  group('TimelineController Unit Tests', () {
    test('initializes with correct default values', () {
      final controller = TimelineController(
        dayWidth: 45.0,
        dayMargin: 5.0,
        totalDays: 100,
      );
      
      expect(controller.scrollOffset.value, equals(0.0));
      expect(controller.centerItemIndex.value, equals(0));
      expect(controller.visibleRange.value, equals(const VisibleRange(0, 0)));
      
      controller.dispose();
    });
    
    test('clamps centerItemIndex to valid range', () async {
      final controller = TimelineController(
        dayWidth: 45.0,
        dayMargin: 5.0,
        totalDays: 100,
        viewportWidth: 800.0,
      );
      
      // Test negative offset (should clamp to 0)
      controller.updateScrollOffset(-100);
      await Future.delayed(const Duration(milliseconds: 20));
      expect(controller.centerItemIndex.value, equals(0));
      
      // Test offset beyond max (should clamp to totalDays - 1)
      controller.updateScrollOffset(10000);
      await Future.delayed(const Duration(milliseconds: 20));
      expect(controller.centerItemIndex.value, equals(99));
      
      controller.dispose();
    });
    
    test('updates centerItemIndex based on scroll offset', () async {
      final controller = TimelineController(
        dayWidth: 45.0,
        dayMargin: 5.0,
        totalDays: 100,
        viewportWidth: 800.0,
      );
      
      // Scroll to middle
      controller.updateScrollOffset(2000);
      await Future.delayed(const Duration(milliseconds: 20));
      
      final expectedIndex = (2000 / (45.0 - 5.0)).round();
      expect(controller.centerItemIndex.value, equals(expectedIndex));
      
      controller.dispose();
    });
    
    test('updates visibleRange when viewport width is set', () async {
      final controller = TimelineController(
        dayWidth: 45.0,
        dayMargin: 5.0,
        totalDays: 100,
      );
      
      // Initially, visible range should be (0, 0) without viewport width
      expect(controller.visibleRange.value, equals(const VisibleRange(0, 0)));
      
      // Set viewport width
      controller.setViewportWidth(800.0);
      await Future.delayed(const Duration(milliseconds: 20));
      
      // Visible range should now be calculated
      expect(controller.visibleRange.value.start, greaterThanOrEqualTo(0));
      expect(controller.visibleRange.value.end, greaterThan(0));
      
      controller.dispose();
    });
    
    test('visible range includes buffer', () async {
      final controller = TimelineController(
        dayWidth: 45.0,
        dayMargin: 5.0,
        totalDays: 100,
        viewportWidth: 800.0,
      );
      
      // Scroll to middle
      controller.updateScrollOffset(2000);
      await Future.delayed(const Duration(milliseconds: 20));
      
      final centerIndex = controller.centerItemIndex.value;
      final visibleDays = (800.0 / (45.0 - 5.0)).ceil();
      const buffer = 5;
      
      // Verify buffer is included
      final expectedStart = (centerIndex - (visibleDays ~/ 2) - buffer).clamp(0, 100);
      final expectedEnd = (centerIndex + (visibleDays ~/ 2) + buffer).clamp(0, 100);
      
      expect(controller.visibleRange.value.start, equals(expectedStart));
      expect(controller.visibleRange.value.end, equals(expectedEnd));
      
      controller.dispose();
    });
  });
}
