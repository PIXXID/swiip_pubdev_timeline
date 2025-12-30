import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/models.dart';

void main() {
  group('ConfigurationValidator', () {
    // Feature: external-configuration-system, Property 3: Parameter Range Validation
    // For any configuration parameter with out-of-range value, validator should use default
    // Validates: Requirements 3.1, 3.3
    test('out-of-range values use defaults', () {
      final random = Random(42);
      final constraints = ParameterConstraints.all;
      final defaults = ConfigurationValidator.getDefaultConfiguration();

      // Run 100 iterations with random out-of-range values
      for (int i = 0; i < 100; i++) {
        final config = <String, dynamic>{};

        // Generate random out-of-range values for each parameter
        for (final entry in constraints.entries) {
          final paramName = entry.key;
          final constraint = entry.value;

          if (constraint.min != null && constraint.max != null) {
            // Randomly choose to go below min or above max
            final goBelow = random.nextBool();
            if (goBelow) {
              // Generate value below minimum
              final belowMin = constraint.min! - random.nextDouble() * 100 - 1;
              config[paramName] = constraint.type == 'int' ? belowMin.toInt() : belowMin;
            } else {
              // Generate value above maximum
              final aboveMax = constraint.max! + random.nextDouble() * 100 + 1;
              config[paramName] = constraint.type == 'int' ? aboveMax.toInt() : aboveMax;
            }
          }
        }

        // Validate the configuration
        final result = ConfigurationValidator.validate(config);

        // Assert: all out-of-range parameters should use defaults
        for (final paramName in config.keys) {
          expect(
            result.validatedConfig[paramName],
            equals(defaults[paramName]),
            reason: 'Parameter $paramName with out-of-range value '
                '${config[paramName]} should use default ${defaults[paramName]}',
          );
        }

        // Assert: errors should be reported for out-of-range values
        expect(result.errors.isNotEmpty, isTrue, reason: 'Out-of-range values should generate errors');
      }
    });

    // Feature: external-configuration-system, Property 4: Type Validation
    // For any parameter with incorrect type, validator should log warning and use default
    // Validates: Requirements 3.2
    test('incorrect types use defaults and log warnings', () {
      final constraints = ParameterConstraints.all;
      final defaults = ConfigurationValidator.getDefaultConfiguration();

      // Run 100 iterations with random incorrect types
      for (int i = 0; i < 100; i++) {
        final config = <String, dynamic>{};

        // Generate incorrect types for each parameter
        for (final entry in constraints.entries) {
          final paramName = entry.key;
          final constraint = entry.value;

          // Provide wrong type based on expected type
          if (constraint.type == 'double' || constraint.type == 'int') {
            // Provide string instead of number
            config[paramName] = 'not_a_number_$i';
          } else if (constraint.type == 'String') {
            // Provide number instead of string
            config[paramName] = 123;
          }
        }

        // Validate the configuration
        final result = ConfigurationValidator.validate(config);

        // Assert: all parameters with incorrect types should use defaults
        for (final paramName in config.keys) {
          expect(
            result.validatedConfig[paramName],
            equals(defaults[paramName]),
            reason: 'Parameter $paramName with incorrect type '
                '${config[paramName].runtimeType} should use default ${defaults[paramName]}',
          );
        }

        // Assert: warnings should be logged for type mismatches
        expect(result.warnings.isNotEmpty, isTrue, reason: 'Type mismatches should generate warnings');
      }
    });

    // Feature: external-configuration-system, Property 5: Partial Configuration Validity
    // For any config with mixed valid/invalid parameters, valid ones should be preserved
    // Validates: Requirements 3.4
    test('partial configuration preserves valid parameters', () {
      final random = Random(42);
      final constraints = ParameterConstraints.all;
      final defaults = ConfigurationValidator.getDefaultConfiguration();
      final paramNames = constraints.keys.toList();

      // Run 100 iterations with mixed valid/invalid configurations
      for (int i = 0; i < 100; i++) {
        final config = <String, dynamic>{};
        final validParams = <String, dynamic>{};
        final invalidParams = <String>{};

        // Randomly assign valid or invalid values to each parameter
        for (final paramName in paramNames) {
          final constraint = constraints[paramName]!;
          final makeInvalid = random.nextBool();

          if (makeInvalid) {
            // Create invalid value (out of range or wrong type)
            if (random.nextBool()) {
              // Out of range
              if (constraint.max != null) {
                final outOfRange = constraint.max! + random.nextDouble() * 100 + 1;
                config[paramName] = constraint.type == 'int' ? outOfRange.toInt() : outOfRange;
              }
            } else {
              // Wrong type
              config[paramName] = 'invalid_type_$i';
            }
            invalidParams.add(paramName);
          } else {
            // Create valid value within range
            if (constraint.min != null && constraint.max != null) {
              final range = constraint.max! - constraint.min!;
              final validValue = constraint.min! + random.nextDouble() * range;
              final value = constraint.type == 'int' ? validValue.toInt() : validValue;
              config[paramName] = value;
              validParams[paramName] = value;
            }
          }
        }

        // Validate the configuration
        final result = ConfigurationValidator.validate(config);

        // Assert: valid parameters should be preserved
        for (final entry in validParams.entries) {
          expect(
            result.validatedConfig[entry.key],
            equals(entry.value),
            reason: 'Valid parameter ${entry.key} with value ${entry.value} '
                'should be preserved',
          );
        }

        // Assert: invalid parameters should use defaults
        for (final paramName in invalidParams) {
          expect(
            result.validatedConfig[paramName],
            equals(defaults[paramName]),
            reason: 'Invalid parameter $paramName should use default',
          );
        }
      }
    });

    // Feature: external-configuration-system, Property 11: Error Aggregation
    // For any config with multiple invalid parameters, all errors should be reported together
    // Validates: Requirements 9.5
    test('multiple invalid parameters report all errors together', () {
      final random = Random(42);
      final constraints = ParameterConstraints.all;
      final paramNames = constraints.keys.toList();

      // Run 100 iterations with multiple invalid parameters
      for (int i = 0; i < 100; i++) {
        final config = <String, dynamic>{};
        final expectedErrorCount = random.nextInt(paramNames.length) + 1;
        final invalidParamCount = <String>{};

        // Create configuration with multiple out-of-range values
        for (int j = 0; j < expectedErrorCount && j < paramNames.length; j++) {
          final paramName = paramNames[j];
          final constraint = constraints[paramName]!;

          // Create out-of-range value (which generates errors, not warnings)
          if (constraint.max != null) {
            final outOfRange = constraint.max! + random.nextDouble() * 100 + 1;
            config[paramName] = constraint.type == 'int' ? outOfRange.toInt() : outOfRange;
            invalidParamCount.add(paramName);
          }
        }

        // Validate the configuration
        final result = ConfigurationValidator.validate(config);

        // Assert: all errors should be collected and reported together
        expect(
          result.errors.length,
          equals(invalidParamCount.length),
          reason: 'All ${invalidParamCount.length} invalid parameters should '
              'generate errors, but got ${result.errors.length} errors',
        );

        // Assert: each invalid parameter should have a corresponding error
        final errorParamNames = result.errors.map((e) => e.parameterName).toSet();
        expect(
          errorParamNames,
          equals(invalidParamCount),
          reason: 'Error parameter names should match invalid parameters',
        );
      }
    });

    // Feature: external-configuration-system, Property 10: Error Message Completeness
    // For any validation failure, error message should contain parameter name, value, and expected range/type
    // Validates: Requirements 3.5, 9.4
    test('error messages contain parameter name, value, and expected range/type', () {
      final random = Random(42);
      final constraints = ParameterConstraints.all;

      // Run 100 iterations with various validation failures
      for (int i = 0; i < 100; i++) {
        final config = <String, dynamic>{};

        // Generate various types of validation failures
        for (final entry in constraints.entries) {
          final paramName = entry.key;
          final constraint = entry.value;

          // Randomly choose type of failure
          final failureType = random.nextInt(3);

          if (failureType == 0 && constraint.max != null) {
            // Out of range (above max)
            final outOfRange = constraint.max! + random.nextDouble() * 100 + 1;
            config[paramName] = constraint.type == 'int' ? outOfRange.toInt() : outOfRange;
          } else if (failureType == 1 && constraint.min != null) {
            // Out of range (below min)
            final outOfRange = constraint.min! - random.nextDouble() * 100 - 1;
            config[paramName] = constraint.type == 'int' ? outOfRange.toInt() : outOfRange;
          } else if (failureType == 2) {
            // Wrong type
            config[paramName] = 'invalid_type_$i';
          }
        }

        // Validate the configuration
        final result = ConfigurationValidator.validate(config);

        // Assert: all errors should contain required information
        for (final error in result.errors) {
          // Check parameter name is present
          expect(
            error.parameterName,
            isNotEmpty,
            reason: 'Error should contain parameter name',
          );

          // Check provided value is present
          expect(
            error.providedValue,
            isNotNull,
            reason: 'Error should contain provided value',
          );

          // Check expected type is present
          expect(
            error.expectedType,
            isNotEmpty,
            reason: 'Error should contain expected type',
          );

          // Check expected range is present for numeric types
          if (error.expectedType == 'double' || error.expectedType == 'int') {
            expect(
              error.expectedRange,
              isNotNull,
              reason: 'Error for numeric type should contain expected range',
            );
            expect(
              error.expectedRange,
              isNotEmpty,
              reason: 'Expected range should not be empty',
            );
          }

          // Check message is present
          expect(
            error.message,
            isNotEmpty,
            reason: 'Error should contain a message',
          );

          // Check toString contains all required information
          final errorString = error.toString();
          expect(
            errorString.contains(error.parameterName),
            isTrue,
            reason: 'Error string should contain parameter name',
          );
          expect(
            errorString.contains(error.providedValue.toString()),
            isTrue,
            reason: 'Error string should contain provided value',
          );
          expect(
            errorString.contains(error.expectedType),
            isTrue,
            reason: 'Error string should contain expected type',
          );
        }

        // Assert: all warnings should contain required information
        for (final warning in result.warnings) {
          // Check parameter name is present
          expect(
            warning.parameterName,
            isNotEmpty,
            reason: 'Warning should contain parameter name',
          );

          // Check provided value is present
          expect(
            warning.providedValue,
            isNotNull,
            reason: 'Warning should contain provided value',
          );

          // Check expected type is present
          expect(
            warning.expectedType,
            isNotEmpty,
            reason: 'Warning should contain expected type',
          );

          // Check message is present
          expect(
            warning.message,
            isNotEmpty,
            reason: 'Warning should contain a message',
          );

          // Check toString contains all required information
          final warningString = warning.toString();
          expect(
            warningString.contains(warning.parameterName),
            isTrue,
            reason: 'Warning string should contain parameter name',
          );
          expect(
            warningString.contains(warning.providedValue.toString()),
            isTrue,
            reason: 'Warning string should contain provided value',
          );
          expect(
            warningString.contains(warning.expectedType),
            isTrue,
            reason: 'Warning string should contain expected type',
          );
        }
      }
    });
  });
}
