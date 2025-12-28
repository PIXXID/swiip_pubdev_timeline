import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'configuration_logger.dart';

/// Loads configuration from JSON files.
///
/// This class provides methods to load and parse timeline configuration
/// from JSON files (Flutter assets), with proper error handling and
/// performance considerations.
class ConfigurationLoader {
  /// Loads configuration asynchronously from Flutter assets.
  ///
  /// Returns a Map containing the parsed configuration, or null if:
  /// - The file doesn't exist in assets (silent failure)
  /// - The file cannot be read (logs error)
  /// - The JSON is malformed (logs error)
  ///
  /// [configPath] defaults to 'timeline_config.json'.
  static Future<Map<String, dynamic>?> loadConfiguration({
    String configPath = 'timeline_config.json',
  }) async {
    try {
      // Load from Flutter assets
      final content = await rootBundle.loadString(configPath);

      // Parse JSON
      try {
        final parsed = jsonDecode(content);
        if (parsed is Map<String, dynamic>) {
          ConfigurationLogger.info(
            'Configuration',
            'Successfully loaded configuration from assets: $configPath',
          );
          return parsed;
        } else {
          ConfigurationLogger.error(
            'JSON Structure',
            'Expected JSON object at root, but got ${parsed.runtimeType}',
            details: 'Configuration file must contain a JSON object',
          );
          return null;
        }
      } on FormatException catch (e) {
        final lineNumber = _extractLineNumber(e.message);
        ConfigurationLogger.jsonParsingError(
          configPath,
          e.message,
          lineNumber: lineNumber,
        );
        return null;
      }
    } catch (e) {
      // Assets loading failed - file not found or other error
      ConfigurationLogger.info(
        'Configuration',
        'Could not load configuration from assets: $configPath',
        details: 'Using default configuration values. Error: ${e.toString()}',
      );
      return null;
    }
  }

  /// Extracts line number information from a FormatException message.
  ///
  /// Returns the line number if available, or null.
  static int? _extractLineNumber(String message) {
    // Try to extract line number from error message
    // Format is typically "... at line X column Y"
    final lineMatch = RegExp(r'line (\d+)').firstMatch(message);
    if (lineMatch != null) {
      return int.tryParse(lineMatch.group(1)!);
    }
    return null;
  }
}
