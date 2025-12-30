import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/models.dart';

void main() {
  // Reset the manager before each test to ensure clean state
  setUp(() {
    TimelineConfigurationManager.reset();
  });

  group('TimelineConfigurationManager', () {
    // Feature: external-configuration-system, Property 6: Configuration Immutability
    // For any initialized configuration, multiple accesses should return same values
    // Validates: Requirements 5.2
    test('configuration immutability - multiple accesses return same values', () {
      final random = Random(42);

      // Run 100 iterations with random configurations
      for (int i = 0; i < 100; i++) {
        // Reset for each iteration
        TimelineConfigurationManager.reset();

        // Generate random valid configuration
        final config = _generateRandomValidConfig(random);

        // Initialize with the configuration
        TimelineConfigurationManager.initialize(
          programmaticConfig: config,
        );

        // Access configuration multiple times
        final access1 = TimelineConfigurationManager.configuration;
        final access2 = TimelineConfigurationManager.configuration;
        final access3 = TimelineConfigurationManager.configuration;
        final access4 = TimelineConfigurationManager.configuration;
        final access5 = TimelineConfigurationManager.configuration;

        // Assert: all accesses should return the same instance
        expect(identical(access1, access2), isTrue, reason: 'Multiple accesses should return the same instance');
        expect(identical(access2, access3), isTrue, reason: 'Multiple accesses should return the same instance');
        expect(identical(access3, access4), isTrue, reason: 'Multiple accesses should return the same instance');
        expect(identical(access4, access5), isTrue, reason: 'Multiple accesses should return the same instance');

        // Assert: all accesses should have the same values
        expect(access1, equals(access2));
        expect(access2, equals(access3));
        expect(access3, equals(access4));
        expect(access4, equals(access5));

        // Assert: values should match the original configuration
        expect(access1.dayWidth, equals(config.dayWidth));
        expect(access1.dayMargin, equals(config.dayMargin));
        expect(access1.bufferDays, equals(config.bufferDays));
        expect(access1.scrollThrottleDuration, equals(config.scrollThrottleDuration));
        expect(access1.animationDuration, equals(config.animationDuration));
        expect(access1.rowHeight, equals(config.rowHeight));
        expect(access1.rowMargin, equals(config.rowMargin));
        expect(access1.datesHeight, equals(config.datesHeight));
        expect(access1.timelineHeight, equals(config.timelineHeight));
      }
    });

    // Feature: external-configuration-system, Property 7: Programmatic Override Precedence
    // For any conflicting file and programmatic configs, programmatic should win
    // Validates: Requirements 8.4
    test('programmatic override precedence - programmatic config takes precedence', () {
      final random = Random(42);

      // Run 100 iterations with conflicting configurations
      for (int i = 0; i < 100; i++) {
        // Reset for each iteration
        TimelineConfigurationManager.reset();

        // Generate two different random valid configurations
        final fileConfig = _generateRandomValidConfig(random);
        final programmaticConfig = _generateRandomValidConfig(random);

        // Ensure they are different
        expect(fileConfig, isNot(equals(programmaticConfig)),
            reason: 'File and programmatic configs should be different');

        // Initialize with both configurations
        TimelineConfigurationManager.initialize(
          fileConfig: fileConfig.toMap(),
          programmaticConfig: programmaticConfig,
        );

        // Access the configuration
        final resultConfig = TimelineConfigurationManager.configuration;

        // Assert: all values should match programmatic config, not file config
        expect(resultConfig.dayWidth, equals(programmaticConfig.dayWidth),
            reason: 'dayWidth should match programmatic config');
        expect(resultConfig.dayMargin, equals(programmaticConfig.dayMargin),
            reason: 'dayMargin should match programmatic config');
        expect(resultConfig.bufferDays, equals(programmaticConfig.bufferDays),
            reason: 'bufferDays should match programmatic config');
        expect(resultConfig.scrollThrottleDuration, equals(programmaticConfig.scrollThrottleDuration),
            reason: 'scrollThrottleDuration should match programmatic config');
        expect(resultConfig.animationDuration, equals(programmaticConfig.animationDuration),
            reason: 'animationDuration should match programmatic config');
        expect(resultConfig.rowHeight, equals(programmaticConfig.rowHeight),
            reason: 'rowHeight should match programmatic config');
        expect(resultConfig.rowMargin, equals(programmaticConfig.rowMargin),
            reason: 'rowMargin should match programmatic config');
        expect(resultConfig.datesHeight, equals(programmaticConfig.datesHeight),
            reason: 'datesHeight should match programmatic config');
        expect(resultConfig.timelineHeight, equals(programmaticConfig.timelineHeight),
            reason: 'timelineHeight should match programmatic config');

        // Assert: values should NOT match file config
        expect(resultConfig.dayWidth, isNot(equals(fileConfig.dayWidth)),
            reason: 'dayWidth should not match file config');
        expect(resultConfig.dayMargin, isNot(equals(fileConfig.dayMargin)),
            reason: 'dayMargin should not match file config');
      }
    });

    // Feature: external-configuration-system, Property 13: Configuration Caching
    // For any initialized config, multiple accesses should not re-read file
    // Validates: Requirements 10.3
    test('configuration caching - multiple accesses do not re-read file', () {
      final random = Random(42);

      // Run 100 iterations with file-based configurations
      for (int i = 0; i < 100; i++) {
        // Reset for each iteration
        TimelineConfigurationManager.reset();

        // Generate random valid configuration
        final config = _generateRandomValidConfig(random);
        final fileConfigMap = config.toMap();

        // Initialize with file configuration
        TimelineConfigurationManager.initialize(
          fileConfig: fileConfigMap,
        );

        // Access configuration multiple times
        final access1 = TimelineConfigurationManager.configuration;
        final access2 = TimelineConfigurationManager.configuration;
        final access3 = TimelineConfigurationManager.configuration;
        final access4 = TimelineConfigurationManager.configuration;
        final access5 = TimelineConfigurationManager.configuration;

        // Assert: all accesses should return the exact same instance (cached)
        expect(identical(access1, access2), isTrue, reason: 'Multiple accesses should return the same cached instance');
        expect(identical(access2, access3), isTrue, reason: 'Multiple accesses should return the same cached instance');
        expect(identical(access3, access4), isTrue, reason: 'Multiple accesses should return the same cached instance');
        expect(identical(access4, access5), isTrue, reason: 'Multiple accesses should return the same cached instance');

        // Assert: values should remain consistent across all accesses
        expect(access1.dayWidth, equals(access2.dayWidth));
        expect(access2.dayWidth, equals(access3.dayWidth));
        expect(access3.dayWidth, equals(access4.dayWidth));
        expect(access4.dayWidth, equals(access5.dayWidth));

        expect(access1.bufferDays, equals(access2.bufferDays));
        expect(access2.bufferDays, equals(access3.bufferDays));
        expect(access3.bufferDays, equals(access4.bufferDays));
        expect(access4.bufferDays, equals(access5.bufferDays));

        // Assert: configuration should match the original file config
        expect(access1.dayWidth, equals(config.dayWidth));
        expect(access1.dayMargin, equals(config.dayMargin));
        expect(access1.bufferDays, equals(config.bufferDays));
      }
    });
  });
}

/// Generates a random valid TimelineConfiguration for testing.
TimelineConfiguration _generateRandomValidConfig(Random random) {
  // Generate random values within valid ranges
  final dayWidth = 20.0 + random.nextDouble() * 80.0; // 20.0 - 100.0
  final dayMargin = random.nextDouble() * 20.0; // 0.0 - 20.0
  final datesHeight = 40.0 + random.nextDouble() * 60.0; // 40.0 - 100.0
  final timelineHeight = 100.0 + random.nextDouble() * 900.0; // 100.0 - 1000.0
  final rowHeight = 20.0 + random.nextDouble() * 40.0; // 20.0 - 60.0
  final rowMargin = random.nextDouble() * 10.0; // 0.0 - 10.0
  final bufferDays = 1 + random.nextInt(20); // 1 - 20
  final scrollThrottleMs = 8 + random.nextInt(93); // 8 - 100
  final animationDurationMs = 100 + random.nextInt(401); // 100 - 500

  return TimelineConfiguration(
    dayWidth: dayWidth,
    dayMargin: dayMargin,
    datesHeight: datesHeight,
    timelineHeight: timelineHeight,
    rowHeight: rowHeight,
    rowMargin: rowMargin,
    bufferDays: bufferDays,
    scrollThrottleDuration: Duration(milliseconds: scrollThrottleMs),
    animationDuration: Duration(milliseconds: animationDurationMs),
  );
}
