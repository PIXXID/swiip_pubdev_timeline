import 'dart:async';
import 'package:flutter/material.dart';

/// Overlay widget that displays a loading indicator with a delay threshold.
///
/// This widget listens to a ValueNotifier of type bool and displays a loading indicator
/// only if the loading state persists for more than the specified threshold.
/// This prevents flickering for quick operations.
class LoadingIndicatorOverlay extends StatefulWidget {
  /// Notifier that controls the loading state
  final ValueNotifier<bool> isLoadingNotifier;

  /// Threshold duration before showing the indicator (default: 200ms)
  final Duration threshold;

  /// Child widget to display behind the overlay
  final Widget child;

  /// Color of the overlay background
  final Color? overlayColor;

  /// Color of the loading indicator
  final Color? indicatorColor;

  const LoadingIndicatorOverlay({
    super.key,
    required this.isLoadingNotifier,
    required this.child,
    this.threshold = const Duration(milliseconds: 200),
    this.overlayColor,
    this.indicatorColor,
  });

  @override
  State<LoadingIndicatorOverlay> createState() => _LoadingIndicatorOverlayState();
}

class _LoadingIndicatorOverlayState extends State<LoadingIndicatorOverlay> {
  /// Timer for threshold delay
  Timer? _thresholdTimer;

  /// Whether to show the indicator (after threshold)
  bool _showIndicator = false;

  @override
  void initState() {
    super.initState();
    widget.isLoadingNotifier.addListener(_onLoadingStateChanged);
  }

  @override
  void dispose() {
    _thresholdTimer?.cancel();
    widget.isLoadingNotifier.removeListener(_onLoadingStateChanged);
    super.dispose();
  }

  /// Handles loading state changes with threshold delay
  void _onLoadingStateChanged() {
    final isLoading = widget.isLoadingNotifier.value;

    if (isLoading) {
      // Start threshold timer
      _thresholdTimer?.cancel();
      _thresholdTimer = Timer(widget.threshold, () {
        // Only show indicator if still loading after threshold
        if (widget.isLoadingNotifier.value && mounted) {
          setState(() {
            _showIndicator = true;
          });
        }
      });
    } else {
      // Cancel timer and hide indicator immediately
      _thresholdTimer?.cancel();
      if (_showIndicator && mounted) {
        setState(() {
          _showIndicator = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Child widget
        widget.child,

        // Loading overlay (only shown after threshold)
        if (_showIndicator)
          Positioned.fill(
            child: Container(
              color: widget.overlayColor ?? Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.indicatorColor ?? Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
