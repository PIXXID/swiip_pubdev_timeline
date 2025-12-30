import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Property-Based Test for Scroll Position Retrieval
///
/// **Feature: native-scroll-only, Property 1: Scroll Position Retrieval**
/// **Validates: Requirements 2.1, 2.2**
///
/// This test verifies that for any scroll position applied to a ScrollController
/// (horizontal or vertical), reading the `offset` property returns the applied
/// scroll position.
///
/// The test generates random scroll offsets and verifies that:
/// 1. Horizontal ScrollController.offset matches applied position
/// 2. Vertical ScrollController.offset matches applied position
/// 3. Both controllers work independently
void main() {
  group('Property 1: Scroll Position Retrieval', () {
    testWidgets(
        'For any scroll offset, horizontal controller position should match applied value',
        (WidgetTester tester) async {
      // Feature: native-scroll-only, Property 1: Scroll Position Retrieval
      // Validates: Requirements 2.1, 2.2

      const numIterations = 100;
      final random = Random(42); // Fixed seed for reproducibility

      // Create a scrollable widget with horizontal scroll
      final horizontalController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              controller: horizontalController,
              scrollDirection: Axis.horizontal,
              child: Container(
                width: 10000, // Large width to allow scrolling
                height: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify controller has clients
      expect(horizontalController.hasClients, isTrue);

      final maxScrollExtent = horizontalController.position.maxScrollExtent;
      int passedTests = 0;

      for (int i = 0; i < numIterations; i++) {
        // Generate random scroll offset within valid range [0, maxScrollExtent]
        final targetOffset = random.nextDouble() * maxScrollExtent;

        try {
          // Apply scroll offset using jumpTo()
          horizontalController.jumpTo(targetOffset);
          await tester.pump();

          // Verify offset property matches applied value
          final actualOffset = horizontalController.offset;
          final difference = (actualOffset - targetOffset).abs();

          // Allow small floating point tolerance (< 0.01 pixels)
          if (difference < 0.01) {
            passedTests++;
          } else {
            debugPrint(
                'Iteration $i: Offset mismatch - target=$targetOffset, actual=$actualOffset, diff=$difference');
          }
        } catch (e) {
          debugPrint('Iteration $i failed with targetOffset=$targetOffset: $e');
        }
      }

      // Cleanup
      horizontalController.dispose();

      // Verify that all iterations passed
      expect(passedTests, equals(numIterations),
          reason:
              'Property test failed: $passedTests/$numIterations iterations passed. '
              'Expected horizontal ScrollController.offset to match applied scroll position.');
    });

    testWidgets(
        'For any scroll offset, vertical controller position should match applied value',
        (WidgetTester tester) async {
      // Feature: native-scroll-only, Property 1: Scroll Position Retrieval
      // Validates: Requirements 2.1, 2.2

      const numIterations = 100;
      final random = Random(42); // Fixed seed for reproducibility

      // Create a scrollable widget with vertical scroll
      final verticalController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              controller: verticalController,
              scrollDirection: Axis.vertical,
              child: Container(
                width: 100,
                height: 10000, // Large height to allow scrolling
                color: Colors.green,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify controller has clients
      expect(verticalController.hasClients, isTrue);

      final maxScrollExtent = verticalController.position.maxScrollExtent;
      int passedTests = 0;

      for (int i = 0; i < numIterations; i++) {
        // Generate random scroll offset within valid range [0, maxScrollExtent]
        final targetOffset = random.nextDouble() * maxScrollExtent;

        try {
          // Apply scroll offset using jumpTo()
          verticalController.jumpTo(targetOffset);
          await tester.pump();

          // Verify offset property matches applied value
          final actualOffset = verticalController.offset;
          final difference = (actualOffset - targetOffset).abs();

          // Allow small floating point tolerance (< 0.01 pixels)
          if (difference < 0.01) {
            passedTests++;
          } else {
            debugPrint(
                'Iteration $i: Offset mismatch - target=$targetOffset, actual=$actualOffset, diff=$difference');
          }
        } catch (e) {
          debugPrint('Iteration $i failed with targetOffset=$targetOffset: $e');
        }
      }

      // Cleanup
      verticalController.dispose();

      // Verify that all iterations passed
      expect(passedTests, equals(numIterations),
          reason:
              'Property test failed: $passedTests/$numIterations iterations passed. '
              'Expected vertical ScrollController.offset to match applied scroll position.');
    });

    testWidgets('Horizontal and vertical controllers work independently',
        (WidgetTester tester) async {
      // Feature: native-scroll-only, Property 1: Scroll Position Retrieval
      // Validates: Requirements 2.1, 2.2

      const numIterations = 50;
      final random = Random(42); // Fixed seed for reproducibility

      // Create a widget with both horizontal and vertical scroll
      final horizontalController = ScrollController();
      final verticalController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              controller: horizontalController,
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                controller: verticalController,
                scrollDirection: Axis.vertical,
                child: Container(
                  width: 5000,
                  height: 5000,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify both controllers have clients
      expect(horizontalController.hasClients, isTrue);
      expect(verticalController.hasClients, isTrue);

      final maxHorizontalScroll = horizontalController.position.maxScrollExtent;
      final maxVerticalScroll = verticalController.position.maxScrollExtent;
      int passedTests = 0;

      for (int i = 0; i < numIterations; i++) {
        // Generate random scroll offsets for both controllers
        final targetHorizontal = random.nextDouble() * maxHorizontalScroll;
        final targetVertical = random.nextDouble() * maxVerticalScroll;

        try {
          // Apply scroll offsets independently
          horizontalController.jumpTo(targetHorizontal);
          verticalController.jumpTo(targetVertical);
          await tester.pump();

          // Verify both offsets match independently
          final actualHorizontal = horizontalController.offset;
          final actualVertical = verticalController.offset;

          final horizontalDiff = (actualHorizontal - targetHorizontal).abs();
          final verticalDiff = (actualVertical - targetVertical).abs();

          // Allow small floating point tolerance (< 0.01 pixels)
          if (horizontalDiff < 0.01 && verticalDiff < 0.01) {
            passedTests++;
          } else {
            debugPrint(
                'Iteration $i: Offset mismatch - horizontal: target=$targetHorizontal, actual=$actualHorizontal, diff=$horizontalDiff; vertical: target=$targetVertical, actual=$actualVertical, diff=$verticalDiff');
          }
        } catch (e) {
          debugPrint(
              'Iteration $i failed with targetHorizontal=$targetHorizontal, targetVertical=$targetVertical: $e');
        }
      }

      // Cleanup
      horizontalController.dispose();
      verticalController.dispose();

      // Verify that all iterations passed
      expect(passedTests, equals(numIterations),
          reason:
              'Property test failed: $passedTests/$numIterations iterations passed. '
              'Expected horizontal and vertical ScrollControllers to work independently.');
    });
  });
}
