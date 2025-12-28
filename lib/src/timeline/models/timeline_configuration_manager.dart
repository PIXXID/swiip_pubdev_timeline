import 'package:flutter/foundation.dart';
import 'configuration_loader.dart';
import 'configuration_validator.dart';
import 'timeline_configuration.dart';

/// Manages the runtime configuration for the timeline widget.
///
/// This class implements a singleton pattern to provide global access to the
/// timeline configuration. It handles loading configuration from files,
/// validating parameters, and managing precedence between file-based and
/// programmatic configurations.
class TimelineConfigurationManager {
  static TimelineConfigurationManager? _instance;
  TimelineConfiguration? _configuration;
  bool _isInitialized = false;

  /// Private constructor for singleton pattern.
  TimelineConfigurationManager._();

  /// Initializes the configuration manager.
  ///
  /// This method should be called once during application startup.
  /// Subsequent calls will be ignored with a warning.
  ///
  /// Configuration precedence (highest to lowest):
  /// 1. Programmatic configuration ([programmaticConfig])
  /// 2. File-based configuration ([fileConfig])
  /// 3. Default configuration
  ///
  /// [fileConfig] is a map loaded from a JSON configuration file.
  /// [programmaticConfig] is a TimelineConfiguration instance provided directly.
  ///
  /// If both are provided, programmatic configuration takes precedence for
  /// all parameters.
  static void initialize({
    Map<String, dynamic>? fileConfig,
    TimelineConfiguration? programmaticConfig,
  }) {
    // Check if already initialized
    if (_instance != null && _instance!._isInitialized) {
      debugPrint(
        'Configuration Warning: TimelineConfigurationManager is already '
        'initialized. Subsequent initialization attempts are ignored.',
      );
      return;
    }

    // Create instance if needed
    _instance ??= TimelineConfigurationManager._();

    // Validate file configuration if provided
    Map<String, dynamic>? validatedFileConfig;
    if (fileConfig != null) {
      final validationResult = ConfigurationValidator.validate(fileConfig);

      // Log validation errors and warnings
      for (final error in validationResult.errors) {
        debugPrint('Configuration Error: $error');
      }
      for (final warning in validationResult.warnings) {
        debugPrint('Configuration Warning: $warning');
      }

      validatedFileConfig = validationResult.validatedConfig;
    }

    // Determine final configuration based on precedence
    TimelineConfiguration finalConfig;

    if (programmaticConfig != null) {
      // Programmatic configuration takes precedence
      finalConfig = programmaticConfig;
    } else if (validatedFileConfig != null) {
      // Use validated file configuration
      finalConfig = TimelineConfiguration.fromMap(validatedFileConfig);
    } else {
      // Use default configuration
      finalConfig = const TimelineConfiguration();
    }

    _instance!._configuration = finalConfig;
    _instance!._isInitialized = true;
  }

  /// Gets the current runtime configuration.
  ///
  /// Throws a [StateError] if the configuration manager has not been initialized.
  static TimelineConfiguration get configuration {
    if (_instance == null || !_instance!._isInitialized) {
      throw StateError(
        'TimelineConfigurationManager has not been initialized. '
        'Call TimelineConfigurationManager.initialize() before accessing configuration.',
      );
    }
    return _instance!._configuration!;
  }

  /// Checks if the configuration manager has been initialized.
  static bool get isInitialized {
    return _instance != null && _instance!._isInitialized;
  }

  /// Converts the current configuration to a map for debugging.
  ///
  /// Returns null if the configuration manager has not been initialized.
  static Map<String, dynamic>? toMap() {
    if (_instance == null || !_instance!._isInitialized) {
      return null;
    }
    return _instance!._configuration!.toMap();
  }

  /// Resets the configuration manager (primarily for testing).
  ///
  /// This method clears the singleton instance, allowing for re-initialization.
  /// Should only be used in test environments.
  @visibleForTesting
  static void reset() {
    _instance = null;
  }
}
