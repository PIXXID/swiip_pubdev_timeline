import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/timeline_configuration.dart';

void main() {
  group('TimelineConfiguration', () {
    group('constructor', () {
      test('creates instance with default values', () {
        const config = TimelineConfiguration();
        expect(config.dayWidth, equals(45.0));
        expect(config.dayMargin, equals(5.0));
        expect(config.datesHeight, equals(65.0));
        expect(config.timelineHeight, equals(300.0));
        expect(config.rowHeight, equals(30.0));
        expect(config.rowMargin, equals(3.0));
        expect(config.bufferDays, equals(5));
        expect(config.scrollThrottleDuration,
            equals(const Duration(milliseconds: 16)));
        expect(config.animationDuration,
            equals(const Duration(milliseconds: 220)));
      });

      test('creates instance with custom values', () {
        const config = TimelineConfiguration(
          dayWidth: 50.0,
          dayMargin: 10.0,
          datesHeight: 70.0,
          timelineHeight: 400.0,
          rowHeight: 35.0,
          rowMargin: 5.0,
          bufferDays: 10,
          scrollThrottleDuration: Duration(milliseconds: 32),
          animationDuration: Duration(milliseconds: 300),
        );
        expect(config.dayWidth, equals(50.0));
        expect(config.dayMargin, equals(10.0));
        expect(config.datesHeight, equals(70.0));
        expect(config.timelineHeight, equals(400.0));
        expect(config.rowHeight, equals(35.0));
        expect(config.rowMargin, equals(5.0));
        expect(config.bufferDays, equals(10));
        expect(config.scrollThrottleDuration,
            equals(const Duration(milliseconds: 32)));
        expect(config.animationDuration,
            equals(const Duration(milliseconds: 300)));
      });

      test('allows zero values', () {
        const config = TimelineConfiguration(
          dayWidth: 0.0,
          dayMargin: 0.0,
          bufferDays: 0,
        );
        expect(config.dayWidth, equals(0.0));
        expect(config.dayMargin, equals(0.0));
        expect(config.bufferDays, equals(0));
      });

      test('allows negative values', () {
        // Note: The model doesn't enforce positive values, allowing flexibility
        const config = TimelineConfiguration(
          dayWidth: -10.0,
          bufferDays: -5,
        );
        expect(config.dayWidth, equals(-10.0));
        expect(config.bufferDays, equals(-5));
      });
    });

    group('copyWith', () {
      test('returns new instance with updated dayWidth', () {
        const original = TimelineConfiguration();
        final updated = original.copyWith(dayWidth: 60.0);
        expect(updated.dayWidth, equals(60.0));
        expect(updated.dayMargin, equals(original.dayMargin));
        expect(updated.datesHeight, equals(original.datesHeight));
      });

      test('returns new instance with updated dayMargin', () {
        const original = TimelineConfiguration();
        final updated = original.copyWith(dayMargin: 8.0);
        expect(updated.dayMargin, equals(8.0));
        expect(updated.dayWidth, equals(original.dayWidth));
      });

      test('returns new instance with updated datesHeight', () {
        const original = TimelineConfiguration();
        final updated = original.copyWith(datesHeight: 80.0);
        expect(updated.datesHeight, equals(80.0));
        expect(updated.dayWidth, equals(original.dayWidth));
      });

      test('returns new instance with updated timelineHeight', () {
        const original = TimelineConfiguration();
        final updated = original.copyWith(timelineHeight: 500.0);
        expect(updated.timelineHeight, equals(500.0));
        expect(updated.dayWidth, equals(original.dayWidth));
      });

      test('returns new instance with updated rowHeight', () {
        const original = TimelineConfiguration();
        final updated = original.copyWith(rowHeight: 40.0);
        expect(updated.rowHeight, equals(40.0));
        expect(updated.dayWidth, equals(original.dayWidth));
      });

      test('returns new instance with updated rowMargin', () {
        const original = TimelineConfiguration();
        final updated = original.copyWith(rowMargin: 6.0);
        expect(updated.rowMargin, equals(6.0));
        expect(updated.dayWidth, equals(original.dayWidth));
      });

      test('returns new instance with updated bufferDays', () {
        const original = TimelineConfiguration();
        final updated = original.copyWith(bufferDays: 15);
        expect(updated.bufferDays, equals(15));
        expect(updated.dayWidth, equals(original.dayWidth));
      });

      test('returns new instance with updated scrollThrottleDuration', () {
        const original = TimelineConfiguration();
        final updated = original.copyWith(
          scrollThrottleDuration: const Duration(milliseconds: 50),
        );
        expect(updated.scrollThrottleDuration,
            equals(const Duration(milliseconds: 50)));
        expect(updated.dayWidth, equals(original.dayWidth));
      });

      test('returns new instance with updated animationDuration', () {
        const original = TimelineConfiguration();
        final updated = original.copyWith(
          animationDuration: const Duration(milliseconds: 400),
        );
        expect(updated.animationDuration,
            equals(const Duration(milliseconds: 400)));
        expect(updated.dayWidth, equals(original.dayWidth));
      });

      test('returns new instance with multiple updated fields', () {
        const original = TimelineConfiguration();
        final updated = original.copyWith(
          dayWidth: 55.0,
          dayMargin: 7.0,
          bufferDays: 8,
          animationDuration: const Duration(milliseconds: 250),
        );
        expect(updated.dayWidth, equals(55.0));
        expect(updated.dayMargin, equals(7.0));
        expect(updated.bufferDays, equals(8));
        expect(updated.animationDuration,
            equals(const Duration(milliseconds: 250)));
        expect(updated.datesHeight, equals(original.datesHeight));
        expect(updated.timelineHeight, equals(original.timelineHeight));
      });

      test('returns new instance when no fields are updated', () {
        const original = TimelineConfiguration();
        final updated = original.copyWith();
        expect(updated.dayWidth, equals(original.dayWidth));
        expect(updated.dayMargin, equals(original.dayMargin));
        expect(updated.datesHeight, equals(original.datesHeight));
        expect(updated.timelineHeight, equals(original.timelineHeight));
        expect(updated.rowHeight, equals(original.rowHeight));
        expect(updated.rowMargin, equals(original.rowMargin));
        expect(updated.bufferDays, equals(original.bufferDays));
        expect(updated.scrollThrottleDuration,
            equals(original.scrollThrottleDuration));
        expect(updated.animationDuration, equals(original.animationDuration));
      });

      test('does not modify original instance', () {
        const original = TimelineConfiguration(dayWidth: 45.0);
        final updated = original.copyWith(dayWidth: 60.0);
        expect(original.dayWidth, equals(45.0));
        expect(updated.dayWidth, equals(60.0));
      });
    });

    group('equality', () {
      test('returns true for identical configurations', () {
        const config1 = TimelineConfiguration();
        const config2 = TimelineConfiguration();
        expect(config1, equals(config2));
      });

      test('returns true for configurations with same custom values', () {
        const config1 = TimelineConfiguration(
          dayWidth: 50.0,
          dayMargin: 10.0,
          bufferDays: 8,
        );
        const config2 = TimelineConfiguration(
          dayWidth: 50.0,
          dayMargin: 10.0,
          bufferDays: 8,
        );
        expect(config1, equals(config2));
      });

      test('returns false for different dayWidth', () {
        const config1 = TimelineConfiguration(dayWidth: 45.0);
        const config2 = TimelineConfiguration(dayWidth: 50.0);
        expect(config1, isNot(equals(config2)));
      });

      test('returns false for different dayMargin', () {
        const config1 = TimelineConfiguration(dayMargin: 5.0);
        const config2 = TimelineConfiguration(dayMargin: 10.0);
        expect(config1, isNot(equals(config2)));
      });

      test('returns false for different bufferDays', () {
        const config1 = TimelineConfiguration(bufferDays: 5);
        const config2 = TimelineConfiguration(bufferDays: 10);
        expect(config1, isNot(equals(config2)));
      });

      test('returns false for different scrollThrottleDuration', () {
        const config1 = TimelineConfiguration(
          scrollThrottleDuration: Duration(milliseconds: 16),
        );
        const config2 = TimelineConfiguration(
          scrollThrottleDuration: Duration(milliseconds: 32),
        );
        expect(config1, isNot(equals(config2)));
      });

      test('returns true for same instance', () {
        const config = TimelineConfiguration();
        expect(config, equals(config));
      });
    });

    group('hashCode', () {
      test('returns same hashCode for equal configurations', () {
        const config1 = TimelineConfiguration();
        const config2 = TimelineConfiguration();
        expect(config1.hashCode, equals(config2.hashCode));
      });

      test('returns same hashCode for configurations with same custom values',
          () {
        const config1 = TimelineConfiguration(
          dayWidth: 50.0,
          bufferDays: 8,
        );
        const config2 = TimelineConfiguration(
          dayWidth: 50.0,
          bufferDays: 8,
        );
        expect(config1.hashCode, equals(config2.hashCode));
      });

      test('returns different hashCode for different configurations', () {
        const config1 = TimelineConfiguration(dayWidth: 45.0);
        const config2 = TimelineConfiguration(dayWidth: 50.0);
        expect(config1.hashCode, isNot(equals(config2.hashCode)));
      });
    });

    group('toString', () {
      test('returns formatted string representation with default values', () {
        const config = TimelineConfiguration();
        final str = config.toString();
        expect(str, contains('TimelineConfiguration'));
        expect(str, contains('dayWidth: 45.0'));
        expect(str, contains('dayMargin: 5.0'));
        expect(str, contains('datesHeight: 65.0'));
        expect(str, contains('timelineHeight: 300.0'));
        expect(str, contains('rowHeight: 30.0'));
        expect(str, contains('rowMargin: 3.0'));
        expect(str, contains('bufferDays: 5'));
        expect(str, contains('scrollThrottleDuration: 0:00:00.016000'));
        expect(str, contains('animationDuration: 0:00:00.220000'));
      });

      test('returns formatted string representation with custom values', () {
        const config = TimelineConfiguration(
          dayWidth: 60.0,
          bufferDays: 10,
        );
        final str = config.toString();
        expect(str, contains('dayWidth: 60.0'));
        expect(str, contains('bufferDays: 10'));
      });
    });
  });
}
