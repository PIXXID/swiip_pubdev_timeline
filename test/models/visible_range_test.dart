import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/visible_range.dart';

void main() {
  group('VisibleRange', () {
    group('constructor', () {
      test('creates instance with given start and end', () {
        const range = VisibleRange(5, 15);
        expect(range.start, equals(5));
        expect(range.end, equals(15));
      });

      test('allows start equal to end', () {
        const range = VisibleRange(10, 10);
        expect(range.start, equals(10));
        expect(range.end, equals(10));
      });

      test('allows start greater than end', () {
        // Note: The model doesn't enforce start <= end, allowing flexibility
        const range = VisibleRange(15, 5);
        expect(range.start, equals(15));
        expect(range.end, equals(5));
      });
    });

    group('contains', () {
      test('returns true when index is within range', () {
        const range = VisibleRange(5, 15);
        expect(range.contains(10), isTrue);
      });

      test('returns true when index equals start', () {
        const range = VisibleRange(5, 15);
        expect(range.contains(5), isTrue);
      });

      test('returns true when index equals end', () {
        const range = VisibleRange(5, 15);
        expect(range.contains(15), isTrue);
      });

      test('returns false when index is before start', () {
        const range = VisibleRange(5, 15);
        expect(range.contains(4), isFalse);
      });

      test('returns false when index is after end', () {
        const range = VisibleRange(5, 15);
        expect(range.contains(16), isFalse);
      });

      test('handles single-item range', () {
        const range = VisibleRange(10, 10);
        expect(range.contains(10), isTrue);
        expect(range.contains(9), isFalse);
        expect(range.contains(11), isFalse);
      });

      test('handles negative indices', () {
        const range = VisibleRange(-5, 5);
        expect(range.contains(-3), isTrue);
        expect(range.contains(0), isTrue);
        expect(range.contains(3), isTrue);
        expect(range.contains(-6), isFalse);
        expect(range.contains(6), isFalse);
      });
    });

    group('overlaps', () {
      test('returns true when ranges fully overlap', () {
        const range = VisibleRange(5, 15);
        expect(range.overlaps(5, 15), isTrue);
      });

      test('returns true when test range is inside visible range', () {
        const range = VisibleRange(5, 15);
        expect(range.overlaps(8, 12), isTrue);
      });

      test('returns true when visible range is inside test range', () {
        const range = VisibleRange(8, 12);
        expect(range.overlaps(5, 15), isTrue);
      });

      test('returns true when ranges partially overlap at start', () {
        const range = VisibleRange(5, 15);
        expect(range.overlaps(3, 7), isTrue);
      });

      test('returns true when ranges partially overlap at end', () {
        const range = VisibleRange(5, 15);
        expect(range.overlaps(13, 20), isTrue);
      });

      test('returns true when ranges touch at boundaries', () {
        const range = VisibleRange(5, 15);
        expect(range.overlaps(15, 20), isTrue);
        expect(range.overlaps(0, 5), isTrue);
      });

      test('returns false when test range is completely before', () {
        const range = VisibleRange(10, 20);
        expect(range.overlaps(0, 9), isFalse);
      });

      test('returns false when test range is completely after', () {
        const range = VisibleRange(10, 20);
        expect(range.overlaps(21, 30), isFalse);
      });

      test('handles single-point ranges', () {
        const range = VisibleRange(10, 10);
        expect(range.overlaps(10, 10), isTrue);
        expect(range.overlaps(9, 11), isTrue);
        expect(range.overlaps(5, 9), isFalse);
        expect(range.overlaps(11, 15), isFalse);
      });

      test('handles negative indices', () {
        const range = VisibleRange(-10, 10);
        expect(range.overlaps(-15, -5), isTrue);
        expect(range.overlaps(5, 15), isTrue);
        expect(range.overlaps(-20, -11), isFalse);
      });
    });

    group('length', () {
      test('returns correct length for normal range', () {
        const range = VisibleRange(5, 15);
        expect(range.length, equals(11));
      });

      test('returns 1 for single-item range', () {
        const range = VisibleRange(10, 10);
        expect(range.length, equals(1));
      });

      test('returns negative length when start > end', () {
        const range = VisibleRange(15, 5);
        expect(range.length, equals(-9));
      });

      test('handles zero-based range', () {
        const range = VisibleRange(0, 10);
        expect(range.length, equals(11));
      });
    });

    group('equality', () {
      test('returns true for identical ranges', () {
        const range1 = VisibleRange(5, 15);
        const range2 = VisibleRange(5, 15);
        expect(range1, equals(range2));
      });

      test('returns false for different start', () {
        const range1 = VisibleRange(5, 15);
        const range2 = VisibleRange(6, 15);
        expect(range1, isNot(equals(range2)));
      });

      test('returns false for different end', () {
        const range1 = VisibleRange(5, 15);
        const range2 = VisibleRange(5, 16);
        expect(range1, isNot(equals(range2)));
      });

      test('returns true for same instance', () {
        const range = VisibleRange(5, 15);
        expect(range, equals(range));
      });
    });

    group('hashCode', () {
      test('returns same hashCode for equal ranges', () {
        const range1 = VisibleRange(5, 15);
        const range2 = VisibleRange(5, 15);
        expect(range1.hashCode, equals(range2.hashCode));
      });

      test('returns different hashCode for different ranges', () {
        const range1 = VisibleRange(5, 15);
        const range2 = VisibleRange(6, 16);
        expect(range1.hashCode, isNot(equals(range2.hashCode)));
      });
    });

    group('toString', () {
      test('returns formatted string representation', () {
        const range = VisibleRange(5, 15);
        expect(range.toString(), equals('VisibleRange(5, 15)'));
      });

      test('handles negative values', () {
        const range = VisibleRange(-5, 10);
        expect(range.toString(), equals('VisibleRange(-5, 10)'));
      });
    });
  });
}
