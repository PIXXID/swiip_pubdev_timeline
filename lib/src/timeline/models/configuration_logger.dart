import 'package:flutter/foundation.dart';

/// Log levels for configuration system messages.
enum LogLevel {
  /// Critical errors that prevent configuration loading.
  error,

  /// Non-critical issues that use fallback values.
  warning,

  /// Informational messages about configuration state.
  info,

  /// Detailed information for troubleshooting.
  debug,
}

/// Centralized logging utility for the configuration system.
///
/// This class provides structured logging with different severity levels
/// and consistent formatting for configuration-related messages.
class ConfigurationLogger {
  /// Whether debug mode is enabled.
  static bool _debugModeEnabled = false;

  /// Enables debug mode for verbose logging.
  static void enableDebugMode() {
    _debugModeEnabled = true;
  }

  /// Disables debug mode.
  static void disableDebugMode() {
    _debugModeEnabled = false;
  }

  /// Checks if debug mode is enabled.
  static bool get isDebugModeEnabled => _debugModeEnabled;

  /// Logs an error message.
  ///
  /// Errors are critical issues that prevent configuration loading or
  /// cause significant functionality problems.
  ///
  /// [context] describes where the error occurred (e.g., "File Loading", "JSON Parsing").
  /// [message] is the error description.
  /// [details] provides additional context (optional).
  static void error(String context, String message, {String? details}) {
    _log(LogLevel.error, context, message, details: details);
  }

  /// Logs a warning message.
  ///
  /// Warnings are non-critical issues where the system can continue with
  /// fallback values or default behavior.
  ///
  /// [context] describes where the warning occurred.
  /// [message] is the warning description.
  /// [details] provides additional context (optional).
  static void warning(String context, String message, {String? details}) {
    _log(LogLevel.warning, context, message, details: details);
  }

  /// Logs an informational message.
  ///
  /// Info messages provide useful information about configuration state
  /// and operations.
  ///
  /// [context] describes the context of the information.
  /// [message] is the informational message.
  /// [details] provides additional context (optional).
  static void info(String context, String message, {String? details}) {
    _log(LogLevel.info, context, message, details: details);
  }

  /// Logs a debug message.
  ///
  /// Debug messages are only shown when debug mode is enabled and provide
  /// detailed information for troubleshooting.
  ///
  /// [context] describes the context of the debug information.
  /// [message] is the debug message.
  /// [details] provides additional context (optional).
  static void debug(String context, String message, {String? details}) {
    if (_debugModeEnabled) {
      _log(LogLevel.debug, context, message, details: details);
    }
  }

  /// Internal logging method that formats and prints messages.
  static void _log(
    LogLevel level,
    String context,
    String message, {
    String? details,
  }) {
    final levelStr = _getLevelString(level);
    final prefix = '[Timeline Config $levelStr]';

    if (details != null && details.isNotEmpty) {
      debugPrint('$prefix $context: $message\n  Details: $details');
    } else {
      debugPrint('$prefix $context: $message');
    }
  }

  /// Gets the string representation of a log level.
  static String _getLevelString(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.warning:
        return 'WARNING';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.debug:
        return 'DEBUG';
    }
  }

  /// Logs a file system error with context.
  ///
  /// [filePath] is the path to the file that caused the error.
  /// [errorMessage] is the error message from the exception.
  static void fileSystemError(String filePath, String errorMessage) {
    error(
      'File System',
      'Failed to read file',
      details: 'Path: $filePath, Error: $errorMessage',
    );
  }

  /// Logs a JSON parsing error with line number if available.
  ///
  /// [filePath] is the path to the file being parsed.
  /// [errorMessage] is the parsing error message.
  /// [lineNumber] is the line number where the error occurred (optional).
  static void jsonParsingError(
    String filePath,
    String errorMessage, {
    int? lineNumber,
  }) {
    final lineInfo = lineNumber != null ? ' at line $lineNumber' : '';
    error(
      'JSON Parsing',
      'Invalid JSON in $filePath$lineInfo',
      details: errorMessage,
    );
  }

  /// Logs a validation error with parameter details.
  ///
  /// [parameterName] is the name of the parameter that failed validation.
  /// [providedValue] is the value that was provided.
  /// [expectedType] is the expected type for the parameter.
  /// [expectedRange] is the expected range (optional).
  /// [reason] explains why validation failed.
  static void validationError(
    String parameterName,
    dynamic providedValue,
    String expectedType, {
    String? expectedRange,
    required String reason,
  }) {
    final rangeInfo = expectedRange != null ? ', range: $expectedRange' : '';
    error(
      'Validation',
      'Parameter "$parameterName" failed validation',
      details:
          '$reason (provided: $providedValue, expected: $expectedType$rangeInfo)',
    );
  }

  /// Logs a validation warning with parameter details.
  ///
  /// [parameterName] is the name of the parameter that triggered the warning.
  /// [providedValue] is the value that was provided.
  /// [expectedType] is the expected type for the parameter.
  /// [expectedRange] is the expected range (optional).
  /// [reason] explains the warning.
  static void validationWarning(
    String parameterName,
    dynamic providedValue,
    String expectedType, {
    String? expectedRange,
    required String reason,
  }) {
    final rangeInfo = expectedRange != null ? ', range: $expectedRange' : '';
    warning(
      'Validation',
      'Parameter "$parameterName" has an issue',
      details:
          '$reason (provided: $providedValue, expected: $expectedType$rangeInfo)',
    );
  }
}
