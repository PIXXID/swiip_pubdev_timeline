import 'dart:convert';
import 'dart:io';
import 'configuration_logger.dart';

/// Loads configuration from JSON files.
///
/// This class provides methods to load and parse timeline configuration
/// from JSON files, with proper error handling and performance considerations.
class ConfigurationLoader {
  /// Maximum file size in bytes (10KB).
  static const int maxFileSizeBytes = 10 * 1024;

  /// Loads configuration synchronously from the specified path.
  ///
  /// Returns a Map containing the parsed configuration, or null if:
  /// - The file doesn't exist (silent failure)
  /// - The file cannot be read (logs error)
  /// - The JSON is malformed (logs error)
  ///
  /// Logs a warning if the file size exceeds 10KB.
  ///
  /// [configPath] defaults to 'timeline_config.json' in the current directory.
  static Map<String, dynamic>? loadConfigurationSync({
    String configPath = 'timeline_config.json',
  }) {
    try {
      final file = File(configPath);

      // Check if file exists
      if (!file.existsSync()) {
        // Silent failure - file not found is expected when no config is provided
        return null;
      }

      // Check file size
      final fileSize = file.lengthSync();
      if (fileSize > maxFileSizeBytes) {
        ConfigurationLogger.warning(
          'File Size',
          'File size ($fileSize bytes) exceeds recommended maximum ($maxFileSizeBytes bytes)',
          details: 'Large configuration files may impact startup performance',
        );
      }

      // Read file content
      final content = file.readAsStringSync();

      // Parse JSON
      try {
        final parsed = jsonDecode(content);
        if (parsed is Map<String, dynamic>) {
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
        // JSON parsing error - try to extract line number
        final lineNumber = _extractLineNumber(e.message);
        ConfigurationLogger.jsonParsingError(
          configPath,
          e.message,
          lineNumber: lineNumber,
        );
        return null;
      }
    } on FileSystemException catch (e) {
      // File system error (permissions, etc.)
      ConfigurationLogger.fileSystemError(configPath, e.message);
      return null;
    } catch (e) {
      // Unexpected error
      ConfigurationLogger.error(
        'Unexpected Error',
        'Failed to load configuration from $configPath',
        details: e.toString(),
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
