import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/timeline_configuration.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/timeline_configuration_manager.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/configuration_logger.dart';

import 'helpers/test_fixtures.dart';

void main() {
  // Reset the singleton before each test to ensure test isolation
  setUp(() {
    TimelineConfigurationManager.reset();
    ConfigurationLogger.disableDebugMode();
  });

  // Clean up after each test
  tearDown(() {
    TimelineConfigurationManager.reset();
    ConfigurationLogger.disableDebugMode();
  });

  group('TimelineConfigurationManager - initialize', () {
    test('initialize with valid file config loads configuration successfully', () {
      // Arrange
      final fileConfig = TestFixtures.defaultConfig;

      // Act
      TimelineConfigurationManager.initialize(fileConfig: fileConfig);

      // Assert
      expect(TimelineConfigurationManager.isInitialized, isTrue);
      final config = TimelineConfigurationManager.configuration;
      expect(config.dayWidth, equals(100.0));
      expect(config.dayMargin, equals(5.0));
      expect(config.rowHeight, equals(60.0));
      expect(config.bufferDays, equals(10));
    });

    test('initialize called twice ignores second call with warning', () {
      // Arrange
      final fileConfig1 = TestFixtures.defaultConfig;
      final fileConfig2 = {
        ...TestFixtures.defaultConfig,
        'dayWidth': 200.0, // Different value
      };

      // Act
      TimelineConfigurationManager.initialize(fileConfig: fileConfig1);
      final configAfterFirst = TimelineConfigurationManager.configuration;

      // Second initialization should be ignored
      TimelineConfigurationManager.initialize(fileConfig: fileConfig2);
      final configAfterSecond = TimelineConfigurationManager.configuration;

      // Assert
      expect(TimelineConfigurationManager.isInitialized, isTrue);
      expect(configAfterFirst.dayWidth, equals(100.0));
      expect(configAfterSecond.dayWidth, equals(100.0)); // Should still be 100, not 200
      expect(configAfterFirst, equals(configAfterSecond)); // Should be the same instance
    });

    test('initialize with programmatic config takes precedence over file config', () {
      // Arrange
      final fileConfig = TestFixtures.defaultConfig;
      final programmaticConfig = TimelineConfiguration(
        dayWidth: 150.0,
        dayMargin: 10.0,
        rowHeight: 80.0,
        bufferDays: 15,
      );

      // Act
      TimelineConfigurationManager.initialize(
        fileConfig: fileConfig,
        programmaticConfig: programmaticConfig,
      );

      // Assert
      expect(TimelineConfigurationManager.isInitialized, isTrue);
      final config = TimelineConfigurationManager.configuration;
      expect(config.dayWidth, equals(150.0)); // From programmatic, not file
      expect(config.dayMargin, equals(10.0)); // From programmatic, not file
      expect(config.rowHeight, equals(80.0)); // From programmatic, not file
      expect(config.bufferDays, equals(15)); // From programmatic, not file
    });

    test('initialize with invalid config uses defaults with warnings', () {
      // Arrange
      final invalidConfig = TestFixtures.invalidConfig;

      // Act
      TimelineConfigurationManager.initialize(fileConfig: invalidConfig);

      // Assert
      expect(TimelineConfigurationManager.isInitialized, isTrue);
      final config = TimelineConfigurationManager.configuration;

      // Should use default values for invalid parameters
      expect(config.dayWidth, equals(65.0)); // Default value
      expect(config.dayMargin, equals(5.0)); // Default value
      expect(config.rowHeight, equals(30.0)); // Default value
      expect(config.bufferDays, equals(5)); // Default value
    });

    test('initialize with null config uses all defaults', () {
      // Act
      TimelineConfigurationManager.initialize(fileConfig: null);

      // Assert
      expect(TimelineConfigurationManager.isInitialized, isTrue);
      final config = TimelineConfigurationManager.configuration;

      // Should use all default values
      expect(config.dayWidth, equals(65.0));
      expect(config.dayMargin, equals(5.0));
      expect(config.datesHeight, equals(65.0));
      expect(config.rowHeight, equals(30.0));
      expect(config.rowMargin, equals(3.0));
      expect(config.bufferDays, equals(5));
      expect(config.animationDuration, equals(const Duration(milliseconds: 220)));
    });

    test('initialize with only programmatic config works correctly', () {
      // Arrange
      final programmaticConfig = TimelineConfiguration(
        dayWidth: 120.0,
        dayMargin: 8.0,
        rowHeight: 70.0,
        bufferDays: 12,
      );

      // Act
      TimelineConfigurationManager.initialize(programmaticConfig: programmaticConfig);

      // Assert
      expect(TimelineConfigurationManager.isInitialized, isTrue);
      final config = TimelineConfigurationManager.configuration;
      expect(config.dayWidth, equals(120.0));
      expect(config.dayMargin, equals(8.0));
      expect(config.rowHeight, equals(70.0));
      expect(config.bufferDays, equals(12));
    });

    test('initialize with partial file config fills missing values with defaults', () {
      // Arrange
      final partialConfig = {
        'dayWidth': 90.0,
        'bufferDays': 8,
        // Missing: dayMargin, rowHeight, etc.
      };

      // Act
      TimelineConfigurationManager.initialize(fileConfig: partialConfig);

      // Assert
      expect(TimelineConfigurationManager.isInitialized, isTrue);
      final config = TimelineConfigurationManager.configuration;
      expect(config.dayWidth, equals(90.0)); // From file
      expect(config.bufferDays, equals(8)); // From file
      expect(config.dayMargin, equals(5.0)); // Default
      expect(config.rowHeight, equals(30.0)); // Default
    });
  });

  group('TimelineConfigurationManager - configuration access', () {
    test('configuration access before initialize throws StateError', () {
      // Assert - should throw StateError when accessing before initialization
      expect(
        () => TimelineConfigurationManager.configuration,
        throwsStateError,
      );
    });

    test('isInitialized returns false before initialize', () {
      // Assert
      expect(TimelineConfigurationManager.isInitialized, isFalse);
    });

    test('isInitialized returns true after initialize', () {
      // Arrange & Act
      TimelineConfigurationManager.initialize(fileConfig: TestFixtures.defaultConfig);

      // Assert
      expect(TimelineConfigurationManager.isInitialized, isTrue);
    });

    test('configuration can be accessed multiple times after initialize', () {
      // Arrange
      TimelineConfigurationManager.initialize(fileConfig: TestFixtures.defaultConfig);

      // Act
      final config1 = TimelineConfigurationManager.configuration;
      final config2 = TimelineConfigurationManager.configuration;
      final config3 = TimelineConfigurationManager.configuration;

      // Assert - all should return the same instance
      expect(config1, equals(config2));
      expect(config2, equals(config3));
      expect(config1.dayWidth, equals(100.0));
    });

    test('StateError message is descriptive when accessing before initialize', () {
      // Act & Assert
      try {
        final _ = TimelineConfigurationManager.configuration;
        fail('Should have thrown StateError');
      } catch (e) {
        expect(e, isA<StateError>());
        expect(
          e.toString(),
          contains('TimelineConfigurationManager has not been initialized'),
        );
        expect(
          e.toString(),
          contains('Call TimelineConfigurationManager.initialize()'),
        );
      }
    });
  });

  group('TimelineConfigurationManager - utilities', () {
    test('reset() clears singleton instance', () {
      // Arrange
      TimelineConfigurationManager.initialize(fileConfig: TestFixtures.defaultConfig);
      expect(TimelineConfigurationManager.isInitialized, isTrue);

      // Act
      TimelineConfigurationManager.reset();

      // Assert
      expect(TimelineConfigurationManager.isInitialized, isFalse);
      expect(
        () => TimelineConfigurationManager.configuration,
        throwsStateError,
      );
    });

    test('reset() allows re-initialization with different config', () {
      // Arrange
      final config1 = {'dayWidth': 50.0, 'bufferDays': 10};
      TimelineConfigurationManager.initialize(fileConfig: config1);
      final firstConfig = TimelineConfigurationManager.configuration;
      expect(firstConfig.dayWidth, equals(50.0));

      // Act
      TimelineConfigurationManager.reset();
      final config2 = {'dayWidth': 80.0, 'bufferDays': 15};
      TimelineConfigurationManager.initialize(fileConfig: config2);
      final secondConfig = TimelineConfigurationManager.configuration;

      // Assert
      expect(secondConfig.dayWidth, equals(80.0));
      expect(secondConfig.bufferDays, equals(15));
    });

    test('enableDebugMode enables debug logging', () {
      // Act
      TimelineConfigurationManager.enableDebugMode();

      // Assert
      expect(ConfigurationLogger.isDebugModeEnabled, isTrue);
    });

    test('disableDebugMode disables debug logging', () {
      // Arrange
      TimelineConfigurationManager.enableDebugMode();
      expect(ConfigurationLogger.isDebugModeEnabled, isTrue);

      // Act
      TimelineConfigurationManager.disableDebugMode();

      // Assert
      expect(ConfigurationLogger.isDebugModeEnabled, isFalse);
    });

    test('enableDebugMode before initialize prints configuration on init', () {
      // Arrange
      TimelineConfigurationManager.enableDebugMode();

      // Act - initialize should print debug info
      TimelineConfigurationManager.initialize(fileConfig: TestFixtures.defaultConfig);

      // Assert - just verify it doesn't crash and config is loaded
      expect(TimelineConfigurationManager.isInitialized, isTrue);
      expect(ConfigurationLogger.isDebugModeEnabled, isTrue);
    });

    test('enableDebugMode after initialize prints configuration immediately', () {
      // Arrange
      TimelineConfigurationManager.initialize(fileConfig: TestFixtures.defaultConfig);

      // Act - enabling debug mode after init should print current config
      TimelineConfigurationManager.enableDebugMode();

      // Assert
      expect(TimelineConfigurationManager.isInitialized, isTrue);
      expect(ConfigurationLogger.isDebugModeEnabled, isTrue);
    });

    test('toMap() returns null before initialization', () {
      // Act
      final map = TimelineConfigurationManager.toMap();

      // Assert
      expect(map, isNull);
    });

    test('toMap() returns correct structure after initialization', () {
      // Arrange
      TimelineConfigurationManager.initialize(fileConfig: TestFixtures.defaultConfig);

      // Act
      final map = TimelineConfigurationManager.toMap();

      // Assert
      expect(map, isNotNull);
      expect(map, isA<Map<String, dynamic>>());

      // Verify it's a valid map with expected keys
      expect(map!.containsKey('dayWidth'), isTrue);
      expect(map.containsKey('dayMargin'), isTrue);
      expect(map.containsKey('rowHeight'), isTrue);
      expect(map.containsKey('bufferDays'), isTrue);

      // Verify specific values
      expect(map['dayWidth'], equals(100.0));
      expect(map['dayMargin'], equals(5.0));
      expect(map['rowHeight'], equals(60.0));
      expect(map['bufferDays'], equals(10));
    });

    test('toMap() returns all configuration parameters', () {
      // Arrange
      TimelineConfigurationManager.initialize(fileConfig: TestFixtures.defaultConfig);

      // Act
      final map = TimelineConfigurationManager.toMap();

      // Assert
      expect(map, isNotNull);
      expect(map!.containsKey('dayWidth'), isTrue);
      expect(map.containsKey('dayMargin'), isTrue);
      expect(map.containsKey('datesHeight'), isTrue);
      expect(map.containsKey('rowHeight'), isTrue);
      expect(map.containsKey('rowMargin'), isTrue);
      expect(map.containsKey('bufferDays'), isTrue);
      expect(map.containsKey('animationDurationMs'), isTrue);
    });

    test('toMap() values match configuration object', () {
      // Arrange
      TimelineConfigurationManager.initialize(fileConfig: TestFixtures.defaultConfig);
      final config = TimelineConfigurationManager.configuration;

      // Act
      final map = TimelineConfigurationManager.toMap();

      // Assert
      expect(map, isNotNull);
      expect(map!['dayWidth'], equals(config.dayWidth));
      expect(map['dayMargin'], equals(config.dayMargin));
      expect(map['datesHeight'], equals(config.datesHeight));
      expect(map['rowHeight'], equals(config.rowHeight));
      expect(map['rowMargin'], equals(config.rowMargin));
      expect(map['bufferDays'], equals(config.bufferDays));
      expect(map['animationDurationMs'], equals(config.animationDuration.inMilliseconds));
    });
  });
}
