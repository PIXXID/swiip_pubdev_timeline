import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/models.dart';

void main() {
  group('Edge Case Handling', () {
    setUp(() {
      TimelineConfigurationManager.reset();
    });

    group('Empty Configuration', () {
      // Requirements: 3.1-3.5, 9.1-9.5
      test('empty configuration file uses all defaults', () {
        final emptyConfig = <String, dynamic>{};
        final result = ConfigurationValidator.validate(emptyConfig);

        final defaults = ConfigurationValidator.getDefaultConfiguration();

        // Verify all parameters use defaults
        expect(
            result.validatedConfig['dayWidth'], equals(defaults['dayWidth']));
        expect(
            result.validatedConfig['dayMargin'], equals(defaults['dayMargin']));
        expect(result.validatedConfig['datesHeight'],
            equals(defaults['datesHeight']));
        expect(result.validatedConfig['timelineHeight'],
            equals(defaults['timelineHeight']));
        expect(
            result.validatedConfig['rowHeight'], equals(defaults['rowHeight']));
        expect(
            result.validatedConfig['rowMargin'], equals(defaults['rowMargin']));
        expect(result.validatedConfig['bufferDays'],
            equals(defaults['bufferDays']));
        expect(result.validatedConfig['scrollThrottleMs'],
            equals(defaults['scrollThrottleMs']));
        expect(result.validatedConfig['animationDurationMs'],
            equals(defaults['animationDurationMs']));

        // No errors should be generated for empty config
        expect(result.errors, isEmpty);
      });

      test('empty configuration initializes manager successfully', () {
        final emptyConfig = <String, dynamic>{};

        TimelineConfigurationManager.initialize(fileConfig: emptyConfig);

        final config = TimelineConfigurationManager.configuration;

        // Should have default values
        expect(config.dayWidth, equals(45.0));
        expect(config.dayMargin, equals(5.0));
        expect(config.bufferDays, equals(5));
      });
    });

    group('Partial Configuration', () {
      // Requirements: 3.4
      test(
          'configuration with only dayWidth preserves it and uses defaults for others',
          () {
        final partialConfig = {
          'dayWidth': 60.0,
        };

        final result = ConfigurationValidator.validate(partialConfig);
        final defaults = ConfigurationValidator.getDefaultConfiguration();

        // Provided parameter should be preserved
        expect(result.validatedConfig['dayWidth'], equals(60.0));

        // Others should use defaults
        expect(
            result.validatedConfig['dayMargin'], equals(defaults['dayMargin']));
        expect(result.validatedConfig['bufferDays'],
            equals(defaults['bufferDays']));
        expect(result.validatedConfig['scrollThrottleMs'],
            equals(defaults['scrollThrottleMs']));
      });

      test(
          'configuration with only bufferDays preserves it and uses defaults for others',
          () {
        final partialConfig = {
          'bufferDays': 10,
        };

        final result = ConfigurationValidator.validate(partialConfig);
        final defaults = ConfigurationValidator.getDefaultConfiguration();

        // Provided parameter should be preserved
        expect(result.validatedConfig['bufferDays'], equals(10));

        // Others should use defaults
        expect(
            result.validatedConfig['dayWidth'], equals(defaults['dayWidth']));
        expect(
            result.validatedConfig['dayMargin'], equals(defaults['dayMargin']));
      });

      test('configuration with multiple parameters preserves all valid ones',
          () {
        final partialConfig = {
          'dayWidth': 50.0,
          'bufferDays': 8,
          'scrollThrottleMs': 20,
        };

        final result = ConfigurationValidator.validate(partialConfig);
        final defaults = ConfigurationValidator.getDefaultConfiguration();

        // Provided parameters should be preserved
        expect(result.validatedConfig['dayWidth'], equals(50.0));
        expect(result.validatedConfig['bufferDays'], equals(8));
        expect(result.validatedConfig['scrollThrottleMs'], equals(20));

        // Others should use defaults
        expect(
            result.validatedConfig['dayMargin'], equals(defaults['dayMargin']));
        expect(result.validatedConfig['datesHeight'],
            equals(defaults['datesHeight']));
      });
    });

    group('Unknown Parameters', () {
      // Requirements: 9.1-9.5
      test('configuration with unknown parameters ignores them', () {
        final configWithUnknown = {
          'dayWidth': 50.0,
          'unknownParam1': 'should be ignored',
          'bufferDays': 8,
          'unknownParam2': 12345,
          'anotherUnknown': true,
        };

        final result = ConfigurationValidator.validate(configWithUnknown);

        // Known parameters should be preserved
        expect(result.validatedConfig['dayWidth'], equals(50.0));
        expect(result.validatedConfig['bufferDays'], equals(8));

        // Unknown parameters should not be in validated config
        expect(result.validatedConfig.containsKey('unknownParam1'), isFalse);
        expect(result.validatedConfig.containsKey('unknownParam2'), isFalse);
        expect(result.validatedConfig.containsKey('anotherUnknown'), isFalse);
      });

      test('configuration with only unknown parameters uses all defaults', () {
        final configWithOnlyUnknown = {
          'unknownParam1': 'value1',
          'unknownParam2': 123,
          'unknownParam3': true,
        };

        final result = ConfigurationValidator.validate(configWithOnlyUnknown);
        final defaults = ConfigurationValidator.getDefaultConfiguration();

        // All parameters should use defaults
        expect(
            result.validatedConfig['dayWidth'], equals(defaults['dayWidth']));
        expect(
            result.validatedConfig['dayMargin'], equals(defaults['dayMargin']));
        expect(result.validatedConfig['bufferDays'],
            equals(defaults['bufferDays']));

        // Unknown parameters should not be present
        expect(result.validatedConfig.containsKey('unknownParam1'), isFalse);
        expect(result.validatedConfig.containsKey('unknownParam2'), isFalse);
        expect(result.validatedConfig.containsKey('unknownParam3'), isFalse);
      });

      test('unknown parameters do not cause errors or warnings', () {
        final configWithUnknown = {
          'dayWidth': 50.0,
          'unknownParam': 'ignored',
        };

        final result = ConfigurationValidator.validate(configWithUnknown);

        // Should not generate errors or warnings for unknown parameters
        // (only for invalid known parameters)
        expect(result.errors, isEmpty);
        expect(result.warnings, isEmpty);
      });
    });

    group('Boundary Values', () {
      // Requirements: 3.1, 3.3
      test('dayWidth at minimum boundary (20.0) is accepted', () {
        final config = {'dayWidth': 20.0};
        final result = ConfigurationValidator.validate(config);

        expect(result.validatedConfig['dayWidth'], equals(20.0));
        expect(result.errors, isEmpty);
      });

      test('dayWidth at maximum boundary (100.0) is accepted', () {
        final config = {'dayWidth': 100.0};
        final result = ConfigurationValidator.validate(config);

        expect(result.validatedConfig['dayWidth'], equals(100.0));
        expect(result.errors, isEmpty);
      });

      test('dayMargin at minimum boundary (0.0) is accepted', () {
        final config = {'dayMargin': 0.0};
        final result = ConfigurationValidator.validate(config);

        expect(result.validatedConfig['dayMargin'], equals(0.0));
        expect(result.errors, isEmpty);
      });

      test('dayMargin at maximum boundary (20.0) is accepted', () {
        final config = {'dayMargin': 20.0};
        final result = ConfigurationValidator.validate(config);

        expect(result.validatedConfig['dayMargin'], equals(20.0));
        expect(result.errors, isEmpty);
      });

      test('bufferDays at minimum boundary (1) is accepted', () {
        final config = {'bufferDays': 1};
        final result = ConfigurationValidator.validate(config);

        expect(result.validatedConfig['bufferDays'], equals(1));
        expect(result.errors, isEmpty);
      });

      test('bufferDays at maximum boundary (20) is accepted', () {
        final config = {'bufferDays': 20};
        final result = ConfigurationValidator.validate(config);

        expect(result.validatedConfig['bufferDays'], equals(20));
        expect(result.errors, isEmpty);
      });

      test('scrollThrottleMs at minimum boundary (8) is accepted', () {
        final config = {'scrollThrottleMs': 8};
        final result = ConfigurationValidator.validate(config);

        expect(result.validatedConfig['scrollThrottleMs'], equals(8));
        expect(result.errors, isEmpty);
      });

      test('scrollThrottleMs at maximum boundary (100) is accepted', () {
        final config = {'scrollThrottleMs': 100};
        final result = ConfigurationValidator.validate(config);

        expect(result.validatedConfig['scrollThrottleMs'], equals(100));
        expect(result.errors, isEmpty);
      });

      test('animationDurationMs at minimum boundary (100) is accepted', () {
        final config = {'animationDurationMs': 100};
        final result = ConfigurationValidator.validate(config);

        expect(result.validatedConfig['animationDurationMs'], equals(100));
        expect(result.errors, isEmpty);
      });

      test('animationDurationMs at maximum boundary (500) is accepted', () {
        final config = {'animationDurationMs': 500};
        final result = ConfigurationValidator.validate(config);

        expect(result.validatedConfig['animationDurationMs'], equals(500));
        expect(result.errors, isEmpty);
      });

      test('rowHeight at minimum boundary (20.0) is accepted', () {
        final config = {'rowHeight': 20.0};
        final result = ConfigurationValidator.validate(config);

        expect(result.validatedConfig['rowHeight'], equals(20.0));
        expect(result.errors, isEmpty);
      });

      test('rowHeight at maximum boundary (60.0) is accepted', () {
        final config = {'rowHeight': 60.0};
        final result = ConfigurationValidator.validate(config);

        expect(result.validatedConfig['rowHeight'], equals(60.0));
        expect(result.errors, isEmpty);
      });

      test('rowMargin at minimum boundary (0.0) is accepted', () {
        final config = {'rowMargin': 0.0};
        final result = ConfigurationValidator.validate(config);

        expect(result.validatedConfig['rowMargin'], equals(0.0));
        expect(result.errors, isEmpty);
      });

      test('rowMargin at maximum boundary (10.0) is accepted', () {
        final config = {'rowMargin': 10.0};
        final result = ConfigurationValidator.validate(config);

        expect(result.validatedConfig['rowMargin'], equals(10.0));
        expect(result.errors, isEmpty);
      });

      test('datesHeight at minimum boundary (40.0) is accepted', () {
        final config = {'datesHeight': 40.0};
        final result = ConfigurationValidator.validate(config);

        expect(result.validatedConfig['datesHeight'], equals(40.0));
        expect(result.errors, isEmpty);
      });

      test('datesHeight at maximum boundary (100.0) is accepted', () {
        final config = {'datesHeight': 100.0};
        final result = ConfigurationValidator.validate(config);

        expect(result.validatedConfig['datesHeight'], equals(100.0));
        expect(result.errors, isEmpty);
      });

      test('timelineHeight at minimum boundary (100.0) is accepted', () {
        final config = {'timelineHeight': 100.0};
        final result = ConfigurationValidator.validate(config);

        expect(result.validatedConfig['timelineHeight'], equals(100.0));
        expect(result.errors, isEmpty);
      });

      test('timelineHeight at maximum boundary (1000.0) is accepted', () {
        final config = {'timelineHeight': 1000.0};
        final result = ConfigurationValidator.validate(config);

        expect(result.validatedConfig['timelineHeight'], equals(1000.0));
        expect(result.errors, isEmpty);
      });

      test('all parameters at their minimum boundaries are accepted', () {
        final config = {
          'dayWidth': 20.0,
          'dayMargin': 0.0,
          'datesHeight': 40.0,
          'timelineHeight': 100.0,
          'rowHeight': 20.0,
          'rowMargin': 0.0,
          'bufferDays': 1,
          'scrollThrottleMs': 8,
          'animationDurationMs': 100,
        };

        final result = ConfigurationValidator.validate(config);

        expect(result.validatedConfig['dayWidth'], equals(20.0));
        expect(result.validatedConfig['dayMargin'], equals(0.0));
        expect(result.validatedConfig['datesHeight'], equals(40.0));
        expect(result.validatedConfig['timelineHeight'], equals(100.0));
        expect(result.validatedConfig['rowHeight'], equals(20.0));
        expect(result.validatedConfig['rowMargin'], equals(0.0));
        expect(result.validatedConfig['bufferDays'], equals(1));
        expect(result.validatedConfig['scrollThrottleMs'], equals(8));
        expect(result.validatedConfig['animationDurationMs'], equals(100));
        expect(result.errors, isEmpty);
      });

      test('all parameters at their maximum boundaries are accepted', () {
        final config = {
          'dayWidth': 100.0,
          'dayMargin': 20.0,
          'datesHeight': 100.0,
          'timelineHeight': 1000.0,
          'rowHeight': 60.0,
          'rowMargin': 10.0,
          'bufferDays': 20,
          'scrollThrottleMs': 100,
          'animationDurationMs': 500,
        };

        final result = ConfigurationValidator.validate(config);

        expect(result.validatedConfig['dayWidth'], equals(100.0));
        expect(result.validatedConfig['dayMargin'], equals(20.0));
        expect(result.validatedConfig['datesHeight'], equals(100.0));
        expect(result.validatedConfig['timelineHeight'], equals(1000.0));
        expect(result.validatedConfig['rowHeight'], equals(60.0));
        expect(result.validatedConfig['rowMargin'], equals(10.0));
        expect(result.validatedConfig['bufferDays'], equals(20));
        expect(result.validatedConfig['scrollThrottleMs'], equals(100));
        expect(result.validatedConfig['animationDurationMs'], equals(500));
        expect(result.errors, isEmpty);
      });

      test('values just below minimum boundary use defaults', () {
        final config = {
          'dayWidth': 19.9,
          'bufferDays': 0,
          'scrollThrottleMs': 7,
        };

        final result = ConfigurationValidator.validate(config);
        final defaults = ConfigurationValidator.getDefaultConfiguration();

        expect(
            result.validatedConfig['dayWidth'], equals(defaults['dayWidth']));
        expect(result.validatedConfig['bufferDays'],
            equals(defaults['bufferDays']));
        expect(result.validatedConfig['scrollThrottleMs'],
            equals(defaults['scrollThrottleMs']));
        expect(result.errors.length, equals(3));
      });

      test('values just above maximum boundary use defaults', () {
        final config = {
          'dayWidth': 100.1,
          'bufferDays': 21,
          'scrollThrottleMs': 101,
        };

        final result = ConfigurationValidator.validate(config);
        final defaults = ConfigurationValidator.getDefaultConfiguration();

        expect(
            result.validatedConfig['dayWidth'], equals(defaults['dayWidth']));
        expect(result.validatedConfig['bufferDays'],
            equals(defaults['bufferDays']));
        expect(result.validatedConfig['scrollThrottleMs'],
            equals(defaults['scrollThrottleMs']));
        expect(result.errors.length, equals(3));
      });
    });

    group('Concurrent Initialization', () {
      // Requirements: 9.1-9.5
      test('concurrent initialization attempts use first initialization', () {
        TimelineConfigurationManager.reset();

        final config1 = const TimelineConfiguration(dayWidth: 50.0);
        final config2 = const TimelineConfiguration(dayWidth: 60.0);

        // Initialize with first config
        TimelineConfigurationManager.initialize(programmaticConfig: config1);

        // Attempt second initialization (should be ignored)
        TimelineConfigurationManager.initialize(programmaticConfig: config2);

        // Should use first initialization
        final result = TimelineConfigurationManager.configuration;
        expect(result.dayWidth, equals(50.0));
      });

      test('multiple initialization attempts do not change configuration', () {
        TimelineConfigurationManager.reset();

        final config1 = const TimelineConfiguration(
          dayWidth: 50.0,
          bufferDays: 8,
        );

        TimelineConfigurationManager.initialize(programmaticConfig: config1);

        // Store reference to first configuration
        final firstConfig = TimelineConfigurationManager.configuration;

        // Attempt multiple re-initializations
        for (int i = 0; i < 10; i++) {
          final newConfig = TimelineConfiguration(
            dayWidth: 60.0 + i,
            bufferDays: 10 + i,
          );
          TimelineConfigurationManager.initialize(
              programmaticConfig: newConfig);
        }

        // Configuration should remain unchanged
        final finalConfig = TimelineConfigurationManager.configuration;
        expect(identical(firstConfig, finalConfig), isTrue);
        expect(finalConfig.dayWidth, equals(50.0));
        expect(finalConfig.bufferDays, equals(8));
      });

      test('isInitialized returns true after first initialization', () {
        TimelineConfigurationManager.reset();

        expect(TimelineConfigurationManager.isInitialized, isFalse);

        TimelineConfigurationManager.initialize(
          programmaticConfig: const TimelineConfiguration(),
        );

        expect(TimelineConfigurationManager.isInitialized, isTrue);
      });

      test('isInitialized remains true after multiple initialization attempts',
          () {
        TimelineConfigurationManager.reset();

        TimelineConfigurationManager.initialize(
          programmaticConfig: const TimelineConfiguration(),
        );

        expect(TimelineConfigurationManager.isInitialized, isTrue);

        // Attempt multiple re-initializations
        for (int i = 0; i < 5; i++) {
          TimelineConfigurationManager.initialize(
            programmaticConfig: const TimelineConfiguration(dayWidth: 60.0),
          );
          expect(TimelineConfigurationManager.isInitialized, isTrue);
        }
      });
    });

    group('Null and Missing Values', () {
      // Requirements: 3.1-3.5
      test('null configuration map uses all defaults', () {
        final result = ConfigurationValidator.validate(null);
        final defaults = ConfigurationValidator.getDefaultConfiguration();

        expect(
            result.validatedConfig['dayWidth'], equals(defaults['dayWidth']));
        expect(
            result.validatedConfig['dayMargin'], equals(defaults['dayMargin']));
        expect(result.validatedConfig['bufferDays'],
            equals(defaults['bufferDays']));
      });

      test('configuration with null values uses defaults for those parameters',
          () {
        final config = {
          'dayWidth': null,
          'bufferDays': 8,
          'dayMargin': null,
        };

        final result = ConfigurationValidator.validate(config);
        final defaults = ConfigurationValidator.getDefaultConfiguration();

        // Null values should use defaults
        expect(
            result.validatedConfig['dayWidth'], equals(defaults['dayWidth']));
        expect(
            result.validatedConfig['dayMargin'], equals(defaults['dayMargin']));

        // Valid value should be preserved
        expect(result.validatedConfig['bufferDays'], equals(8));
      });
    });

    group('Special Numeric Values', () {
      // Requirements: 3.1-3.5
      test('configuration with zero values where valid are accepted', () {
        final config = {
          'dayMargin': 0.0,
          'rowMargin': 0.0,
        };

        final result = ConfigurationValidator.validate(config);

        expect(result.validatedConfig['dayMargin'], equals(0.0));
        expect(result.validatedConfig['rowMargin'], equals(0.0));
        expect(result.errors, isEmpty);
      });

      test('configuration with negative values uses defaults', () {
        final config = {
          'dayWidth': -10.0,
          'bufferDays': -5,
        };

        final result = ConfigurationValidator.validate(config);
        final defaults = ConfigurationValidator.getDefaultConfiguration();

        expect(
            result.validatedConfig['dayWidth'], equals(defaults['dayWidth']));
        expect(result.validatedConfig['bufferDays'],
            equals(defaults['bufferDays']));
        expect(result.errors.length, equals(2));
      });

      test('configuration with very large values uses defaults', () {
        final config = {
          'dayWidth': 1000000.0,
          'bufferDays': 1000000,
        };

        final result = ConfigurationValidator.validate(config);
        final defaults = ConfigurationValidator.getDefaultConfiguration();

        expect(
            result.validatedConfig['dayWidth'], equals(defaults['dayWidth']));
        expect(result.validatedConfig['bufferDays'],
            equals(defaults['bufferDays']));
        expect(result.errors.length, equals(2));
      });

      test('configuration with decimal values for integer parameters', () {
        final config = {
          'bufferDays': 5.5,
          'scrollThrottleMs': 16.7,
        };

        final result = ConfigurationValidator.validate(config);

        // The validator accepts numeric types (num) for integer parameters
        // This is a design decision - the validator is lenient with numeric types
        // The values should be within valid range
        final bufferDaysResult = result.validatedConfig['bufferDays'];
        final scrollThrottleResult = result.validatedConfig['scrollThrottleMs'];

        // Values should be numeric and within valid range
        expect(bufferDaysResult, isA<num>());
        expect(scrollThrottleResult, isA<num>());
        expect(bufferDaysResult, greaterThanOrEqualTo(1));
        expect(bufferDaysResult, lessThanOrEqualTo(20));
        expect(scrollThrottleResult, greaterThanOrEqualTo(8));
        expect(scrollThrottleResult, lessThanOrEqualTo(100));

        // No errors should be generated for valid numeric values
        expect(result.errors, isEmpty);
      });
    });

    group('Mixed Valid and Invalid Configurations', () {
      // Requirements: 3.4
      test('configuration with mix of valid, invalid, and unknown parameters',
          () {
        final config = {
          'dayWidth': 50.0, // valid
          'bufferDays': 100, // invalid (out of range)
          'unknownParam': 'ignored', // unknown
          'dayMargin': 'invalid', // invalid (wrong type)
          'scrollThrottleMs': 20, // valid
        };

        final result = ConfigurationValidator.validate(config);
        final defaults = ConfigurationValidator.getDefaultConfiguration();

        // Valid parameters should be preserved
        expect(result.validatedConfig['dayWidth'], equals(50.0));
        expect(result.validatedConfig['scrollThrottleMs'], equals(20));

        // Invalid parameters should use defaults
        expect(result.validatedConfig['bufferDays'],
            equals(defaults['bufferDays']));
        expect(
            result.validatedConfig['dayMargin'], equals(defaults['dayMargin']));

        // Unknown parameters should not be present
        expect(result.validatedConfig.containsKey('unknownParam'), isFalse);

        // Should have errors for invalid parameters
        expect(result.errors.length, greaterThan(0));
      });
    });
  });
}
