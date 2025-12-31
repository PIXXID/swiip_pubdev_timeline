import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/scroll_calculations.dart';

void main() {
  group('calculateCenterDateIndex', () {
    test('calcule correctement l\'index au centre du viewport', () {
      // Arrange
      const scrollOffset = 1000.0;
      const viewportWidth = 800.0;
      const dayWidth = 45.0;
      const dayMargin = 5.0;
      const totalDays = 100;

      // Act
      final result = calculateCenterDateIndex(
        scrollOffset: scrollOffset,
        viewportWidth: viewportWidth,
        dayWidth: dayWidth,
        dayMargin: dayMargin,
        totalDays: totalDays,
      );

      // Assert
      // centerPosition = 1000 + 400 = 1400
      // centerIndex = 1400 / (45 - 5) = 1400 / 40 = 35
      expect(result, equals(35));
    });

    test('clamp l\'index à 0 quand le calcul donne un nombre négatif', () {
      // Arrange
      const scrollOffset = 0.0;
      const viewportWidth = 800.0;
      const dayWidth = 45.0;
      const dayMargin = 5.0;
      const totalDays = 100;

      // Act
      final result = calculateCenterDateIndex(
        scrollOffset: scrollOffset,
        viewportWidth: viewportWidth,
        dayWidth: dayWidth,
        dayMargin: dayMargin,
        totalDays: totalDays,
      );

      // Assert
      // centerPosition = 0 + 400 = 400
      // centerIndex = 400 / 40 = 10
      expect(result, greaterThanOrEqualTo(0));
      expect(result, equals(10));
    });

    test('clamp l\'index à totalDays-1 quand le calcul dépasse', () {
      // Arrange
      const scrollOffset = 10000.0;
      const viewportWidth = 800.0;
      const dayWidth = 45.0;
      const dayMargin = 5.0;
      const totalDays = 100;

      // Act
      final result = calculateCenterDateIndex(
        scrollOffset: scrollOffset,
        viewportWidth: viewportWidth,
        dayWidth: dayWidth,
        dayMargin: dayMargin,
        totalDays: totalDays,
      );

      // Assert
      expect(result, lessThanOrEqualTo(totalDays - 1));
      expect(result, equals(99));
    });

    test('retourne le même résultat pour les mêmes paramètres (pureté)', () {
      // Arrange
      const scrollOffset = 500.0;
      const viewportWidth = 800.0;
      const dayWidth = 45.0;
      const dayMargin = 5.0;
      const totalDays = 100;

      // Act - Appeler 10 fois avec les mêmes paramètres
      final results = List.generate(
        10,
        (_) => calculateCenterDateIndex(
          scrollOffset: scrollOffset,
          viewportWidth: viewportWidth,
          dayWidth: dayWidth,
          dayMargin: dayMargin,
          totalDays: totalDays,
        ),
      );

      // Assert - Tous les résultats doivent être identiques
      expect(results.toSet().length, equals(1));
      // centerPosition = 500 + 400 = 900
      // centerIndex = 900 / 40 = 22.5 ≈ 23
      expect(results.first, equals(23));
    });

    test('gère correctement les positions de scroll au début', () {
      // Arrange
      const scrollOffset = 0.0;
      const viewportWidth = 800.0;
      const dayWidth = 45.0;
      const dayMargin = 5.0;
      const totalDays = 100;

      // Act
      final result = calculateCenterDateIndex(
        scrollOffset: scrollOffset,
        viewportWidth: viewportWidth,
        dayWidth: dayWidth,
        dayMargin: dayMargin,
        totalDays: totalDays,
      );

      // Assert
      expect(result, equals(10)); // (0 + 400) / 40 = 10
    });

    test('gère correctement différentes largeurs de jour', () {
      // Arrange
      const scrollOffset = 1000.0;
      const viewportWidth = 800.0;
      const dayWidth = 60.0; // Largeur différente
      const dayMargin = 10.0; // Marge différente
      const totalDays = 100;

      // Act
      final result = calculateCenterDateIndex(
        scrollOffset: scrollOffset,
        viewportWidth: viewportWidth,
        dayWidth: dayWidth,
        dayMargin: dayMargin,
        totalDays: totalDays,
      );

      // Assert
      // centerPosition = 1000 + 400 = 1400
      // centerIndex = 1400 / (60 - 10) = 1400 / 50 = 28
      expect(result, equals(28));
    });
  });

  group('Pureté des fonctions', () {
    test('calculateCenterDateIndex ne modifie pas les paramètres', () {
      // Arrange
      const scrollOffset = 1000.0;
      const viewportWidth = 800.0;
      const dayWidth = 45.0;
      const dayMargin = 5.0;
      const totalDays = 100;

      // Act
      calculateCenterDateIndex(
        scrollOffset: scrollOffset,
        viewportWidth: viewportWidth,
        dayWidth: dayWidth,
        dayMargin: dayMargin,
        totalDays: totalDays,
      );

      // Assert - Les paramètres ne doivent pas avoir changé
      expect(scrollOffset, equals(1000.0));
      expect(viewportWidth, equals(800.0));
      expect(dayWidth, equals(45.0));
      expect(dayMargin, equals(5.0));
      expect(totalDays, equals(100));
    });
  });
}
