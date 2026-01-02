import 'package:flutter_test/flutter_test.dart';
import 'test_helpers_all.dart';

/// Verification tests for test utilities infrastructure
/// These tests ensure that the test helpers themselves work correctly
void main() {
  group('RandomDataGenerator', () {
    test('generates reproducible data with same seed', () {
      final gen1 = RandomDataGenerator(42);
      final gen2 = RandomDataGenerator(42);

      expect(gen1.scrollOffset(), equals(gen2.scrollOffset()));
      expect(gen1.viewportWidth(), equals(gen2.viewportWidth()));
      expect(gen1.totalDays(), equals(gen2.totalDays()));
    });

    test('generates data within specified ranges', () {
      final gen = RandomDataGenerator();

      final offset = gen.scrollOffset(min: 100, max: 200);
      expect(offset, greaterThanOrEqualTo(100));
      expect(offset, lessThanOrEqualTo(200));

      final width = gen.viewportWidth(min: 500, max: 1000);
      expect(width, greaterThanOrEqualTo(500));
      expect(width, lessThanOrEqualTo(1000));

      final days = gen.totalDays(min: 10, max: 50);
      expect(days, greaterThanOrEqualTo(10));
      expect(days, lessThanOrEqualTo(50));
    });

    test('generates valid timeline elements', () {
      final gen = RandomDataGenerator();
      final elements = gen.timelineElements(count: 5);

      expect(elements.length, equals(5));
      for (final element in elements) {
        expect(element['pre_id'], isNotNull);
        expect(element['type'], isIn(['activity', 'delivrable', 'task']));
        expect(element['start_date'], isNotNull);
        expect(element['end_date'], isNotNull);
      }
    });

    test('generates valid stages', () {
      final gen = RandomDataGenerator();
      final stages = gen.stages(count: 3);

      expect(stages.length, equals(3));
      for (final stage in stages) {
        expect(stage['id'], isNotNull);
        expect(stage['name'], isNotNull);
        expect(stage['start_date'], isNotNull);
        expect(stage['end_date'], isNotNull);
        expect(stage['color'], isNotNull);
      }
    });
  });

  group('TestHelpers', () {
    test('expectIndexInBounds validates correctly', () {
      expect(() => TestHelpers.expectIndexInBounds(5, 0, 10), returnsNormally);
      expect(() => TestHelpers.expectIndexInBounds(0, 0, 10), returnsNormally);
      expect(() => TestHelpers.expectIndexInBounds(10, 0, 10), returnsNormally);
      expect(() => TestHelpers.expectIndexInBounds(-1, 0, 10), throwsA(isA<TestFailure>()));
      expect(() => TestHelpers.expectIndexInBounds(11, 0, 10), throwsA(isA<TestFailure>()));
    });

    test('expectValidConfiguration validates config structure', () {
      expect(() => TestHelpers.expectValidConfiguration(TestFixtures.defaultConfig), returnsNormally);
      expect(() => TestHelpers.expectValidConfiguration({}), throwsA(isA<TestFailure>()));
    });

    test('expectInRange validates numeric ranges', () {
      expect(() => TestHelpers.expectInRange(5, 0, 10), returnsNormally);
      expect(() => TestHelpers.expectInRange(-1, 0, 10), throwsA(isA<TestFailure>()));
      expect(() => TestHelpers.expectInRange(11, 0, 10), throwsA(isA<TestFailure>()));
    });

    test('expectNoDuplicates detects duplicates', () {
      final list = [
        {'id': 1},
        {'id': 2},
        {'id': 3}
      ];
      expect(() => TestHelpers.expectNoDuplicates(list, (item) => item['id']), returnsNormally);

      final duplicateList = [
        {'id': 1},
        {'id': 2},
        {'id': 1}
      ];
      expect(() => TestHelpers.expectNoDuplicates(duplicateList, (item) => item['id']), throwsA(isA<TestFailure>()));
    });

    test('expectValidDateRange validates date ranges', () {
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 31);
      expect(() => TestHelpers.expectValidDateRange(start, end), returnsNormally);
      expect(() => TestHelpers.expectValidDateRange(end, start), throwsA(isA<TestFailure>()));
    });
  });

  group('TestFixtures', () {
    test('provides valid default configuration', () {
      final config = TestFixtures.defaultConfig;
      expect(config['dayWidth'], isA<double>());
      expect(config['dayMargin'], isA<double>());
      expect(config['rowHeight'], isA<double>());
      expect(config['bufferDays'], isA<int>());
      expect(config['scrollThrottleMs'], isA<int>());
    });

    test('provides valid date fixtures', () {
      expect(TestFixtures.testStartDate, isA<DateTime>());
      expect(TestFixtures.testEndDate, isA<DateTime>());
      expect(TestFixtures.testEndDate.isAfter(TestFixtures.testStartDate), isTrue);
    });

    test('provides valid element fixtures', () {
      final elements = TestFixtures.sampleElements;
      expect(elements, isNotEmpty);
      for (final element in elements) {
        expect(element['pre_id'], isNotNull);
        expect(element['type'], isNotNull);
      }
    });

    test('provides valid stage fixtures', () {
      final stages = TestFixtures.sampleStages;
      expect(stages, isNotEmpty);
      for (final stage in stages) {
        expect(stage['id'], isNotNull);
        expect(stage['name'], isNotNull);
      }
    });

    test('provides overlapping and non-overlapping stages', () {
      expect(TestFixtures.overlappingStages, isNotEmpty);
      expect(TestFixtures.nonOverlappingStages, isNotEmpty);
    });

    test('provides capacity fixtures', () {
      final capacities = TestFixtures.sampleCapacities;
      expect(capacities, isNotEmpty);
      for (final capacity in capacities) {
        expect(capacity['date'], isNotNull);
        expect(capacity['capeff'], isA<double>());
        expect(capacity['buseff'], isA<double>());
      }
    });

    test('provides scroll calculation fixtures', () {
      final params = TestFixtures.standardScrollParams;
      expect(params['scrollOffset'], isA<double>());
      expect(params['viewportWidth'], isA<double>());
      expect(params['dayWidth'], isA<double>());
      expect(params['totalDays'], isA<int>());
    });
  });
}
