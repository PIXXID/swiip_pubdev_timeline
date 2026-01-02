# Design Document: Remove Scroll Throttle

## Overview

This document describes the design for removing the scroll throttling mechanism from the Flutter timeline widget. The current implementation uses a Timer-based throttling approach that limits scroll event processing to approximately 60 FPS (16ms intervals). This throttling is causing issues with scroll management and needs to be completely removed.

The removal will simplify the scroll architecture by processing scroll events immediately and synchronously, eliminating the artificial delay introduced by the throttling timer. All other performance optimizations (lazy rendering, data caching, ValueNotifier-based updates) will be preserved.

## Architecture

### Current Architecture (With Throttling)

```
ScrollController.addListener()
    ↓
Cancel existing throttle timer
    ↓
Create new Timer(16ms)
    ↓
[Wait 16ms]
    ↓
Execute scroll calculations
    ↓
Update state (setState)
    ↓
Update ValueNotifiers
    ↓
Trigger callbacks
```

### New Architecture (Without Throttling)

```
ScrollController.addListener()
    ↓
Execute scroll calculations immediately
    ↓
Update state (setState)
    ↓
Update ValueNotifiers
    ↓
Trigger callbacks
```

### Key Changes

1. **Remove Timer-based throttling**: Scroll calculations execute immediately when scroll events occur
2. **Maintain mounted checks**: Keep safety checks to prevent updates on unmounted widgets
3. **Preserve calculation logic**: All scroll calculation functions remain unchanged
4. **Keep state management**: ValueNotifiers and setState patterns remain the same
5. **Simplify configuration**: Remove throttle-related configuration parameters

## Components and Interfaces

### Timeline Widget (`lib/src/timeline/timeline.dart`)

**Fields to Remove:**
- `Timer? _scrollThrottleTimer` - The throttle timer instance

**Methods to Modify:**

#### `_initializeTimeline()`

**Current Implementation:**
```dart
_controllerHorizontal.addListener(() {
  // Cancel existing throttle timer
  _scrollThrottleTimer?.cancel();
  
  // Throttle scroll calculations to ~60 FPS (16ms interval)
  _scrollThrottleTimer = Timer(const Duration(milliseconds: 16), () {
    if (!mounted) return;
    
    // ... scroll calculations ...
  });
});
```

**New Implementation:**
```dart
_controllerHorizontal.addListener(() {
  if (!mounted) return;
  
  // Execute scroll calculations immediately
  // ... scroll calculations ...
});
```

**Changes:**
- Remove timer cancellation
- Remove Timer creation
- Move mounted check to beginning of listener
- Execute calculations directly without delay

#### `dispose()`

**Current Implementation:**
```dart
void dispose() {
  // Cancel timers to prevent memory leaks
  // _scrollThrottleTimer: Throttles scroll calculations
  // _verticalScrollDebounceTimer: Debounces vertical auto-scroll
  _scrollThrottleTimer?.cancel();
  _verticalScrollDebounceTimer?.cancel();
  // ... rest of disposal ...
}
```

**New Implementation:**
```dart
void dispose() {
  // Cancel timer to prevent memory leaks
  // _verticalScrollDebounceTimer: Debounces vertical auto-scroll
  _verticalScrollDebounceTimer?.cancel();
  // ... rest of disposal ...
}
```

**Changes:**
- Remove `_scrollThrottleTimer?.cancel()` call
- Update comments to remove throttle timer references

### TimelineConfiguration (`lib/src/timeline/models/timeline_configuration.dart`)

**Fields to Remove:**
- `final Duration scrollThrottleDuration` - The throttle duration parameter

**Methods to Modify:**

#### Constructor

**Current:**
```dart
const TimelineConfiguration({
  // ... other parameters ...
  this.scrollThrottleDuration = const Duration(milliseconds: 16),
  // ... other parameters ...
});
```

**New:**
```dart
const TimelineConfiguration({
  // ... other parameters ...
  // scrollThrottleDuration removed
  // ... other parameters ...
});
```

#### `fromMap()` Factory

**Current:**
```dart
factory TimelineConfiguration.fromMap(Map<String, dynamic> map) {
  Duration scrollThrottleDuration = const Duration(milliseconds: 16);
  if (map['scrollThrottleMs'] != null) {
    scrollThrottleDuration = Duration(
      milliseconds: (map['scrollThrottleMs'] as num).toInt(),
    );
  }
  // ... rest of parsing ...
  
  return TimelineConfiguration(
    // ... other parameters ...
    scrollThrottleDuration: scrollThrottleDuration,
    // ... other parameters ...
  );
}
```

**New:**
```dart
factory TimelineConfiguration.fromMap(Map<String, dynamic> map) {
  // Remove scrollThrottleDuration parsing
  // ... rest of parsing ...
  
  return TimelineConfiguration(
    // ... other parameters ...
    // scrollThrottleDuration removed
    // ... other parameters ...
  );
}
```

#### `toMap()` Method

**Current:**
```dart
Map<String, dynamic> toMap() {
  return {
    // ... other parameters ...
    'scrollThrottleMs': scrollThrottleDuration.inMilliseconds,
    // ... other parameters ...
  };
}
```

**New:**
```dart
Map<String, dynamic> toMap() {
  return {
    // ... other parameters ...
    // 'scrollThrottleMs' removed
    // ... other parameters ...
  };
}
```

#### `copyWith()` Method

**Current:**
```dart
TimelineConfiguration copyWith({
  // ... other parameters ...
  Duration? scrollThrottleDuration,
  // ... other parameters ...
}) {
  return TimelineConfiguration(
    // ... other parameters ...
    scrollThrottleDuration: scrollThrottleDuration ?? this.scrollThrottleDuration,
    // ... other parameters ...
  );
}
```

**New:**
```dart
TimelineConfiguration copyWith({
  // ... other parameters ...
  // scrollThrottleDuration parameter removed
  // ... other parameters ...
}) {
  return TimelineConfiguration(
    // ... other parameters ...
    // scrollThrottleDuration removed
    // ... other parameters ...
  );
}
```

#### Equality and HashCode

**Current:**
```dart
@override
bool operator ==(Object other) =>
    identical(this, other) ||
    other is TimelineConfiguration &&
        // ... other comparisons ...
        scrollThrottleDuration == other.scrollThrottleDuration &&
        // ... other comparisons ...

@override
int get hashCode => Object.hash(
      // ... other fields ...
      scrollThrottleDuration,
      // ... other fields ...
    );
```

**New:**
```dart
@override
bool operator ==(Object other) =>
    identical(this, other) ||
    other is TimelineConfiguration &&
        // ... other comparisons ...
        // scrollThrottleDuration removed
        // ... other comparisons ...

@override
int get hashCode => Object.hash(
      // ... other fields ...
      // scrollThrottleDuration removed
      // ... other fields ...
    );
```

#### `toString()` Method

**Current:**
```dart
@override
String toString() {
  return 'TimelineConfiguration(\n'
      // ... other fields ...
      '  scrollThrottleDuration: $scrollThrottleDuration,\n'
      // ... other fields ...
      ')';
}
```

**New:**
```dart
@override
String toString() {
  return 'TimelineConfiguration(\n'
      // ... other fields ...
      // scrollThrottleDuration removed
      // ... other fields ...
      ')';
}
```

### ParameterConstraints (`lib/src/timeline/models/parameter_constraints.dart`)

**Changes to `all` Map:**

**Current:**
```dart
static final Map<String, ParameterConstraints> all = {
  // ... other constraints ...
  'scrollThrottleMs': const ParameterConstraints(
    type: 'int',
    min: 8,
    max: 100,
    defaultValue: 16,
  ),
  // ... other constraints ...
};
```

**New:**
```dart
static final Map<String, ParameterConstraints> all = {
  // ... other constraints ...
  // 'scrollThrottleMs' removed
  // ... other constraints ...
};
```

## Data Models

No changes to data models. The scroll state data structures (`ScrollState`, `VisibleRange`) remain unchanged.

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Immediate Scroll Processing

*For any* scroll event, the scroll calculations should execute immediately without artificial delay.

**Validates: Requirements 1.3, 3.1**

### Property 2: Mounted Check Before State Updates

*For any* scroll event, state updates should only occur if the widget is still mounted.

**Validates: Requirements 3.2**

### Property 3: Configuration Completeness

*For any* TimelineConfiguration instance created from a map, all required parameters should be present and valid, with no references to removed throttle parameters.

**Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5, 2.6**

### Property 4: Scroll Calculation Preservation

*For any* scroll offset, the center index and visible range calculations should produce the same results as before throttle removal.

**Validates: Requirements 3.3, 7.2**

### Property 5: Performance Maintenance

*For any* rapid scrolling sequence, the timeline should remain responsive and not degrade in performance compared to the throttled version.

**Validates: Requirements 7.1, 7.5**

## Error Handling

### Existing Error Handling (Preserved)

- **Mounted checks**: Prevent state updates on unmounted widgets
- **Index clamping**: Prevent out-of-bounds access in scroll calculations
- **Null safety**: Handle null values in configuration and data
- **Error boundaries**: TimelineErrorHandler wraps risky operations

### No New Error Handling Required

The removal of throttling does not introduce new error conditions. All existing error handling mechanisms remain in place and continue to function as before.

## Testing Strategy

### Unit Tests

**Tests to Update:**

1. **Configuration Tests** (`test/models/timeline_configuration_test.dart`)
   - Remove tests for `scrollThrottleDuration` parameter
   - Update `fromMap()` tests to not expect `scrollThrottleMs`
   - Update `toMap()` tests to not include `scrollThrottleMs`
   - Update `copyWith()` tests to remove `scrollThrottleDuration` parameter
   - Update equality tests to not compare `scrollThrottleDuration`

2. **Edge Case Tests** (`test/edge_case_handling_test.dart`)
   - Remove `scrollThrottleMs` validation tests
   - Remove `scrollThrottleMs` boundary tests
   - Update default configuration tests to not expect `scrollThrottleMs`

3. **Parameter Constraints Tests** (if they exist)
   - Remove `scrollThrottleMs` constraint validation tests

**Tests to Verify Still Pass:**

1. **Scroll Calculation Tests** (`test/scroll_calculations_test.dart`)
   - Center index calculation should work identically
   - Visible range calculation should work identically
   - All pure function tests should pass unchanged

2. **Integration Tests** (`test/timeline_integration_test.dart`)
   - Timeline initialization should work
   - Scrolling behavior should work
   - Auto-scroll should work

### Property-Based Tests

**Tests to Update:**

1. **Current Date Callback Property Test** (`test/current_date_callback_property_test.dart`)
   - Remove throttling tolerance logic (lines 172-173)
   - Update pass rate expectation from 90% to 100% (line 184)
   - The test currently allows 10% failures due to throttling - this should no longer be necessary

**Property Test Configuration:**
- Minimum 100 iterations per property test
- Each test references its design document property
- Tag format: **Feature: remove-scroll-throttle, Property {number}: {property_text}**

### Manual Testing

**Scenarios to Test:**

1. **Rapid Scrolling**: Scroll quickly through the timeline and verify smooth performance
2. **Slow Scrolling**: Scroll slowly and verify immediate response
3. **Auto-Scroll**: Verify vertical auto-scroll still works correctly
4. **Center Item Updates**: Verify center item highlighting updates immediately
5. **Callback Execution**: Verify `updateCurrentDate` callback fires immediately

### Performance Testing

**Metrics to Monitor:**

1. **Frame Rate**: Should maintain 60 FPS during scrolling
2. **Memory Usage**: Should remain similar to throttled version
3. **CPU Usage**: May increase slightly but should remain acceptable
4. **Scroll Responsiveness**: Should feel more immediate and responsive

**Acceptance Criteria:**
- Frame rate: ≥ 60 FPS during normal scrolling
- Memory usage: Within 10% of throttled version
- CPU usage: Within 20% of throttled version
- User perception: Scrolling feels smooth and responsive

## Documentation Updates

### Files to Update

1. **`lib/src/timeline/timeline.dart`**
   - Remove "Scroll Throttling" from features list (line 40)
   - Remove "Throttled Updates" from scroll architecture description (line 55)
   - Remove throttle timer description from state management comments (line 186)
   - Update scroll listener comments to remove throttling references (lines 354, 368, 375-377)
   - Update dispose() comments to remove throttle timer references (lines 504, 506)

2. **`lib/run.dart`**
   - Remove "Scroll Throttling" from performance features list (line 27)
   - Remove throttling from performance comments (line 140)

3. **`lib/src/timeline/models/timeline_configuration.dart`**
   - Remove `scrollThrottleDuration` field documentation (lines 30-34)

4. **Specification Documents**
   - Update `.kiro/specs/native-scroll-only/requirements.md` - Mark Requirement 6 as deprecated
   - Update `.kiro/specs/native-scroll-only/design.md` - Add note about throttling removal
   - Update `.kiro/specs/timeline-performance-optimization/requirements.md` - Mark throttling requirement as deprecated
   - Update `.kiro/specs/timeline-performance-optimization/design.md` - Add note about throttling removal

### Documentation Principles

- **Accuracy**: Documentation must reflect actual implementation
- **Clarity**: Explain why throttling was removed (causing scroll management issues)
- **Completeness**: Update all references, not just obvious ones
- **Historical Context**: Add notes to spec documents explaining the change

## Migration Notes

### For Users

**No Breaking Changes:**
- The public API remains unchanged
- Existing code using the Timeline widget will continue to work
- Configuration files with `scrollThrottleMs` will simply ignore that parameter

**Potential Improvements:**
- Scrolling may feel more responsive
- Center item updates will be immediate
- Callbacks will fire without delay

### For Developers

**Code Changes:**
- Remove any custom code that relied on throttling behavior
- Update any tests that expected throttling delays
- Remove `scrollThrottleMs` from configuration files (optional, will be ignored if present)

**Testing:**
- Re-run all tests to ensure compatibility
- Verify scroll performance in your specific use case
- Monitor CPU usage if you have very large datasets

## Implementation Notes

### Order of Changes

1. **Phase 1: Core Implementation**
   - Remove `_scrollThrottleTimer` field from Timeline
   - Update scroll listener to execute immediately
   - Update dispose() method

2. **Phase 2: Configuration**
   - Remove `scrollThrottleDuration` from TimelineConfiguration
   - Update all configuration methods (fromMap, toMap, copyWith, etc.)
   - Remove `scrollThrottleMs` from ParameterConstraints

3. **Phase 3: Documentation**
   - Update Timeline widget documentation
   - Update run.dart documentation
   - Update configuration documentation
   - Update specification documents

4. **Phase 4: Tests**
   - Update configuration tests
   - Update edge case tests
   - Update property tests
   - Run full test suite

### Backward Compatibility

**Configuration Files:**
- Old configuration files with `scrollThrottleMs` will not cause errors
- The parameter will simply be ignored during parsing
- No migration of existing configuration files is required

**Code:**
- No breaking changes to public API
- All existing Timeline widget usage continues to work
- No changes required in consuming code

### Performance Considerations

**Expected Impact:**
- Slightly higher CPU usage during scrolling (no artificial delay)
- More immediate UI updates (better user experience)
- Same memory usage (no change to data structures)
- Same frame rate (lazy rendering still active)

**Mitigation Strategies:**
- Lazy rendering continues to limit rendered items
- Data caching continues to avoid redundant calculations
- ValueNotifier-based updates continue to minimize rebuilds
- Mounted checks continue to prevent unnecessary work

## Rationale

### Why Remove Throttling?

1. **Scroll Management Issues**: The throttling is causing problems with scroll management, as stated by the user
2. **Artificial Delay**: The 16ms delay makes the UI feel less responsive
3. **Unnecessary Complexity**: Modern Flutter handles scroll events efficiently without manual throttling
4. **Better User Experience**: Immediate updates provide better feedback to users

### Why Keep Other Optimizations?

1. **Lazy Rendering**: Still essential for large datasets (500+ days)
2. **Data Caching**: Still prevents redundant calculations
3. **ValueNotifiers**: Still provide granular, efficient updates
4. **Mounted Checks**: Still prevent errors on unmounted widgets

### Alternative Approaches Considered

1. **Adjust Throttle Duration**: Would still have artificial delay
2. **Conditional Throttling**: Would add complexity without clear benefit
3. **Debouncing Instead**: Would delay updates even more
4. **Keep Throttling**: Would not solve the scroll management issues

**Decision**: Complete removal is the simplest and most effective solution.
