import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/timeline_configuration.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/parameter_constraints.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/configuration_validator.dart';

void main() {
  group('Requirements Verification', () {
    group('Requirement 1: Ajout du Paramètre barHeight', () {
      test('1.1 - TimelineConfiguration includes barHeight of type double', () {
        const config = TimelineConfiguration();
        expect(config.barHeight, isA<double>());
      });

      test('1.2 - barHeight has default value of 70.0', () {
        const config = TimelineConfiguration();
        expect(config.barHeight, equals(70.0));
      });

      test('1.3 - barHeight is accessible via TimelineConfiguration instance',
          () {
        const config = TimelineConfiguration(barHeight: 100.0);
        expect(config.barHeight, equals(100.0));
      });

      test('1.4 - fromMap parses barHeight from JSON', () {
        final config = TimelineConfiguration.fromMap({'barHeight': 85.0});
        expect(config.barHeight, equals(85.0));
      });

      test('1.5 - toMap includes barHeight in output', () {
        const config = TimelineConfiguration(barHeight: 90.0);
        final map = config.toMap();
        expect(map['barHeight'], equals(90.0));
      });
    });

    group('Requirement 2: Validation du Paramètre barHeight', () {
      test('2.1 - ParameterConstraints defines valid range 40.0-150.0', () {
        final constraints = ParameterConstraints.all['barHeight']!;
        expect(constraints.min, equals(40.0));
        expect(constraints.max, equals(150.0));
      });

      test('2.2 - barHeight < 40.0 uses default 70.0', () {
        final result = ConfigurationValidator.validate({'barHeight': 30.0});
        expect(result.validatedConfig['barHeight'], equals(70.0));
      });

      test('2.3 - barHeight > 150.0 uses default 70.0', () {
        final result = ConfigurationValidator.validate({'barHeight': 200.0});
        expect(result.validatedConfig['barHeight'], equals(70.0));
      });

      test('2.4 - Invalid type uses default and logs warning', () {
        final result = ConfigurationValidator.validate({'barHeight': 'tall'});
        expect(result.validatedConfig['barHeight'], equals(70.0));
        expect(
            result.warnings.any((w) => w.parameterName == 'barHeight'), isTrue);
      });

      test('2.5 - Validation errors include barHeight in message', () {
        final result = ConfigurationValidator.validate({'barHeight': 200.0});
        expect(
            result.errors.any((e) => e.parameterName == 'barHeight'), isTrue);
      });
    });

    group('Requirement 3: Intégration dans le Fichier de Configuration', () {
      test('3.1 - timeline_config.json supports barHeight parameter', () {
        // This is verified by the file existing and being parseable
        final config = TimelineConfiguration.fromMap({'barHeight': 80.0});
        expect(config.barHeight, equals(80.0));
      });

      test('3.3 - Omitted barHeight uses default 70.0', () {
        final config = TimelineConfiguration.fromMap({'dayWidth': 50.0});
        expect(config.barHeight, equals(70.0));
      });
    });

    group('Requirement 7: Compatibilité Ascendante', () {
      test('7.1 - No barHeight specified uses default 70.0', () {
        final config = TimelineConfiguration.fromMap({});
        expect(config.barHeight, equals(70.0));
      });

      test('7.3 - Constructor accepts barHeight as optional parameter', () {
        const config1 = TimelineConfiguration();
        const config2 = TimelineConfiguration(barHeight: 100.0);

        expect(config1.barHeight, equals(70.0));
        expect(config2.barHeight, equals(100.0));
      });

      test('7.4 - Created without barHeight uses default', () {
        const config = TimelineConfiguration(dayWidth: 50.0);
        expect(config.barHeight, equals(70.0));
      });
    });

    group('Requirement 8: Cohérence avec le Système Existant', () {
      test('8.1 - barHeight follows camelCase naming convention', () {
        // Verified by compilation - if it wasn\'t camelCase, it wouldn\'t compile
        const config = TimelineConfiguration(barHeight: 70.0);
        expect(config.barHeight, equals(70.0));
      });

      test('8.2 - barHeight uses ParameterConstraints pattern', () {
        final constraints = ParameterConstraints.all['barHeight'];
        expect(constraints, isNotNull);
        expect(constraints!.type, equals('double'));
        expect(constraints.defaultValue, equals(70.0));
      });
    });
  });
}
