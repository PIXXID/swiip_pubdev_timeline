# Timeline Test Suite

This directory contains a comprehensive test suite for the `swiip_pubdev_timeline` Flutter package. The tests cover scroll calculations, data management, configuration, validation, error handling, and integration scenarios.

## 📁 Test Organization

```
test/
├── README.md                                    # This file
├── helpers/                                     # Test utilities and fixtures
│   ├── test_helpers_all.dart                   # Barrel file (import all helpers)
│   ├── random_data_generator.dart              # Random test data generation
│   ├── test_helpers.dart                       # Common assertion helpers
│   ├── test_fixtures.dart                      # Reusable test data
│   └── test_utilities_verification_test.dart   # Tests for test utilities
├── scroll_calculations_test.dart               # Scroll calculation tests
├── timeline_data_manager_test.dart             # Data formatting and caching tests
├── timeline_configuration_manager_test.dart    # Configuration management tests
├── configuration_validator_test.dart           # Configuration validation tests
├── visible_range_test.dart                     # VisibleRange model tests
├── timeline_error_handler_test.dart            # Error handling tests
├── parameter_constraints_test.dart             # Parameter constraint tests
├── data_formatting_integration_test.dart       # Integration tests
└── cache_performance_test.dart                 # Performance tests

```

## 🚀 Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test File
```bash
flutter test test/scroll_calculations_test.dart
flutter test test/timeline_data_manager_test.dart
```

### Run Tests with Coverage
```bash
# Generate coverage report
flutter test --coverage

# View coverage in browser (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Run Tests by Tag
```bash
# Run only property-based tests
flutter test --tags property-test

# Run only unit tests
flutter test --tags unit-test

# Run only integration tests
flutter test --tags integration-test
```

### Run Tests in Watch Mode (during development)
```bash
# Note: Flutter doesn't have built-in watch mode
# Use a file watcher or IDE integration instead
```

## 📚 Test Categories

### Unit Tests
Unit tests verify specific behaviors with concrete examples. They test:
- Edge cases (empty, null, boundary values)
- Specific scenarios and examples
- Error conditions
- Individual function behavior

**Example:**
```dart
test('returns 0 when scroll offset is at start (0)', () {
  final result = calculateCenterDateIndex(
    scrollOffset: 0.0,
    viewportWidth: 800.0,
    dayWidth: 100.0,
    dayMargin: 5.0,
    totalDays: 100,
  );
  expect(result, equals(4));
});
```

### Property-Based Tests
Property-based tests verify universal properties across many generated inputs. They test:
- Properties that should hold for all valid inputs
- Invariants and mathematical relationships
- Behavior across a wide input space

**Example:**
```dart
test('Property 1: Center index bounds', () {
  final generator = RandomDataGenerator(42); // Fixed seed for reproducibility
  
  for (int i = 0; i < 100; i++) {
    final scrollOffset = generator.scrollOffset();
    final viewportWidth = generator.viewportWidth();
    final dayWidth = generator.dayWidth();
    final dayMargin = generator.dayMargin();
    final totalDays = generator.totalDays();
    
    final result = calculateCenterDateIndex(
      scrollOffset: scrollOffset,
      viewportWidth: viewportWidth,
      dayWidth: dayWidth,
      dayMargin: dayMargin,
      totalDays: totalDays,
    );
    
    // Property: result should always be in valid bounds
    expect(result, greaterThanOrEqualTo(0));
    expect(result, lessThan(totalDays));
  }
}, tags: ['property-test']);
```

### Integration Tests
Integration tests verify end-to-end behavior across multiple components:
- Complete data formatting workflows
- Cache behavior across multiple operations
- Component interactions

## 🛠️ Test Utilities

### RandomDataGenerator
Generates random test data with optional seeding for reproducibility.

**Usage:**
```dart
import 'helpers/test_helpers_all.dart';

// Create generator with fixed seed for reproducible tests
final generator = RandomDataGenerator(42);

// Generate random values
final scrollOffset = generator.scrollOffset(min: 0, max: 5000);
final viewportWidth = generator.viewportWidth(min: 300, max: 2000);
final elements = generator.timelineElements(count: 20);
final stages = generator.stages(count: 10);
```

**Available Methods:**
- `scrollOffset({min, max})` - Random scroll offset
- `viewportWidth({min, max})` - Random viewport dimensions
- `dayWidth({min, max})` - Random day width
- `dayMargin({min, max})` - Random day margin
- `totalDays({min, max})` - Random day count
- `dateRange({minDays, maxDays})` - Random date range
- `configuration({valid})` - Random configuration map
- `timelineElements({count})` - Random timeline elements
- `stages({count})` - Random stages
- `capacities({count})` - Random capacity data

### TestHelpers
Common assertion helpers for validating test results.

**Usage:**
```dart
import 'helpers/test_helpers_all.dart';

// Verify index is within bounds
TestHelpers.expectIndexInBounds(index, 0, 99);

// Verify configuration is valid
TestHelpers.expectValidConfiguration(config);

// Verify days list structure
TestHelpers.expectValidDaysList(days);

// Verify no overlapping stages in a row
TestHelpers.expectNoOverlapsInRow(stageRow);
```

### TestFixtures
Reusable test data for common scenarios.

**Usage:**
```dart
import 'helpers/test_helpers_all.dart';

// Use predefined configurations
final config = TestFixtures.defaultConfig;
final invalidConfig = TestFixtures.invalidConfig;

// Use predefined dates
final startDate = TestFixtures.testStartDate;
final endDate = TestFixtures.testEndDate;

// Use predefined elements
final elements = TestFixtures.sampleElements;
final duplicates = TestFixtures.duplicateElements;
final multiDay = TestFixtures.multiDayElements;

// Use predefined stages
final stages = TestFixtures.sampleStages;
final overlapping = TestFixtures.overlappingStages;
final nonOverlapping = TestFixtures.nonOverlappingStages;

// Use predefined capacities
final capacities = TestFixtures.sampleCapacities;
```

## 📊 Coverage Goals

- **Line coverage**: > 90% for all tested files
- **Branch coverage**: > 85% for conditional logic
- **Property coverage**: All defined properties have at least one test

## 🎯 Test Patterns

### Arrange-Act-Assert (AAA)
All tests follow the AAA pattern for clarity:

```dart
test('description', () {
  // Arrange - Set up test data and preconditions
  final input = 'test data';
  final expected = 'expected result';
  
  // Act - Execute the code under test
  final result = functionUnderTest(input);
  
  // Assert - Verify the results
  expect(result, equals(expected));
});
```

### Setup and Teardown
Use `setUp()` and `tearDown()` for test initialization and cleanup:

```dart
group('MyClass', () {
  late MyClass instance;
  
  setUp(() {
    // Initialize before each test
    instance = MyClass();
  });
  
  tearDown(() {
    // Clean up after each test
    instance.dispose();
  });
  
  test('test case', () {
    // Test uses the instance
  });
});
```

### Configuration Manager Tests
For `TimelineConfigurationManager` tests, always reset the singleton:

```dart
group('TimelineConfigurationManager', () {
  tearDown(() {
    // Reset singleton after each test
    TimelineConfigurationManager.reset();
  });
  
  test('test case', () {
    // Test configuration manager
  });
});
```

## 🔍 Debugging Tests

### Print Debug Information
```dart
test('debug example', () {
  final result = calculateSomething();
  print('Result: $result'); // Prints during test execution
  expect(result, isNotNull);
});
```

### Run Single Test
```dart
test('specific test', () {
  // Test code
}, skip: false); // Remove skip to run only this test

test('other test', () {
  // Test code
}, skip: true); // Skip this test temporarily
```

### Use Test Tags for Organization
```dart
test('my test', () {
  // Test code
}, tags: ['unit-test', 'scroll-calculations']);

// Run with: flutter test --tags scroll-calculations
```

## 📝 Writing New Tests

### 1. Choose Test Type
- **Unit test**: Testing specific behavior with concrete examples
- **Property test**: Testing universal properties across many inputs
- **Integration test**: Testing end-to-end workflows

### 2. Use Test Utilities
```dart
import 'helpers/test_helpers_all.dart';

test('my new test', () {
  // Use fixtures for common data
  final config = TestFixtures.defaultConfig;
  
  // Use generator for random data
  final generator = RandomDataGenerator(42);
  final elements = generator.timelineElements(count: 10);
  
  // Use helpers for assertions
  TestHelpers.expectValidConfiguration(config);
});
```

### 3. Follow Naming Conventions
- Test file: `feature_name_test.dart`
- Test group: `group('ClassName or Feature', () { ... })`
- Test case: `test('should do something when condition', () { ... })`

### 4. Add Descriptive Comments
```dart
test('calculates center index correctly', () {
  // Arrange - Set up scroll at position 2000
  // Center position = 2000 + 800/2 = 2400
  // Center index = 2400 / 95 ≈ 25.3 → rounds to 25
  final scrollOffset = 2000.0;
  
  // Act
  final result = calculateCenterDateIndex(...);
  
  // Assert
  expect(result, equals(25));
});
```

## 🐛 Common Issues

### Issue: Tests fail with "Null check operator used on a null value"
**Solution**: Ensure all required fields are initialized in `setUp()` or use `late` keyword appropriately.

### Issue: Configuration manager tests interfere with each other
**Solution**: Always call `TimelineConfigurationManager.reset()` in `tearDown()`.

### Issue: Property tests are flaky
**Solution**: Use fixed seeds for `RandomDataGenerator` to ensure reproducibility:
```dart
final generator = RandomDataGenerator(42); // Fixed seed
```

### Issue: Tests are slow
**Solution**: 
- Reduce iteration count for property tests during development
- Use `flutter test --concurrency=1` to run tests sequentially
- Profile tests to identify slow operations

## 📖 Additional Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/testing)
- [Property-Based Testing Concepts](https://hypothesis.works/articles/what-is-property-based-testing/)

## 🤝 Contributing

When adding new tests:
1. Follow existing patterns and conventions
2. Add tests to appropriate test file or create new file if needed
3. Update this README if adding new test utilities or patterns
4. Ensure all tests pass before committing
5. Maintain or improve code coverage

## 📄 License

This test suite is part of the `swiip_pubdev_timeline` package and follows the same license.
