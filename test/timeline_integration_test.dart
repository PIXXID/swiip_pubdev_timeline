import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/timeline.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/timeline_configuration.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/timeline_configuration_manager.dart';

void main() {
  group('Timeline Integration Tests', () {
    setUp(() {
      // Reset configuration manager before each test
      TimelineConfigurationManager.reset();
    });

    tearDown(() {
      // Clean up after each test
      TimelineConfigurationManager.reset();
    });

    group('Timeline with File-Based Configuration', () {
      test(
          'Timeline configuration manager initializes with file-based configuration',
          () {
        // Requirements: 5.3, 5.4

        // Create a custom configuration that simulates file-based config
        final fileConfig = {
          'dayWidth': 50.0,
          'dayMargin': 6.0,
          'datesHeight': 70.0,
          'timelineHeight': 350.0,
          'rowHeight': 35.0,
          'rowMargin': 4.0,
          'bufferDays': 7,
          'scrollThrottleMs': 20,
          'animationDurationMs': 250,
        };

        // Initialize configuration manager with file config
        TimelineConfigurationManager.initialize(fileConfig: fileConfig);

        // Verify configuration is loaded
        expect(TimelineConfigurationManager.isInitialized, isTrue);
        final config = TimelineConfigurationManager.configuration;

        // Verify file config values are used
        expect(config.dayWidth, equals(50.0));
        expect(config.dayMargin, equals(6.0));
        expect(config.datesHeight, equals(70.0));
        expect(config.timelineHeight, equals(350.0));
        expect(config.rowHeight, equals(35.0));
        expect(config.rowMargin, equals(4.0));
        expect(config.bufferDays, equals(7));
        expect(config.scrollThrottleDuration,
            equals(const Duration(milliseconds: 20)));
        expect(config.animationDuration,
            equals(const Duration(milliseconds: 250)));
      });

      test(
          'Timeline configuration with partial file configuration uses defaults for missing values',
          () {
        // Requirements: 5.3, 5.4

        // Create a partial configuration (only some parameters)
        final partialFileConfig = {
          'dayWidth': 55.0,
          'bufferDays': 8,
          // Other parameters missing - should use defaults
        };

        // Initialize with partial config
        TimelineConfigurationManager.initialize(fileConfig: partialFileConfig);

        final config = TimelineConfigurationManager.configuration;

        // Verify custom values are used
        expect(config.dayWidth, equals(55.0));
        expect(config.bufferDays, equals(8));

        // Verify defaults are used for missing values
        expect(config.dayMargin, equals(5.0)); // default
        expect(config.datesHeight, equals(65.0)); // default
        expect(config.timelineHeight, equals(300.0)); // default
        expect(config.rowHeight, equals(30.0)); // default
      });
    });

    group('Timeline Without Configuration (Backward Compatibility)', () {
      test(
          'Timeline configuration manager works without any configuration file (backward compatibility)',
          () {
        // Requirements: 8.1, 8.2, 8.3, 8.5

        // Do NOT initialize configuration manager
        // Initialize with no config (simulates previous behavior)
        TimelineConfigurationManager.initialize();

        // Verify configuration was auto-initialized with defaults
        expect(TimelineConfigurationManager.isInitialized, isTrue);

        final config = TimelineConfigurationManager.configuration;

        // Verify default values are used (backward compatible behavior)
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

      testWidgets('Timeline widget initializes without pre-configured manager',
          (WidgetTester tester) async {
        // Requirements: 8.1, 8.3

        // Do NOT pre-initialize configuration manager
        // This simulates the previous behavior where no configuration exists

        final infos = {
          'startDate': DateTime(2024, 1, 1).toIso8601String(),
          'endDate': DateTime(2024, 1, 10).toIso8601String(),
          'lmax': 8,
        };

        // Build Timeline widget WITHOUT pre-initializing configuration
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Timeline(
                colors: {
                  'primary': Colors.blue,
                  'primaryBackground': Colors.white,
                  'secondaryBackground': Colors.grey[200]!,
                  'primaryText': Colors.black,
                  'error': Colors.red,
                  'warning': Colors.orange,
                },
                infos: infos,
                elements: [],
                elementsDone: [],
                capacities: [],
                stages: [],
                openDayDetail: (date, capacity, preIds, elements, infos) {},
              ),
            ),
          ),
        );

        // Wait for async initialization
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify configuration was auto-initialized
        expect(TimelineConfigurationManager.isInitialized, isTrue);

        final config = TimelineConfigurationManager.configuration;

        // Verify configuration values are loaded (from file if present, otherwise defaults)
        expect(config.dayWidth, equals(45.0));
        expect(config.bufferDays, equals(7)); // From timeline_config.json
      });
    });

    group('Preset Configurations End-to-End', () {
      test('Small dataset preset configuration values are applied', () {
        // Requirements: 5.3, 5.4

        // Simulate small dataset preset configuration
        final smallPresetConfig = {
          'dayWidth': 50.0,
          'dayMargin': 5.0,
          'bufferDays': 3,
          'scrollThrottleMs': 16,
          'animationDurationMs': 200,
        };

        TimelineConfigurationManager.initialize(fileConfig: smallPresetConfig);

        final config = TimelineConfigurationManager.configuration;

        // Verify small preset values
        expect(config.dayWidth, equals(50.0));
        expect(config.bufferDays, equals(3));
        expect(config.animationDuration,
            equals(const Duration(milliseconds: 200)));
      });

      test('Medium dataset preset configuration values are applied', () {
        // Requirements: 5.3, 5.4

        // Simulate medium dataset preset configuration
        final mediumPresetConfig = {
          'dayWidth': 45.0,
          'dayMargin': 5.0,
          'bufferDays': 5,
          'scrollThrottleMs': 16,
          'animationDurationMs': 220,
        };

        TimelineConfigurationManager.initialize(fileConfig: mediumPresetConfig);

        final config = TimelineConfigurationManager.configuration;

        // Verify medium preset values
        expect(config.dayWidth, equals(45.0));
        expect(config.bufferDays, equals(5));
        expect(config.animationDuration,
            equals(const Duration(milliseconds: 220)));
      });

      test('Large dataset preset configuration values are applied', () {
        // Requirements: 5.3, 5.4

        // Simulate large dataset preset configuration
        final largePresetConfig = {
          'dayWidth': 40.0,
          'dayMargin': 4.0,
          'bufferDays': 8,
          'scrollThrottleMs': 20,
          'animationDurationMs': 250,
        };

        TimelineConfigurationManager.initialize(fileConfig: largePresetConfig);

        final config = TimelineConfigurationManager.configuration;

        // Verify large preset values
        expect(config.dayWidth, equals(40.0));
        expect(config.bufferDays, equals(8));
        expect(config.scrollThrottleDuration,
            equals(const Duration(milliseconds: 20)));
        expect(config.animationDuration,
            equals(const Duration(milliseconds: 250)));
      });
    });

    group('Configuration Precedence Integration', () {
      test('Programmatic configuration overrides file configuration', () {
        // Requirements: 8.4

        // Initialize with both file and programmatic config
        final fileConfig = {
          'dayWidth': 50.0,
          'bufferDays': 7,
        };

        final programmaticConfig = TimelineConfiguration(
          dayWidth: 60.0, // Override file config
          bufferDays: 10, // Override file config
          dayMargin: 8.0,
        );

        TimelineConfigurationManager.initialize(
          fileConfig: fileConfig,
          programmaticConfig: programmaticConfig,
        );

        final config = TimelineConfigurationManager.configuration;

        // Verify programmatic config takes precedence
        expect(config.dayWidth, equals(60.0)); // From programmatic
        expect(config.bufferDays, equals(10)); // From programmatic
        expect(config.dayMargin, equals(8.0)); // From programmatic
      });
    });

    group('Error Handling Integration', () {
      test('Timeline handles invalid configuration gracefully', () {
        // Requirements: 8.1, 8.3

        // Initialize with invalid configuration (out of range values)
        final invalidConfig = {
          'dayWidth': 150.0, // Out of range (max 100)
          'bufferDays': 50, // Out of range (max 20)
          'scrollThrottleMs': 200, // Out of range (max 100)
        };

        TimelineConfigurationManager.initialize(fileConfig: invalidConfig);

        final config = TimelineConfigurationManager.configuration;

        // Verify defaults are used for invalid values
        expect(config.dayWidth, equals(45.0)); // Default
        expect(config.bufferDays, equals(5)); // Default
        expect(config.scrollThrottleDuration,
            equals(const Duration(milliseconds: 16))); // Default
      });

      testWidgets('Timeline handles empty timeline data with configuration',
          (WidgetTester tester) async {
        // Requirements: 8.1, 8.3

        TimelineConfigurationManager.initialize(fileConfig: {
          'dayWidth': 50.0,
          'bufferDays': 7,
        });

        // Create timeline with no elements
        final infos = {
          'startDate': DateTime(2024, 1, 1).toIso8601String(),
          'endDate': DateTime(2024, 1, 10).toIso8601String(),
          'lmax': 8,
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Timeline(
                colors: {
                  'primary': Colors.blue,
                  'primaryBackground': Colors.white,
                  'secondaryBackground': Colors.grey[200]!,
                  'primaryText': Colors.black,
                  'error': Colors.red,
                  'warning': Colors.orange,
                },
                infos: infos,
                elements: [], // Empty
                elementsDone: [],
                capacities: [],
                stages: [], // Empty
                openDayDetail: (date, capacity, preIds, elements, infos) {},
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify configuration is initialized
        expect(TimelineConfigurationManager.isInitialized, isTrue);
      });
    });
  });
}
