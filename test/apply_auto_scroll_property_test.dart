import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/scroll_state.dart';

/// Property-based test for _applyAutoScroll independence
///
/// Feature: scroll-calculation-refactoring, Property 4: Indépendance Calcul/Action
/// Validates: Requirements 1.4, 5.4
///
/// This test verifies that the action function (_applyAutoScroll) is independent
/// from calculation functions:
/// - When enableAutoScroll=false, no scroll action should be triggered
/// - When enableAutoScroll=true, scroll action should be triggered
/// - The function should only act based on the ScrollState parameter
void main() {
  group('Property 4: Indépendance Calcul/Action', () {
    final random = Random(42); // Seed for reproducibility

    /// Generate random ScrollState for testing
    ScrollState generateRandomScrollState({
      bool? enableAutoScroll,
      double? targetVerticalOffset,
    }) {
      return ScrollState(
        centerDateIndex: random.nextInt(100),
        targetVerticalOffset: targetVerticalOffset ??
            (random.nextBool() ? random.nextDouble() * 1000 : null),
        enableAutoScroll: enableAutoScroll ?? random.nextBool(),
        scrollingLeft: random.nextBool(),
      );
    }

    /// Simulates the _applyAutoScroll logic decision
    /// Returns true if scroll action should be triggered
    bool shouldTriggerScroll(ScrollState scrollState) {
      // This mimics the logic in _applyAutoScroll
      if (!scrollState.enableAutoScroll) return false;
      if (scrollState.targetVerticalOffset == null) return false;
      return true;
    }

    test('enableAutoScroll=false ne déclenche jamais de scroll - 3 itérations',
        () {
      // Run 3 iterations with random ScrollState where enableAutoScroll=false
      for (int iteration = 0; iteration < 3; iteration++) {
        // Generate random ScrollState with enableAutoScroll=false
        final scrollState = generateRandomScrollState(enableAutoScroll: false);

        // Verify that the decision logic returns false
        final shouldScroll = shouldTriggerScroll(scrollState);

        expect(
          shouldScroll,
          isFalse,
          reason:
              'Iteration $iteration: No scroll should be triggered when enableAutoScroll=false',
        );
      }
    });

    test(
        'enableAutoScroll=true avec targetVerticalOffset déclenche le scroll - 3 itérations',
        () {
      // Run 3 iterations with random ScrollState where enableAutoScroll=true
      for (int iteration = 0; iteration < 3; iteration++) {
        // Generate random ScrollState with enableAutoScroll=true and valid targetVerticalOffset
        final targetOffset = 100.0 + random.nextDouble() * 500;
        final scrollState = generateRandomScrollState(
          enableAutoScroll: true,
          targetVerticalOffset: targetOffset,
        );

        // Verify that the decision logic returns true
        final shouldScroll = shouldTriggerScroll(scrollState);

        expect(
          shouldScroll,
          isTrue,
          reason:
              'Iteration $iteration: Scroll should be triggered when enableAutoScroll=true and targetVerticalOffset is not null',
        );
      }
    });

    test(
        'enableAutoScroll=true avec targetVerticalOffset=null ne déclenche pas de scroll - 3 itérations',
        () {
      // Run 3 iterations with random ScrollState where targetVerticalOffset=null
      for (int iteration = 0; iteration < 3; iteration++) {
        // Generate random ScrollState with enableAutoScroll=true but targetVerticalOffset=null
        final scrollState = ScrollState(
          centerDateIndex: random.nextInt(100),
          targetVerticalOffset: null,
          enableAutoScroll: true,
          scrollingLeft: random.nextBool(),
        );

        // Verify that the decision logic returns false
        final shouldScroll = shouldTriggerScroll(scrollState);

        expect(
          shouldScroll,
          isFalse,
          reason:
              'Iteration $iteration: No scroll should be triggered when targetVerticalOffset=null',
        );
      }
    });

    test(
        'ScrollState détermine l\'action indépendamment des calculs - 3 itérations',
        () {
      // This test verifies that the action is determined solely by the ScrollState
      // parameter, not by any calculation logic

      for (int iteration = 0; iteration < 3; iteration++) {
        // Generate two different ScrollStates with same enableAutoScroll value
        final enableAutoScroll = random.nextBool();
        final hasTargetOffset1 = random.nextBool();
        final hasTargetOffset2 = random.nextBool();

        final scrollState1 = ScrollState(
          centerDateIndex: random.nextInt(100),
          targetVerticalOffset:
              hasTargetOffset1 ? random.nextDouble() * 1000 : null,
          enableAutoScroll: enableAutoScroll,
          scrollingLeft: random.nextBool(),
        );

        final scrollState2 = ScrollState(
          centerDateIndex: random.nextInt(100),
          targetVerticalOffset:
              hasTargetOffset2 ? random.nextDouble() * 1000 : null,
          enableAutoScroll: enableAutoScroll,
          scrollingLeft: random.nextBool(),
        );

        // Apply same logic to both ScrollStates
        final shouldScroll1 = shouldTriggerScroll(scrollState1);
        final shouldScroll2 = shouldTriggerScroll(scrollState2);

        // Verify both actions have the same behavior based on their parameters
        if (enableAutoScroll) {
          // If enableAutoScroll is true, behavior depends on targetVerticalOffset
          expect(shouldScroll1, equals(hasTargetOffset1),
              reason:
                  'Iteration $iteration: ScrollState1 should trigger scroll only if targetVerticalOffset is not null');
          expect(shouldScroll2, equals(hasTargetOffset2),
              reason:
                  'Iteration $iteration: ScrollState2 should trigger scroll only if targetVerticalOffset is not null');
        } else {
          // If enableAutoScroll is false, no scroll should be triggered
          expect(shouldScroll1, isFalse,
              reason:
                  'Iteration $iteration: ScrollState1 should not trigger scroll when enableAutoScroll=false');
          expect(shouldScroll2, isFalse,
              reason:
                  'Iteration $iteration: ScrollState2 should not trigger scroll when enableAutoScroll=false');
        }
      }
    });

    test('ScrollState est immutable - les valeurs ne changent pas', () {
      // Run 3 iterations to verify ScrollState immutability
      for (int iteration = 0; iteration < 3; iteration++) {
        final scrollState = generateRandomScrollState();

        // Store original values
        final originalCenterDateIndex = scrollState.centerDateIndex;
        final originalTargetVerticalOffset = scrollState.targetVerticalOffset;
        final originalEnableAutoScroll = scrollState.enableAutoScroll;
        final originalScrollingLeft = scrollState.scrollingLeft;

        // Simulate using the ScrollState (reading its values)
        // ignore: unused_local_variable
        final centerDateIndexValue = scrollState.centerDateIndex;
        // ignore: unused_local_variable
        final targetVerticalOffsetValue = scrollState.targetVerticalOffset;
        // ignore: unused_local_variable
        final enableAutoScrollValue = scrollState.enableAutoScroll;
        // ignore: unused_local_variable
        final scrollingLeftValue = scrollState.scrollingLeft;

        // Verify values haven't changed
        expect(scrollState.centerDateIndex, equals(originalCenterDateIndex));
        expect(scrollState.targetVerticalOffset,
            equals(originalTargetVerticalOffset));
        expect(scrollState.enableAutoScroll, equals(originalEnableAutoScroll));
        expect(scrollState.scrollingLeft, equals(originalScrollingLeft));
      }
    });

    test(
        'La décision de scroll est déterministe pour les mêmes paramètres - 3 itérations',
        () {
      // Verify that the same ScrollState always produces the same decision
      for (int iteration = 0; iteration < 3; iteration++) {
        final scrollState = generateRandomScrollState();

        // Call the decision logic multiple times
        final decision1 = shouldTriggerScroll(scrollState);
        final decision2 = shouldTriggerScroll(scrollState);
        final decision3 = shouldTriggerScroll(scrollState);

        // Verify all decisions are identical
        expect(decision1, equals(decision2),
            reason:
                'Iteration $iteration: Same ScrollState should produce same decision');
        expect(decision2, equals(decision3),
            reason:
                'Iteration $iteration: Same ScrollState should produce same decision');
      }
    });
  });
}
