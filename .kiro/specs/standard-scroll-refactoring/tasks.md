# Implementation Plan: Standard Scroll Refactoring

## Overview

This implementation plan breaks down the refactoring of the Timeline component to replace slider-based scrolling with standard Flutter scrolling. The tasks are organized to make incremental progress, starting with code removal, then updating core functionality, followed by testing and documentation.

## Tasks

- [x] 1. Remove slider-related code from Timeline widget
  - Remove Slider widget from build() method (lines 838-858)
  - Remove state variables: `sliderValue`, `sliderMargin`, `sliderMaxValue`
  - Remove `_scrollH()` method
  - Remove `_scrollHAnimated()` method
  - Remove slider max value calculation from `_initializeTimeline()`
  - Remove slider value update from scroll listener in `_initializeTimeline()`
  - Adjust layout spacing (reduce bottom padding from 100 to 20 in scrollbar positioning)
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 2. Update scrollTo() method to use ScrollController directly
  - [x] 2.1 Modify scrollTo() to call ScrollController methods directly
    - Replace `_scrollH()` call with `_controllerTimeline.jumpTo()`
    - Replace `_scrollHAnimated()` call with `_controllerTimeline.animateTo()`
    - Update scroll offset clamping to use `_controllerTimeline.position.maxScrollExtent`
    - Remove `sliderValue` state update
    - _Requirements: 5.1, 5.2, 5.3, 5.4_

  - [x] 2.2 Write property test for scrollTo() conversion logic
    - **Property 7: Date Index to Scroll Offset Conversion**
    - **Validates: Requirements 5.4, 5.1**
    - Generate random date indices (0 to days.length-1)
    - Call scrollTo() with each index
    - Verify scroll offset = dateIndex * (dayWidth - dayMargin)
    - Run 100 iterations

- [x] 3. Verify scroll position tracking still works
  - [x] 3.1 Ensure horizontal scroll listener updates TimelineController
    - Verify scroll listener still calls `_timelineController.updateScrollOffset()`
    - Verify center item index calculation still works
    - Verify updateCurrentDate callback still triggered
    - _Requirements: 4.1, 4.2, 4.3, 4.4_

  - [x] 3.2 Write property test for horizontal scroll position updates
    - **Property 1: Horizontal Scroll Position Updates**
    - **Validates: Requirements 2.1, 1.5**
    - Generate random scroll offsets (0 to maxScrollExtent)
    - Apply scroll using jumpTo()
    - Verify _controllerTimeline.offset matches expected value
    - Run 100 iterations

  - [x] 3.3 Write property test for TimelineController updates
    - **Property 4: TimelineController Updates**
    - **Validates: Requirements 4.1, 4.4**
    - Generate random horizontal scroll positions
    - Verify TimelineController receives scroll offset updates
    - Verify visible range recalculated correctly
    - Run 100 iterations

  - [x] 3.4 Write property test for center item calculation
    - **Property 5: Center Item Calculation**
    - **Validates: Requirements 4.2, 4.5**
    - Generate random scroll positions
    - Calculate expected center index: (offset + viewportWidth/2) / (dayWidth - dayMargin)
    - Verify TimelineController reports same center index (within 1 day tolerance)
    - Run 100 iterations

  - [x] 3.5 Write property test for current date callback
    - **Property 6: Current Date Callback Invocation**
    - **Validates: Requirements 4.3**
    - Generate random scroll positions that change center item
    - Provide mock updateCurrentDate callback
    - Verify callback called with correct date string (YYYY-MM-DD format)
    - Run 100 iterations

- [ ] 4. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Verify vertical scrolling remains independent
  - [ ] 5.1 Ensure vertical scroll controller still works
    - Verify vertical scroll listener still updates scrollbar position
    - Verify auto-scroll behavior preserved
    - Verify manual vertical scroll detection still works
    - _Requirements: 3.1, 3.2, 3.4_

  - [ ] 5.2 Write property test for vertical scroll position updates
    - **Property 2: Vertical Scroll Position Updates**
    - **Validates: Requirements 3.1, 3.2**
    - Generate random vertical scroll offsets (0 to maxScrollExtent)
    - Apply scroll using jumpTo() on vertical controller
    - Verify _controllerVerticalStages.offset matches expected value
    - Run 100 iterations

  - [ ] 5.3 Write property test for auto-scroll behavior
    - **Property 3: Auto-Scroll Behavior**
    - **Validates: Requirements 3.4**
    - Generate random horizontal scroll positions that change center item
    - Verify vertical auto-scroll triggers when no manual scroll detected
    - Verify vertical position updates to show highest visible stage row
    - Run 100 iterations

  - [ ] 5.4 Write property test for scroll independence
    - **Property 8: Scroll Independence**
    - **Validates: Requirements 6.5**
    - Generate random sequences of horizontal and vertical scroll operations
    - Apply scrolls in random order
    - Verify horizontal position unchanged by vertical scrolls
    - Verify vertical position unchanged by horizontal scrolls (except auto-scroll)
    - Run 100 iterations

- [ ] 6. Remove slider-related tests
  - Delete `test/timeline_slider_isolation_test.dart` file
  - Remove any slider-specific test cases from integration tests
  - Update scroll simulation tests to use ScrollController directly
  - _Requirements: 6.1, 6.2_

- [ ] 7. Update integration tests
  - [ ] 7.1 Write integration test for horizontal scrolling
    - Test mouse wheel horizontal scrolling
    - Test trackpad horizontal gesture scrolling
    - Test touch drag horizontal scrolling
    - Verify scroll position updates correctly
    - _Requirements: 2.2, 2.3, 2.4_

  - [ ] 7.2 Write integration test for scrollTo initialization
    - Test scrolling to defaultDate on initialization
    - Test scrolling to nowIndex when no defaultDate provided
    - Verify correct initial scroll position
    - _Requirements: 5.5_

  - [ ] 7.3 Write integration test for custom scrollbar
    - Verify scrollbar widget exists in widget tree
    - Verify scrollbar position updates with vertical scroll
    - Verify scrollbar height calculated correctly
    - _Requirements: 3.3_

- [ ] 8. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 9. Update documentation
  - Update README.md to remove slider references and describe standard scrolling
  - Update CONFIGURATION.md to remove slider-related configuration notes
  - Update code comments in timeline.dart to reflect ScrollController usage
  - Update class-level documentation in timeline.dart
  - Add entry to CHANGELOG.md describing the breaking change
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 10. Final checkpoint - Verify all functionality
  - Run full test suite
  - Manually verify horizontal scrolling works (mouse, trackpad, touch)
  - Manually verify vertical scrolling works independently
  - Manually verify scrollTo today/default date works
  - Manually verify auto-scroll behavior works
  - Manually verify performance is smooth
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- All tasks are required for comprehensive implementation
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties across many inputs
- Integration tests validate specific user interaction scenarios
- The refactoring removes approximately 50 lines of code while maintaining all functionality
