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
