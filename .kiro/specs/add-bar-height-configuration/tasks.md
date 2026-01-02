# Implementation Plan: Add barHeight Configuration Parameter

## Overview

This implementation plan breaks down the addition of the `barHeight` configuration parameter into discrete, manageable tasks. Each task builds on previous steps and includes specific requirements references. The plan follows a logical progression: core model updates → validation → integration → testing → documentation.

## Tasks

- [x] 1. Update TimelineConfiguration class to include barHeight parameter
  - Add `barHeight` field with type `double` and default value `70.0`
  - Update constructor to accept optional `barHeight` parameter
  - Update `fromMap` factory to parse `barHeight` from JSON (with fallback to 70.0)
  - Update `toMap` method to include `barHeight` in output map
  - Update `copyWith` method to support `barHeight` parameter
  - Update `operator ==` to compare `barHeight` values
  - Update `hashCode` to include `barHeight`
  - Update `toString` to display `barHeight` value
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 7.3, 7.4_

- [ ]* 1.1 Write property test for barHeight serialization round-trip
  - **Property 1: Configuration Serialization Round-trip**
  - *For any* TimelineConfiguration with valid barHeight, toMap then fromMap should preserve barHeight
  - **Validates: Requirements 1.4, 1.5**

- [x] 2. Add barHeight constraints to ParameterConstraints
  - Add `barHeight` entry to `ParameterConstraints.all` map
  - Set type to `'double'`
  - Set min to `40.0`
  - Set max to `150.0`
  - Set defaultValue to `70.0`
  - _Requirements: 2.1_

- [ ]* 2.1 Write property test for out-of-range barHeight validation
  - **Property 2: Out-of-range Values Use Default**
  - *For any* barHeight value outside [40.0, 150.0], validator should use default 70.0
  - **Validates: Requirements 2.2, 2.3**

- [ ]* 2.2 Write property test for invalid type barHeight validation
  - **Property 3: Invalid Type Uses Default**
  - *For any* non-numeric barHeight value, validator should log warning and use default 70.0
  - **Validates: Requirements 2.4**

- [ ]* 2.3 Write property test for barHeight error message completeness
  - **Property 4: Error Messages Include Parameter Name**
  - *For any* barHeight validation failure, error message should contain parameter name, value, and range
  - **Validates: Requirements 2.5**

- [ ]* 2.4 Write unit test for default barHeight when omitted
  - Test that configurations without barHeight use default value 70.0
  - Test loading config file without barHeight parameter
  - Test creating TimelineConfiguration without barHeight parameter
  - **Validates: Requirements 1.2, 3.3, 7.1, 7.4**

- [x] 3. Integrate barHeight into Timeline widget
  - [x] 3.1 Update Timeline widget to retrieve barHeight from configuration
    - In `initState`, get configuration and extract `barHeight` value
    - Store `barHeight` in a local variable for use in build method
    - _Requirements: 4.3_

  - [x] 3.2 Update SizedBox at line 623 to use configured barHeight
    - Replace hardcoded `height: 70.0` with `height: _config.barHeight`
    - Verify the SizedBox correctly uses the configured value
    - _Requirements: 4.1_

  - [x] 3.3 Update TimelineBarItem to accept height parameter
    - Add `height` parameter to TimelineBarItem constructor
    - Make `height` a required parameter
    - Use `height` for the container height in TimelineBarItem
    - _Requirements: 4.2_

  - [x] 3.4 Pass barHeight to TimelineBarItem components
    - Update all TimelineBarItem instantiations to pass `height: _config.barHeight`
    - Verify TimelineBarItem receives correct height value
    - _Requirements: 4.4_

- [ ]* 3.5 Write integration test for Timeline widget using barHeight
  - Test Timeline widget with custom barHeight value
  - Verify SizedBox has correct height
  - Verify TimelineBarItem receives correct height
  - **Validates: Requirements 4.1, 4.2, 4.5**

- [x] 4. Checkpoint - Ensure core implementation works
  - Verify TimelineConfiguration includes barHeight with correct default
  - Verify ParameterConstraints validates barHeight correctly
  - Verify Timeline widget uses barHeight from configuration
  - Verify TimelineBarItem uses provided height
  - Run existing tests to ensure no regressions
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Update configuration template file
  - Add `barHeight` parameter to `timeline_config.template.json`
  - Set value to `70.0` (default)
  - Add `_barHeight_range` comment: "40.0 - 150.0"
  - Add `_barHeight_default` comment: "70.0"
  - Add `_barHeight_description` comment explaining purpose
  - Add `_barHeight_impact` comment explaining visual impact
  - _Requirements: 3.2, 3.4, 3.5_

- [x] 6. Update CONFIGURATION.md documentation
  - Add section for `barHeight` parameter
  - Document the purpose: "Controls the height of timeline bars in pixels"
  - Document the valid range: "40.0 - 150.0 pixels"
  - Document the default value: "70.0 pixels"
  - Explain visual impact of different values (compact vs spacious)
  - Provide example configuration with barHeight
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [ ]* 7. Write unit tests for edge cases
  - Test barHeight at boundary values (40.0, 150.0)
  - Test barHeight just outside boundaries (39.9, 150.1)
  - Test barHeight with various invalid types (string, boolean, null, array, object)
  - Test barHeight omitted from configuration file
  - Test backward compatibility (existing code without barHeight)
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 7.2, 7.5_

- [x] 8. Update timeline_config.json example file
  - Add `barHeight: 70.0` to the example configuration file
  - Ensure the file remains valid JSON
  - _Requirements: 3.1_

- [x] 9. Final checkpoint - Complete validation
  - Run all tests (unit, property, integration)
  - Verify documentation is complete and accurate
  - Test with example project to ensure barHeight works end-to-end
  - Verify backward compatibility with existing code
  - Verify all requirements are met
  - Ask the user if questions arise or if ready for release.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties
- Unit tests validate specific examples and edge cases
- Integration tests validate end-to-end functionality
- The implementation leverages the existing configuration system, minimizing new code
