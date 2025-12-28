---
inclusion: always
---

# Product Overview

High-performance Flutter timeline/Gantt chart widget for displaying project schedules, milestones, and activities. Designed for large datasets with lazy rendering, granular state management, and memory-efficient operations.

## Key Features

- Lazy rendering with configurable buffer zones
- ValueNotifier-based state management for localized updates
- Data caching to avoid redundant calculations
- Scroll throttling (~60 FPS)
- External JSON configuration for performance tuning
- Support for stages, elements, capacities, and milestones
- Interactive day/stage/element editing callbacks

## Performance Characteristics

- Handles 500+ days with 100+ stages efficiently
- Initial render < 500ms
- Memory usage ~50MB (vs ~200MB unoptimized)
- 90% reduction in rebuild count vs naive implementation

## Configuration

External configuration via `timeline_config.json` allows runtime tuning of:
- Day width, margins, and buffer zones
- Scroll throttling and animation durations
- Row heights and timeline dimensions

Recommended configurations provided for small (<100 days), medium (100-500 days), and large (>500 days) datasets.
