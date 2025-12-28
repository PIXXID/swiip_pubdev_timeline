import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/models.dart';

void main() {
  group('ConfigurationLoader', () {
    // Feature: external-configuration-system, Property 1: Configuration File Loading
    // For any valid JSON file, loading should return non-null Map
    // Validates: Requirements 1.1, 1.3, 4.3
    test('valid JSON files return non-null Map', () {
      final random = Random(42);
      final tempDir = Directory.systemTemp.createTempSync('config_test_');

      try {
        // Run 100 iterations with random valid configurations
        for (int i = 0; i < 100; i++) {
          final config = _generateRandomValidConfig(random);
          final jsonString = jsonEncode(config);

          // Write to temporary file
          final testFile = File('${tempDir.path}/test_config_$i.json');
          testFile.writeAsStringSync(jsonString);

          // Load configuration
          final loaded = ConfigurationLoader.loadConfigurationSync(
            configPath: testFile.path,
          );

          // Assert: loading should return non-null Map
          expect(
            loaded,
            isNotNull,
            reason: 'Valid JSON file should return non-null Map',
          );

          // Assert: loaded config should be a Map
          expect(
            loaded,
            isA<Map<String, dynamic>>(),
            reason: 'Loaded config should be a Map<String, dynamic>',
          );

          // Assert: loaded config should match original (for values that were written)
          for (final key in config.keys) {
            expect(
              loaded![key],
              equals(config[key]),
              reason: 'Loaded value for $key should match original',
            );
          }

          // Clean up
          testFile.deleteSync();
        }
      } finally {
        // Clean up temp directory
        tempDir.deleteSync(recursive: true);
      }
    });

    // Feature: external-configuration-system, Property 2: Default Configuration Fallback
    // For any missing or malformed file, system should use defaults
    // Validates: Requirements 1.2, 1.5, 4.2, 4.4
    test('missing or malformed files return null', () {
      final random = Random(42);
      final tempDir = Directory.systemTemp.createTempSync('config_test_');

      try {
        // Test 1: Missing files (50 iterations)
        for (int i = 0; i < 50; i++) {
          final nonExistentPath = '${tempDir.path}/non_existent_$i.json';

          final loaded = ConfigurationLoader.loadConfigurationSync(
            configPath: nonExistentPath,
          );

          // Assert: missing file should return null
          expect(
            loaded,
            isNull,
            reason: 'Missing file should return null',
          );
        }

        // Test 2: Malformed JSON files (50 iterations)
        for (int i = 0; i < 50; i++) {
          final malformedJson = _generateMalformedJson(random, i);
          final testFile = File('${tempDir.path}/malformed_$i.json');
          testFile.writeAsStringSync(malformedJson);

          final loaded = ConfigurationLoader.loadConfigurationSync(
            configPath: testFile.path,
          );

          // Assert: malformed file should return null
          expect(
            loaded,
            isNull,
            reason: 'Malformed JSON should return null',
          );

          // Clean up
          testFile.deleteSync();
        }
      } finally {
        // Clean up temp directory
        tempDir.deleteSync(recursive: true);
      }
    });

    // Feature: external-configuration-system, Property 12: Loading Performance
    // For any config file under 10KB, loading should complete within 100ms
    // Validates: Requirements 4.5, 10.5
    test('config files under 10KB load within 100ms', () {
      final random = Random(42);
      final tempDir = Directory.systemTemp.createTempSync('config_test_');

      try {
        // Run 100 iterations with various file sizes under 10KB
        for (int i = 0; i < 100; i++) {
          // Generate config with varying complexity
          final config = _generateRandomValidConfig(random);

          // Add some extra data to vary file size (but keep under 10KB)
          final extraFields = random.nextInt(50);
          for (int j = 0; j < extraFields; j++) {
            config['extra_field_$j'] = random.nextDouble() * 1000;
          }

          final jsonString = jsonEncode(config);
          final testFile = File('${tempDir.path}/perf_test_$i.json');
          testFile.writeAsStringSync(jsonString);

          // Verify file is under 10KB
          final fileSize = testFile.lengthSync();
          expect(
            fileSize,
            lessThan(10 * 1024),
            reason: 'Test file should be under 10KB',
          );

          // Measure loading time
          final stopwatch = Stopwatch()..start();
          final loaded = ConfigurationLoader.loadConfigurationSync(
            configPath: testFile.path,
          );
          stopwatch.stop();

          // Assert: loading should complete within 100ms
          expect(
            stopwatch.elapsedMilliseconds,
            lessThan(100),
            reason:
                'Loading ${fileSize} byte file should complete within 100ms, '
                'but took ${stopwatch.elapsedMilliseconds}ms',
          );

          // Assert: loading should succeed
          expect(
            loaded,
            isNotNull,
            reason: 'Valid file should load successfully',
          );

          // Clean up
          testFile.deleteSync();
        }
      } finally {
        // Clean up temp directory
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}

/// Generates a random valid configuration map.
Map<String, dynamic> _generateRandomValidConfig(Random random) {
  final config = <String, dynamic>{};
  final constraints = ParameterConstraints.all;

  // Randomly include some parameters (not all)
  for (final entry in constraints.entries) {
    if (random.nextBool()) {
      final paramName = entry.key;
      final constraint = entry.value;

      // Generate valid value within range
      if (constraint.min != null && constraint.max != null) {
        final range = constraint.max! - constraint.min!;
        final value = constraint.min! + random.nextDouble() * range;
        config[paramName] = constraint.type == 'int' ? value.toInt() : value;
      } else {
        config[paramName] = constraint.defaultValue;
      }
    }
  }

  return config;
}

/// Generates malformed JSON strings for testing error handling.
String _generateMalformedJson(Random random, int seed) {
  final malformedExamples = [
    '{ invalid json }',
    '{ "key": }',
    '{ "key": "value" ',
    '{ "key": "value", }',
    '[ "not", "an", "object" ]',
    'not json at all',
    '{ "key": undefined }',
    '{ "key": NaN }',
    '{ "key": Infinity }',
    '{ "key": "value" "key2": "value2" }',
    '{ "key": "value\n }',
    '{ "key": \'single quotes\' }',
  ];

  return malformedExamples[seed % malformedExamples.length];
}
