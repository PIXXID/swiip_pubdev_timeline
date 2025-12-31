import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/timeline_configuration.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/timeline_configuration_manager.dart';

void main() {
  group('Timeline Backward Compatibility Property Tests', () {
    setUp(() {
      // Reset configuration manager before each test
      TimelineConfigurationManager.reset();
    });

    test('Property 8: Backward Compatibility - Timeline without config uses default values', () {
      // Feature: external-configuration-system, Property 8: Backward Compatibility
      // Validates: Requirements 8.1, 8.3

      // Run property test with 100 iterations
      for (var iteration = 0; iteration < 100; iteration++) {
        // Reset configuration manager for each iteration
        TimelineConfigurationManager.reset();

        // Initialize without any configuration
        // This simulates the previous behavior where no configuration file exists
        TimelineConfigurationManager.initialize();

        // Verify that default configuration values are used
        expect(TimelineConfigurationManager.isInitialized, isTrue);

        final config = TimelineConfigurationManager.configuration;

        // Verify default values match the previous hardcoded values
        expect(config.dayWidth, equals(45.0), reason: 'Default dayWidth should be 45.0');
        expect(config.dayMargin, equals(5.0), reason: 'Default dayMargin should be 5.0');
        expect(config.datesHeight, equals(65.0), reason: 'Default datesHeight should be 65.0');
        expect(config.rowHeight, equals(30.0), reason: 'Default rowHeight should be 30.0');
        expect(config.rowMargin, equals(3.0), reason: 'Default rowMargin should be 3.0');
        expect(config.bufferDays, equals(5), reason: 'Default bufferDays should be 5');
        expect(config.animationDuration, equals(const Duration(milliseconds: 220)),
            reason: 'Default animationDuration should be 220ms');

        // Clean up
        TimelineConfigurationManager.reset();
      }
    });

    test('Property 8: Backward Compatibility - Programmatic configuration overrides defaults', () {
      // Feature: external-configuration-system, Property 8: Backward Compatibility
      // Validates: Requirements 8.1, 8.3

      final random = Random();

      // Run property test with 100 iterations
      for (var iteration = 0; iteration < 100; iteration++) {
        // Reset configuration manager for each iteration
        TimelineConfigurationManager.reset();

        // Generate random configuration values
        final customConfig = TimelineConfiguration(
          dayWidth: 30.0 + random.nextDouble() * 50, // 30-80
          dayMargin: random.nextDouble() * 10, // 0-10
          datesHeight: 50.0 + random.nextDouble() * 40, // 50-90
          rowHeight: 25.0 + random.nextDouble() * 25, // 25-50
          rowMargin: random.nextDouble() * 8, // 0-8
          bufferDays: 1 + random.nextInt(15), // 1-15
          animationDuration: Duration(milliseconds: 150 + random.nextInt(300)), // 150-450ms
        );

        // Initialize with programmatic configuration
        TimelineConfigurationManager.initialize(
          programmaticConfig: customConfig,
        );

        // Verify that the configuration manager uses the programmatic config
        expect(TimelineConfigurationManager.isInitialized, isTrue);

        final config = TimelineConfigurationManager.configuration;

        // Verify custom values are used
        expect(config.dayWidth, equals(customConfig.dayWidth), reason: 'dayWidth should match programmatic config');
        expect(config.dayMargin, equals(customConfig.dayMargin), reason: 'dayMargin should match programmatic config');
        expect(config.datesHeight, equals(customConfig.datesHeight),
            reason: 'datesHeight should match programmatic config');
        expect(config.rowHeight, equals(customConfig.rowHeight), reason: 'rowHeight should match programmatic config');
        expect(config.rowMargin, equals(customConfig.rowMargin), reason: 'rowMargin should match programmatic config');
        expect(config.bufferDays, equals(customConfig.bufferDays),
            reason: 'bufferDays should match programmatic config');
        expect(config.animationDuration, equals(customConfig.animationDuration),
            reason: 'animationDuration should match programmatic config');

        // Clean up
        TimelineConfigurationManager.reset();
      }
    });
  });
}
