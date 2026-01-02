import 'dart:math';

/// Utility class for generating random test data with optional seeding for reproducibility.
///
/// This class provides methods to generate various types of random data needed for
/// property-based testing and general test data generation. All methods support
/// customizable ranges to generate data within specific bounds.
///
/// **Usage Example:**
/// ```dart
/// // Create generator with fixed seed for reproducible tests
/// final generator = RandomDataGenerator(42);
///
/// // Generate random values
/// final scrollOffset = generator.scrollOffset(min: 0, max: 5000);
/// final elements = generator.timelineElements(count: 20);
/// ```
///
/// **Seeding:**
/// - Pass a seed to the constructor for reproducible random sequences
/// - Use the same seed to get the same sequence of random values
/// - Omit the seed for truly random values (different each run)
///
/// **Property-Based Testing:**
/// This class is designed for property-based testing where you want to test
/// properties across many random inputs. Use a fixed seed during development
/// to reproduce failures, then remove the seed for final testing.
class RandomDataGenerator {
  final Random _random;

  /// Creates a generator with an optional seed for reproducibility
  RandomDataGenerator([int? seed]) : _random = Random(seed);

  /// Generates a random scroll offset within the specified range
  double scrollOffset({double min = 0, double max = 10000}) {
    return min + _random.nextDouble() * (max - min);
  }

  /// Generates random viewport width dimensions
  double viewportWidth({double min = 300, double max = 2000}) {
    return min + _random.nextDouble() * (max - min);
  }

  /// Generates a random day width
  double dayWidth({double min = 50, double max = 200}) {
    return min + _random.nextDouble() * (max - min);
  }

  /// Generates a random day margin
  double dayMargin({double min = 0, double max = 20}) {
    return min + _random.nextDouble() * (max - min);
  }

  /// Generates a random total days count
  int totalDays({int min = 1, int max = 500}) {
    return min + _random.nextInt(max - min + 1);
  }

  /// Generates a random date range
  DateRange dateRange({int minDays = 1, int maxDays = 365}) {
    final startDate = DateTime(2024, 1, 1);
    final days = minDays + _random.nextInt(maxDays - minDays + 1);
    final endDate = startDate.add(Duration(days: days));
    return DateRange(startDate, endDate);
  }

  /// Generates a random configuration map
  Map<String, dynamic> configuration({bool valid = true}) {
    if (valid) {
      return {
        'dayWidth': dayWidth(min: 50, max: 150),
        'dayMargin': dayMargin(min: 0, max: 10),
        'rowHeight': 40.0 + _random.nextDouble() * 40,
        'bufferDays': 5 + _random.nextInt(15),
        'scrollThrottleMs': 8 + _random.nextInt(8),
      };
    } else {
      // Generate invalid configuration with out-of-range or wrong-type values
      return {
        'dayWidth': _random.nextBool() ? -50.0 : 'invalid',
        'dayMargin': _random.nextBool() ? -10.0 : null,
        'rowHeight': _random.nextBool() ? 0.0 : 'not a number',
        'bufferDays': -5,
        'scrollThrottleMs': 'invalid',
      };
    }
  }

  /// Generates random timeline elements
  List<Map<String, dynamic>> timelineElements({int count = 10}) {
    final elements = <Map<String, dynamic>>[];
    final baseDate = DateTime(2024, 1, 1);

    for (int i = 0; i < count; i++) {
      final startOffset = _random.nextInt(100);
      final duration = 1 + _random.nextInt(30);
      final type = ['activity', 'delivrable', 'task'][_random.nextInt(3)];

      elements.add({
        'pre_id': 'elem_${i}_${_random.nextInt(1000)}',
        'type': type,
        'start_date': baseDate.add(Duration(days: startOffset)).toIso8601String(),
        'end_date': baseDate.add(Duration(days: startOffset + duration)).toIso8601String(),
        'name': 'Element $i',
        'buseff': _random.nextDouble() * 100,
      });
    }

    return elements;
  }

  /// Generates random stages
  List<Map<String, dynamic>> stages({int count = 5}) {
    final stagesList = <Map<String, dynamic>>[];
    final baseDate = DateTime(2024, 1, 1);

    for (int i = 0; i < count; i++) {
      final startOffset = _random.nextInt(100);
      final duration = 5 + _random.nextInt(50);

      stagesList.add({
        'id': 'stage_$i',
        'name': 'Stage $i',
        'start_date': baseDate.add(Duration(days: startOffset)).toIso8601String(),
        'end_date': baseDate.add(Duration(days: startOffset + duration)).toIso8601String(),
        'color': '#${_random.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
      });
    }

    return stagesList;
  }

  /// Generates random capacity data
  List<Map<String, dynamic>> capacities({int count = 10}) {
    final capacitiesList = <Map<String, dynamic>>[];
    final baseDate = DateTime(2024, 1, 1);

    for (int i = 0; i < count; i++) {
      capacitiesList.add({
        'date': baseDate.add(Duration(days: i)).toIso8601String(),
        'capeff': 50.0 + _random.nextDouble() * 50,
        'buseff': _random.nextDouble() * 120, // Can exceed capacity
      });
    }

    return capacitiesList;
  }

  /// Generates a random integer within range
  int randomInt({int min = 0, int max = 100}) {
    return min + _random.nextInt(max - min + 1);
  }

  /// Generates a random double within range
  double randomDouble({double min = 0.0, double max = 1.0}) {
    return min + _random.nextDouble() * (max - min);
  }

  /// Generates a random boolean
  bool randomBool() {
    return _random.nextBool();
  }
}

/// Simple date range class for test data generation
class DateRange {
  final DateTime startDate;
  final DateTime endDate;

  DateRange(this.startDate, this.endDate);

  int get days => endDate.difference(startDate).inDays + 1;
}
