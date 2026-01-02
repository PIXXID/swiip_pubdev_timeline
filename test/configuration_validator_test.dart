import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/configuration_validator.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/parameter_constraints.dart';

void main() {
  group('ConfigurationValidator - validate', () {
    test('validate with null config returns defaults', () {
      // Act
      final result = ConfigurationValidator.validate(null);

      // Assert
      expect(result.validatedConfig, isNotNull);
      expect(result.errors, isEmpty);
      expect(result.warnings, isEmpty);

      // Verify all default values are present
      expect(result.validatedConfig['dayWidth'], equals(45.0));
      expect(result.validatedConfig['dayMargin'], equals(5.0));
      expect(result.validatedConfig['datesHeight'], equals(65.0));
      expect(result.validatedConfig['rowHeight'], equals(30.0));
      expect(result.validatedConfig['rowMargin'], equals(3.0));
      expect(result.validatedConfig['bufferDays'], equals(5));
      expect(result.validatedConfig['animationDurationMs'], equals(220));
    });

    test('validate with missing parameter uses default', () {
      // Arrange - config missing dayMargin and bufferDays
      final config = {
        'dayWidth': 50.0,
        'rowHeight': 40.0,
        // Missing: dayMargin, bufferDays, etc.
      };

      // Act
      final result = ConfigurationValidator.validate(config);

      // Assert
      expect(result.validatedConfig, isNotNull);
      expect(result.errors, isEmpty);
      expect(result.warnings, isEmpty);

      // Provided values should be used
      expect(result.validatedConfig['dayWidth'], equals(50.0));
      expect(result.validatedConfig['rowHeight'], equals(40.0));

      // Missing values should use defaults
      expect(result.validatedConfig['dayMargin'], equals(5.0)); // Default
      expect(result.validatedConfig['bufferDays'], equals(5)); // Default
      expect(result.validatedConfig['datesHeight'], equals(65.0)); // Default
    });

    test('validate with invalid type uses default and generates warning', () {
      // Arrange - config with wrong types
      final config = {
        'dayWidth': 'not a number', // Should be double
        'bufferDays': 'invalid', // Should be int
        'rowHeight': true, // Should be double
      };

      // Act
      final result = ConfigurationValidator.validate(config);

      // Assert
      expect(result.validatedConfig, isNotNull);
      expect(result.errors, isEmpty);
      expect(result.warnings, isNotEmpty);
      expect(result.warnings.length, equals(3));

      // All invalid values should be replaced with defaults
      expect(result.validatedConfig['dayWidth'], equals(45.0)); // Default
      expect(result.validatedConfig['bufferDays'], equals(5)); // Default
      expect(result.validatedConfig['rowHeight'], equals(30.0)); // Default

      // Verify warnings contain correct information
      final dayWidthWarning = result.warnings.firstWhere((w) => w.parameterName == 'dayWidth');
      expect(dayWidthWarning.providedValue, equals('not a number'));
      expect(dayWidthWarning.expectedType, equals('double'));
      expect(dayWidthWarning.message, contains('Invalid type'));
    });

    test('validate with negative value for positive parameter uses default', () {
      // Arrange - config with negative values
      final config = {
        'dayWidth': -50.0, // Should be >= 20.0
        'bufferDays': -10, // Should be >= 1
        'rowMargin': -5.0, // Should be >= 0.0
      };

      // Act
      final result = ConfigurationValidator.validate(config);

      // Assert
      expect(result.validatedConfig, isNotNull);
      expect(result.warnings, isEmpty);
      expect(result.errors, isNotEmpty);
      expect(result.errors.length, equals(3));

      // All out-of-range values should be replaced with defaults
      expect(result.validatedConfig['dayWidth'], equals(45.0)); // Default
      expect(result.validatedConfig['bufferDays'], equals(5)); // Default
      expect(result.validatedConfig['rowMargin'], equals(3.0)); // Default

      // Verify errors contain correct information
      final dayWidthError = result.errors.firstWhere((e) => e.parameterName == 'dayWidth');
      expect(dayWidthError.providedValue, equals(-50.0));
      expect(dayWidthError.expectedType, equals('double'));
      expect(dayWidthError.expectedRange, equals('20.0 - 100.0'));
      expect(dayWidthError.message, contains('Value out of range'));
    });

    test('validate with values above maximum uses default', () {
      // Arrange - config with values exceeding max
      final config = {
        'dayWidth': 150.0, // Max is 100.0
        'bufferDays': 50, // Max is 20
        'rowHeight': 100.0, // Max is 60.0
      };

      // Act
      final result = ConfigurationValidator.validate(config);

      // Assert
      expect(result.validatedConfig, isNotNull);
      expect(result.warnings, isEmpty);
      expect(result.errors, isNotEmpty);
      expect(result.errors.length, equals(3));

      // All out-of-range values should be replaced with defaults
      expect(result.validatedConfig['dayWidth'], equals(45.0)); // Default
      expect(result.validatedConfig['bufferDays'], equals(5)); // Default
      expect(result.validatedConfig['rowHeight'], equals(30.0)); // Default
    });

    test('getDefaultConfiguration returns all parameters', () {
      // Act
      final defaults = ConfigurationValidator.getDefaultConfiguration();

      // Assert
      expect(defaults, isNotNull);
      expect(defaults, isNotEmpty);

      // Verify all known parameters are present
      expect(defaults.containsKey('dayWidth'), isTrue);
      expect(defaults.containsKey('dayMargin'), isTrue);
      expect(defaults.containsKey('datesHeight'), isTrue);
      expect(defaults.containsKey('rowHeight'), isTrue);
      expect(defaults.containsKey('rowMargin'), isTrue);
      expect(defaults.containsKey('bufferDays'), isTrue);
      expect(defaults.containsKey('animationDurationMs'), isTrue);

      // Verify default values match ParameterConstraints
      expect(defaults['dayWidth'], equals(45.0));
      expect(defaults['dayMargin'], equals(5.0));
      expect(defaults['datesHeight'], equals(65.0));
      expect(defaults['rowHeight'], equals(30.0));
      expect(defaults['rowMargin'], equals(3.0));
      expect(defaults['bufferDays'], equals(5));
      expect(defaults['animationDurationMs'], equals(220));
    });

    test('validate with all valid parameters returns no errors or warnings', () {
      // Arrange - all valid values within ranges
      final config = {
        'dayWidth': 50.0, // Valid: 20.0 - 100.0
        'dayMargin': 3.0, // Valid: 0.0 - 20.0
        'datesHeight': 70.0, // Valid: 40.0 - 100.0
        'rowHeight': 40.0, // Valid: 20.0 - 60.0
        'rowMargin': 5.0, // Valid: 0.0 - 10.0
        'bufferDays': 10, // Valid: 1 - 20
        'animationDurationMs': 300, // Valid: 100 - 500
      };

      // Act
      final result = ConfigurationValidator.validate(config);

      // Assert
      expect(result.validatedConfig, isNotNull);
      expect(result.errors, isEmpty);
      expect(result.warnings, isEmpty);

      // All values should be preserved
      expect(result.validatedConfig['dayWidth'], equals(50.0));
      expect(result.validatedConfig['dayMargin'], equals(3.0));
      expect(result.validatedConfig['datesHeight'], equals(70.0));
      expect(result.validatedConfig['rowHeight'], equals(40.0));
      expect(result.validatedConfig['rowMargin'], equals(5.0));
      expect(result.validatedConfig['bufferDays'], equals(10));
      expect(result.validatedConfig['animationDurationMs'], equals(300));
    });

    test('validate with boundary values at minimum returns no errors', () {
      // Arrange - all values at minimum boundaries
      final config = {
        'dayWidth': 20.0, // Min boundary
        'dayMargin': 0.0, // Min boundary
        'datesHeight': 40.0, // Min boundary
        'rowHeight': 20.0, // Min boundary
        'rowMargin': 0.0, // Min boundary
        'bufferDays': 1, // Min boundary
        'animationDurationMs': 100, // Min boundary
      };

      // Act
      final result = ConfigurationValidator.validate(config);

      // Assert
      expect(result.validatedConfig, isNotNull);
      expect(result.errors, isEmpty);
      expect(result.warnings, isEmpty);

      // All boundary values should be preserved
      expect(result.validatedConfig['dayWidth'], equals(20.0));
      expect(result.validatedConfig['dayMargin'], equals(0.0));
      expect(result.validatedConfig['bufferDays'], equals(1));
    });

    test('validate with boundary values at maximum returns no errors', () {
      // Arrange - all values at maximum boundaries
      final config = {
        'dayWidth': 100.0, // Max boundary
        'dayMargin': 20.0, // Max boundary
        'datesHeight': 100.0, // Max boundary
        'rowHeight': 60.0, // Max boundary
        'rowMargin': 10.0, // Max boundary
        'bufferDays': 20, // Max boundary
        'animationDurationMs': 500, // Max boundary
      };

      // Act
      final result = ConfigurationValidator.validate(config);

      // Assert
      expect(result.validatedConfig, isNotNull);
      expect(result.errors, isEmpty);
      expect(result.warnings, isEmpty);

      // All boundary values should be preserved
      expect(result.validatedConfig['dayWidth'], equals(100.0));
      expect(result.validatedConfig['dayMargin'], equals(20.0));
      expect(result.validatedConfig['bufferDays'], equals(20));
    });

    test('validate with mixed valid and invalid parameters', () {
      // Arrange - mix of valid and invalid values
      final config = {
        'dayWidth': 60.0, // Valid
        'dayMargin': -5.0, // Invalid: negative
        'rowHeight': 'invalid', // Invalid: wrong type
        'bufferDays': 15, // Valid
        'animationDurationMs': 1000, // Invalid: too large
      };

      // Act
      final result = ConfigurationValidator.validate(config);

      // Assert
      expect(result.validatedConfig, isNotNull);

      // Valid values should be preserved
      expect(result.validatedConfig['dayWidth'], equals(60.0));
      expect(result.validatedConfig['bufferDays'], equals(15));

      // Invalid values should use defaults
      expect(result.validatedConfig['dayMargin'], equals(5.0)); // Default
      expect(result.validatedConfig['rowHeight'], equals(30.0)); // Default
      expect(result.validatedConfig['animationDurationMs'], equals(220)); // Default

      // Should have both errors and warnings
      expect(result.errors.length, equals(2)); // dayMargin, animationDurationMs
      expect(result.warnings.length, equals(1)); // rowHeight
    });

    test('validate with empty config uses all defaults', () {
      // Arrange
      final config = <String, dynamic>{};

      // Act
      final result = ConfigurationValidator.validate(config);

      // Assert
      expect(result.validatedConfig, isNotNull);
      expect(result.errors, isEmpty);
      expect(result.warnings, isEmpty);

      // All values should be defaults
      expect(result.validatedConfig['dayWidth'], equals(45.0));
      expect(result.validatedConfig['dayMargin'], equals(5.0));
      expect(result.validatedConfig['datesHeight'], equals(65.0));
      expect(result.validatedConfig['rowHeight'], equals(30.0));
      expect(result.validatedConfig['rowMargin'], equals(3.0));
      expect(result.validatedConfig['bufferDays'], equals(5));
      expect(result.validatedConfig['animationDurationMs'], equals(220));
    });
  });

  group('ConfigurationValidator - validateParameter', () {
    test('validateParameter with valid value returns no errors or warnings', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'double',
        min: 20.0,
        max: 100.0,
        defaultValue: 45.0,
      );

      // Act
      final result = ConfigurationValidator.validateParameter('dayWidth', 50.0, constraints);

      // Assert
      expect(result.errors, isEmpty);
      expect(result.warnings, isEmpty);
    });

    test('validateParameter with invalid type generates warning', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'double',
        min: 20.0,
        max: 100.0,
        defaultValue: 45.0,
      );

      // Act
      final result = ConfigurationValidator.validateParameter('dayWidth', 'not a number', constraints);

      // Assert
      expect(result.errors, isEmpty);
      expect(result.warnings, isNotEmpty);
      expect(result.warnings.length, equals(1));

      final warning = result.warnings.first;
      expect(warning.parameterName, equals('dayWidth'));
      expect(warning.providedValue, equals('not a number'));
      expect(warning.expectedType, equals('double'));
      expect(warning.message, contains('Invalid type'));
    });

    test('validateParameter with value below minimum generates error', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'double',
        min: 20.0,
        max: 100.0,
        defaultValue: 45.0,
      );

      // Act
      final result = ConfigurationValidator.validateParameter('dayWidth', 10.0, constraints);

      // Assert
      expect(result.errors, isNotEmpty);
      expect(result.errors.length, equals(1));
      expect(result.warnings, isEmpty);

      final error = result.errors.first;
      expect(error.parameterName, equals('dayWidth'));
      expect(error.providedValue, equals(10.0));
      expect(error.expectedType, equals('double'));
      expect(error.expectedRange, equals('20.0 - 100.0'));
      expect(error.message, contains('Value out of range'));
    });

    test('validateParameter with value above maximum generates error', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'double',
        min: 20.0,
        max: 100.0,
        defaultValue: 45.0,
      );

      // Act
      final result = ConfigurationValidator.validateParameter('dayWidth', 150.0, constraints);

      // Assert
      expect(result.errors, isNotEmpty);
      expect(result.errors.length, equals(1));
      expect(result.warnings, isEmpty);

      final error = result.errors.first;
      expect(error.parameterName, equals('dayWidth'));
      expect(error.providedValue, equals(150.0));
      expect(error.expectedType, equals('double'));
      expect(error.expectedRange, equals('20.0 - 100.0'));
      expect(error.message, contains('Value out of range'));
    });

    test('validateParameter with value at minimum boundary is valid', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'double',
        min: 20.0,
        max: 100.0,
        defaultValue: 45.0,
      );

      // Act
      final result = ConfigurationValidator.validateParameter('dayWidth', 20.0, constraints);

      // Assert
      expect(result.errors, isEmpty);
      expect(result.warnings, isEmpty);
    });

    test('validateParameter with value at maximum boundary is valid', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'double',
        min: 20.0,
        max: 100.0,
        defaultValue: 45.0,
      );

      // Act
      final result = ConfigurationValidator.validateParameter('dayWidth', 100.0, constraints);

      // Assert
      expect(result.errors, isEmpty);
      expect(result.warnings, isEmpty);
    });

    test('validateParameter with int type and valid int value is valid', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'int',
        min: 1,
        max: 20,
        defaultValue: 5,
      );

      // Act
      final result = ConfigurationValidator.validateParameter('bufferDays', 10, constraints);

      // Assert
      expect(result.errors, isEmpty);
      expect(result.warnings, isEmpty);
    });

    test('validateParameter with int type and invalid type generates warning', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'int',
        min: 1,
        max: 20,
        defaultValue: 5,
      );

      // Act
      final result = ConfigurationValidator.validateParameter('bufferDays', 'not an int', constraints);

      // Assert
      expect(result.errors, isEmpty);
      expect(result.warnings, isNotEmpty);
      expect(result.warnings.length, equals(1));

      final warning = result.warnings.first;
      expect(warning.parameterName, equals('bufferDays'));
      expect(warning.expectedType, equals('int'));
    });

    test('validateParameter with int type accepts num values', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'int',
        min: 1,
        max: 20,
        defaultValue: 5,
      );

      // Act - passing a double that represents an int
      final result = ConfigurationValidator.validateParameter('bufferDays', 10.0, constraints);

      // Assert - should be valid since num includes both int and double
      expect(result.errors, isEmpty);
      expect(result.warnings, isEmpty);
    });

    test('validateParameter with double type accepts int values', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'double',
        min: 20.0,
        max: 100.0,
        defaultValue: 45.0,
      );

      // Act - passing an int
      final result = ConfigurationValidator.validateParameter('dayWidth', 50, constraints);

      // Assert - should be valid since int is a num
      expect(result.errors, isEmpty);
      expect(result.warnings, isEmpty);
    });

    test('validateParameter with null value generates type warning', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'double',
        min: 20.0,
        max: 100.0,
        defaultValue: 45.0,
      );

      // Act
      final result = ConfigurationValidator.validateParameter('dayWidth', null, constraints);

      // Assert
      expect(result.errors, isEmpty);
      expect(result.warnings, isNotEmpty);
      expect(result.warnings.first.message, contains('Invalid type'));
    });

    test('validateParameter with boolean value generates type warning', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'double',
        min: 20.0,
        max: 100.0,
        defaultValue: 45.0,
      );

      // Act
      final result = ConfigurationValidator.validateParameter('dayWidth', true, constraints);

      // Assert
      expect(result.errors, isEmpty);
      expect(result.warnings, isNotEmpty);
      expect(result.warnings.first.expectedType, equals('double'));
    });

    test('validateParameter with constraints having only min validates correctly', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'double',
        min: 20.0,
        defaultValue: 45.0,
      );

      // Act - value above min
      final validResult = ConfigurationValidator.validateParameter('param', 50.0, constraints);
      // Act - value below min
      final invalidResult = ConfigurationValidator.validateParameter('param', 10.0, constraints);

      // Assert
      expect(validResult.errors, isEmpty);
      expect(validResult.warnings, isEmpty);

      expect(invalidResult.errors, isNotEmpty);
      expect(invalidResult.errors.first.expectedRange, equals('>= 20.0'));
    });

    test('validateParameter with constraints having only max validates correctly', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'double',
        max: 100.0,
        defaultValue: 45.0,
      );

      // Act - value below max
      final validResult = ConfigurationValidator.validateParameter('param', 50.0, constraints);
      // Act - value above max
      final invalidResult = ConfigurationValidator.validateParameter('param', 150.0, constraints);

      // Assert
      expect(validResult.errors, isEmpty);
      expect(validResult.warnings, isEmpty);

      expect(invalidResult.errors, isNotEmpty);
      expect(invalidResult.errors.first.expectedRange, equals('<= 100.0'));
    });

    test('validateParameter with no range constraints only validates type', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'double',
        defaultValue: 45.0,
      );

      // Act - any numeric value should be valid
      final result1 = ConfigurationValidator.validateParameter('param', -1000.0, constraints);
      final result2 = ConfigurationValidator.validateParameter('param', 1000.0, constraints);
      final result3 = ConfigurationValidator.validateParameter('param', 0.0, constraints);

      // Assert - all should be valid
      expect(result1.errors, isEmpty);
      expect(result1.warnings, isEmpty);
      expect(result2.errors, isEmpty);
      expect(result2.warnings, isEmpty);
      expect(result3.errors, isEmpty);
      expect(result3.warnings, isEmpty);
    });
  });
}
