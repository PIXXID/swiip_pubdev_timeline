# Implementation Plan: Native Scroll Only

## Overview

This implementation plan breaks down the removal of the `TimelineController` class and transition to using only native Flutter `ScrollController` instances. The tasks are organized to make incremental progress, starting with updating lazy viewports to accept parameters, then removing the controller, updating state management, and finally testing and documentation.

## Tasks

- [x] 1. Update LazyViewport widgets to accept visible range parameters
  - [x] 1.1 Update LazyTimelineViewport constructor and implementation
    - Replace `controller` parameter with `visibleStart`, `visibleEnd`, and `centerItemIndex`
    - Remove ValueListenableBuilder from build() method
    - Use parameters directly to render items in range
    - Update itemBuilder calls to pass centerItemIndex directly
    - _Requirements: 5.1, 5.3_

  - [x] 1.2 Write property test for LazyTimelineViewport rendering
    - **Property 5: Lazy Viewport Rendering**
    - **Validates: Requirements 5.5**
    - Generate random visible ranges (start, end, centerIndex)
    - Verify viewport renders only items in range
    - Verify correct center item index passed to itemBuilder
    - Run 100 iterations

  - [x] 1.3 Update LazyStageRowsViewport constructor and implementation
    - Replace `controller` parameter with `visibleStart` and `visibleEnd`
    - Remove ValueListenableBuilder from build() method
    - Use parameters directly to render stage rows in range
    - _Requirements: 5.2, 5.4_

  - [x] 1.4 Write property test for LazyStageRowsViewport rendering
    - **Property 5: Lazy Viewport Rendering**
    - **Validates: Requirements 5.5**
    - Generate random visible ranges for stage rows
    - Verify viewport renders only rows in range
    - Run 100 iterations

- [x] 2. Update Timeline widget state management
  - [x] 2.1 Add new state variables to Timeline widget
    - Add `int _centerItemIndex = 0`
    - Add `int _visibleStart = 0`
    - Add `int _visibleEnd = 0`
    - Add `double _viewportWidth = 0.0`
    - Add `Timer? _scrollThrottleTimer`
    - _Requirements: 2.3, 2.4_

  - [x] 2.2 Update build() method to capture viewport width
    - In LayoutBuilder, set `_viewportWidth = constraints.maxWidth`
    - Pass visible range parameters to LazyTimelineViewport
    - Pass visible range parameters to LazyStageRowsViewport
    - Pass centerItemIndex directly instead of from controller
    - _Requirements: 4.2, 5.5_

  - [x] 2.3 Write unit test for viewport width capture
    - Test that viewport width is correctly captured from LayoutBuilder
    - Test that width updates when constraints change
    - _Requirements: 4.2_

- [ ] 3. Implement direct scroll calculations in Timeline
  - [ ] 3.1 Update horizontal scroll listener
    - Implement throttling with Timer (16ms interval)
    - Calculate center index using `calculateCenterDateIndex()` directly
    - Calculate visible range inline using formula
    - Update state only when values change (check before setState)
    - Trigger callbacks and auto-scroll when center changes
    - _Requirements: 2.1, 2.3, 2.4, 2.5, 3.1, 3.2, 4.1, 4.3, 4.4, 4.5_

  - [ ] 3.2 Write property test for scroll position retrieval
    - **Property 1: Scroll Position Retrieval**
    - **Validates: Requirements 2.1, 2.2**
    - Generate random scroll offsets for both controllers
    - Apply using jumpTo() and verify offset property matches
    - Test horizontal and vertical controllers independently
    - Run 100 iterations

  - [ ] 3.3 Write property test for center item calculation
    - **Property 2: Center Item Calculation**
    - **Validates: Requirements 2.3, 3.1, 3.2**
    - Generate random scroll offsets and viewport widths
    - Calculate expected center index using pure function
    - Verify calculated index matches expected value
    - Verify index within valid range [0, totalDays-1]
    - Run 100 iterations

  - [ ] 3.4 Write property test for visible range calculation
    - **Property 3: Visible Range Calculation**
    - **Validates: Requirements 2.4, 4.1, 4.3, 4.4, 4.5**
    - Generate random scroll offsets, viewport widths, buffer values
    - Calculate expected visible range using formula
    - Verify range matches expected values
    - Verify range clamped to [0, totalDays]
    - Test edge cases: scroll at start, scroll at end, small/large viewport
    - Run 100 iterations

  - [ ] 3.5 Write property test for current date callback
    - **Property 4: Current Date Callback Invocation**
    - **Validates: Requirements 3.5**
    - Generate random scroll positions that change center item
    - Provide mock updateCurrentDate callback
    - Verify callback called with correct date string (YYYY-MM-DD)
    - Verify callback not called when center unchanged
    - Run 100 iterations

- [ ] 4. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Remove TimelineController and related code
  - [ ] 5.1 Remove TimelineController from Timeline widget
    - Remove `_timelineController` instance variable
    - Remove TimelineController initialization from `_initializeTimeline()`
    - Remove TimelineController disposal from `dispose()`
    - Remove import of `timeline_controller.dart`
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

  - [ ] 5.2 Delete TimelineController class file
    - Delete `lib/src/timeline/models/timeline_controller.dart`
    - Delete `lib/src/timeline/models/visible_range.dart` (if not used elsewhere)
    - _Requirements: 1.1_

  - [ ] 5.3 Update dispose() method
    - Add `_scrollThrottleTimer?.cancel()` to dispose()
    - Ensure all timers are cancelled properly
    - _Requirements: 6.5_

  - [ ] 5.4 Write unit test for timer cleanup
    - Test that scroll throttle timer is cancelled in dispose()
    - Test that no memory leaks occur from timer
    - _Requirements: 6.5_

- [ ] 6. Update auto-scroll implementation
  - [ ] 6.1 Verify auto-scroll logic works with new state management
    - Ensure `_applyAutoScroll()` uses new state variables
    - Ensure auto-scroll conditions check new state variables
    - Ensure vertical scroll animation works correctly
    - _Requirements: 7.1, 7.3, 7.4_

  - [ ] 6.2 Write property test for auto-scroll behavior
    - **Property 6: Auto-Scroll Behavior**
    - **Validates: Requirements 7.1, 7.3, 7.4**
    - Generate random horizontal scroll positions (≥2 day change)
    - Verify vertical auto-scroll triggers when userScrollOffset is null
    - Verify auto-scroll does not trigger when userScrollOffset is set
    - Verify vertical position animates to correct target offset
    - Run 100 iterations

- [ ] 7. Verify scrollTo functionality
  - [ ] 7.1 Ensure scrollTo() method works correctly
    - Verify scrollTo() calculates offset correctly
    - Verify animated and non-animated variants work
    - Verify default scroll on initialization works
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

  - [ ] 7.2 Write property test for scrollTo offset calculation
    - **Property 7: ScrollTo Offset Calculation**
    - **Validates: Requirements 8.2**
    - Generate random valid date indices [0, totalDays-1]
    - Calculate expected offset: dateIndex * (dayWidth - dayMargin)
    - Call scrollTo(index) and verify scroll position matches
    - Test both animated and non-animated variants
    - Run 100 iterations

  - [ ] 7.3 Write unit tests for scrollTo edge cases
    - Test scrollTo with index 0 (start)
    - Test scrollTo with index totalDays-1 (end)
    - Test scrollTo with out-of-bounds index (should clamp)
    - Test scrollTo on initialization (defaultDate and nowIndex)
    - _Requirements: 8.3, 8.4, 8.5_

- [ ] 8. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 9. Remove TimelineController tests
  - [ ] 9.1 Delete TimelineController test file
    - Delete `test/models/timeline_controller_test.dart`
    - _Requirements: 9.1, 9.2_

  - [ ] 9.2 Update existing tests to use direct calculations
    - Update scroll position tracking tests
    - Update visible range calculation tests
    - Update center item calculation tests
    - Remove any TimelineController mocks or verifications
    - _Requirements: 9.3, 9.4, 9.5_

- [ ] 10. Write integration tests
  - [ ] 10.1 Write integration test for complete scroll flow
    - Test user scroll → calculation → state update → render
    - Verify horizontal scroll updates center item and visible range
    - Verify lazy viewports render correct items
    - Verify current date callback fires
    - _Requirements: 2.1, 2.3, 2.4, 3.5, 5.5_

  - [ ] 10.2 Write integration test for throttling behavior
    - Simulate rapid scroll events
    - Verify calculations don't happen more than ~60 FPS
    - Verify state updates are throttled correctly
    - _Requirements: 2.5, 6.1, 6.2, 6.3, 6.4_

  - [ ] 10.3 Write integration test for initialization
    - Test correct initial scroll position (defaultDate or nowIndex)
    - Test correct initial visible range calculation
    - Test correct initial center item
    - _Requirements: 8.5_

- [ ] 11. Update documentation
  - [ ] 11.1 Update code documentation
    - Update Timeline class documentation to remove TimelineController references
    - Update scroll listener comments to describe direct calculation approach
    - Update architecture comments to reflect simplified flow
    - Add comments explaining throttling and state management
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

  - [ ] 11.2 Update README.md
    - Remove TimelineController references
    - Describe scroll state management using native ScrollControllers
    - Update architecture description
    - _Requirements: 10.1, 10.2, 10.4_

  - [ ] 11.3 Update CONFIGURATION.md
    - Update any references to scroll state management
    - Ensure configuration options are still accurate
    - _Requirements: 10.2_

  - [ ] 11.4 Update CHANGELOG.md
    - Add entry describing internal refactoring
    - Note removal of TimelineController
    - Note that public API unchanged
    - _Requirements: 10.1, 10.2_

- [ ] 12. Final checkpoint - Verify all functionality
  - Run full test suite
  - Manually verify horizontal scrolling works smoothly
  - Manually verify vertical scrolling works independently
  - Manually verify lazy rendering works correctly
  - Manually verify center item highlighting updates
  - Manually verify current date callback fires
  - Manually verify auto-scroll follows horizontal position
  - Manually verify scrollTo today/default date works
  - Manually verify performance is smooth (no regressions)
  - Manually verify no console errors or warnings
  - Manually verify memory usage stable (no timer leaks)
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- All tasks are required for comprehensive implementation
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties across many inputs
- Integration tests validate complete user interaction flows
- The refactoring removes approximately 150 lines of code while maintaining all functionality
- Throttling is critical for performance - must be implemented correctly
- State updates should only occur when values actually change to minimize rebuilds
