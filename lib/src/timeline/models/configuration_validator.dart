import 'configuration_logger.dart';
import 'parameter_constraints.dart';
import 'validation_error.dart';

/// Result of configuration validation.
///
/// Contains the validated configuration map along with any errors and warnings
/// that were encountered during validation.
class ValidationResult {
  /// The validated configuration map with invalid values replaced by defaults.
  final Map<String, dynamic> validatedConfig;

  /// List of validation errors encountered.
  final List<ValidationError> errors;

  /// List of validation warnings encountered.
  final List<ValidationWarning> warnings;

  /// Creates a [ValidationResult] with the given data.
  ValidationResult({
    required this.validatedConfig,
    required this.errors,
    required this.warnings,
  });
}

/// Validates configuration parameters against defined constraints.
///
/// This class provides methods to validate configuration maps, ensuring that
/// all parameters have valid types and values within acceptable ranges.
/// Invalid parameters are replaced with default values.
class ConfigurationValidator {
  /// Validates a raw configuration map.
  ///
  /// Returns a [ValidationResult] containing the validated configuration,
  /// along with any errors and warnings encountered during validation.
  ///
  /// If [rawConfig] is null, returns the default configuration.
  static ValidationResult validate(Map<String, dynamic>? rawConfig) {
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];
    final validatedConfig = <String, dynamic>{};

    // If no config provided, use defaults
    if (rawConfig == null) {
      return ValidationResult(
        validatedConfig: getDefaultConfiguration(),
        errors: errors,
        warnings: warnings,
      );
    }

    // Validate each known parameter
    for (final entry in ParameterConstraints.all.entries) {
      final paramName = entry.key;
      final constraints = entry.value;

      if (rawConfig.containsKey(paramName)) {
        final value = rawConfig[paramName];
        final result = validateParameter(paramName, value, constraints);

        if (result.errors.isNotEmpty) {
          errors.addAll(result.errors);
          validatedConfig[paramName] = constraints.defaultValue;

          // Log each validation error
          for (final error in result.errors) {
            ConfigurationLogger.validationError(
              error.parameterName,
              error.providedValue,
              error.expectedType,
              expectedRange: error.expectedRange,
              reason: error.message,
            );
          }
        } else if (result.warnings.isNotEmpty) {
          warnings.addAll(result.warnings);
          validatedConfig[paramName] = constraints.defaultValue;

          // Log each validation warning
          for (final warning in result.warnings) {
            ConfigurationLogger.validationWarning(
              warning.parameterName,
              warning.providedValue,
              warning.expectedType,
              expectedRange: warning.expectedRange,
              reason: warning.message,
            );
          }
        } else {
          validatedConfig[paramName] = value;
        }
      } else {
        // Parameter not provided, use default
        validatedConfig[paramName] = constraints.defaultValue;
      }
    }

    return ValidationResult(
      validatedConfig: validatedConfig,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validates a single parameter against its constraints.
  ///
  /// Returns a [ValidationResult] containing any errors or warnings.
  static ValidationResult validateParameter(
    String key,
    dynamic value,
    ParameterConstraints constraints,
  ) {
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];

    // Check type
    bool typeValid = true;
    if (constraints.type == 'double' && value is! num) {
      typeValid = false;
      warnings.add(ValidationWarning(
        parameterName: key,
        providedValue: value,
        expectedType: constraints.type,
        expectedRange: constraints.rangeString,
        message: 'Invalid type, expected ${constraints.type}',
      ));
    } else if (constraints.type == 'int') {
      if (value is! int && value is! num) {
        typeValid = false;
        warnings.add(ValidationWarning(
          parameterName: key,
          providedValue: value,
          expectedType: constraints.type,
          expectedRange: constraints.rangeString,
          message: 'Invalid type, expected ${constraints.type}',
        ));
      }
    }

    // Check range for numeric types
    if (typeValid && value is num) {
      if (constraints.min != null && value < constraints.min!) {
        errors.add(ValidationError(
          parameterName: key,
          providedValue: value,
          expectedType: constraints.type,
          expectedRange: constraints.rangeString,
          message: 'Value out of range',
        ));
      } else if (constraints.max != null && value > constraints.max!) {
        errors.add(ValidationError(
          parameterName: key,
          providedValue: value,
          expectedType: constraints.type,
          expectedRange: constraints.rangeString,
          message: 'Value out of range',
        ));
      }
    }

    return ValidationResult(
      validatedConfig: {},
      errors: errors,
      warnings: warnings,
    );
  }

  /// Returns the default configuration with all default values.
  static Map<String, dynamic> getDefaultConfiguration() {
    final defaultConfig = <String, dynamic>{};

    for (final entry in ParameterConstraints.all.entries) {
      defaultConfig[entry.key] = entry.value.defaultValue;
    }

    return defaultConfig;
  }
}
