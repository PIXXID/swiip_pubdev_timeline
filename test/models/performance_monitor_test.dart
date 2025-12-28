import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/performance_monitor.dart';

void main() {
  group('PerformanceMonitor', () {
    late PerformanceMonitor monitor;

    setUp(() {
      monitor = PerformanceMonitor(profilingEnabled: true);
    });

    group('Operation Tracking', () {
      test('startOperation records operation start time', () {
        monitor.startOperation('test_operation');

        // Operation should be tracked
        expect(monitor.getOperationDuration('test_operation'), isNull,
            reason: 'Operation not yet completed');
      });

      test('endOperation returns duration and records it', () {
        monitor.startOperation('test_operation');

        // Simulate some work
        Future.delayed(const Duration(milliseconds: 10));

        final duration = monitor.endOperation('test_operation');

        expect(duration, isNotNull);
        expect(duration!.inMicroseconds, greaterThan(0));
        expect(
            monitor.getOperationDuration('test_operation'), equals(duration));
      });

      test('endOperation without startOperation returns null', () {
        final duration = monitor.endOperation('nonexistent_operation');

        expect(duration, isNull);
      });

      test('multiple operations can be tracked independently', () {
        monitor.startOperation('operation1');
        monitor.startOperation('operation2');

        final duration1 = monitor.endOperation('operation1');
        final duration2 = monitor.endOperation('operation2');

        expect(duration1, isNotNull);
        expect(duration2, isNotNull);
        expect(monitor.getOperationDuration('operation1'), equals(duration1));
        expect(monitor.getOperationDuration('operation2'), equals(duration2));
      });
    });

    group('Rebuild Tracking', () {
      test('trackRebuild increments rebuild counter', () {
        monitor.trackRebuild();
        monitor.trackRebuild();
        monitor.trackRebuild();

        final metrics = monitor.getMetrics();
        expect(metrics.rebuildCount, equals(3));
      });

      test('rebuild count starts at zero', () {
        final metrics = monitor.getMetrics();
        expect(metrics.rebuildCount, equals(0));
      });
    });

    group('Widget Count Tracking', () {
      test('trackWidgetCount accumulates widget counts', () {
        monitor.trackWidgetCount(10);
        monitor.trackWidgetCount(5);
        monitor.trackWidgetCount(3);

        final metrics = monitor.getMetrics();
        expect(metrics.widgetCount, equals(18));
      });

      test('widget count starts at zero', () {
        final metrics = monitor.getMetrics();
        expect(metrics.widgetCount, equals(0));
      });
    });

    group('Frame Time Tracking', () {
      test('recordFrameTime stores frame times', () {
        monitor.recordFrameTime(const Duration(milliseconds: 16));
        monitor.recordFrameTime(const Duration(milliseconds: 17));

        final metrics = monitor.getMetrics();
        expect(metrics.averageFPS, greaterThan(0));
      });

      test('averageFPS is calculated correctly', () {
        // Record consistent 60 FPS frame times (16.67ms per frame)
        for (int i = 0; i < 10; i++) {
          monitor.recordFrameTime(const Duration(microseconds: 16667));
        }

        final metrics = monitor.getMetrics();
        // Should be approximately 60 FPS
        expect(metrics.averageFPS, closeTo(60.0, 1.0));
      });

      test('keeps only last 60 frame times', () {
        // Record more than 60 frames
        for (int i = 0; i < 100; i++) {
          monitor.recordFrameTime(const Duration(milliseconds: 16));
        }

        // Should still calculate FPS correctly
        final metrics = monitor.getMetrics();
        expect(metrics.averageFPS, greaterThan(0));
      });
    });

    group('Memory Usage Tracking', () {
      test('recordMemoryUsage stores memory samples', () {
        monitor.recordMemoryUsage(50.5);
        monitor.recordMemoryUsage(52.3);

        final metrics = monitor.getMetrics();
        expect(metrics.memoryUsageMB, greaterThan(0));
      });

      test('averages memory usage correctly', () {
        monitor.recordMemoryUsage(50.0);
        monitor.recordMemoryUsage(60.0);

        final metrics = monitor.getMetrics();
        expect(metrics.memoryUsageMB, equals(55.0));
      });

      test('keeps only last 10 memory samples', () {
        // Record more than 10 samples
        for (int i = 0; i < 20; i++) {
          monitor.recordMemoryUsage(50.0 + i);
        }

        // Should still calculate average correctly
        final metrics = monitor.getMetrics();
        expect(metrics.memoryUsageMB, greaterThan(0));
      });
    });

    group('Metrics Retrieval', () {
      test('getMetrics returns complete metrics object', () {
        monitor.startOperation('test_op');
        monitor.endOperation('test_op');
        monitor.trackRebuild();
        monitor.trackWidgetCount(10);
        monitor.recordFrameTime(const Duration(milliseconds: 16));
        monitor.recordMemoryUsage(50.0);

        final metrics = monitor.getMetrics();

        expect(metrics.renderTime, isNotNull);
        expect(metrics.widgetCount, equals(10));
        expect(metrics.rebuildCount, equals(1));
        expect(metrics.memoryUsageMB, equals(50.0));
        expect(metrics.averageFPS, greaterThan(0));
      });

      test('getMetrics with no data returns default values', () {
        final metrics = monitor.getMetrics();

        expect(metrics.renderTime, equals(Duration.zero));
        expect(metrics.widgetCount, equals(0));
        expect(metrics.rebuildCount, equals(0));
        expect(metrics.memoryUsageMB, equals(0.0));
        expect(metrics.averageFPS, equals(60.0)); // Default FPS
      });
    });

    group('Reset Functionality', () {
      test('reset clears all metrics', () {
        monitor.startOperation('test_op');
        monitor.endOperation('test_op');
        monitor.trackRebuild();
        monitor.trackWidgetCount(10);
        monitor.recordFrameTime(const Duration(milliseconds: 16));
        monitor.recordMemoryUsage(50.0);

        monitor.reset();

        final metrics = monitor.getMetrics();
        expect(metrics.renderTime, equals(Duration.zero));
        expect(metrics.widgetCount, equals(0));
        expect(metrics.rebuildCount, equals(0));
        expect(metrics.memoryUsageMB, equals(0.0));
        expect(monitor.getOperationDuration('test_op'), isNull);
      });
    });

    group('Profiling Enabled/Disabled', () {
      test('operations are tracked when profiling is enabled', () {
        final enabledMonitor = PerformanceMonitor(profilingEnabled: true);
        enabledMonitor.startOperation('test');
        final duration = enabledMonitor.endOperation('test');

        expect(duration, isNotNull);
      });

      test('operations are not tracked when profiling is disabled', () {
        final disabledMonitor = PerformanceMonitor(profilingEnabled: false);
        disabledMonitor.startOperation('test');
        final duration = disabledMonitor.endOperation('test');

        expect(duration, isNull);
      });

      test('trackRebuild does nothing when profiling is disabled', () {
        final disabledMonitor = PerformanceMonitor(profilingEnabled: false);
        disabledMonitor.trackRebuild();

        final metrics = disabledMonitor.getMetrics();
        expect(metrics.rebuildCount, equals(0));
      });
    });

    group('Profiling Hooks', () {
      test('logMetrics does not throw when called', () {
        monitor.startOperation('test_op');
        monitor.endOperation('test_op');
        monitor.trackRebuild();

        expect(() => monitor.logMetrics(), returnsNormally);
      });

      test('logMetrics works with empty metrics', () {
        expect(() => monitor.logMetrics(), returnsNormally);
      });
    });

    group('Edge Cases', () {
      test('handles zero duration operations', () {
        monitor.startOperation('instant_op');
        final duration = monitor.endOperation('instant_op');

        expect(duration, isNotNull);
        expect(duration!.inMicroseconds, greaterThanOrEqualTo(0));
      });

      test('handles negative widget counts gracefully', () {
        // This shouldn't happen in practice, but test robustness
        monitor.trackWidgetCount(-5);

        final metrics = monitor.getMetrics();
        expect(metrics.widgetCount, equals(-5));
      });

      test('handles zero frame times', () {
        monitor.recordFrameTime(Duration.zero);

        final metrics = monitor.getMetrics();
        // Should not crash or produce NaN
        expect(metrics.averageFPS.isFinite, isTrue);
      });
    });
  });
}
