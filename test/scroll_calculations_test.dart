import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/scroll_calculations.dart';

void main() {
  group('calculateCenterDateIndex', () {
    test('calcule correctement l\'index au centre du viewport', () {
      // Arrange
      const scrollOffset = 1000.0;
      const dayWidth = 45.0;
      const dayMargin = 5.0;
      const totalDays = 100;

      // Act
      final result = calculateCenterDateIndex(
        scrollOffset: scrollOffset,
        dayWidth: dayWidth,
        dayMargin: dayMargin,
        totalDays: totalDays,
      );

      // Assert
      // centerIndex = 1000 / (45 - 5) = 1000 / 40 = 25
      expect(result, equals(25));
    });

    test('clamp l\'index à 0 quand le calcul donne un nombre négatif', () {
      // Arrange
      const scrollOffset = 0.0;
      const viewportWidth = 800.0;
      const dayWidth = 45.0;
      const dayMargin = 5.0;
      const totalDays = 100;
      const firstElementMargin =
          (viewportWidth - (dayWidth - dayMargin)) / 2; // 380.0

      // Act
      final result = calculateCenterDateIndex(
        scrollOffset: scrollOffset,
        
        dayWidth: dayWidth,
        dayMargin: dayMargin,
        totalDays: totalDays,
      );

      // Assert
      // centerPosition = 0 + 380 = 380
      // centerIndex = 380 / 40 = 9.5 ≈ 10
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
      const firstElementMargin =
          (viewportWidth - (dayWidth - dayMargin)) / 2; // 380.0

      // Act
      final result = calculateCenterDateIndex(
        scrollOffset: scrollOffset,
        
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
      const firstElementMargin =
          (viewportWidth - (dayWidth - dayMargin)) / 2; // 380.0

      // Act - Appeler 10 fois avec les mêmes paramètres
      final results = List.generate(
        10,
        (_) => calculateCenterDateIndex(
          scrollOffset: scrollOffset,
          
          dayWidth: dayWidth,
          dayMargin: dayMargin,
          totalDays: totalDays,
        ),
      );

      // Assert - Tous les résultats doivent être identiques
      expect(results.toSet().length, equals(1));
      // Formule: firstElementMargin = (800 - 40) / 2 = 380
      //          centerPosition = 500 + 380 = 880
      //          centerIndex = 880 / 40 = 22
      expect(results.first, equals(22));
    });

    test('gère correctement les positions de scroll au début', () {
      // Arrange
      const scrollOffset = 0.0;
      const viewportWidth = 800.0;
      const dayWidth = 45.0;
      const dayMargin = 5.0;
      const totalDays = 100;
      const firstElementMargin =
          (viewportWidth - (dayWidth - dayMargin)) / 2; // 380.0

      // Act
      final result = calculateCenterDateIndex(
        scrollOffset: scrollOffset,
        
        dayWidth: dayWidth,
        dayMargin: dayMargin,
        totalDays: totalDays,
      );

      // Assert
      expect(result, equals(10)); // (0 + 380) / 40 = 9.5 ≈ 10
    });

    test('gère correctement différentes largeurs de jour', () {
      // Arrange
      const scrollOffset = 1000.0;
      const viewportWidth = 800.0;
      const dayWidth = 60.0; // Largeur différente
      const dayMargin = 10.0; // Marge différente
      const totalDays = 100;
      const firstElementMargin =
          (viewportWidth - (dayWidth - dayMargin)) / 2; // 275.0

      // Act
      final result = calculateCenterDateIndex(
        scrollOffset: scrollOffset,
        
        dayWidth: dayWidth,
        dayMargin: dayMargin,
        totalDays: totalDays,
      );

      // Assert
      // centerPosition = 1000 + 375 = 1375
      // centerIndex = 1375 / (60 - 10) = 1375 / 50 = 27.5 ≈ 28
      expect(result, equals(28));
    });
  });

  group('calculateTargetVerticalOffset', () {
    // Mock functions pour les tests
    int mockGetHigherStageRowIndex(List stagesRows, int searchIndex) {
      // Retourne toujours la première ligne pour simplifier
      return stagesRows.isNotEmpty ? 0 : -1;
    }

    int mockGetLowerStageRowIndex(List stagesRows, int searchIndex) {
      // Retourne toujours la dernière ligne pour simplifier
      return stagesRows.isNotEmpty ? stagesRows.length - 1 : -1;
    }

    test('calcule correctement l\'offset vertical pour scroll vers la droite',
        () {
      // Arrange
      const centerDateIndex = 50;
      final stagesRows = [
        [
          {'startDateIndex': 0, 'endDateIndex': 100}
        ],
        [
          {'startDateIndex': 0, 'endDateIndex': 100}
        ],
      ];
      const rowHeight = 30.0;
      const rowMargin = 3.0;
      const scrollingLeft = false;

      // Act
      final result = calculateTargetVerticalOffset(
        centerDateIndex: centerDateIndex,
        stagesRows: stagesRows,
        rowHeight: rowHeight,
        rowMargin: rowMargin,
        scrollingLeft: scrollingLeft,
        getHigherStageRowIndex: mockGetHigherStageRowIndex,
        getLowerStageRowIndex: mockGetLowerStageRowIndex,
      );

      // Assert
      // rowIndex = 0 (mockGetHigherStageRowIndex retourne 0)
      // offset = 0 * (30 + 3*2) = 0
      expect(result, equals(0.0));
    });

    test('calcule correctement l\'offset vertical pour scroll vers la gauche',
        () {
      // Arrange
      const centerDateIndex = 50;
      final stagesRows = [
        [
          {'startDateIndex': 0, 'endDateIndex': 100}
        ],
        [
          {'startDateIndex': 0, 'endDateIndex': 100}
        ],
        [
          {'startDateIndex': 0, 'endDateIndex': 100}
        ],
      ];
      const rowHeight = 30.0;
      const rowMargin = 3.0;
      const scrollingLeft = true;

      // Act
      final result = calculateTargetVerticalOffset(
        centerDateIndex: centerDateIndex,
        stagesRows: stagesRows,
        rowHeight: rowHeight,
        rowMargin: rowMargin,
        scrollingLeft: scrollingLeft,
        getHigherStageRowIndex: mockGetHigherStageRowIndex,
        getLowerStageRowIndex: mockGetLowerStageRowIndex,
      );

      // Assert
      // rowIndex = 2 (mockGetLowerStageRowIndex retourne length-1 = 2)
      // offset = 2 * (30 + 3*2) = 2 * 36 = 72
      expect(result, equals(72.0));
    });

    test('retourne null quand stagesRows est vide', () {
      // Arrange
      const centerDateIndex = 50;
      final stagesRows = [];
      const rowHeight = 30.0;
      const rowMargin = 3.0;
      const scrollingLeft = false;

      // Act
      final result = calculateTargetVerticalOffset(
        centerDateIndex: centerDateIndex,
        stagesRows: stagesRows,
        rowHeight: rowHeight,
        rowMargin: rowMargin,
        scrollingLeft: scrollingLeft,
        getHigherStageRowIndex: mockGetHigherStageRowIndex,
        getLowerStageRowIndex: mockGetLowerStageRowIndex,
      );

      // Assert
      expect(result, isNull);
    });

    test('retourne null quand aucune ligne n\'est trouvée', () {
      // Arrange
      const centerDateIndex = 50;
      final stagesRows = [
        [
          {'startDateIndex': 0, 'endDateIndex': 100}
        ]
      ];
      const rowHeight = 30.0;
      const rowMargin = 3.0;
      const scrollingLeft = false;

      // Mock qui retourne -1 (aucune ligne trouvée)
      int mockGetNoRowIndex(List stagesRows, int searchIndex) => -1;

      // Act
      final result = calculateTargetVerticalOffset(
        centerDateIndex: centerDateIndex,
        stagesRows: stagesRows,
        rowHeight: rowHeight,
        rowMargin: rowMargin,
        scrollingLeft: scrollingLeft,
        getHigherStageRowIndex: mockGetNoRowIndex,
        getLowerStageRowIndex: mockGetNoRowIndex,
      );

      // Assert
      expect(result, isNull);
    });

    test('retourne le même résultat pour les mêmes paramètres (pureté)', () {
      // Arrange
      const centerDateIndex = 50;
      final stagesRows = [
        [
          {'startDateIndex': 0, 'endDateIndex': 100}
        ],
        [
          {'startDateIndex': 0, 'endDateIndex': 100}
        ],
      ];
      const rowHeight = 30.0;
      const rowMargin = 3.0;
      const scrollingLeft = false;

      // Act - Appeler 10 fois avec les mêmes paramètres
      final results = List.generate(
        10,
        (_) => calculateTargetVerticalOffset(
          centerDateIndex: centerDateIndex,
          stagesRows: stagesRows,
          rowHeight: rowHeight,
          rowMargin: rowMargin,
          scrollingLeft: scrollingLeft,
          getHigherStageRowIndex: mockGetHigherStageRowIndex,
          getLowerStageRowIndex: mockGetLowerStageRowIndex,
        ),
      );

      // Assert - Tous les résultats doivent être identiques
      expect(results.toSet().length, equals(1));
    });

    test('calcule correctement avec différentes hauteurs de ligne', () {
      // Arrange
      const centerDateIndex = 50;
      final stagesRows = [
        [
          {'startDateIndex': 0, 'endDateIndex': 100}
        ],
        [
          {'startDateIndex': 0, 'endDateIndex': 100}
        ],
        [
          {'startDateIndex': 0, 'endDateIndex': 100}
        ],
      ];
      const rowHeight = 50.0; // Hauteur différente
      const rowMargin = 5.0; // Marge différente
      const scrollingLeft = true;

      // Act
      final result = calculateTargetVerticalOffset(
        centerDateIndex: centerDateIndex,
        stagesRows: stagesRows,
        rowHeight: rowHeight,
        rowMargin: rowMargin,
        scrollingLeft: scrollingLeft,
        getHigherStageRowIndex: mockGetHigherStageRowIndex,
        getLowerStageRowIndex: mockGetLowerStageRowIndex,
      );

      // Assert
      // rowIndex = 2
      // offset = 2 * (50 + 5*2) = 2 * 60 = 120
      expect(result, equals(120.0));
    });
  });

  group('shouldEnableAutoScroll', () {
    test('retourne true quand userScrollOffset est null', () {
      // Arrange
      const userScrollOffset = null;
      const targetVerticalOffset = 150.0;
      const scrollingLeft = true;
      const totalRowsHeight = 1000.0;
      const viewportHeight = 300.0;

      // Act
      final result = shouldEnableAutoScroll(
        userScrollOffset: userScrollOffset,
        targetVerticalOffset: targetVerticalOffset,
        scrollingLeft: scrollingLeft,
        totalRowsHeight: totalRowsHeight,
        viewportHeight: viewportHeight,
      );

      // Assert
      expect(result, isTrue);
    });

    test('retourne false quand targetVerticalOffset est null', () {
      // Arrange
      const userScrollOffset = 100.0;
      const targetVerticalOffset = null;
      const scrollingLeft = true;
      const totalRowsHeight = 1000.0;
      const viewportHeight = 300.0;

      // Act
      final result = shouldEnableAutoScroll(
        userScrollOffset: userScrollOffset,
        targetVerticalOffset: targetVerticalOffset,
        scrollingLeft: scrollingLeft,
        totalRowsHeight: totalRowsHeight,
        viewportHeight: viewportHeight,
      );

      // Assert
      expect(result, isFalse);
    });

    test(
        'retourne true quand scrollingLeft=true et userScrollOffset < targetVerticalOffset',
        () {
      // Arrange - Scroll vers la gauche
      const userScrollOffset = 100.0;
      const targetVerticalOffset = 200.0;
      const scrollingLeft = true;
      const totalRowsHeight = 1000.0;
      const viewportHeight = 300.0;

      // Act
      final result = shouldEnableAutoScroll(
        userScrollOffset: userScrollOffset,
        targetVerticalOffset: targetVerticalOffset,
        scrollingLeft: scrollingLeft,
        totalRowsHeight: totalRowsHeight,
        viewportHeight: viewportHeight,
      );

      // Assert
      expect(result, isTrue);
    });

    test(
        'retourne false quand scrollingLeft=true et userScrollOffset >= targetVerticalOffset',
        () {
      // Arrange - Scroll vers la gauche
      const userScrollOffset = 200.0;
      const targetVerticalOffset = 100.0;
      const scrollingLeft = true;
      const totalRowsHeight = 1000.0;
      const viewportHeight = 300.0;

      // Act
      final result = shouldEnableAutoScroll(
        userScrollOffset: userScrollOffset,
        targetVerticalOffset: targetVerticalOffset,
        scrollingLeft: scrollingLeft,
        totalRowsHeight: totalRowsHeight,
        viewportHeight: viewportHeight,
      );

      // Assert
      expect(result, isFalse);
    });

    test(
        'retourne true quand scrollingLeft=false et userScrollOffset > targetVerticalOffset',
        () {
      // Arrange - Scroll vers la droite
      const userScrollOffset = 200.0;
      const targetVerticalOffset = 100.0;
      const scrollingLeft = false;
      const totalRowsHeight = 1000.0;
      const viewportHeight = 300.0;

      // Act
      final result = shouldEnableAutoScroll(
        userScrollOffset: userScrollOffset,
        targetVerticalOffset: targetVerticalOffset,
        scrollingLeft: scrollingLeft,
        totalRowsHeight: totalRowsHeight,
        viewportHeight: viewportHeight,
      );

      // Assert
      expect(result, isTrue);
    });

    test(
        'retourne false quand scrollingLeft=false et userScrollOffset <= targetVerticalOffset',
        () {
      // Arrange - Scroll vers la droite
      const userScrollOffset = 100.0;
      const targetVerticalOffset = 200.0;
      const scrollingLeft = false;
      const totalRowsHeight = 1000.0;
      const viewportHeight = 300.0;

      // Act
      final result = shouldEnableAutoScroll(
        userScrollOffset: userScrollOffset,
        targetVerticalOffset: targetVerticalOffset,
        scrollingLeft: scrollingLeft,
        totalRowsHeight: totalRowsHeight,
        viewportHeight: viewportHeight,
      );

      // Assert
      expect(result, isFalse);
    });

    test('retourne le même résultat pour les mêmes paramètres (pureté)', () {
      // Arrange
      const userScrollOffset = 100.0;
      const targetVerticalOffset = 200.0;
      const scrollingLeft = true;
      const totalRowsHeight = 1000.0;
      const viewportHeight = 300.0;

      // Act - Appeler 10 fois avec les mêmes paramètres
      final results = List.generate(
        10,
        (_) => shouldEnableAutoScroll(
          userScrollOffset: userScrollOffset,
          targetVerticalOffset: targetVerticalOffset,
          scrollingLeft: scrollingLeft,
          totalRowsHeight: totalRowsHeight,
          viewportHeight: viewportHeight,
        ),
      );

      // Assert - Tous les résultats doivent être identiques
      expect(results.toSet().length, equals(1));
      expect(results.first, isTrue);
    });

    test('gère correctement les cas limites avec des valeurs à 0', () {
      // Arrange
      const userScrollOffset = 0.0;
      const targetVerticalOffset = 0.0;
      const scrollingLeft = true;
      const totalRowsHeight = 1000.0;
      const viewportHeight = 300.0;

      // Act
      final result = shouldEnableAutoScroll(
        userScrollOffset: userScrollOffset,
        targetVerticalOffset: targetVerticalOffset,
        scrollingLeft: scrollingLeft,
        totalRowsHeight: totalRowsHeight,
        viewportHeight: viewportHeight,
      );

      // Assert
      expect(result, isFalse); // userScrollOffset == targetVerticalOffset
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
      const firstElementMargin = (viewportWidth - (dayWidth - dayMargin)) / 2;

      // Act
      calculateCenterDateIndex(
        scrollOffset: scrollOffset,
        
        dayWidth: dayWidth,
        dayMargin: dayMargin,
        totalDays: totalDays,
      );

      // Assert - Les paramètres ne doivent pas avoir changé
      expect(scrollOffset, equals(1000.0));
      expect(firstElementMargin, equals(380.0));
      expect(dayWidth, equals(45.0));
      expect(dayMargin, equals(5.0));
      expect(totalDays, equals(100));
    });

    test('calculateTargetVerticalOffset ne modifie pas stagesRows', () {
      // Arrange
      final stagesRows = [
        [
          {'startDateIndex': 0, 'endDateIndex': 100}
        ],
        [
          {'startDateIndex': 0, 'endDateIndex': 100}
        ],
      ];
      final originalLength = stagesRows.length;
      final originalFirstRow = stagesRows[0];

      int mockGetHigherStageRowIndex(List stagesRows, int searchIndex) => 0;
      int mockGetLowerStageRowIndex(List stagesRows, int searchIndex) => 1;

      // Act
      calculateTargetVerticalOffset(
        centerDateIndex: 50,
        stagesRows: stagesRows,
        rowHeight: 30.0,
        rowMargin: 3.0,
        scrollingLeft: false,
        getHigherStageRowIndex: mockGetHigherStageRowIndex,
        getLowerStageRowIndex: mockGetLowerStageRowIndex,
      );

      // Assert - stagesRows ne doit pas avoir été modifié
      expect(stagesRows.length, equals(originalLength));
      expect(stagesRows[0], equals(originalFirstRow));
    });

    test('shouldEnableAutoScroll ne modifie pas les paramètres', () {
      // Arrange
      const userScrollOffset = 100.0;
      const targetVerticalOffset = 200.0;
      const scrollingLeft = true;
      const totalRowsHeight = 1000.0;
      const viewportHeight = 300.0;

      // Act
      shouldEnableAutoScroll(
        userScrollOffset: userScrollOffset,
        targetVerticalOffset: targetVerticalOffset,
        scrollingLeft: scrollingLeft,
        totalRowsHeight: totalRowsHeight,
        viewportHeight: viewportHeight,
      );

      // Assert - Les paramètres ne doivent pas avoir changé
      expect(userScrollOffset, equals(100.0));
      expect(targetVerticalOffset, equals(200.0));
      expect(totalRowsHeight, equals(1000.0));
      expect(viewportHeight, equals(300.0));
    });
  });
}
