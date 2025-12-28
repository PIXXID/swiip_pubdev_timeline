/// Represents a validation error for a configuration parameter.
///
/// This class encapsulates information about a parameter that failed validation,
/// including the parameter name, the provided value, the expected type/range,
/// and a descriptive error message.
class ValidationError {
  /// The name of the parameter that failed validation.
  final String parameterName;

  /// The value that was provided for the parameter.
  final dynamic providedValue;

  /// The expected type for the parameter (e.g., "double", "int", "String").
  final String expectedType;

  /// The expected range for the parameter (e.g., "20.0 - 100.0"), if applicable.
  final String? expectedRange;

  /// A descriptive error message explaining the validation failure.
  final String message;

  /// Creates a [ValidationError] with the given details.
  ValidationError({
    required this.parameterName,
    required this.providedValue,
    required this.expectedType,
    this.expectedRange,
    required this.message,
  });

  @override
  String toString() {
    return 'ValidationError: $parameterName - $message '
        '(provided: $providedValue, expected: $expectedType'
        '${expectedRange != null ? ", range: $expectedRange" : ""})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationError &&
          runtimeType == other.runtimeType &&
          parameterName == other.parameterName &&
          providedValue == other.providedValue &&
          expectedType == other.expectedType &&
          expectedRange == other.expectedRange &&
          message == other.message;

  @override
  int get hashCode => Object.hash(
        parameterName,
        providedValue,
        expectedType,
        expectedRange,
        message,
      );
}

/// Represents a validation warning for a configuration parameter.
///
/// This class encapsulates information about a parameter that has a non-critical
/// issue, such as using a default value due to a missing or invalid parameter.
class ValidationWarning {
  /// The name of the parameter that triggered the warning.
  final String parameterName;

  /// The value that was provided for the parameter, if any.
  final dynamic providedValue;

  /// The expected type for the parameter (e.g., "double", "int", "String").
  final String expectedType;

  /// The expected range for the parameter (e.g., "20.0 - 100.0"), if applicable.
  final String? expectedRange;

  /// A descriptive warning message.
  final String message;

  /// Creates a [ValidationWarning] with the given details.
  ValidationWarning({
    required this.parameterName,
    required this.providedValue,
    required this.expectedType,
    this.expectedRange,
    required this.message,
  });

  @override
  String toString() {
    return 'ValidationWarning: $parameterName - $message '
        '(provided: $providedValue, expected: $expectedType'
        '${expectedRange != null ? ", range: $expectedRange" : ""})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationWarning &&
          runtimeType == other.runtimeType &&
          parameterName == other.parameterName &&
          providedValue == other.providedValue &&
          expectedType == other.expectedType &&
          expectedRange == other.expectedRange &&
          message == other.message;

  @override
  int get hashCode => Object.hash(
        parameterName,
        providedValue,
        expectedType,
        expectedRange,
        message,
      );
}
