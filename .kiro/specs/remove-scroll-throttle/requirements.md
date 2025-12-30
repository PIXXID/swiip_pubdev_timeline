# Requirements Document

## Introduction

This specification defines the requirements for removing the scroll throttling mechanism from the Flutter timeline widget. The current throttling implementation (limiting scroll calculations to ~60 FPS) is causing issues with scroll management and needs to be completely removed from the codebase.

## Glossary

- **Timeline**: The main Flutter widget that displays a horizontal scrollable timeline with stages and items
- **ScrollThrottle**: The current mechanism using Timer to limit scroll event processing to approximately 60 FPS (16ms intervals)
- **ScrollController**: Flutter's native scroll controller that manages scroll position
- **Configuration**: The external JSON configuration system for timeline parameters
- **ValueNotifier**: Flutter's reactive state management primitive used for scroll state updates

## Requirements

### Requirement 1: Remove Scroll Throttle Timer

**User Story:** As a developer, I want the scroll throttle timer removed from the Timeline widget, so that scroll events are processed immediately without artificial delays.

#### Acceptance Criteria

1. THE Timeline SHALL remove the `_scrollThrottleTimer` field from the Timeline state
2. THE Timeline SHALL remove all Timer-based throttling logic from the scroll listener
3. WHEN a scroll event occurs, THE Timeline SHALL process it immediately without delay
4. THE Timeline SHALL remove the timer cancellation from the dispose() method
5. THE Timeline SHALL update all related documentation and comments to reflect the removal

### Requirement 2: Remove Throttle Configuration Parameters

**User Story:** As a developer, I want throttle-related configuration parameters removed, so that the configuration system is simplified and no longer references unused features.

#### Acceptance Criteria

1. THE TimelineConfiguration SHALL remove the `scrollThrottleDuration` field
2. THE TimelineConfiguration SHALL remove `scrollThrottleMs` from the fromMap() factory
3. THE TimelineConfiguration SHALL remove `scrollThrottleMs` from the toMap() method
4. THE TimelineConfiguration SHALL remove `scrollThrottleDuration` from the copyWith() method
5. THE TimelineConfiguration SHALL remove `scrollThrottleDuration` from equality and hashCode implementations
6. THE ParameterConstraints SHALL remove the `scrollThrottleMs` constraint definition

### Requirement 3: Update Scroll Listener Implementation

**User Story:** As a developer, I want the scroll listener to execute calculations directly, so that scroll position updates are reflected immediately in the UI.

#### Acceptance Criteria

1. WHEN a scroll event occurs, THE Timeline SHALL execute scroll calculations synchronously
2. THE Timeline SHALL maintain the mounted check before state updates
3. THE Timeline SHALL preserve all existing scroll calculation logic (center index, visible range)
4. THE Timeline SHALL maintain the same state update mechanisms (ValueNotifiers)
5. THE Timeline SHALL ensure no performance degradation from immediate processing

### Requirement 4: Clean Up Documentation

**User Story:** As a developer, I want all documentation updated to remove throttling references, so that the codebase accurately reflects the current implementation.

#### Acceptance Criteria

1. THE Timeline widget documentation SHALL remove all references to "throttling" and "60 FPS"
2. THE run.dart documentation SHALL remove throttling performance claims
3. THE Timeline class comments SHALL remove throttled updates descriptions
4. THE scroll listener comments SHALL remove throttling explanations
5. THE dispose() method comments SHALL remove throttle timer references

### Requirement 5: Update Test Suite

**User Story:** As a developer, I want all tests updated to remove throttling expectations, so that the test suite validates the new immediate-processing behavior.

#### Acceptance Criteria

1. THE test suite SHALL remove all throttling-related test assertions
2. THE edge case tests SHALL remove `scrollThrottleMs` validation tests
3. THE property tests SHALL remove throttling tolerance logic
4. THE configuration tests SHALL remove `scrollThrottleMs` parameter tests
5. WHEN tests reference throttling behavior, THE tests SHALL be updated or removed

### Requirement 6: Update Specification Documents

**User Story:** As a developer, I want existing specification documents updated, so that historical design documents reflect the current architecture.

#### Acceptance Criteria

1. THE native-scroll-only spec SHALL be updated to remove throttling requirements
2. THE timeline-performance-optimization spec SHALL be updated to remove throttling design
3. THE specification documents SHALL add notes explaining why throttling was removed
4. THE design documents SHALL remove throttling from architecture diagrams
5. THE requirements documents SHALL mark throttling requirements as deprecated or removed

### Requirement 7: Maintain Scroll Performance

**User Story:** As a user, I want smooth scrolling performance maintained, so that removing throttling does not degrade the user experience.

#### Acceptance Criteria

1. THE Timeline SHALL maintain smooth scrolling without throttling
2. THE Timeline SHALL continue to use lazy rendering for performance
3. THE Timeline SHALL preserve data caching mechanisms
4. THE Timeline SHALL maintain ValueNotifier-based granular updates
5. WHEN scrolling rapidly, THE Timeline SHALL remain responsive and performant
