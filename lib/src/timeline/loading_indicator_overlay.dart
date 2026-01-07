import 'package:flutter/material.dart';

/// Overlay widget that displays a loading indicator with a delay threshold.
///
/// Usage:
/// Stack(
///   children: [
///     ...,
///     if (isLoading)
///       LoadingOverlay(),
///   ],
/// )
class LoadingOverlay extends StatelessWidget {
  /// Creates a loading overlay widget.
  const LoadingOverlay({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Widget overlay = Positioned.fill(
      child: Stack(
        children: [
          // Carte centrée + petite anim
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.92, end: 1.0),
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                child: child,
              ),
              child: _Card(
                width: 200,
                borderRadius: 25,
                spinnerSize: 30,
                spinnerStrokeWidth: 4,
              ),
            ),
          ),
        ],
      ),
    );

    overlay = AbsorbPointer(absorbing: true, child: overlay);

    return overlay;
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.width,
    required this.borderRadius,
    required this.spinnerSize,
    required this.spinnerStrokeWidth,
  });

  final double width;
  final double borderRadius;
  final double spinnerSize;
  final double spinnerStrokeWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: spinnerSize,
            height: spinnerSize,
            child: CircularProgressIndicator(
              strokeWidth: spinnerStrokeWidth,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
