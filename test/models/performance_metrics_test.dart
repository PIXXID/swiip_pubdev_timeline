import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/performance_metrics.dart';

void main() {
  group('PerformanceMetrics', () {
    group('constructor', () {
      test('creates instance with given values', () {
        const metrics = PerformanceMetrics(
          renderTime: Duration(milliseconds: 250),
          widgetCount: 150,
          rebuildCount: 5,
          memoryUsageMB: 12.5,
          averageFPS: 58.3,
        );
        expect(metrics.renderTime, equals(const Duration(milliseconds: 250)));
        expect(metrics.widgetCount, equals(150));
        expect(metrics.rebuildCount, equals(5));
        expect(metrics.memoryUsageMB, equals(12.5));
        expect(metrics.averageFPS, equals(58.3));
      });

      test('allows zero values', () {
        const metrics = PerformanceMetrics(
          renderTime: Duration.zero,
          widgetCount: 0,
          rebuildCount: 0,
          memoryUsageMB: 0.0,
          averageFPS: 0.0,
        );
        expect(metrics.renderTime, equals(Duration.zero));
        expect(metrics.widgetCount, equals(0));
        expect(metrics.rebuildCount, equals(0));
        expect(metrics.memoryUsageMB, equals(0.0));
        expect(metrics.averageFPS, equals(0.0));
      });

      test('allows negative values', () {
        // Note: The model doesn't enforce positive values, allowing flexibility
        const metrics = PerformanceMetrics(
          renderTime: Duration(milliseconds: -100),
          widgetCount: -5,
          rebuildCount: -2,
          memoryUsageMB: -1.0,
          averageFPS: -10.0,
        );
        expect(metrics.renderTime, equals(const Duration(milliseconds: -100)));
        expect(metrics.widgetCount, equals(-5));
        expect(metrics.rebuildCount, equals(-2));
        expect(metrics.memoryUsageMB, equals(-1.0));
        expect(metrics.averageFPS, equals(-10.0));
      });

      test('handles large values', () {
        const metrics = PerformanceMetrics(
          renderTime: Duration(seconds: 10),
          widgetCount: 10000,
          rebuildCount: 1000,
          memoryUsageMB: 1024.0,
          averageFPS: 120.0,
        );
        expect(metrics.renderTime, equals(const Duration(seconds: 10)));
        expect(metrics.widgetCount, equals(10000));
        expect(metrics.rebuildCount, equals(1000));
        expect(metrics.memoryUsageMB, equals(1024.0));
        expect(metrics.averageFPS, equals(120.0));
      });

      test('handles fractional values', () {
        const metrics = PerformanceMetrics(
          renderTime: Duration(microseconds: 1500),
          widgetCount: 100,
          rebuildCount: 3,
          memoryUsageMB: 0.125,
          averageFPS: 59.97,
        );
        expect(metrics.renderTime, equals(const Duration(microseconds: 1500)));
        expect(metrics.memoryUsageMB, equals(0.125));
        expect(metrics.averageFPS, equals(59.97));
      });
    });

    group('equality', () {
      test('returns true for identical metrics', () {
        const metrics1 = PerformanceMetrics(
          renderTime: Duration(milliseconds: 250),
          widgetCount: 150,
          rebuildCount: 5,
          memoryUsageMB: 12.5,
          averageFPS: 58.3,
        );
        const metrics2 = PerformanceMetrics(
          renderTime: Duration(milliseconds: 250),
          widgetCount: 150,
          rebuildCount: 5,
          memoryUsageMB: 12.5,
          averageFPS: 58.3,
        );
        expect(metrics1, equals(metrics2));
      });

      test('returns false for different renderTime', () {
        const metrics1 = PerformanceMetrics(
          renderTime: Duration(milliseconds: 250),
          widgetCount: 150,
          rebuildCount: 5,
          memoryUsageMB: 12.5,
          averageFPS: 58.3,
        );
        const metrics2 = PerformanceMetrics(
          renderTime: Duration(milliseconds: 300),
          widgetCount: 150,
          rebuildCount: 5,
          memoryUsageMB: 12.5,
          averageFPS: 58.3,
        );
        expect(metrics1, isNot(equals(metrics2)));
      });

      test('returns false for different widgetCount', () {
        const metrics1 = PerformanceMetrics(
          renderTime: Duration(milliseconds: 250),
          widgetCount: 150,
          rebuildCount: 5,
          memoryUsageMB: 12.5,
          averageFPS: 58.3,
        );
        const metrics2 = PerformanceMetrics(
          renderTime: Duration(milliseconds: 250),
          widgetCount: 200,
          rebuildCount: 5,
          memoryUsageMB: 12.5,
          averageFPS: 58.3,
        );
        expect(metrics1, isNot(equals(metrics2)));
      });

      test('returns false for different rebuildCount', () {
        const metrics1 = PerformanceMetrics(
          renderTime: Duration(milliseconds: 250),
          widgetCount: 150,
          rebuildCount: 5,
          memoryUsageMB: 12.5,
          averageFPS: 58.3,
        );
        const metrics2 = PerformanceMetrics(
          renderTime: Duration(milliseconds: 250),
          widgetCount: 150,
          rebuildCount: 10,
          memoryUsageMB: 12.5,
          averageFPS: 58.3,
        );
        expect(metrics1, isNot(equals(metrics2)));
      });

      test('returns false for different memoryUsageMB', () {
        const metrics1 = PerformanceMetrics(
          renderTime: Duration(milliseconds: 250),
          widgetCount: 150,
          rebuildCount: 5,
          memoryUsageMB: 12.5,
          averageFPS: 58.3,
        );
        const metrics2 = PerformanceMetrics(
          renderTime: Duration(milliseconds: 250),
          widgetCount: 150,
          rebuildCount: 5,
          memoryUsageMB: 15.0,
          averageFPS: 58.3,
        );
        expect(metrics1, isNot(equals(metrics2)));
      });

      test('returns false for different averageFPS', () {
        const metrics1 = PerformanceMetrics(
          renderTime: Duration(milliseconds: 250),
          widgetCount: 150,
          rebuildCount: 5,
          memoryUsageMB: 12.5,
          averageFPS: 58.3,
        );
        const metrics2 = PerformanceMetrics(
          renderTime: Duration(milliseconds: 250),
          widgetCount: 150,
          rebuildCount: 5,
          memoryUsageMB: 12.5,
          averageFPS: 60.0,
        );
        expect(metrics1, isNot(equals(metrics2)));
      });

      test('returns true for same instance', () {
        const metrics = PerformanceMetrics(
          renderTime: Duration(milliseconds: 250),
          widgetCount: 150,
          rebuildCount: 5,
          memoryUsageMB: 12.5,
          averageFPS: 58.3,
        );
        expect(metrics, equals(metrics));
      });
    });

    group('hashCode', () {
      test('returns same hashCode for equal metrics', () {
        const metrics1 = PerformanceMetrics(
          renderTime: Duration(milliseconds: 250),
          widgetCount: 150,
          rebuildCount: 5,
          memoryUsageMB: 12.5,
          averageFPS: 58.3,
        );
        const metrics2 = PerformanceMetrics(
          renderTime: Duration(milliseconds: 250),
          widgetCount: 150,
          rebuildCount: 5,
          memoryUsageMB: 12.5,
          averageFPS: 58.3,
        );
        expect(metrics1.hashCode, equals(metrics2.hashCode));
      });

      test('returns different hashCode for different metrics', () {
        const metrics1 = PerformanceMetrics(
          renderTime: Duration(milliseconds: 250),
          widgetCount: 150,
          rebuildCount: 5,
          memoryUsageMB: 12.5,
          averageFPS: 58.3,
        );
        const metrics2 = PerformanceMetrics(
          renderTime: Duration(milliseconds: 300),
          widgetCount: 200,
          rebuildCount: 10,
          memoryUsageMB: 15.0,
          averageFPS: 60.0,
        );
        expect(metrics1.hashCode, isNot(equals(metrics2.hashCode)));
      });
    });

    group('toString', () {
      test('returns formatted string representation', () {
        const metrics = PerformanceMetrics(
          renderTime: Duration(milliseconds: 250),
          widgetCount: 150,
          rebuildCount: 5,
          memoryUsageMB: 12.5,
          averageFPS: 58.3,
        );
        final str = metrics.toString();
        expect(str, contains('PerformanceMetrics'));
        expect(str, contains('renderTime: 250ms'));
        expect(str, contains('widgetCount: 150'));
        expect(str, contains('rebuildCount: 5'));
        expect(str, contains('memoryUsage: 12.50MB'));
        expect(str, contains('averageFPS: 58.3'));
      });

      test('formats memory usage with 2 decimal places', () {
        const metrics = PerformanceMetrics(
          renderTime: Duration(milliseconds: 100),
          widgetCount: 50,
          rebuildCount: 2,
          memoryUsageMB: 12.123456,
          averageFPS: 60.0,
        );
        final str = metrics.toString();
        expect(str, contains('memoryUsage: 12.12MB'));
      });

      test('formats FPS with 1 decimal place', () {
        const metrics = PerformanceMetrics(
          renderTime: Duration(milliseconds: 100),
          widgetCount: 50,
          rebuildCount: 2,
          memoryUsageMB: 10.0,
          averageFPS: 59.987654,
        );
        final str = metrics.toString();
        expect(str, contains('averageFPS: 60.0'));
      });

      test('handles zero values', () {
        const metrics = PerformanceMetrics(
          renderTime: Duration.zero,
          widgetCount: 0,
          rebuildCount: 0,
          memoryUsageMB: 0.0,
          averageFPS: 0.0,
        );
        final str = metrics.toString();
        expect(str, contains('renderTime: 0ms'));
        expect(str, contains('widgetCount: 0'));
        expect(str, contains('rebuildCount: 0'));
        expect(str, contains('memoryUsage: 0.00MB'));
        expect(str, contains('averageFPS: 0.0'));
      });

      test('handles large values', () {
        const metrics = PerformanceMetrics(
          renderTime: Duration(seconds: 5),
          widgetCount: 10000,
          rebuildCount: 1000,
          memoryUsageMB: 1024.0,
          averageFPS: 120.0,
        );
        final str = metrics.toString();
        expect(str, contains('renderTime: 5000ms'));
        expect(str, contains('widgetCount: 10000'));
        expect(str, contains('rebuildCount: 1000'));
        expect(str, contains('memoryUsage: 1024.00MB'));
        expect(str, contains('averageFPS: 120.0'));
      });
    });
  });
}
