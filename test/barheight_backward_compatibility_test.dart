import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/timeline_configuration.dart';

void main() {
  group('barHeight Backward Compatibility', () {
    test('TimelineConfiguration without barHeight uses default 70.0', () {
      // Create configuration without specifying barHeight
      const config = TimelineConfiguration();

      expect(config.barHeight, equals(70.0));
    });

    test('TimelineConfiguration.fromMap without barHeight uses default 70.0', () {
      // Load configuration from map without barHeight parameter
      final config = TimelineConfiguration.fromMap({
        'dayWidth': 50.0,
        'bufferDays': 10,
      });

      expect(config.barHeight, equals(70.0));
      expect(config.dayWidth, equals(50.0));
      expect(config.bufferDays, equals(10));
    });

    test('TimelineConfiguration.copyWith without barHeight preserves original', () {
      const original = TimelineConfiguration(barHeight: 100.0);

      final copied = original.copyWith(dayWidth: 60.0);

      expect(copied.barHeight, equals(100.0));
      expect(copied.dayWidth, equals(60.0));
    });

    test('TimelineConfiguration with explicit barHeight uses provided value', () {
      const config = TimelineConfiguration(barHeight: 120.0);

      expect(config.barHeight, equals(120.0));
    });

    test('TimelineConfiguration.fromMap with barHeight uses provided value', () {
      final config = TimelineConfiguration.fromMap({
        'barHeight': 90.0,
        'dayWidth': 50.0,
      });

      expect(config.barHeight, equals(90.0));
      expect(config.dayWidth, equals(50.0));
    });

    test('TimelineConfiguration.toMap includes barHeight', () {
      const config = TimelineConfiguration(barHeight: 85.0);

      final map = config.toMap();

      expect(map['barHeight'], equals(85.0));
    });

    test('TimelineConfiguration equality includes barHeight', () {
      const config1 = TimelineConfiguration(barHeight: 70.0);
      const config2 = TimelineConfiguration(barHeight: 70.0);
      const config3 = TimelineConfiguration(barHeight: 80.0);

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });

    test('TimelineConfiguration hashCode includes barHeight', () {
      const config1 = TimelineConfiguration(barHeight: 70.0);
      const config2 = TimelineConfiguration(barHeight: 70.0);
      const config3 = TimelineConfiguration(barHeight: 80.0);

      expect(config1.hashCode, equals(config2.hashCode));
      expect(config1.hashCode, isNot(equals(config3.hashCode)));
    });

    test('TimelineConfiguration.toString includes barHeight', () {
      const config = TimelineConfiguration(barHeight: 95.0);

      final str = config.toString();

      expect(str, contains('barHeight: 95.0'));
    });
  });
}
