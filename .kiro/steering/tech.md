---
inclusion: always
---

# Technology Stack

## Framework & Language

- **Flutter**: Cross-platform UI framework (web, mobile, desktop)
- **Dart**: SDK >=3.3.0 <4.0.0
- **Package**: `swiip_pubdev_timeline` v1.1.0

## Dependencies

- `intl: ^0.20.2` - Internationalization and date formatting
- `defer_pointer: ^0.0.2` - Pointer event handling
- `font_awesome_flutter: ^10.7.0` - Icon library
- `http: ^1.6.0` - HTTP requests
- `flutter_dotenv: ^6.0.0` - Environment configuration
- `web: ^1.1.1` - Web platform support

## Dev Dependencies

- `flutter_test` - Testing framework
- `flutter_lints: ^6.0.0` - Linting rules

## Coding Standards

### Dart Code Style

- **Line length**: Maximum 120 characters per line for Dart files
- Follow standard Dart formatting conventions
- Use `dart format` with line length override when needed: `dart format --line-length 120 .`

## Build System

Standard Flutter build system with pub package manager.

### Common Commands

```bash
# Get dependencies
flutter pub get

# Run tests
flutter test

# Run specific test file
flutter test test/timeline_integration_test.dart

# Analyze code
flutter analyze

# Format code
dart format .

# Build for web
flutter build web

# Run app (development)
flutter run
```

## Configuration Files

- `pubspec.yaml` - Package dependencies and metadata
- `analysis_options.yaml` - Linting configuration (uses flutter_lints)
- `.env` - Environment variables (not committed)
- `timeline_config.json` - Runtime performance configuration (optional)

## Assets

Assets must be declared in `pubspec.yaml`:
- `.env` file for environment variables
- `timeline_config.json` for performance tuning
