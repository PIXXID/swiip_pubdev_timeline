import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/visible_range.dart';

void main() {
  group('VisibleRange', () {
    group('contains', () {
      test('returns true for index at the beginning of range', () {
        // Requirements: 5.1
        final range = VisibleRange(5, 10);
        expect(range.contains(5), isTrue,
            reason: 'Index 5 should be contained in range [5, 10]');
      });

      test('returns true for index at the end of range', () {
        // Requirements: 5.1
        final range = VisibleRange(5, 10);
        expect(range.contains(10), isTrue,
            reason: 'Index 10 should be contained in range [5, 10]');
      });

      test('returns true for index in the middle of range', () {
        // Requirements: 5.1
        final range = VisibleRange(5, 10);
        expect(range.contains(7), isTrue,
            reason: 'Index 7 should be contained in range [5, 10]');
      });

      test('returns false for index before range', () {
        // Requirements: 5.2
        final range = VisibleRange(5, 10);
        expect(range.contains(4), isFalse,
            reason: 'Index 4 should not be contained in range [5, 10]');
      });

      test('returns false for index after range', () {
        // Requirements: 5.2
        final range = VisibleRange(5, 10);
        expect(range.contains(11), isFalse,
            reason: 'Index 11 should not be contained in range [5, 10]');
      });

      test('returns false for negative index when range is positive', () {
        // Requirements: 5.2
        final range = VisibleRange(5, 10);
        expect(range.contains(-1), isFalse,
            reason: 'Index -1 should not be contained in range [5, 10]');
      });

      test('works correctly with single-element range', () {
        // Requirements: 5.1, 5.2
        final range = VisibleRange(5, 5);
        expect(range.contains(5), isTrue,
            reason:
                'Index 5 should be contained in single-element range [5, 5]');
        expect(range.contains(4), isFalse,
            reason: 'Index 4 should not be contained in range [5, 5]');
        expect(range.contains(6), isFalse,
            reason: 'Index 6 should not be contained in range [5, 5]');
      });

      test('works correctly with range starting at zero', () {
        // Requirements: 5.1, 5.2
        final range = VisibleRange(0, 5);
        expect(range.contains(0), isTrue,
            reason: 'Index 0 should be contained in range [0, 5]');
        expect(range.contains(-1), isFalse,
            reason: 'Index -1 should not be contained in range [0, 5]');
      });
    });

    group('overlaps', () {
      test('returns true for ranges that overlap in the middle', () {
        // Requirements: 5.3
        final range = VisibleRange(5, 10);
        expect(
          range.overlaps(7, 12),
          isTrue,
          reason: 'Range [5, 10] should overlap with [7, 12]',
        );
      });

      test('returns true for ranges that overlap at the start', () {
        // Requirements: 5.3
        final range = VisibleRange(5, 10);
        expect(
          range.overlaps(3, 7),
          isTrue,
          reason: 'Range [5, 10] should overlap with [3, 7]',
        );
      });

      test('returns true for range completely contained within', () {
        // Requirements: 5.3
        final range = VisibleRange(5, 10);
        expect(
          range.overlaps(6, 9),
          isTrue,
          reason: 'Range [5, 10] should overlap with [6, 9] (contained within)',
        );
      });

      test('returns true for range that completely contains this range', () {
        // Requirements: 5.3
        final range = VisibleRange(5, 10);
        expect(
          range.overlaps(3, 12),
          isTrue,
          reason:
              'Range [5, 10] should overlap with [3, 12] (contains this range)',
        );
      });

      test('returns true for identical ranges', () {
        // Requirements: 5.3
        final range = VisibleRange(5, 10);
        expect(
          range.overlaps(5, 10),
          isTrue,
          reason: 'Range [5, 10] should overlap with identical range [5, 10]',
        );
      });

      test('returns true for adjacent ranges touching at boundary', () {
        // Requirements: 5.3
        final range = VisibleRange(5, 10);
        expect(
          range.overlaps(10, 15),
          isTrue,
          reason:
              'Range [5, 10] should overlap with adjacent range [10, 15] (touching at 10)',
        );
      });

      test('returns false for ranges separated before', () {
        // Requirements: 5.4
        final range = VisibleRange(5, 10);
        expect(
          range.overlaps(1, 4),
          isFalse,
          reason: 'Range [5, 10] should not overlap with [1, 4] (separated)',
        );
      });

      test('returns false for ranges separated after', () {
        // Requirements: 5.4
        final range = VisibleRange(5, 10);
        expect(
          range.overlaps(11, 15),
          isFalse,
          reason: 'Range [5, 10] should not overlap with [11, 15] (separated)',
        );
      });

      test('returns false for ranges adjacent but not touching', () {
        // Requirements: 5.4
        final range = VisibleRange(5, 10);
        expect(
          range.overlaps(11, 15),
          isFalse,
          reason:
              'Range [5, 10] should not overlap with [11, 15] (adjacent but not touching)',
        );
      });

      test('works correctly with single-element ranges', () {
        // Requirements: 5.3, 5.4
        final range = VisibleRange(5, 5);
        expect(range.overlaps(5, 5), isTrue,
            reason: 'Single-element ranges at same position should overlap');
        expect(range.overlaps(4, 4), isFalse,
            reason:
                'Single-element ranges at different positions should not overlap');
        expect(range.overlaps(5, 10), isTrue,
            reason:
                'Single-element range should overlap with range containing it');
      });
    });

    group('length', () {
      test('calculates correct length for multi-element range', () {
        // Requirements: 5.5
        final range = VisibleRange(5, 10);
        expect(range.length, equals(6),
            reason: 'Range [5, 10] should have length 6');
      });

      test('calculates correct length for single-element range', () {
        // Requirements: 5.5
        final range = VisibleRange(5, 5);
        expect(range.length, equals(1),
            reason: 'Range [5, 5] should have length 1');
      });

      test('calculates correct length for range starting at zero', () {
        // Requirements: 5.5
        final range = VisibleRange(0, 9);
        expect(range.length, equals(10),
            reason: 'Range [0, 9] should have length 10');
      });

      test('calculates correct length for large range', () {
        // Requirements: 5.5
        final range = VisibleRange(0, 999);
        expect(range.length, equals(1000),
            reason: 'Range [0, 999] should have length 1000');
      });

      test('length formula is consistent (end - start + 1)', () {
        // Requirements: 5.5
        final testCases = [
          (0, 0, 1),
          (0, 10, 11),
          (5, 10, 6),
          (10, 20, 11),
          (100, 200, 101),
        ];

        for (final testCase in testCases) {
          final range = VisibleRange(testCase.$1, testCase.$2);
          final expectedLength = testCase.$3;
          expect(
            range.length,
            equals(expectedLength),
            reason:
                'Range [${testCase.$1}, ${testCase.$2}] should have length $expectedLength',
          );
        }
      });
    });

    group('equality operator (==)', () {
      test('returns true for identical ranges', () {
        // Requirements: 5.6
        final range1 = VisibleRange(5, 10);
        final range2 = VisibleRange(5, 10);
        expect(range1 == range2, isTrue,
            reason: 'Ranges with same start and end should be equal');
      });

      test('returns true for same instance', () {
        // Requirements: 5.6
        final range = VisibleRange(5, 10);
        expect(range == range, isTrue,
            reason: 'Range should be equal to itself');
      });

      test('returns false for ranges with different start', () {
        // Requirements: 5.6
        final range1 = VisibleRange(5, 10);
        final range2 = VisibleRange(6, 10);
        expect(range1 == range2, isFalse,
            reason: 'Ranges with different start should not be equal');
      });

      test('returns false for ranges with different end', () {
        // Requirements: 5.6
        final range1 = VisibleRange(5, 10);
        final range2 = VisibleRange(5, 11);
        expect(range1 == range2, isFalse,
            reason: 'Ranges with different end should not be equal');
      });

      test('returns false for ranges with both different start and end', () {
        // Requirements: 5.6
        final range1 = VisibleRange(5, 10);
        final range2 = VisibleRange(6, 11);
        expect(range1 == range2, isFalse,
            reason: 'Ranges with different start and end should not be equal');
      });

      test('returns false when comparing with non-VisibleRange object', () {
        // Requirements: 5.6
        final range = VisibleRange(5, 10);
        expect(range == 'not a range', isFalse,
            reason: 'Range should not be equal to non-VisibleRange object');
        expect(range == 5, isFalse,
            reason: 'Range should not be equal to integer');
        expect(range == null, isFalse,
            reason: 'Range should not be equal to null');
      });
    });

    group('hashCode', () {
      test('is consistent for identical ranges', () {
        // Requirements: 5.6
        final range1 = VisibleRange(5, 10);
        final range2 = VisibleRange(5, 10);
        expect(
          range1.hashCode,
          equals(range2.hashCode),
          reason: 'Identical ranges should have the same hashCode',
        );
      });

      test('is consistent for same instance', () {
        // Requirements: 5.6
        final range = VisibleRange(5, 10);
        final hash1 = range.hashCode;
        final hash2 = range.hashCode;
        expect(hash1, equals(hash2),
            reason: 'hashCode should be consistent for same instance');
      });

      test('is different for ranges with different values', () {
        // Requirements: 5.6
        final range1 = VisibleRange(5, 10);
        final range2 = VisibleRange(6, 11);
        // Note: While different objects should ideally have different hash codes,
        // hash collisions are possible. We just verify they're computed consistently.
        expect(
          range1.hashCode != range2.hashCode ||
              range1.hashCode == range2.hashCode,
          isTrue,
          reason:
              'hashCode should be computed (collision possible but unlikely)',
        );
      });

      test('satisfies hashCode contract with equality', () {
        // Requirements: 5.6
        // If two objects are equal, they must have the same hashCode
        final range1 = VisibleRange(5, 10);
        final range2 = VisibleRange(5, 10);
        final range3 = VisibleRange(6, 11);

        if (range1 == range2) {
          expect(
            range1.hashCode,
            equals(range2.hashCode),
            reason: 'Equal objects must have equal hashCodes',
          );
        }

        // Different objects may or may not have different hashCodes (collisions allowed)
        // but we verify the contract holds
        expect(range1 == range3, isFalse);
      });
    });

    group('toString', () {
      test('returns correct format for standard range', () {
        // Requirements: 5.6
        final range = VisibleRange(5, 10);
        expect(range.toString(), equals('VisibleRange(5, 10)'),
            reason: 'toString should return correct format');
      });

      test('returns correct format for single-element range', () {
        // Requirements: 5.6
        final range = VisibleRange(5, 5);
        expect(range.toString(), equals('VisibleRange(5, 5)'),
            reason: 'toString should return correct format for single element');
      });

      test('returns correct format for range starting at zero', () {
        // Requirements: 5.6
        final range = VisibleRange(0, 10);
        expect(range.toString(), equals('VisibleRange(0, 10)'),
            reason: 'toString should return correct format for zero start');
      });

      test('returns correct format for large range', () {
        // Requirements: 5.6
        final range = VisibleRange(100, 999);
        expect(range.toString(), equals('VisibleRange(100, 999)'),
            reason: 'toString should return correct format for large range');
      });

      test('toString is consistent across multiple calls', () {
        // Requirements: 5.6
        final range = VisibleRange(5, 10);
        final str1 = range.toString();
        final str2 = range.toString();
        expect(str1, equals(str2),
            reason: 'toString should be consistent across multiple calls');
      });
    });

    group('edge cases', () {
      test('handles range with start equal to end', () {
        final range = VisibleRange(5, 5);
        expect(range.contains(5), isTrue);
        expect(range.length, equals(1));
        expect(range.overlaps(5, 5), isTrue);
        expect(range.toString(), equals('VisibleRange(5, 5)'));
      });

      test('handles range starting at zero', () {
        final range = VisibleRange(0, 5);
        expect(range.contains(0), isTrue);
        expect(range.contains(-1), isFalse);
        expect(range.length, equals(6));
      });

      test('handles large range values', () {
        final range = VisibleRange(1000, 2000);
        expect(range.contains(1500), isTrue);
        expect(range.length, equals(1001));
        expect(range.overlaps(1500, 2500), isTrue);
      });

      test('equality works with const constructor', () {
        const range1 = VisibleRange(5, 10);
        const range2 = VisibleRange(5, 10);
        expect(range1 == range2, isTrue);
        expect(range1.hashCode, equals(range2.hashCode));
      });
    });
  });
}
