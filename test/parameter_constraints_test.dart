import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/parameter_constraints.dart';

void main() {
  group('ParameterConstraints - rangeString', () {
    test('rangeString with min and max returns formatted range', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'double',
        min: 20.0,
        max: 100.0,
        defaultValue: 45.0,
      );

      // Act
      final rangeString = constraints.rangeString;

      // Assert
      expect(rangeString, equals('20.0 - 100.0'));
    });

    test('rangeString with only min returns >= format', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'double',
        min: 20.0,
        defaultValue: 45.0,
      );

      // Act
      final rangeString = constraints.rangeString;

      // Assert
      expect(rangeString, equals('>= 20.0'));
    });

    test('rangeString with only max returns <= format', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'double',
        max: 100.0,
        defaultValue: 45.0,
      );

      // Act
      final rangeString = constraints.rangeString;

      // Assert
      expect(rangeString, equals('<= 100.0'));
    });

    test('rangeString without limits returns null', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'double',
        defaultValue: 45.0,
      );

      // Act
      final rangeString = constraints.rangeString;

      // Assert
      expect(rangeString, isNull);
    });
  });

  group('ParameterConstraints - isValid', () {
    test('isValid with valid double value returns true', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'double',
        min: 20.0,
        max: 100.0,
        defaultValue: 45.0,
      );

      // Act
      final result = constraints.isValid(50.0);

      // Assert
      expect(result, isTrue);
    });

    test('isValid with valid int value for int type returns true', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'int',
        min: 1,
        max: 20,
        defaultValue: 5,
      );

      // Act
      final result = constraints.isValid(10);

      // Assert
      expect(result, isTrue);
    });

    test('isValid with invalid type for double returns false', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'double',
        min: 20.0,
        max: 100.0,
        defaultValue: 45.0,
      );

      // Act
      final result = constraints.isValid('not a number');

      // Assert
      expect(result, isFalse);
    });

    test('isValid with invalid type for int returns false', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'int',
        min: 1,
        max: 20,
        defaultValue: 5,
      );

      // Act
      final result = constraints.isValid('not an int');

      // Assert
      expect(result, isFalse);
    });

    test('isValid with value below minimum returns false', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'double',
        min: 20.0,
        max: 100.0,
        defaultValue: 45.0,
      );

      // Act
      final result = constraints.isValid(10.0);

      // Assert
      expect(result, isFalse);
    });

    test('isValid with value above maximum returns false', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'double',
        min: 20.0,
        max: 100.0,
        defaultValue: 45.0,
      );

      // Act
      final result = constraints.isValid(150.0);

      // Assert
      expect(result, isFalse);
    });

    test('isValid with value at minimum boundary returns true', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'double',
        min: 20.0,
        max: 100.0,
        defaultValue: 45.0,
      );

      // Act
      final result = constraints.isValid(20.0);

      // Assert
      expect(result, isTrue);
    });

    test('isValid with value at maximum boundary returns true', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'double',
        min: 20.0,
        max: 100.0,
        defaultValue: 45.0,
      );

      // Act
      final result = constraints.isValid(100.0);

      // Assert
      expect(result, isTrue);
    });

    test('isValid with int value for double type returns true', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'double',
        min: 20.0,
        max: 100.0,
        defaultValue: 45.0,
      );

      // Act - int is a num, so should be valid for double type
      final result = constraints.isValid(50);

      // Assert
      expect(result, isTrue);
    });

    test('isValid with double value for int type returns true', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'int',
        min: 1,
        max: 20,
        defaultValue: 5,
      );

      // Act - double is a num, so should be valid for int type
      final result = constraints.isValid(10.0);

      // Assert
      expect(result, isTrue);
    });

    test('isValid with null value returns false', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'double',
        min: 20.0,
        max: 100.0,
        defaultValue: 45.0,
      );

      // Act
      final result = constraints.isValid(null);

      // Assert
      expect(result, isFalse);
    });

    test('isValid with boolean value returns false', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'double',
        min: 20.0,
        max: 100.0,
        defaultValue: 45.0,
      );

      // Act
      final result = constraints.isValid(true);

      // Assert
      expect(result, isFalse);
    });

    test('isValid with String type and valid string returns true', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'String',
        defaultValue: 'default',
      );

      // Act
      final result = constraints.isValid('test string');

      // Assert
      expect(result, isTrue);
    });

    test('isValid with String type and non-string value returns false', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'String',
        defaultValue: 'default',
      );

      // Act
      final result = constraints.isValid(123);

      // Assert
      expect(result, isFalse);
    });

    test('isValid with no range constraints only validates type', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'double',
        defaultValue: 45.0,
      );

      // Act - any numeric value should be valid
      final result1 = constraints.isValid(-1000.0);
      final result2 = constraints.isValid(1000.0);
      final result3 = constraints.isValid(0.0);

      // Assert
      expect(result1, isTrue);
      expect(result2, isTrue);
      expect(result3, isTrue);
    });

    test('isValid with only min constraint validates correctly', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'double',
        min: 20.0,
        defaultValue: 45.0,
      );

      // Act
      final validResult = constraints.isValid(50.0);
      final invalidResult = constraints.isValid(10.0);

      // Assert
      expect(validResult, isTrue);
      expect(invalidResult, isFalse);
    });

    test('isValid with only max constraint validates correctly', () {
      // Arrange
      const constraints = ParameterConstraints(
        type: 'double',
        max: 100.0,
        defaultValue: 45.0,
      );

      // Act
      final validResult = constraints.isValid(50.0);
      final invalidResult = constraints.isValid(150.0);

      // Assert
      expect(validResult, isTrue);
      expect(invalidResult, isFalse);
    });
  });

  group('ParameterConstraints - all', () {
    test('all contains all expected parameters', () {
      // Act
      final allConstraints = ParameterConstraints.all;

      // Assert
      expect(allConstraints, isNotNull);
      expect(allConstraints, isNotEmpty);

      // Verify all known parameters are present
      expect(allConstraints.containsKey('dayWidth'), isTrue);
      expect(allConstraints.containsKey('dayMargin'), isTrue);
      expect(allConstraints.containsKey('datesHeight'), isTrue);
      expect(allConstraints.containsKey('rowHeight'), isTrue);
      expect(allConstraints.containsKey('rowMargin'), isTrue);
      expect(allConstraints.containsKey('bufferDays'), isTrue);
      expect(allConstraints.containsKey('animationDurationMs'), isTrue);

      // Verify count
      expect(allConstraints.length, equals(7));
    });

    test('all dayWidth constraint has correct values', () {
      // Act
      final dayWidth = ParameterConstraints.all['dayWidth'];

      // Assert
      expect(dayWidth, isNotNull);
      expect(dayWidth!.type, equals('double'));
      expect(dayWidth.min, equals(20.0));
      expect(dayWidth.max, equals(100.0));
      expect(dayWidth.defaultValue, equals(45.0));
    });

    test('all dayMargin constraint has correct values', () {
      // Act
      final dayMargin = ParameterConstraints.all['dayMargin'];

      // Assert
      expect(dayMargin, isNotNull);
      expect(dayMargin!.type, equals('double'));
      expect(dayMargin.min, equals(0.0));
      expect(dayMargin.max, equals(20.0));
      expect(dayMargin.defaultValue, equals(5.0));
    });

    test('all datesHeight constraint has correct values', () {
      // Act
      final datesHeight = ParameterConstraints.all['datesHeight'];

      // Assert
      expect(datesHeight, isNotNull);
      expect(datesHeight!.type, equals('double'));
      expect(datesHeight.min, equals(40.0));
      expect(datesHeight.max, equals(100.0));
      expect(datesHeight.defaultValue, equals(65.0));
    });

    test('all rowHeight constraint has correct values', () {
      // Act
      final rowHeight = ParameterConstraints.all['rowHeight'];

      // Assert
      expect(rowHeight, isNotNull);
      expect(rowHeight!.type, equals('double'));
      expect(rowHeight.min, equals(20.0));
      expect(rowHeight.max, equals(60.0));
      expect(rowHeight.defaultValue, equals(30.0));
    });

    test('all rowMargin constraint has correct values', () {
      // Act
      final rowMargin = ParameterConstraints.all['rowMargin'];

      // Assert
      expect(rowMargin, isNotNull);
      expect(rowMargin!.type, equals('double'));
      expect(rowMargin.min, equals(0.0));
      expect(rowMargin.max, equals(10.0));
      expect(rowMargin.defaultValue, equals(3.0));
    });

    test('all bufferDays constraint has correct values', () {
      // Act
      final bufferDays = ParameterConstraints.all['bufferDays'];

      // Assert
      expect(bufferDays, isNotNull);
      expect(bufferDays!.type, equals('int'));
      expect(bufferDays.min, equals(1));
      expect(bufferDays.max, equals(20));
      expect(bufferDays.defaultValue, equals(5));
    });

    test('all animationDurationMs constraint has correct values', () {
      // Act
      final animationDurationMs = ParameterConstraints.all['animationDurationMs'];

      // Assert
      expect(animationDurationMs, isNotNull);
      expect(animationDurationMs!.type, equals('int'));
      expect(animationDurationMs.min, equals(100));
      expect(animationDurationMs.max, equals(500));
      expect(animationDurationMs.defaultValue, equals(220));
    });
  });
}
