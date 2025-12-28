# Requirements Document

## Introduction

This specification defines the requirements for refactoring the Timeline component to replace the custom slider-based scroll control with standard Flutter scrolling mechanisms. The goal is to simplify the codebase by removing the slider UI element while maintaining all existing timeline functionality with native horizontal and vertical scrolling.

## Glossary

- **Timeline**: The main widget displaying project schedules, stages, and activities across days
- **Slider**: The current custom UI control (Flutter Slider widget) used to navigate horizontally through the timeline
- **Standard_Scroll**: Native Flutter scrolling behavior using mouse wheel, trackpad gestures, or touch gestures
- **Horizontal_Scroll**: Left-right navigation through timeline days
- **Vertical_Scroll**: Up-down navigation through stage rows
- **ScrollController**: Flutter's controller for managing scroll position and behavior
- **Auto_Scroll**: Automatic vertical scrolling behavior that follows the horizontal position

## Requirements

### Requirement 1: Remove Slider Control

**User Story:** As a developer, I want to remove the slider-based scroll control, so that the codebase is simpler and uses standard Flutter patterns.

#### Acceptance Criteria

1. THE Timeline SHALL remove the Slider widget from the UI layout
2. THE Timeline SHALL remove all slider-related state variables (sliderValue, sliderMargin, sliderMaxValue)
3. THE Timeline SHALL remove the _scrollH() and _scrollHAnimated() methods that were triggered by slider changes
4. THE Timeline SHALL remove slider event handlers (onChanged callback)
5. THE Timeline SHALL maintain the existing ScrollController for horizontal scrolling

### Requirement 2: Implement Standard Horizontal Scrolling

**User Story:** As a user, I want to scroll horizontally through the timeline using standard gestures, so that the interaction feels natural and familiar.

#### Acceptance Criteria

1. WHEN a user performs a horizontal scroll gesture, THE Timeline SHALL update the horizontal scroll position
2. WHEN a user uses a mouse wheel with horizontal capability, THE Timeline SHALL scroll horizontally
3. WHEN a user uses trackpad horizontal gestures, THE Timeline SHALL scroll horizontally
4. WHEN a user touches and drags horizontally on touch devices, THE Timeline SHALL scroll horizontally
5. THE Timeline SHALL maintain smooth scrolling performance with the existing scroll throttling mechanism

### Requirement 3: Maintain Vertical Scrolling

**User Story:** As a user, I want to scroll vertically through stage rows, so that I can view all stages in large timelines.

#### Acceptance Criteria

1. WHEN a user performs a vertical scroll gesture, THE Timeline SHALL update the vertical scroll position
2. THE Timeline SHALL maintain the existing vertical ScrollController behavior
3. THE Timeline SHALL preserve the custom scrollbar visualization
4. THE Timeline SHALL maintain the existing auto-scroll behavior that follows horizontal position

### Requirement 4: Preserve Scroll Position Tracking

**User Story:** As a developer, I want to maintain scroll position tracking, so that features like center item calculation and current date updates continue to work.

#### Acceptance Criteria

1. WHEN the horizontal scroll position changes, THE Timeline SHALL update the TimelineController with the new offset
2. WHEN the horizontal scroll position changes, THE Timeline SHALL calculate the center item index
3. WHEN the center item changes, THE Timeline SHALL trigger the updateCurrentDate callback if provided
4. THE Timeline SHALL maintain the existing scroll listener on _controllerTimeline
5. THE Timeline SHALL preserve all scroll-related calculations (center position, visible range, buffer zones)

### Requirement 5: Maintain ScrollTo Functionality

**User Story:** As a developer, I want to maintain programmatic scroll functionality, so that features like "scroll to today" continue to work.

#### Acceptance Criteria

1. THE Timeline SHALL preserve the scrollTo(dateIndex) method
2. WHEN scrollTo is called with animated=true, THE Timeline SHALL use animateTo() on the ScrollController
3. WHEN scrollTo is called with animated=false, THE Timeline SHALL use jumpTo() on the ScrollController
4. THE Timeline SHALL maintain date index to scroll offset conversion logic
5. THE Timeline SHALL preserve the default scroll behavior (scrolling to defaultDate or nowIndex on initialization)

### Requirement 6: Update Tests

**User Story:** As a developer, I want updated tests that reflect the new scroll implementation, so that the codebase remains well-tested.

#### Acceptance Criteria

1. THE Test_Suite SHALL remove all tests related to slider functionality
2. THE Test_Suite SHALL update tests that verify scroll behavior to use ScrollController directly
3. THE Test_Suite SHALL maintain test coverage for scrollTo() functionality
4. THE Test_Suite SHALL maintain test coverage for scroll position tracking
5. THE Test_Suite SHALL verify that horizontal and vertical scrolling work independently

### Requirement 7: Update Documentation

**User Story:** As a developer, I want updated documentation that reflects the simplified scroll implementation, so that the codebase is easy to understand.

#### Acceptance Criteria

1. THE Documentation SHALL remove references to slider-based scroll control
2. THE Documentation SHALL describe the standard scroll implementation
3. THE Documentation SHALL update code comments to reflect the new scroll mechanism
4. THE Documentation SHALL update any architecture diagrams or descriptions that mention the slider
5. THE Documentation SHALL maintain clarity about the auto-scroll behavior and its interaction with manual scrolling
