/// Defines constraints for a configuration parameter.
///
/// This class encapsulates the type, valid range, and default value for a
/// configuration parameter, enabling validation and fallback behavior.
class ParameterConstraints {
  /// The expected type of the parameter (e.g., "double", "int", "String").
  final String type;

  /// The minimum valid value for numeric parameters.
  final num? min;

  /// The maximum valid value for numeric parameters.
  final num? max;

  /// The default value to use if validation fails or the parameter is missing.
  final dynamic defaultValue;

  /// Creates a [ParameterConstraints] with the given constraints.
  const ParameterConstraints({
    required this.type,
    this.min,
    this.max,
    required this.defaultValue,
  });

  /// Returns a formatted string representing the valid range.
  String? get rangeString {
    if (min != null && max != null) {
      return '$min - $max';
    } else if (min != null) {
      return '>= $min';
    } else if (max != null) {
      return '<= $max';
    }
    return null;
  }

  /// Validates whether a value is within the defined constraints.
  ///
  /// Returns true if the value is valid, false otherwise.
  bool isValid(dynamic value) {
    // Check type
    if (type == 'double' && value is! num) {
      return false;
    }
    if (type == 'int' && value is! int && value is! num) {
      return false;
    }
    if (type == 'String' && value is! String) {
      return false;
    }

    // Check range for numeric types
    if (value is num) {
      if (min != null && value < min!) {
        return false;
      }
      if (max != null && value > max!) {
        return false;
      }
    }

    return true;
  }

  /// All parameter constraints for timeline configuration.
  static final Map<String, ParameterConstraints> all = {
    'dayWidth': const ParameterConstraints(
      type: 'double',
      min: 20.0,
      max: 100.0,
      defaultValue: 45.0,
    ),
    'dayMargin': const ParameterConstraints(
      type: 'double',
      min: 0.0,
      max: 20.0,
      defaultValue: 5.0,
    ),
    'datesHeight': const ParameterConstraints(
      type: 'double',
      min: 40.0,
      max: 100.0,
      defaultValue: 65.0,
    ),
    'timelineHeight': const ParameterConstraints(
      type: 'double',
      min: 100.0,
      max: 1000.0,
      defaultValue: 300.0,
    ),
    'rowHeight': const ParameterConstraints(
      type: 'double',
      min: 20.0,
      max: 60.0,
      defaultValue: 30.0,
    ),
    'rowMargin': const ParameterConstraints(
      type: 'double',
      min: 0.0,
      max: 10.0,
      defaultValue: 3.0,
    ),
    'bufferDays': const ParameterConstraints(
      type: 'int',
      min: 1,
      max: 20,
      defaultValue: 5,
    ),
    'scrollThrottleMs': const ParameterConstraints(
      type: 'int',
      min: 8,
      max: 100,
      defaultValue: 16,
    ),
    'animationDurationMs': const ParameterConstraints(
      type: 'int',
      min: 100,
      max: 500,
      defaultValue: 220,
    ),
  };
}
