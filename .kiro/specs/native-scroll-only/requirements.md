# Requirements Document

## Introduction

This specification defines the requirements for further simplifying the Timeline component by removing the custom `TimelineController` class and relying entirely on native Flutter `ScrollController` instances. The goal is to eliminate unnecessary abstraction layers and use Flutter's built-in scroll management capabilities directly, reducing code complexity while maintaining all existing functionality.

## Glossary

- **Timeline**: The main widget displaying project schedules, stages, and activities across days
- **TimelineController**: Custom controller class that manages scroll state, center item index, and visible range using ValueNotifiers
- **ScrollController**: Flutter's native controller for managing scroll position and behavior
- **Horizontal_Scroll**: Left-right navigation through timeline days using `_controllerTimeline`
- **Vertical_Scroll**: Up-down navigation through stage rows using `_controllerVerticalStages`
- **Center_Item**: The day item currently positioned at the center of the viewport
- **Visible_Range**: The range of items (with buffer) that should be rendered in the viewport
- **Lazy_Rendering**: Rendering only visible items plus a buffer to optimize performance
- **Auto_Scroll**: Automatic vertical scrolling behavior that follows the horizontal position
- **Scroll_Calculations**: Pure functions in `scroll_calculations.dart` that calculate scroll-related values

## Requirements

### Requirement 1: Remove TimelineController Class

**User Story:** As a developer, I want to remove the TimelineController class, so that the codebase uses only native Flutter patterns without custom abstractions.

#### Acceptance Criteria

1. THE Timeline SHALL remove the TimelineController class from the codebase
2. THE Timeline SHALL remove the `_timelineController` instance variable
3. THE Timeline SHALL remove all imports of `timeline_controller.dart`
4. THE Timeline SHALL remove the TimelineController initialization in `_initializeTimeline()`
5. THE Timeline SHALL remove the TimelineController disposal in `dispose()`

### Requirement 2: Manage Scroll State with Native Controllers

**User Story:** As a developer, I want scroll state managed by native ScrollControllers, so that the implementation is simpler and uses standard Flutter APIs.

#### Acceptance Criteria

1. THE Timeline SHALL use `_controllerTimeline.offset` directly to get horizontal scroll position
2. THE Timeline SHALL use `_controllerVerticalStages.offset` directly to get vertical scroll position
3. THE Timeline SHALL calculate center item index directly from scroll offset using pure functions
4. THE Timeline SHALL calculate visible range directly from scroll offset and viewport width
5. THE Timeline SHALL maintain scroll throttling using Timer to limit calculations to ~60 FPS

### Requirement 3: Calculate Center Item Index Directly

**User Story:** As a developer, I want center item calculation to use pure functions directly, so that the logic is transparent and testable.

#### Acceptance Criteria

1. WHEN horizontal scroll position changes, THE Timeline SHALL call `calculateCenterDateIndex()` directly
2. THE Timeline SHALL pass scroll offset from `_controllerTimeline.offset` to the calculation function
3. THE Timeline SHALL store the calculated center index in a local variable
4. THE Timeline SHALL compare the new center index with the previous value to detect changes
5. WHEN the center index changes, THE Timeline SHALL trigger the `updateCurrentDate` callback if provided

### Requirement 4: Calculate Visible Range Directly

**User Story:** As a developer, I want visible range calculation to be performed directly in the Timeline widget, so that lazy rendering logic is transparent.

#### Acceptance Criteria

1. WHEN horizontal scroll position changes, THE Timeline SHALL calculate visible range directly
2. THE Timeline SHALL use viewport width from LayoutBuilder constraints
3. THE Timeline SHALL calculate number of visible days: `(viewportWidth / (dayWidth - dayMargin)).ceil()`
4. THE Timeline SHALL add buffer days to visible range (configurable, default 5)
5. THE Timeline SHALL clamp visible range to valid indices [0, totalDays]

### Requirement 5: Update Lazy Viewports to Accept Visible Range

**User Story:** As a developer, I want lazy viewports to receive visible range as parameters, so that they don't depend on TimelineController.

#### Acceptance Criteria

1. THE LazyTimelineViewport SHALL accept `visibleStart` and `visibleEnd` parameters
2. THE StageRowsViewport SHALL accept `visibleStart` and `visibleEnd` parameters
3. THE LazyTimelineViewport SHALL remove dependency on TimelineController
4. THE StageRowsViewport SHALL remove dependency on TimelineController
5. THE Timeline SHALL pass calculated visible range to lazy viewports

### Requirement 6: Maintain Scroll Throttling [DEPRECATED]

> **⚠️ DEPRECATED**: This requirement has been superseded by the scroll throttle removal implemented in the `remove-scroll-throttle` spec. Scroll throttling has been completely removed from the codebase as it was causing scroll management issues. The Timeline now processes scroll events immediately without artificial delays.

**User Story:** As a developer, I want scroll updates to be throttled, so that performance remains smooth during rapid scrolling.

#### Acceptance Criteria

1. ~~THE Timeline SHALL use a Timer to throttle scroll calculations~~
2. ~~THE Timeline SHALL limit scroll calculations to approximately 60 FPS (16ms intervals)~~
3. ~~WHEN a scroll event occurs during an active throttle timer, THE Timeline SHALL skip the calculation~~
4. ~~WHEN the throttle timer expires, THE Timeline SHALL perform the scroll calculations~~
5. ~~THE Timeline SHALL cancel the throttle timer in the dispose() method~~

### Requirement 7: Preserve Auto-Scroll Behavior

**User Story:** As a user, I want vertical auto-scroll to follow horizontal position, so that I can see relevant stages as I navigate through time.

#### Acceptance Criteria

1. WHEN horizontal scroll position changes significantly, THE Timeline SHALL calculate target vertical offset
2. THE Timeline SHALL use pure functions from `scroll_calculations.dart` for calculations
3. THE Timeline SHALL apply auto-scroll only when user has not manually scrolled vertically
4. THE Timeline SHALL animate vertical scroll to the calculated target offset
5. THE Timeline SHALL maintain the existing auto-scroll logic and conditions

### Requirement 8: Preserve ScrollTo Functionality

**User Story:** As a developer, I want programmatic scroll functionality to work, so that features like "scroll to today" continue to function.

#### Acceptance Criteria

1. THE Timeline SHALL preserve the `scrollTo(dateIndex)` method
2. THE Timeline SHALL calculate scroll offset from date index: `dateIndex * (dayWidth - dayMargin)`
3. WHEN `scrollTo` is called with `animated=true`, THE Timeline SHALL use `animateTo()` on ScrollController
4. WHEN `scrollTo` is called with `animated=false`, THE Timeline SHALL use `jumpTo()` on ScrollController
5. THE Timeline SHALL maintain default scroll behavior (scrolling to defaultDate or nowIndex on initialization)

### Requirement 9: Remove TimelineController Tests

**User Story:** As a developer, I want tests updated to reflect the simplified architecture, so that the test suite remains accurate and maintainable.

#### Acceptance Criteria

1. THE Test_Suite SHALL remove `test/models/timeline_controller_test.dart` file
2. THE Test_Suite SHALL remove tests that verify TimelineController behavior
3. THE Test_Suite SHALL update tests to verify scroll calculations using pure functions directly
4. THE Test_Suite SHALL maintain test coverage for scroll position tracking
5. THE Test_Suite SHALL maintain test coverage for visible range calculation

### Requirement 10: Update Documentation

**User Story:** As a developer, I want documentation updated to reflect the native-only scroll implementation, so that the codebase is easy to understand.

#### Acceptance Criteria

1. THE Documentation SHALL remove references to TimelineController
2. THE Documentation SHALL describe scroll state management using native ScrollControllers
3. THE Documentation SHALL update code comments to reflect direct calculation approach
4. THE Documentation SHALL update architecture descriptions to show simplified flow
5. THE Documentation SHALL maintain clarity about scroll throttling and auto-scroll behavior
