# Design Document: Native Scroll Only

## Overview

This design describes the removal of the custom `TimelineController` class and the transition to using only native Flutter `ScrollController` instances for managing timeline scroll state. This refactoring eliminates an unnecessary abstraction layer, reducing code complexity by approximately 150 lines while maintaining all existing functionality.

> **⚠️ NOTE ON SCROLL THROTTLING**: This design document originally included scroll throttling as a maintained feature (Requirement 6). However, scroll throttling has since been completely removed from the codebase via the `remove-scroll-throttle` spec. The throttling mechanism was causing scroll management issues and has been replaced with immediate scroll event processing. All references to throttling in this document are now deprecated and should be considered historical context only.

The key insight is that Flutter's `ScrollController` already provides all the necessary capabilities for scroll management. The `TimelineController` was adding an extra layer that:
1. Duplicated scroll offset tracking (already available via `ScrollController.offset`)
2. Added throttling that can be implemented directly with a Timer (now removed entirely)
3. Wrapped calculations that can be called directly from pure functions
4. Used ValueNotifiers that can be replaced with local state variables

By removing this abstraction, we simplify the architecture and make the scroll logic more transparent and easier to understand.

## Architecture

### Current Architecture (Before Refactoring)

```
User Interaction
    ↓
ScrollController
    ↓
Scroll Listener
    ↓
TimelineController.updateScrollOffset() [throttled]
    ↓
TimelineController._updateCenterItemIndex()
    ↓
TimelineController._updateVisibleRange()
    ↓
ValueNotifiers (centerItemIndex, visibleRange)
    ↓
LazyViewports listen to ValueNotifiers
```

### New Architecture (After Refactoring)

> **⚠️ UPDATE**: The throttling shown below has been removed. Scroll calculations now execute immediately without Timer-based throttling.

```
User Interaction
    ↓
ScrollController
    ↓
Scroll Listener [throttled with Timer] ← REMOVED
    ↓
calculateCenterDateIndex() [pure function]
    ↓
Calculate visible range [inline]
    ↓
Local state variables (centerIndex, visibleStart, visibleEnd)
    ↓
Pass values directly to LazyViewports
```

The new architecture is simpler because:
1. No intermediate controller class
2. Direct use of pure calculation functions
3. Local state instead of ValueNotifiers
4. Explicit parameter passing instead of reactive updates
5. ~~Throttling implemented directly with Timer~~ (REMOVED - now processes immediately)

## Components and Interfaces

### Removed Components

#### TimelineController (lib/src/timeline/models/timeline_controller.dart)
- **Entire file removed** (~150 lines)
- All functionality replaced with direct calculations and native ScrollController usage

### Modified Components

#### Timeline Widget (lib/src/timeline/timeline.dart)

**Removed State Variables:**
- `TimelineController _timelineController` - Custom controller instance
- All TimelineController-related initialization and disposal code

**Added State Variables:**
- `int _centerItemIndex = 0` - Current center item index (replaces ValueNotifier)
- `int _visibleStart = 0` - Start of visible range
- `int _visibleEnd = 0` - End of visible range
- `double _viewportWidth = 0.0` - Current viewport width
- `Timer? _scrollThrottleTimer` - Timer for throttling scroll calculations

**Modified Methods:**

**`_initializeTimeline()`:**
- Remove TimelineController initialization
- Keep ScrollController initialization
- Remove TimelineController disposal registration

**`dispose()`:**
- Remove TimelineController disposal
- Add scroll throttle timer cancellation

**Scroll Listener (in `_initializeTimeline()`):**
```dart
// Before:
_controllerTimeline.addListener(() {
  _timelineController.updateScrollOffset(currentOffset);
  // ... rest of logic
});

// After:
_controllerTimeline.addListener(() {
  // Cancel existing throttle timer
  _scrollThrottleTimer?.cancel();
  
  // Throttle scroll calculations
  _scrollThrottleTimer = Timer(Duration(milliseconds: 16), () {
    if (!mounted) return;
    
    final currentOffset = _controllerTimeline.offset;
    
    // Calculate center index directly
    final newCenterIndex = calculateCenterDateIndex(
      scrollOffset: currentOffset,
      viewportWidth: _viewportWidth,
      dayWidth: dayWidth,
      dayMargin: dayMargin,
      totalDays: days.length,
    );
    
    // Calculate visible range directly
    final visibleDays = (_viewportWidth / (dayWidth - dayMargin)).ceil();
    final buffer = _config.bufferDays;
    final newVisibleStart = (newCenterIndex - (visibleDays ~/ 2) - buffer)
        .clamp(0, days.length);
    final newVisibleEnd = (newCenterIndex + (visibleDays ~/ 2) + buffer)
        .clamp(0, days.length);
    
    // Update state if changed
    if (newCenterIndex != _centerItemIndex ||
        newVisibleStart != _visibleStart ||
        newVisibleEnd != _visibleEnd) {
      setState(() {
        _centerItemIndex = newCenterIndex;
        _visibleStart = newVisibleStart;
        _visibleEnd = newVisibleEnd;
      });
      
      // Trigger callbacks and auto-scroll
      if (newCenterIndex != _previousCenterIndex) {
        _updateCurrentDateCallback(newCenterIndex);
        // ... auto-scroll logic
      }
    }
  });
});
```

**`scrollTo(int dateIndex, {bool animated})`:**
- No changes needed (already uses ScrollController directly after previous refactoring)

**`build()`:**
- Update LayoutBuilder to capture viewport width: `_viewportWidth = constraints.maxWidth`
- Pass visible range directly to LazyViewports instead of TimelineController

#### LazyTimelineViewport (lib/src/timeline/lazy_timeline_viewport.dart)

**Modified Constructor:**
```dart
// Before:
LazyTimelineViewport({
  required TimelineController controller,
  required List items,
  required double itemWidth,
  required double itemMargin,
  required Widget Function(BuildContext, int) itemBuilder,
})

// After:
LazyTimelineViewport({
  required int visibleStart,
  required int visibleEnd,
  required int centerItemIndex,
  required List items,
  required double itemWidth,
  required double itemMargin,
  required Widget Function(BuildContext, int) itemBuilder,
})
```

**Modified Implementation:**
- Remove ValueListenableBuilder for visibleRange
- Use visibleStart and visibleEnd parameters directly
- Remove dependency on TimelineController
- Pass centerItemIndex directly to itemBuilder

#### StageRowsViewport (lib/src/timeline/lazy_stage_rows_viewport.dart)

**Modified Constructor:**
```dart
// Before:
StageRowsViewport({
  required TimelineController controller,
  required List stagesRows,
  // ... other parameters
})

// After:
StageRowsViewport({
  required int visibleStart,
  required int visibleEnd,
  required List stagesRows,
  // ... other parameters
})
```

**Modified Implementation:**
- Remove ValueListenableBuilder for visibleRange
- Use visibleStart and visibleEnd parameters directly
- Remove dependency on TimelineController

### Unchanged Components

#### Scroll Calculation Functions (lib/src/timeline/scroll_calculations.dart)
- No changes required
- All pure functions remain the same
- Continue to be called directly from Timeline widget

#### TimelineDataManager (lib/src/timeline/models/timeline_data_manager.dart)
- No changes required
- Continues to handle data formatting and caching

#### TimelineConfiguration (lib/src/timeline/models/timeline_configuration.dart)
- No changes required
- Continues to provide configuration values including bufferDays

#### All Other Widgets
- OptimizedTimelineItem
- OptimizedStageRow
- TimelineDayDate
- LoadingIndicatorOverlay
- All remain unchanged

## Data Models

No changes to data models are required. The VisibleRange data class can be removed since we're using simple int variables instead:

**Removed:**
- `VisibleRange` class (lib/src/timeline/models/visible_range.dart)

**Unchanged:**
- `TimelineConfiguration`
- `PerformanceMetrics`
- `ScrollState`
- Stage and element data structures

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system - essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*


### Property 1: Scroll Position Retrieval

*For any* scroll position applied to a ScrollController (horizontal or vertical), reading the `offset` property should return the applied scroll position.

**Validates: Requirements 2.1, 2.2**

### Property 2: Center Item Calculation

*For any* horizontal scroll offset and viewport width, the calculated center item index should match the result of `calculateCenterDateIndex()` with the same parameters, and should correspond to the day item visually centered in the viewport.

**Validates: Requirements 2.3, 3.1, 3.2**

### Property 3: Visible Range Calculation

*For any* horizontal scroll offset and viewport width, the calculated visible range should:
- Include all days visible in the viewport
- Extend by the configured buffer days on both sides
- Be clamped to valid indices [0, totalDays]
- Match the formula: visibleDays = ceil(viewportWidth / (dayWidth - dayMargin))

**Validates: Requirements 2.4, 4.1, 4.3, 4.4, 4.5**

### Property 4: Current Date Callback Invocation

*For any* horizontal scroll position where the center item index changes, if the `updateCurrentDate` callback is provided, it should be called with the date string (YYYY-MM-DD format) of the new center item.

**Validates: Requirements 3.5**

### Property 5: Lazy Viewport Rendering

*For any* calculated visible range (visibleStart, visibleEnd), the lazy viewports should render only the items within that range, and should receive the correct center item index for highlighting.

**Validates: Requirements 5.5**

### Property 6: Auto-Scroll Behavior

*For any* horizontal scroll position that changes the center item significantly (≥2 days), if the user has not manually scrolled vertically, the vertical scroll position should animate to show the highest visible stage row in the current viewport.

**Validates: Requirements 7.1, 7.3, 7.4**

### Property 7: ScrollTo Offset Calculation

*For any* valid date index, calling `scrollTo(dateIndex)` should calculate the scroll offset as `dateIndex * (dayWidth - dayMargin)` and position that date at the center of the viewport.

**Validates: Requirements 8.2**

## Error Handling

### Existing Error Handling (Preserved)

The refactoring maintains all existing error handling mechanisms:

1. **Index Clamping**: `TimelineErrorHandler.clampIndex()` prevents out-of-bounds access
2. **Scroll Offset Clamping**: `TimelineErrorHandler.clampScrollOffset()` prevents invalid scroll positions
3. **Empty Collection Guards**: Checks for `days.isEmpty` and `stagesRows.isEmpty` before operations
4. **Mounted Checks**: Verify widget is mounted before setState after async operations
5. **ScrollController Client Checks**: `hasClients` check before accessing scroll position
6. **Null Safety**: Proper null checks for optional callbacks and parameters

### Simplified Error Surface

By removing TimelineController, we eliminate potential error scenarios:
- No ValueNotifier synchronization errors
- No controller initialization/disposal ordering issues
- Fewer state variables to keep consistent
- Direct calculation reduces indirection and potential bugs

### New Error Considerations

**Throttle Timer Management:**
- Must cancel timer in dispose() to prevent memory leaks
- Must check mounted before setState in throttled callback
- Timer cancellation is idempotent (safe to call multiple times)

**Visible Range Calculation:**
- Must handle edge cases where viewport is very small or very large
- Must clamp to valid range to prevent out-of-bounds rendering
- Must handle totalDays = 0 case gracefully

## Testing Strategy

### Unit Tests

**Tests to Remove:**
- `test/models/timeline_controller_test.dart` - Entire file (TimelineController no longer exists)
- Any tests that mock or verify TimelineController behavior
- Tests that verify ValueNotifier updates from TimelineController

**Tests to Update:**
- Scroll position tracking tests - Update to verify direct calculation instead of controller updates
- Visible range tests - Update to verify inline calculation instead of controller method
- Center item tests - Update to verify direct function call instead of controller property

**Tests to Add:**
- Test throttle timer cancellation in dispose()
- Test visible range clamping at boundaries
- Test setState only called when values actually change

**Tests to Preserve:**
- All scroll calculation function tests (pure functions unchanged)
- All LazyViewport rendering tests (update to pass parameters directly)
- All auto-scroll behavior tests (logic unchanged, just different state management)
- All scrollTo() tests (already updated in previous refactoring)

### Property-Based Tests

Property-based testing will verify the correctness properties defined above using the `test` package with parameterized tests and generated inputs.

**Test Configuration:**
- Minimum 100 iterations per property test
- Use random scroll offsets, viewport widths, and date indices
- Tag format: **Feature: native-scroll-only, Property {number}: {property_text}**

**Property Test Implementation:**

1. **Property 1: Scroll Position Retrieval**
   - Generate random scroll offsets within valid range [0, maxScrollExtent]
   - Apply to both horizontal and vertical controllers using jumpTo()
   - Verify controller.offset matches applied value
   - Test both controllers independently

2. **Property 2: Center Item Calculation**
   - Generate random scroll offsets and viewport widths
   - Calculate expected center index using pure function
   - Verify calculated index matches expected value
   - Verify index is within valid range [0, totalDays-1]

3. **Property 3: Visible Range Calculation**
   - Generate random scroll offsets, viewport widths, and buffer values
   - Calculate expected visible range using formula
   - Verify calculated range matches expected values
   - Verify range is clamped to [0, totalDays]
   - Test edge cases: scroll at start, scroll at end, very small/large viewport

4. **Property 4: Current Date Callback Invocation**
   - Generate random scroll positions that change center item
   - Provide mock updateCurrentDate callback
   - Verify callback called with correct date string (YYYY-MM-DD format)
   - Verify callback not called when center item unchanged

5. **Property 5: Lazy Viewport Rendering**
   - Generate random visible ranges
   - Verify LazyTimelineViewport renders only items in range
   - Verify StageRowsViewport renders only rows in range
   - Verify correct center item index passed for highlighting

6. **Property 6: Auto-Scroll Behavior**
   - Generate random horizontal scroll positions that change center by ≥2 days
   - Verify vertical auto-scroll triggers when userScrollOffset is null
   - Verify vertical auto-scroll does not trigger when userScrollOffset is set
   - Verify vertical position animates to correct target offset

7. **Property 7: ScrollTo Offset Calculation**
   - Generate random valid date indices [0, totalDays-1]
   - Calculate expected offset: dateIndex * (dayWidth - dayMargin)
   - Call scrollTo(index) and verify scroll position matches expected offset
   - Test both animated and non-animated variants

### Integration Tests

**Existing Integration Tests to Update:**
- Update tests to verify scroll state without TimelineController
- Update tests to verify lazy rendering with direct parameter passing
- Update tests to verify auto-scroll behavior with new state management

**New Integration Tests:**
- Test complete scroll flow: user scroll → calculation → state update → render
- Test throttling behavior: rapid scrolls should not cause excessive calculations
- Test initialization: verify correct initial scroll position and visible range

### Manual Testing Checklist

After implementation, manually verify:
- [ ] Horizontal scrolling works smoothly (mouse, trackpad, touch)
- [ ] Vertical scrolling works independently
- [ ] Lazy rendering works correctly (only visible items rendered)
- [ ] Center item highlighting updates correctly
- [ ] Current date callback fires correctly
- [ ] Auto-scroll follows horizontal position
- [ ] ScrollTo today/default date works on initialization
- [ ] Performance remains smooth (no regressions)
- [ ] No console errors or warnings
- [ ] Memory usage stable (no leaks from timer)

## Implementation Notes

### Code Removal Summary

**Files to Remove (~150 lines total):**
1. `lib/src/timeline/models/timeline_controller.dart` - Entire file
2. `lib/src/timeline/models/visible_range.dart` - Entire file (if not used elsewhere)
3. `test/models/timeline_controller_test.dart` - Entire file

**Imports to Remove:**
- `import 'models/timeline_controller.dart';` from timeline.dart
- `import 'models/visible_range.dart';` from timeline.dart (if removed)

### Code Modifications

**State Variables in Timeline:**
```dart
// Remove:
late TimelineController _timelineController;

// Add:
int _centerItemIndex = 0;
int _visibleStart = 0;
int _visibleEnd = 0;
double _viewportWidth = 0.0;
double _viewporHeight = 0.0;
Timer? _scrollThrottleTimer;
```

**Scroll Listener in _initializeTimeline():**
```dart
_controllerTimeline.addListener(() {
  // Cancel existing throttle timer
  _scrollThrottleTimer?.cancel();
  
  // Throttle scroll calculations (~60 FPS)
  _scrollThrottleTimer = Timer(const Duration(milliseconds: 16), () {
    if (!mounted) return;
    
    final currentOffset = _controllerTimeline.offset;
    final maxScrollExtent = _controllerTimeline.position.maxScrollExtent;
    
    if (currentOffset >= 0 && currentOffset < maxScrollExtent) {
      // Calculate center index directly
      final newCenterIndex = calculateCenterDateIndex(
        scrollOffset: currentOffset,
        viewportWidth: _viewportWidth,
        dayWidth: dayWidth,
        dayMargin: dayMargin,
        totalDays: days.length,
      );
      
      // Calculate visible range directly
      final visibleDays = (_viewportWidth / (dayWidth - dayMargin)).ceil();
      final buffer = _config.bufferDays;
      final newVisibleStart = (newCenterIndex - (visibleDays ~/ 2) - buffer)
          .clamp(0, days.length);
      final newVisibleEnd = (newCenterIndex + (visibleDays ~/ 2) + buffer)
          .clamp(0, days.length);
      
      // Update state only if changed
      if (newCenterIndex != _centerItemIndex ||
          newVisibleStart != _visibleStart ||
          newVisibleEnd != _visibleEnd) {
        setState(() {
          _centerItemIndex = newCenterIndex;
          _visibleStart = newVisibleStart;
          _visibleEnd = newVisibleEnd;
        });
        
        // Handle center item change
        if (newCenterIndex != _previousCenterIndex) {
          _updateCurrentDateCallback(newCenterIndex);
          
          // Auto-scroll logic (existing code)
          final centerIndexDifference = (newCenterIndex - _previousCenterIndex).abs();
          if (centerIndexDifference >= 2) {
            _verticalScrollDebounceTimer?.cancel();
            _verticalScrollDebounceTimer = Timer(
              _verticalScrollDebounceDuration,
              () => _applyAutoScroll(/* ... */),
            );
          }
          
          _previousCenterIndex = newCenterIndex;
        }
      }
    }
  });
});
```

**dispose() Method:**
```dart
@override
void dispose() {
  // Cancel timers
  _scrollThrottleTimer?.cancel();
  _verticalScrollDebounceTimer?.cancel();
  
  // Remove listeners
  _controllerTimeline.removeListener(() {});
  _controllerVerticalStages.removeListener(() {});
  
  // Remove TimelineController disposal (no longer exists)
  
  super.dispose();
}
```

**build() Method - LayoutBuilder:**
```dart
LayoutBuilder(
  builder: (context, constraints) {
    final double screenWidth = constraints.maxWidth;
    
    // Update viewport width
    _viewportWidth = screenWidth;
    
    // ... rest of build logic
  },
)
```

**build() Method - LazyTimelineViewport:**
```dart
// Before:
LazyTimelineViewport(
  controller: _timelineController,
  items: days,
  itemWidth: dayWidth,
  itemMargin: dayMargin,
  itemBuilder: (context, index) {
    return TimelineDayDate(
      centerItemIndex: _timelineController.centerItemIndex.value,
      // ...
    );
  },
)

// After:
LazyTimelineViewport(
  visibleStart: _visibleStart,
  visibleEnd: _visibleEnd,
  centerItemIndex: _centerItemIndex,
  items: days,
  itemWidth: dayWidth,
  itemMargin: dayMargin,
  itemBuilder: (context, index) {
    return TimelineDayDate(
      centerItemIndex: _centerItemIndex,
      // ...
    );
  },
)
```

**build() Method - StageRowsViewport:**
```dart
// Before:
StageRowsViewport(
  controller: _timelineController,
  stagesRows: stagesRows,
  // ...
)

// After:
StageRowsViewport(
  visibleStart: _visibleStart,
  visibleEnd: _visibleEnd,
  stagesRows: stagesRows,
  // ...
)
```

### LazyTimelineViewport Modifications

**Constructor:**
```dart
// Before:
const LazyTimelineViewport({
  super.key,
  required this.controller,
  required this.items,
  required this.itemWidth,
  required this.itemMargin,
  required this.itemBuilder,
});

final TimelineController controller;

// After:
const LazyTimelineViewport({
  super.key,
  required this.visibleStart,
  required this.visibleEnd,
  required this.centerItemIndex,
  required this.items,
  required this.itemWidth,
  required this.itemMargin,
  required this.itemBuilder,
});

final int visibleStart;
final int visibleEnd;
final int centerItemIndex;
```

**build() Method:**
```dart
// Before:
@override
Widget build(BuildContext context) {
  return ValueListenableBuilder<VisibleRange>(
    valueListenable: controller.visibleRange,
    builder: (context, visibleRange, child) {
      return Row(
        children: [
          for (int i = visibleRange.start; i < visibleRange.end; i++)
            itemBuilder(context, i),
        ],
      );
    },
  );
}

// After:
@override
Widget build(BuildContext context) {
  return Row(
    children: [
      for (int i = visibleStart; i < visibleEnd; i++)
        itemBuilder(context, i),
    ],
  );
}
```

### StageRowsViewport Modifications

Similar changes to LazyTimelineViewport:
- Replace `controller` parameter with `visibleStart` and `visibleEnd`
- Remove ValueListenableBuilder
- Use parameters directly in build method

### Performance Considerations

**Expected Performance Impact:**
- **Positive**: Fewer object allocations (no ValueNotifiers)
- **Positive**: Simpler call stack (direct calculations)
- **Positive**: Less memory usage (fewer objects)
- **Neutral**: Throttling behavior unchanged (still ~60 FPS)
- **Positive**: setState only called when values actually change

**Potential Concerns:**
- setState in scroll listener could cause more rebuilds than ValueListenableBuilder
- **Mitigation**: Only call setState when values actually change (check before setState)
- **Mitigation**: Throttling limits setState frequency to ~60 FPS

### Migration Path

This is an internal refactoring with no public API changes:

1. Remove TimelineController class and tests
2. Update Timeline widget to use direct calculations
3. Update LazyViewport widgets to accept parameters
4. Update all tests to reflect new architecture
5. Verify all functionality works
6. Update documentation
7. Update CHANGELOG.md with internal refactoring note

### Alternatives Considered

#### Alternative 1: Keep TimelineController but Simplify

**Approach:** Keep TimelineController but remove ValueNotifiers, use simple properties.

**Rejected because:**
- Still maintains an unnecessary abstraction layer
- Doesn't significantly reduce complexity
- Calculations can be done directly without wrapper class

#### Alternative 2: Use Provider or Other State Management

**Approach:** Replace TimelineController with Provider or similar state management solution.

**Rejected because:**
- Adds external dependency
- Overkill for simple scroll state
- Local state with direct calculations is simpler

#### Alternative 3: Keep ValueNotifiers, Remove Controller Class

**Approach:** Use ValueNotifiers directly in Timeline widget without controller class.

**Rejected because:**
- ValueNotifiers add complexity for simple int/double values
- Direct setState is simpler and more idiomatic for local state
- Throttling with Timer is sufficient for performance

## Conclusion

This refactoring eliminates the custom `TimelineController` abstraction layer and uses only native Flutter `ScrollController` instances with direct calculation of scroll-related values. The change reduces code complexity by approximately 150 lines, simplifies the architecture, and makes the scroll logic more transparent and easier to understand while maintaining all existing functionality and performance characteristics.

The key benefits are:
1. **Simpler Architecture**: Direct calculations instead of controller abstraction
2. **Less Code**: ~150 lines removed
3. **More Transparent**: Logic is visible in Timeline widget instead of hidden in controller
4. **Easier to Understand**: Fewer indirection layers
5. **Same Performance**: Throttling and lazy rendering preserved
6. **Same Functionality**: All features maintained
