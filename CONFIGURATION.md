# Timeline Configuration Guide

## Overview

The `swiip_pubdev_timeline` package supports external configuration through a JSON file, allowing you to customize performance and rendering parameters without modifying the package source code. This is particularly useful for optimizing the timeline for different dataset sizes and device capabilities.

## Quick Start

1. **Copy the template file**:
   ```bash
   cp timeline_config.template.json timeline_config.json
   ```

2. **Add to pubspec.yaml**:
   ```yaml
   flutter:
     assets:
       - timeline_config.json
   ```

3. **Edit the configuration**:
   Open `timeline_config.json` and modify the values you want to customize. Remove all lines starting with `_` (these are comments).

4. **Customize parameters**:
   ```json
   {
     "dayWidth": 50.0,
     "bufferDays": 10,
   }
   ```

5. **Restart your app** to apply the changes

## Configuration File Location

The configuration file must be named `timeline_config.json` and placed in the package root directory:

```
your_project/
├── lib/
├── test/
├── timeline_config.json  ← Your configuration file
└── pubspec.yaml
```

**Important for Flutter apps**: You must also add the configuration file to your `pubspec.yaml` assets:

```yaml
flutter:
  assets:
    - timeline_config.json
```

This allows Flutter to bundle the configuration file with your app.

## Configuration Parameters

### dayWidth

**Type**: `double`  
**Range**: `20.0 - 100.0`  
**Default**: `65.0`

Width of each day column in pixels.

**Performance Impact**:
- Larger values = more detail, easier to read, but higher memory usage
- Smaller values = more days visible at once, but harder to read

**Recommendations**:
- Small datasets: `70.0`
- Medium datasets: `65.0` (default)
- Large datasets: `50.0`

### dayMargin

**Type**: `double`  
**Range**: `0.0 - 20.0`  
**Default**: `5.0`

Horizontal spacing between day columns in pixels.

**Performance Impact**: Minimal. Affects visual density and readability.

**Recommendations**:
- Standard: `5.0`
- Compact (large datasets): `3.0 - 4.0`

### bufferDays

**Type**: `int`  
**Range**: `1 - 20`  
**Default**: `8`

Number of days to render outside the visible viewport on each side.

**Performance Impact**: **CRITICAL**
- Higher values = smoother scrolling but significantly higher memory usage
- Each buffer day renders all rows for that day
- This is the most impactful parameter for memory usage

**Recommendations**:
- Small datasets: `5`
- Medium datasets: `8` (default)
- Large datasets: `10`

**⚠️ Warning**: Values greater than 10 can cause significant memory usage, especially with many rows. Monitor memory usage if increasing this value.

### animationDurationMs

**Type**: `int`  
**Range**: `100 - 500`  
**Default**: `250`

Duration of scroll animations in milliseconds.

**Performance Impact**:
- Longer animations feel smoother but take more time
- Shorter animations are snappier but may feel abrupt

**Recommendations**:
- Small datasets: `200`
- Medium datasets: `250` (default)
- Large datasets: `300`

### rowHeight

**Type**: `double`  
**Range**: `20.0 - 60.0`  
**Default**: `30.0`

Height of each stage row in pixels.

**Performance Impact**:
- Larger values = easier to read and interact with, but fewer rows visible
- Affects total timeline height

**Recommendations**:
- Better touch targets: `35.0`
- Standard: `30.0`
- Compact (fit more rows): `25.0`

### rowMargin

**Type**: `double`  
**Range**: `0.0 - 10.0`  
**Default**: `3.0`

Vertical spacing between stage rows in pixels.

**Performance Impact**: Minimal. Affects visual density.

**Recommendations**:
- Standard: `3.0`
- Compact: `2.0`

### datesHeight

**Type**: `double`  
**Range**: `40.0 - 100.0`  
**Default**: `65.0`

Height of the date header row in pixels.

**Performance Impact**: Minimal.

**Recommendations**: `65.0` for standard layouts, adjust based on your date formatting needs.

### barHeight

**Type**: `double`  
**Range**: `40.0 - 150.0`  
**Default**: `70.0`

Controls the height of timeline bars in pixels.

**Visual Impact**:
- **Larger values** (100.0 - 150.0): Provide more vertical space for bar content, creating a more spacious timeline. Fewer rows are visible at once, but individual bars are easier to read and interact with.
- **Default value** (70.0): Balanced height that works well for most use cases, providing good readability without excessive vertical space.
- **Smaller values** (40.0 - 60.0): Create a more compact timeline with more rows visible at once. Useful when you need to see many rows simultaneously, though individual bars have less space for content.

**Performance Impact**: Minimal. Affects visual layout but not rendering performance.

**Recommendations**:
- Spacious layout: `100.0 - 120.0`
- Standard: `70.0` (default)
- Compact (fit more rows): `50.0 - 60.0`
- Minimal (maximum rows visible): `40.0`

**Example Configuration**:
```json
{
  "barHeight": 70.0,
  "dayWidth": 65.0,
  "bufferDays": 8
}
```

## Using Configuration in Code

### Automatic Loading

The configuration is **automatically loaded** when the Timeline widget is initialized. You don't need to do anything special - just ensure the `timeline_config.json` file is in your assets and it will be loaded automatically.

**Steps**:

1. Create `timeline_config.json` in your project root
2. Add it to `pubspec.yaml` assets:
   ```yaml
   flutter:
     assets:
       - timeline_config.json
   ```
3. Use the Timeline widget normally - configuration loads automatically:
   ```dart
   Timeline(
     colors: myColors,
     infos: myInfos,
     elements: myElements,
     // ... other parameters
   )
   ```

The Timeline widget will:
- Load the configuration file from assets on first initialization
- Apply the configuration values automatically
- Show a loading indicator while configuration loads
- Fall back to defaults if the file is not found or has errors

### Configuration Precedence

When the Timeline widget initializes:

1. **File-based configuration** (`timeline_config.json` from assets)
2. **Default values** (if no file or parameter is missing)

The configuration is loaded once per app session and reused for all Timeline widgets.

## Error Handling

The configuration system is designed to be resilient and will never cause your app to crash due to configuration errors.

### File Not Found

If `timeline_config.json` is not found, the system will silently use default values. No error is logged.

### Invalid JSON

If the JSON file is malformed:
- An error is logged to the console with details
- The system falls back to default values
- Your app continues to work normally

Example error:
```
Configuration Error: Failed to parse timeline_config.json
FormatException: Unexpected character at line 5, column 12
Using default configuration values.
```

### Invalid Parameter Values

If a parameter value is invalid (wrong type or out of range):
- A warning is logged to the console
- The invalid parameter is replaced with its default value
- Other valid parameters are still used

Example warning:
```
Configuration Warning: bufferDays - Value 25 is out of range
(provided: 25, expected: int, range: 1-20)
Using default value: 5
```

### Multiple Errors

If multiple parameters are invalid, all errors are collected and reported together:

```
Configuration Validation Results:
- Error: dayWidth out of range (provided: 150.0, expected: 20.0-100.0)
- Error: bufferDays out of range (provided: 25, expected: 1-20)
- Warning: Unknown parameter 'customParam' will be ignored
Using default values for invalid parameters.
```

## Debug Mode

To see which configuration values are being used, enable debug mode:

```dart
TimelineConfigurationManager.enableDebugMode();
```

This will print the active configuration at startup:

```
[Timeline Config] Active configuration:
- dayWidth: 65.0 (from file)
- dayMargin: 5.0 (default)
- bufferDays: 8 (default)
- animationDurationMs: 250 (from file)
...
```

## Troubleshooting

### Configuration Not Loading

**Problem**: Your configuration file isn't being loaded.

**Solutions**:
1. Verify the file is named exactly `timeline_config.json`
2. Ensure it's in the package root directory (same level as `pubspec.yaml`)
3. Check console for parsing errors
4. Enable debug mode to see what configuration is active

### Values Not Applied

**Problem**: You changed values but they're not being used.

**Solutions**:
1. Check console for validation errors
2. Verify values are within valid ranges
3. Ensure JSON syntax is correct (no trailing commas, proper quotes)
4. Remove all comment lines starting with `_`
5. Hot restart your app (hot reload may not reload configuration)

### Performance Issues

**Problem**: Timeline is laggy or slow.

**Solutions**:
1. Reduce `bufferDays` to 3-5
2. Reduce `dayWidth` to 35-40
3. Check if you have too many rows (consider pagination)

### Memory Issues

**Problem**: App crashes or uses too much memory.

**Solutions**:
1. **Reduce `bufferDays`** (most important): Try 3-5
2. Reduce `dayWidth`: Try 35-40
3. Consider reducing the number of rows displayed
4. Monitor memory usage with Flutter DevTools

### Laggy Scrolling

**Problem**: Scrolling feels choppy or unresponsive.

**Solutions**:
1. Reduce `bufferDays` if memory allows
2. Check device performance (test on target devices)

### File Size Warning

**Problem**: You see a warning about file size > 10KB.

**Solution**: The configuration file should be very small (< 1KB typically). If it's over 10KB, you may have included unnecessary data. Use the template as a reference and only include the parameters you want to customize.

## Performance Tuning Guide

### For Small Datasets (< 100 days)

Recommended configuration:
```json
{
  "dayWidth": 70.0,
  "bufferDays": 5,
  "animationDurationMs": 200,
  "barHeight": 80.0
}
```

**Focus**: Better visuals and smoother animations

### For Medium Datasets (100-500 days)

Use default values or customize as needed:
```json
{
  "dayWidth": 65.0,
  "bufferDays": 8,
  "animationDurationMs": 250,
  "barHeight": 70.0
}
```

**Focus**: Balanced performance and visuals (default settings)

### For Large Datasets (> 500 days)

Recommended configuration:
```json
{
  "dayWidth": 50.0,
  "dayMargin": 4.0,
  "bufferDays": 10,
  "animationDurationMs": 300,
  "barHeight": 60.0
}
```

**Focus**: Smoothness and performance over visual details

### For Low-End Devices

Recommended configuration:
```json
{
  "dayWidth": 50.0,
  "bufferDays": 5,
  "animationDurationMs": 300,
  "barHeight": 60.0
}
```

**Focus**: Minimize memory and CPU usage

### For High-End Devices with Large Datasets

Recommended configuration:
```json
{
  "dayWidth": 65.0,
  "bufferDays": 12,
  "animationDurationMs": 250,
  "barHeight": 80.0
}
```

**Focus**: Maximum smoothness with higher resource usage

## Best Practices

1. **Start with recommended values**: Use the recommended configuration for your dataset size from the template file, then customize if needed.

2. **Test on target devices**: Performance varies significantly between devices. Test on the lowest-spec device you need to support.

3. **Monitor memory usage**: Use Flutter DevTools to monitor memory usage, especially when adjusting `bufferDays`.

4. **Iterate gradually**: Change one parameter at a time and test the impact.

5. **Use version control**: Keep your configuration file in version control so you can track changes and revert if needed.

6. **Document your choices**: Add comments in your code or documentation explaining why you chose specific values.

7. **Consider user preferences**: For apps with diverse users, consider providing different configuration files for different performance profiles.

## Examples

### Example 1: Simple Configuration

```json
{
  "dayWidth": 50.0,
  "bufferDays": 10,
  "barHeight": 70.0
}
```

### Example 2: Large Dataset Optimization

```json
{
  "dayWidth": 50.0,
  "dayMargin": 4.0,
  "bufferDays": 10,
  "animationDurationMs": 300,
  "barHeight": 60.0
}
```

### Example 3: Fully Custom Configuration

```json
{
  "dayWidth": 60.0,
  "dayMargin": 4.0,
  "bufferDays": 9,
  "animationDurationMs": 230,
  "rowHeight": 28.0,
  "rowMargin": 2.5,
  "datesHeight": 60.0,
  "barHeight": 80.0
}
```

### Example 4: Minimal Configuration

```json
{
  "bufferDays": 10
}
```

Only customize the parameters you care about. Others will use defaults.

## FAQ

**Q: Do I need a configuration file?**  
A: No, it's optional. Without a configuration file, the timeline uses sensible defaults.

**Q: Can I change configuration at runtime?**  
A: No, configuration is loaded once at initialization and is immutable. You need to restart the app to apply changes to the configuration file.

**Q: What happens if I make a typo in a parameter name?**  
A: Unknown parameters are ignored with an info message in the console. The timeline will work normally.

**Q: Can I use YAML instead of JSON?**  
A: Currently, only JSON format is supported.

**Q: How do I know which configuration to use?**  
A: Start with the recommended values for your dataset size (see template file). If performance isn't satisfactory, customize specific parameters.

**Q: Will this work on web/mobile/desktop?**  
A: Yes, the configuration system works on all Flutter platforms.

**Q: Can I have different configurations for different platforms?**  
A: Not directly through the configuration file. You would need to manage different configuration files manually for each platform.

## Support

If you encounter issues or have questions:

1. Check the troubleshooting section above
2. Enable debug mode to see active configuration
3. Review console logs for validation errors
4. Refer to the template file for parameter details
5. Open an issue on the package repository with your configuration and error logs
