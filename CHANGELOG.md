## 1.5.2 - 05/01/2025

### Documentation

* **Comprehensive API Documentation**: Added complete Dartdoc comments for all public API elements to improve pub.dev documentation score
  - Documented Timeline widget class with detailed usage examples
  - Documented all 11 public parameters (colors, infos, elements, elementsDone, capacities, stages, defaultDate, callbacks)
  - Added library-level documentation with features, usage examples, and performance characteristics
  - Enabled `public_member_api_docs` lint rule to maintain documentation standards

## 1.5.1 - 02/01/2025

### Fix

* Move .env for Sample
 

## 1.5.0 - 02/01/2025

### New Features

* **Independent Vertical and Horizontal Scrolling**: Added independent scroll management for better user experience across all platforms.
  
  **Changes**:
  - Added dedicated `_controllerVertical` ScrollController for vertical scrolling through stage rows
  - Implemented intelligent scroll event handling with `Listener` and `PointerScrollEvent`
  - Added keyboard modifier support (Shift + mouse wheel) for horizontal scrolling on desktop
  - Integrated `DeferredPointerHandler` for proper pointer event propagation between scroll areas
  
  **Benefits**:
  - **Desktop**: Shift + mouse wheel for horizontal scroll, normal wheel for vertical scroll
  - **Trackpad**: Native horizontal and vertical gestures work independently
  - **Mobile**: Touch swipes work naturally in both directions without conflicts
  - Improved user experience with intuitive scroll controls across all platforms
  - No breaking changes - existing functionality preserved
  
  **Migration**: No code changes required. The scrolling behavior is now more intuitive and platform-aware.

## 1.4.0 - 30/12/2024

### Refactoring

* **Native Scroll Architecture**: Major internal refactoring to use only native Flutter ScrollControllers without custom abstraction layers.
  
  **Changes**:
  - Removed `TimelineController` class (~150 lines of code)
  - Removed `VisibleRange` data class
  - Scroll state now managed with local variables in Timeline widget
  - Direct calculation of center index and visible range using pure functions
  - Lazy viewports now accept visible range as parameters instead of controller
  - Timer-based throttling implemented directly in scroll listener
  
  **Benefits**:
  - Simpler architecture with fewer abstraction layers
  - More transparent scroll logic (calculations visible in Timeline widget)
  - Easier to understand and maintain
  - Direct use of native Flutter APIs
  - Same performance characteristics as before
  - All existing functionality preserved
  
  **Migration**: No breaking changes. This is an internal refactoring that maintains all existing functionality and API compatibility. The public API remains unchanged.

## 1.3.0 - 29/12/2024

### Refactoring

* **Scroll Calculation Architecture Refactoring**: Major internal refactoring of the scroll mechanism to separate calculation from action.
  
  **Changes**:
  - Extracted pure calculation functions into `scroll_calculations.dart`:
    - `calculateCenterDateIndex()`: Calculates which day is at viewport center
    - `calculateTargetVerticalOffset()`: Calculates vertical scroll position
    - `shouldEnableAutoScroll()`: Determines if auto-scroll should be enabled
  - Created `ScrollState` data class to encapsulate scroll state
  - Separated calculation (`_calculateScrollState()`) from action (`_applyAutoScroll()`)
  - Improved scroll direction detection logic for better auto-scroll behavior
  
  **Benefits**:
  - Pure functions are easily testable in isolation
  - Clear separation of concerns (calculation vs action)
  - No circular dependencies between scroll state and calculations
  - Better maintainability and code clarity
  - Improved auto-scroll accuracy with direction-aware logic
  
  **Migration**: No breaking changes. This is an internal refactoring that maintains all existing functionality and API compatibility.

## 1.2.0 - 28/12/2024

### Breaking Changes

* **Removed slider-based scroll control**: The Timeline widget no longer includes a slider UI element for horizontal scrolling. Horizontal scrolling now uses standard Flutter scrolling mechanisms (mouse wheel, trackpad gestures, touch drag).
  
  **Migration**: No code changes required. The `scrollTo()` method continues to work as before. Users will now scroll horizontally using native gestures instead of the slider widget.
  
  **Benefits**: 
  - Simpler codebase (~50 lines removed)
  - More familiar user experience with standard scrolling
  - Eliminates potential slider synchronization bugs
  - Reduced memory footprint

### Improvements

* Simplified scroll implementation by using ScrollController directly
* Improved scroll performance by removing slider state synchronization overhead
* Better user experience with native scrolling gestures across all platforms

## 1.1.0 - 23/12/2025

* Fix dependencies for Scoring


## 1.0.0 - 23/12/2025

* Initial version with first version of swiip_pubdev_timeline
