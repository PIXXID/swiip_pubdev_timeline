---
inclusion: always
---

# Project Structure

## Root Organization

```
lib/
├── main.dart                    # Package entry point (exports timeline.dart)
├── run.dart                     # Application runner
└── src/
    ├── platform/                # Platform-specific code
    ├── timeline/                # Core timeline widgets
    └── tools/                   # Utility functions
```

## Core Timeline Components

### Widgets (`lib/src/timeline/`)

- `timeline.dart` - Main Timeline stateful widget and controller
- `lazy_timeline_viewport.dart` - Lazy rendering for horizontal timeline items
- `lazy_stage_rows_viewport.dart` - Lazy rendering for vertical stage rows
- `optimized_timeline_item.dart` - Individual timeline day item (optimized)
- `optimized_stage_row.dart` - Individual stage row (optimized)
- `stage_row.dart` - Stage row widget
- `stage_item.dart` - Individual stage item
- `timeline_item.dart` - Timeline item widget
- `timeline_day_date.dart` - Date header display
- `timeline_day_indicators.dart` - Day indicator widgets
- `timeline_day_info.dart` - Day information display
- `loading_indicator_overlay.dart` - Loading state overlay

### Models (`lib/src/timeline/models/`)

State management and data processing:

- `timeline_controller.dart` - Scroll state, center index, visible range (ValueNotifiers)
- `timeline_data_manager.dart` - Data formatting and caching
- `timeline_configuration.dart` - Configuration data class
- `timeline_configuration_manager.dart` - Configuration singleton
- `configuration_loader.dart` - Loads JSON configuration from assets
- `configuration_validator.dart` - Validates configuration parameters
- `configuration_logger.dart` - Logs configuration state
- `timeline_error_handler.dart` - Error handling utilities
- `performance_monitor.dart` - Performance tracking (debug mode)
- `performance_metrics.dart` - Performance metrics data
- `parameter_constraints.dart` - Configuration parameter constraints
- `visible_range.dart` - Visible range data class
- `validation_error.dart` - Validation error types
- `models.dart` - Shared model exports

### Platform (`lib/src/platform/`)

- `platform_language.dart` - Platform language detection interface
- `platform_language_io.dart` - IO platform implementation
- `platform_language_web.dart` - Web platform implementation

## Test Organization

```
test/
├── models/                      # Model unit tests
│   ├── configuration_*.dart     # Configuration system tests
│   ├── timeline_*.dart          # Timeline model tests
│   └── performance_*.dart       # Performance tracking tests
├── *_test.dart                  # Widget and integration tests
└── timeline_integration_test.dart
```

## Architecture Patterns

### State Management

- **ValueNotifiers** for granular, localized updates
- **ChangeNotifier** for controller lifecycle
- Avoid setState() where possible to minimize rebuilds

### Performance Optimization

- **Lazy rendering**: Only render visible items + buffer
- **Data caching**: TimelineDataManager caches formatted data
- **Scroll throttling**: Limit updates to ~60 FPS
- **Conditional rebuilds**: ValueListenableBuilder for targeted updates

### Error Handling

- `TimelineErrorHandler.withErrorHandling()` wraps risky operations
- Index clamping prevents out-of-bounds errors
- Graceful fallbacks for missing/invalid data

### Configuration

- External JSON configuration loaded at startup
- Singleton manager pattern (TimelineConfigurationManager)
- Validation with detailed error reporting
- Debug mode for configuration inspection

## Key Conventions

- Prefix private members with underscore (`_`)
- Use `late` for non-nullable fields initialized in initState
- Dispose controllers and listeners in dispose()
- Guard against empty collections before accessing
- Use `mounted` check before setState after async operations
