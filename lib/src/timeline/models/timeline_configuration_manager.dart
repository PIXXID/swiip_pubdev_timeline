import 'package:flutter/foundation.dart';
import 'configuration_logger.dart';
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

  // Track configuration sources for debug mode
  Map<String, String>? _configurationSources;

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
      ConfigurationLogger.warning(
        'Initialization',
        'TimelineConfigurationManager is already initialized',
        details: 'Subsequent initialization attempts are ignored',
      );
      return;
    }

    // Create instance if needed
    _instance ??= TimelineConfigurationManager._();

    // Validate file configuration if provided
    Map<String, dynamic>? validatedFileConfig;
    if (fileConfig != null) {
      final validationResult = ConfigurationValidator.validate(fileConfig);

      // Validation errors and warnings are already logged by the validator
      validatedFileConfig = validationResult.validatedConfig;
    }

    // Determine final configuration based on precedence
    TimelineConfiguration finalConfig;
    final sources = <String, String>{};

    if (programmaticConfig != null) {
      // Programmatic configuration takes precedence
      finalConfig = programmaticConfig;

      // All parameters come from programmatic config
      final configMap = programmaticConfig.toMap();
      for (final key in configMap.keys) {
        sources[key] = 'programmatic';
      }
    } else if (validatedFileConfig != null) {
      // Use validated file configuration
      finalConfig = TimelineConfiguration.fromMap(validatedFileConfig);

      // Track which parameters came from file vs defaults
      final defaults = ConfigurationValidator.getDefaultConfiguration();
      for (final key in validatedFileConfig.keys) {
        if (validatedFileConfig[key] == defaults[key]) {
          sources[key] = 'default';
        } else {
          sources[key] = 'file';
        }
      }
    } else {
      // Use default configuration
      finalConfig = const TimelineConfiguration();

      // All parameters are defaults
      final configMap = finalConfig.toMap();
      for (final key in configMap.keys) {
        sources[key] = 'default';
      }
    }

    _instance!._configuration = finalConfig;
    _instance!._configurationSources = sources;
    _instance!._isInitialized = true;

    // Print configuration if debug mode is enabled
    if (ConfigurationLogger.isDebugModeEnabled) {
      _printDebugConfiguration();
    }
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

  /// Enables debug mode for verbose configuration logging.
  ///
  /// When debug mode is enabled, the configuration manager will print
  /// the active configuration at startup, showing the source of each
  /// parameter value (file, programmatic, or default).
  ///
  /// This method should be called before [initialize] to see the
  /// configuration details during initialization.
  static void enableDebugMode() {
    ConfigurationLogger.enableDebugMode();

    // If already initialized, print the configuration now
    if (isInitialized) {
      _printDebugConfiguration();
    }
  }

  /// Disables debug mode.
  static void disableDebugMode() {
    ConfigurationLogger.disableDebugMode();
  }

  /// Prints the active configuration with source information.
  static void _printDebugConfiguration() {
    if (_instance == null || !_instance!._isInitialized) {
      return;
    }

    ConfigurationLogger.debug(
      'Active Configuration',
      'Timeline configuration loaded successfully',
    );

    final config = _instance!._configuration!.toMap();
    final sources = _instance!._configurationSources ?? {};

    for (final entry in config.entries) {
      final key = entry.key;
      final value = entry.value;
      final source = sources[key] ?? 'unknown';

      ConfigurationLogger.debug(
        'Parameter',
        '$key = $value (from $source)',
      );
    }
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
